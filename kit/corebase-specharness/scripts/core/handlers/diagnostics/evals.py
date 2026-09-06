"""Continuous evaluation benchmark handler for agent skills, prompts, and policies."""

from __future__ import annotations

import json
import re
import shlex
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any

from core._lib.artifact_schema import REQUIRED_HEADINGS, extract_ac_ids, traceability_summary
from core._lib.artifacts import canonical_feature_dir
from core._lib.yaml_reader import load as load_yaml
from core.handlers.common import _resolve_root, _result


def _eval_config(root: Path) -> dict[str, Any]:
    config_path = root / "corebase-specharness/evals/eval-config.yaml"
    if not config_path.is_file():
        return {}
    try:
        return load_yaml(str(config_path)) or {}
    except Exception:
        return {}


def _load_case(path: Path) -> dict[str, Any] | None:
    try:
        if path.suffix == ".json":
            return json.loads(path.read_text(encoding="utf-8"))
        if path.suffix in (".yaml", ".yml"):
            return load_yaml(str(path))
    except Exception:
        return None
    return None


def _discover_cases(root: Path, case_id: str = "", suite_name: str = "") -> list[dict[str, Any]]:
    cases_dir = root / "corebase-specharness/evals/cases"
    if not cases_dir.is_dir():
        return []

    config = _eval_config(root)
    suites = config.get("suites") or {}
    suite_case_ids: set[str] | None = None
    if suite_name:
        suite_def = suites.get(suite_name)
        if isinstance(suite_def, dict):
            suite_case_ids = set(suite_def.get("cases") or [])
        elif isinstance(suite_def, list):
            suite_case_ids = set(suite_def)
        else:
            suite_case_ids = set()

    cases = []
    for path in sorted(cases_dir.glob("*")):
        if not path.is_file() or path.suffix not in (".json", ".yaml", ".yml"):
            continue
        data = _load_case(path)
        if not isinstance(data, dict):
            continue
        cid = str(data.get("id") or path.stem)
        data["id"] = cid
        data["_path"] = str(path.relative_to(root))

        if case_id and cid != case_id and path.stem != case_id:
            continue
        if suite_case_ids is not None and cid not in suite_case_ids:
            continue
        cases.append(data)
    return cases


def _evaluate_rubric(
    artifacts: dict[str, str],
    rubric: dict[str, Any],
) -> tuple[bool, list[str], list[str], int]:
    """Grade an artifact collection against an eval case rubric."""
    errors: list[str] = []
    warnings: list[str] = []

    # 1. Required files
    required_files = rubric.get("required_files") or []
    for filename in required_files:
        if filename not in artifacts or not artifacts[filename].strip():
            errors.append(f"missing required artifact: {filename}")

    # 2. Required headings
    required_headings = rubric.get("required_headings") or {}
    for filename, headings in required_headings.items():
        content = artifacts.get(filename, "")
        if not content:
            continue
        for heading in headings:
            clean = heading.strip()
            if clean not in content and clean.lower() not in content.lower():
                errors.append(f"{filename} missing required heading: {clean}")

    # 3. Must contain patterns
    must_contain = rubric.get("must_contain") or {}
    for filename, patterns in must_contain.items():
        content = artifacts.get(filename, "")
        for pattern in patterns:
            if not re.search(pattern, content, re.IGNORECASE):
                errors.append(f"{filename} did not match required pattern: '{pattern}'")

    # 4. Forbidden anti-patterns
    forbidden = rubric.get("forbidden") or {}
    for filename, patterns in forbidden.items():
        content = artifacts.get(filename, "")
        for pattern in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                errors.append(f"{filename} matched forbidden pattern: '{pattern}'")

    # 5. Acceptance criteria count
    min_ac = int(rubric.get("min_ac_count", 0))
    if min_ac > 0 and "spec.md" in artifacts:
        ac_ids = extract_ac_ids(artifacts["spec.md"])
        if len(ac_ids) < min_ac:
            errors.append(f"spec.md has {len(ac_ids)} AC IDs; minimum required is {min_ac}")

    # 6. Bi-directional traceability
    if rubric.get("require_traceability") and "spec.md" in artifacts and "tasks.md" in artifacts:
        summary = traceability_summary(artifacts["spec.md"], artifacts["tasks.md"])
        if summary.get("missing_task_links"):
            errors.append("unmapped ACs: " + ", ".join(summary["missing_task_links"]))
        if summary.get("orphan_task_links"):
            errors.append("orphan AC links: " + ", ".join(summary["orphan_task_links"]))

    raw_ok = len(errors) == 0
    if rubric.get("expect_fail"):
        if raw_ok:
            errors.append("expected rubric failure but all checks passed")
            passed = False
        else:
            warnings.extend(f"expected failure: {item}" for item in errors)
            errors = []
            passed = True
    else:
        passed = raw_ok
    score = 100 if passed else max(0, 100 - (max(1, len(errors)) * 25))
    return passed, errors, warnings, score


