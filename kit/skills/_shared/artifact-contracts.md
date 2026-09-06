# Canonical Artifact Contracts

> **Authority:** `core._lib.artifact_schema`, `core.task_graph`, `skills/_shared/status-template.md`

## 1. Feature artifacts

Feature artifacts live in `artifacts/features/<slug>/`.

| File | Role |
| --- | --- |
| `status.md` | Delivery phase and high-level progress. Do not hand-edit `- Phase:`. |
| `spec.md` | Acceptance criteria with `AC-*` identifiers and problem statement |
| `plan.md` | Approach, public seams, module map, risks, and proof surfaces |
| `tasks.md` | Granular `T-NNN` items with status, proof commands, and AC links |
| `review.md` | Two-axis review (Standards vs Spec), decision, and follow-up |
| `analysis.md` | Research findings when `/spec-research` ran |
| `session-extracts.md` | Feature-local candidates; `## Post-Ship Sync` required before `Done` |

ADRs live in `corebase-specharness/project/adr/` as `NNNN-<slug>.md`; `ADR-NNN` remains the logical identifier.

## 2. AC / task linkage and slicing

Every acceptance criterion maps to at least one task (`Covers: AC-001`). Every Done task includes fresh validation evidence or proof. Task IDs use `T-NNN` only; older `TASK-*` IDs are not parsed.

- **Tracer bullet slices:** Prefer vertical slices cutting across all layers a task touches.
- **Expand–Contract refactors:** For wide mechanical changes, sequence as expand (add new) → migrate (batch call sites) → contract (delete old).
- **Public seams:** Tests observe behavior at declared public interfaces; do not test private implementation state.

## 3. Verification evidence

- Before marking a task Done, confirm proof matches planned proof surfaces and runs through public seams.
- For code tasks: tests must pass, lint must be clean, build must succeed, and tests must not be tautological or implementation-coupled.
- **Bug fixes ("Fix the code, not the test")**: Write and run the failing reproduction test first at a public seam. Watch it fail for the exact bug symptom. Freeze the test file: do not modify, weaken, or delete the test while debugging. Fix only application/production code until the test passes.
- **Visual & UI:** Terminal test exit codes alone are insufficient. Capture visual evidence before marking verified.
- For spec tasks: all ACs written, no HALT markers remaining.
- For design tasks: architecture documented with ADR if contested; module depth / seams declared.
- For closeout: two-axis review in `review.md` independently before deciding verdict.
- Prefer `python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify` for closeout.
- Bare `verify --feature <slug>` remains the coarse `--phase Verify` compatibility path.

After verification, set `- Phase:` only through `skill-exit` or `status-set`. An advisory `verify` exit code of `0` is not a verification verdict; inspect `details.verified`.

`Done` is mechanically protected: `skill-exit --skill harness-verify` runs verification inline. It requires a passing current-config result and a `## Post-Ship Sync` section in `session-extracts.md`. `review.md` and advisory `verify` exit code `0` do not independently authorize `Done`. Use `--verification-override --override-reason "..."` only for a deliberate, explicit exception.
