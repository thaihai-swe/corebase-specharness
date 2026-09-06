"""Local package-health checks for an embedded CoreBase SpecHarness installation."""
from core._lib import doctor_checks
from core._lib.root import resolve_root
from core.harness.config import HarnessConfig


def run_doctor(root_path):
    root = resolve_root(root_path)
    if not root:
        return {"ok": False, "checks": [], "failed": 1, "error": "Could not resolve repository root"}
    checks = []
    for name, callback in (
        ("manifest", lambda: doctor_checks.check_contracts(root)),
        ("ownership", lambda: doctor_checks.check_manifest_overlap(root)),
        ("surfaces", lambda: doctor_checks.check_surface_integrity(root)),
        ("context_routes", lambda: doctor_checks.check_context_routes(root)),
        ("commands", lambda: doctor_checks.check_command_registry(root)),
        ("providers", lambda: doctor_checks.check_provider_contract(root)),
        ("upgrade_contracts", lambda: doctor_checks.check_upgrade_contracts(root)),
        ("static_audit", lambda: doctor_checks.check_static_audit(root)),
    ):
        try:
            failures = callback()
        except Exception as exc:
            failures = [str(exc)]
        checks.append({"name": name, "status": "pass" if not failures else "fail",
                       "message": "ok" if not failures else "; ".join(failures)})
    try:
        HarnessConfig(f"{root}/corebase-specharness/project/harness-config.yaml")
        checks.append({"name": "configuration", "status": "pass", "message": "ok"})
    except Exception as exc:
        checks.append({"name": "configuration", "status": "fail", "message": str(exc)})
    try:
        warnings = doctor_checks.check_project_setup(root)
    except Exception as exc:
        warnings = [f"project setup could not be evaluated: {exc}"]
    checks.append({"name": "project_setup", "status": "warn" if warnings else "pass", "message": "ok" if not warnings else "; ".join(warnings)})
    failed = sum(check["status"] == "fail" for check in checks)
    return {"ok": failed == 0, "checks": checks, "failed": failed}


def doctor(args):
    outcome = run_doctor(args.root)
    if getattr(args, "full", False) and outcome.get("ok"):
        from types import SimpleNamespace
        try:
            from core.handlers.diagnostics.memory import memory_audit
            mem_res = memory_audit(SimpleNamespace(root=args.root, feature="", dry_run=False))
            mem_ok = mem_res.get("status") == "ok"
            outcome["checks"].append({
                "name": "memory_audit",
                "status": "pass" if mem_ok else "fail",
                "message": "ok" if mem_ok else "; ".join(mem_res.get("errors") or ["hard cap breached"]),
            })
            if not mem_ok:
                outcome["failed"] = outcome.get("failed", 0) + 1
                outcome["ok"] = False
        except Exception as exc:
            outcome["checks"].append({"name": "memory_audit", "status": "fail", "message": str(exc)})
            outcome["failed"] = outcome.get("failed", 0) + 1
            outcome["ok"] = False

        try:
            from core.handlers.diagnostics.evals import eval_run
            eval_res = eval_run(SimpleNamespace(
                root=args.root, case="", suite="smoke", live=False, agent_cmd=[], dry_run=False, from_feature="",
            ))
            eval_ok = eval_res.get("status") == "ok"
            outcome["checks"].append({
                "name": "eval_smoke",
                "status": "pass" if eval_ok else "fail",
                "message": "ok" if eval_ok else "; ".join(eval_res.get("errors") or ["eval smoke failed"]),
            })
            if not eval_ok:
                outcome["failed"] = outcome.get("failed", 0) + 1
                outcome["ok"] = False
        except Exception as exc:
            outcome["checks"].append({"name": "eval_smoke", "status": "fail", "message": str(exc)})
            outcome["failed"] = outcome.get("failed", 0) + 1
            outcome["ok"] = False

    errors = [
        f"{check['name']}: {check['message']}"
        for check in outcome.get("checks", [])
        if check.get("status") == "fail"
    ]
    warnings = [
        f"{check['name']}: {check['message']}"
        for check in outcome.get("checks", [])
        if check.get("status") == "warn"
    ]
    return {
        "status": "ok" if outcome.get("ok") else "failed",
        "errors": errors,
        "warnings": warnings,
        "details": outcome,
    }