def _run_live_agent(
    root: Path,
    case: dict[str, Any],
    agent_cmd: list[str],
    timeout_seconds: int = 180,
) -> tuple[dict[str, str], list[str]]:
    """Execute live headless agent in an isolated workspace."""
    artifacts: dict[str, str] = {}
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="specharness-eval-") as tmpdir:
        tmppath = Path(tmpdir)
        feature_dir = tmppath / "artifacts/features" / case["id"]
        feature_dir.mkdir(parents=True, exist_ok=True)

        # Seed initial fixtures if provided
        initial = case.get("initial_artifacts") or {}
        for fname, fcontent in initial.items():
            (feature_dir / fname).write_text(fcontent, encoding="utf-8")

        prompt = f"Run skill /{case.get('skill', 'spec-requirements')} on feature {case['id']}: {case.get('intent', '')}"
        cmd = [
            part.format(
                root=str(root),
                skill=case.get("skill", ""),
                intent=case.get("intent", ""),
                feature=case["id"],
                feature_dir=str(feature_dir),
                prompt=prompt,
            )
            for part in agent_cmd
        ]

        try:
            res = subprocess.run(
                cmd,
                cwd=str(tmppath),
                capture_output=True,
                text=True,
                timeout=timeout_seconds,
                check=False,
            )
            if res.returncode != 0:
                errors.append(f"live agent exited with code {res.returncode}: {res.stderr[:500]}")
        except subprocess.TimeoutExpired:
            errors.append(f"live agent timed out after {timeout_seconds}s")
        except Exception as exc:
            errors.append(f"failed to run live agent command: {exc}")

        # Collect resulting artifacts
        if feature_dir.is_dir():
            for fpath in feature_dir.glob("*.md"):
                artifacts[fpath.name] = fpath.read_text(encoding="utf-8", errors="replace")

    return artifacts, errors


def _slug_to_case_id(slug: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "_", slug.strip().lower()).strip("_")
    return f"case_{cleaned}" if cleaned else "case_recorded"


def _record_from_feature(root: Path, slug: str, dry_run: bool) -> dict[str, Any]:
    """Snapshot a feature directory into an eval fixture with an inferred rubric."""
    feature_dir = canonical_feature_dir(root, slug)
    if not feature_dir.is_dir():
        return _result(
            "eval-run",
            status="failed",
            feature=slug,
            errors=[f"feature directory not found: {feature_dir.relative_to(root)}"],
        )

    artifacts: dict[str, str] = {}
    for path in sorted(feature_dir.glob("*.md")):
        artifacts[path.name] = path.read_text(encoding="utf-8", errors="replace")
    if not artifacts:
        return _result(
            "eval-run",
            status="failed",
            feature=slug,
            errors=[f"no markdown artifacts under {feature_dir.relative_to(root)}"],
        )

    headings = {
        name: list(REQUIRED_HEADINGS[name])
        for name in artifacts
        if name in REQUIRED_HEADINGS and REQUIRED_HEADINGS[name]
    }
    rubric: dict[str, Any] = {
        "required_files": list(artifacts),
        "required_headings": headings,
    }
    if "spec.md" in artifacts:
        rubric["min_ac_count"] = max(1, len(extract_ac_ids(artifacts["spec.md"])))
    if "spec.md" in artifacts and "tasks.md" in artifacts:
        rubric["require_traceability"] = True

    case_id = _slug_to_case_id(slug)
    case = {
        "id": case_id,
        "skill": "",
        "description": f"Recorded golden fixture from feature {slug}",
        "intent": f"replay {slug}",
        "artifacts": artifacts,
        "rubric": rubric,
    }
    dest = root / "corebase-specharness/evals/cases" / f"{case_id}.json"
    if dry_run:
        return _result(
            "eval-run",
            status="ok",
            feature=slug,
            details={
                "dry_run": True,
                "would_write": str(dest.relative_to(root)),
                "case": {"id": case_id, "required_files": rubric["required_files"]},
                "text": f"DRY-RUN would write {dest.relative_to(root)} ({len(artifacts)} artifacts)",
            },
        )

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(case, indent=2) + "\n", encoding="utf-8")
    relative = str(dest.relative_to(root))
    return _result(
        "eval-run",
        status="ok",
        feature=slug,
        artifacts=[relative],
        details={
            "recorded": True,
            "path": relative,
            "case_id": case_id,
            "artifact_count": len(artifacts),
            "text": f"Recorded {case_id} -> {relative} ({len(artifacts)} artifacts)",
        },
    )


