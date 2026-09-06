---
id: skill-harness-verify
name: harness-verify
description: "Verify implemented work against the spec and plan. Handles split verification modes, mechanical gates, optional fallow-pass cleanup, manual testing guides, and final closeout authority."
tags: ['harness', 'verification', 'gates']
triggers: ['verify', 'gate', 'test', 'validation']
---
# Harness Verify

## At a Glance

| | |
|---|---|
| **Reads** | `security.md` (§Verification), `harness-config.yaml`, `spec.md`, `tasks.md`, `plan.md` |
| **Writes** | Required: `review.md`. Optional: `status.md` (`Verifying` → `Done` / `ChangesRequested`) |
| **Key CLI** | `python3 corebase-specharness/scripts/core/cli.py skill-enter --skill harness-verify --feature <slug>`, `python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify`, `python3 corebase-specharness/scripts/core/cli.py skill-exit --skill harness-verify --feature <slug> --handoff context-memory` |
| **Handoff** | `/context-memory` after `Done`; `## Post-Ship Sync` required first |
| **Session** | `.corebase-specharness/sessions/<slug>/session.md` |

## Overview

Sole authority for AC completion and `Done`. Runs gates, AC-to-task traceability, security audit, two-axis review, and writes `review.md`. Use when all `tasks.md` items are done, or to re-verify after a fix or replan.

## Execution Modes & Profiles

| Pass | Scope | Required output |
|---|---|---|
| `mechanical-gate` | Configured build/lint/test runners | Pass/fail in `review.md` |
| `alignment-audit` | AC ↔ task ↔ proof | `AC-ID \| Task-ID \| Proof \| Pass/Fail` |
| `design-conformance` | Code vs `plan.md` | `Design Element \| Evidence \| Pass/Fail` |
| `security-audit` | `core-policies.md` `## Security Policy` | Security Audit in `review.md` |

## Step-by-Step Execution Workflow

1. **Pre-flight**:
   - `python3 corebase-specharness/scripts/core/cli.py skill-enter --skill harness-verify --feature <slug> --intent "<request>"`.
   - Pass `--full` only when reloading. See `skills/_shared/context-loading.md`.
   - `python3 corebase-specharness/scripts/core/cli.py phase-check --feature <slug> --skill harness-verify`.

2. **Mechanical gates**:
   - `python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify`.
   - `python3 corebase-specharness/scripts/core/cli.py artifact-check --feature <slug> --skill harness-verify --trace`.
   - If this closeout changed skills, prompts, or policies, also run `python3 corebase-specharness/scripts/core/cli.py eval-run --suite smoke --json`. Record the result in `review.md`. A failing smoke suite is a Fail, not a deferred note.
   - **Visual & UI Feedback**: If the feature touches UI components, views, or styles, terminal test exit codes alone are insufficient. Capture visual evidence (browser inspection, rendered HTML/DOM assertion logs, or screenshot artifacts) and cite it in `review.md` before a Pass.

3. **Alignment & two-axis review**:
   - Map every `AC-*` to a completed `T-NNN` with fresh proof. Unmapped AC = `Fail`.
   - After `verify`, review the `git` diff on two isolated axes. Delegate each axis to a **read-only verifier subagent** when available; keep reports summarized, not raw traces:
     1. **Standards**: `code-design.md`, `security.md`, Fowler smells in `references/review-template.md`. Repo rules override. Smells are judgement, not hard fails. Skip tooling-enforced items.
     2. **Spec**: missing/partial `AC-*`, unrequested behavior, wrong implementations. Cite the spec line.
     Present both reports side by side. Do not merge or rerank.
   - Check architecture vs `plan.md`.
   - Inspect `git diff` for deleted public surface or removed tests without spec justification.

4. **Security & provider**:
   - Audit `core-policies.md` `## Security Policy`.
   - Record `verify` provider outcome in `review.md` `## Provider Review`. Default `providers.review.active: none`, `mode: optional`. Missing provider is `deferred`, not Fail. Two-axis review is required. Enable `open-code-review` only after local `ocr` setup. `mode: required` only when closeout must fail without `ocr review`.

5. **Closeout**:
   - On pass, record `Verification passed; sync pending`.
   - Write `## Post-Ship Sync` in `session-extracts.md` (`no candidates` if none). `skill-exit` to `Done` fails without that heading and `review.md`.
   - Invoke `/context-memory` after `Done`. Missing heading → `[:HALT SYNC REQUIRED]`; do not exit to `Done`.
   - Write verdict (`Pass`, `Pass with Follow-Up Debt`, `Fail`) via `references/review-template.md`.
   - Pass + `details.verified: true` → `python3 corebase-specharness/scripts/core/cli.py skill-exit --skill harness-verify --feature <slug> --handoff context-memory`.
   - No confirmed gates or not verified → `ChangesRequested`, configure gates, or `--verification-override --override-reason "..."`.
   - Fail → `python3 corebase-specharness/scripts/core/cli.py skill-exit --skill harness-verify --feature <slug> --phase ChangesRequested --handoff spec-implement`.

## Anti-Patterns & Red Flags

- `Done` without mechanical verify or post-ship sync.
- Passing with an unmapped `AC-*`.
- Accepting stale prior-session logs.
- Ignoring `verify` failures.
- Shipping a UI change on test exit codes alone, without visual evidence in `review.md`.
- Skipping `eval-run --suite smoke` after skills, prompts, or policies changed.

## Core Rules

- Only this skill may `skill-exit` with `Done`.
- Every `AC-*` MUST map to a task with verifiable proof.
- Write `## Post-Ship Sync` before `Done`, then hand off to `/context-memory`.
- Proof MUST match planned surfaces.