def _format_eval_text(details: dict[str, Any]) -> str:
    """Human-readable eval-run summary for non-JSON CLI output."""
    if details.get("dry_run"):
        lines = [f"DRY-RUN {details.get('count', 0)} case(s)"]
        for item in details.get("cases") or []:
            lines.append(f"  {item.get('id', '')}  {item.get('skill', '')}")
        return "\n".join(lines)

    lines = []
    width = max((len(item.get("id", "")) for item in details.get("results") or []), default=8)
    for item in details.get("results") or []:
        mark = "PASS" if item.get("passed") else "FAIL"
        lines.append(
            f"{mark} {item.get('id', ''):<{width}}  ({item.get('score', 0)}/100) [{item.get('duration_ms', 0)}ms]"
        )
        for err in item.get("errors") or []:
            lines.append(f"     {err}")
    total = details.get("total_cases", 0)
    passed = details.get("passed_cases", 0)
    failed = details.get("failed_cases", 0)
    rate = details.get("pass_rate_percent", 0)
    lines.append("-" * 49)
    lines.append(f"{passed} passed, {failed} failed | {total} total | Pass rate: {rate}%")
    return "\n".join(lines)


def eval_run(args: Any) -> dict[str, Any]:
    """Execute continuous eval benchmarks against skills and policies."""
    root = _resolve_root(args)
    from_feature = (getattr(args, "from_feature", "") or "").strip()
    if from_feature:
        return _record_from_feature(root, from_feature, bool(getattr(args, "dry_run", False)))

    case_id = (getattr(args, "case", "") or "").strip()
    suite_name = (getattr(args, "suite", "") or "").strip()
    is_live = bool(getattr(args, "live", False))
    dry_run = bool(getattr(args, "dry_run", False))

    config = _eval_config(root)
    cases = _discover_cases(root, case_id=case_id, suite_name=suite_name)

    if not cases:
        msg = f"No eval cases matched criteria (case='{case_id}', suite='{suite_name}')"
        return _result(
            "eval-run",
            status="failed" if (case_id or suite_name) else "ok",
            warnings=[msg],
            errors=[msg] if (case_id or suite_name) else [],
            details={"cases_found": 0, "results": []},
        )

    if dry_run:
        summary = [
            {"id": c["id"], "skill": c.get("skill", ""), "description": c.get("description", "")}
            for c in cases
        ]
        details = {"dry_run": True, "cases": summary, "count": len(summary)}
        details["text"] = _format_eval_text(details)
        return _result(
            "eval-run",
            status="ok",
            details=details,
        )

    agent_cmd = getattr(args, "agent_cmd", None)
    if not agent_cmd and is_live:
        agent_cmd = (config.get("live_runner") or {}).get("command") or []
        if isinstance(agent_cmd, str):
            agent_cmd = shlex.split(agent_cmd)

    if is_live and not agent_cmd:
        return _result(
            "eval-run",
            status="failed",
            errors=["--live requested but no agent runner command was provided or configured"],
            details={},
        )

    results = []
    all_findings: list[str] = []
    total_passed = 0

    for case in cases:
        start_time = time.time()
        rubric = case.get("rubric") or {}

        if is_live:
            artifacts, runner_errors = _run_live_agent(root, case, agent_cmd)
        else:
            artifacts = case.get("artifacts") or {}
            runner_errors = []

        passed, rubric_errors, rubric_warns, score = _evaluate_rubric(artifacts, rubric)
        errors = runner_errors + rubric_errors
        if runner_errors:
            passed = False
            score = max(0, score - 30)

        if passed:
            total_passed += 1

        duration_ms = int((time.time() - start_time) * 1000)
        case_res = {
            "id": case["id"],
            "skill": case.get("skill", ""),
            "passed": passed,
            "score": score,
            "errors": errors,
            "warnings": rubric_warns,
            "duration_ms": duration_ms,
        }
        results.append(case_res)
        for err in errors:
            all_findings.append(f"[{case['id']}] {err}")

    pass_rate = round((total_passed / len(cases)) * 100, 1) if cases else 0.0
    overall_status = "ok" if total_passed == len(cases) else "failed"
    details = {
        "mode": "live" if is_live else "deterministic",
        "total_cases": len(cases),
        "passed_cases": total_passed,
        "failed_cases": len(cases) - total_passed,
        "pass_rate_percent": pass_rate,
        "results": results,
    }
    details["text"] = _format_eval_text(details)

    return _result(
        "eval-run",
        status=overall_status,
        findings=all_findings,
        errors=all_findings if overall_status == "failed" else [],
        details=details,
    )
