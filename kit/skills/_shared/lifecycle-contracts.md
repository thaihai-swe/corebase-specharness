# Canonical Lifecycle Contracts

> **Authority:** `corebase-specharness/project/state-machine.yaml`

Write `- Phase:` only through `status-set`, `skill-enter`, or `skill-exit`. Use these exact tokens.

## 1. Phase tokens

| Token | Set by | Meaning | Suggested handoff |
| --- | --- | --- | --- |
| `Researching` | `spec-research` | Investigation active | — |
| `ResearchComplete` | `spec-research` | `analysis.md` ready | `spec-requirements` |
| `Specifying` | `spec-requirements` | Spec authoring active | — |
| `SpecApproved` | `spec-requirements` | `spec.md` locked | `spec-plan` |
| `Planning` | `spec-plan` | Design authoring active | `spec-tasks` |
| `TaskPlanning` | `spec-tasks` | Task graph authoring | — |
| `PlanApproved` | `spec-tasks` | `plan.md` + `tasks.md` ready | `spec-implement` |
| `Implementing` | `spec-implement` | Code work active | — |
| `Verifying` | `harness-verify` | Verification active | — |
| `Done` | `harness-verify` | Gate + alignment + post-ship complete | — |

## 2. Exception tokens (`status-set`)

| Token | Meaning |
| --- | --- |
| `NeedsClarification` | Missing product decision |
| `Blocked` | External dependency; name the blocker |
| `Replanning` | Design/task graph invalidated |
| `ChangesRequested` | Verification found correctable defects |
| `Abandoned` | Feature stopped; archive reusable lessons |

## 3. Transition rules

1. Forward only, except explicit correction of a failed or stale state.
2. Set phase at skill start via `skill-enter`.
3. `SpecApproved`, `PlanApproved`, and `Done` require the skill's verification checklist; they are the last act, not the first.
4. No phase skipping. `spec-implement` requires `PlanApproved`. `harness-verify` requires `Implementing` or a re-verify trigger.
5. Re-entry is explicit. Spec gaps return to `spec-requirements` with a `status.md` note.

Complexity scale is `Simple | Moderate | Complex`. Do not invent alternate profile names.

## 4. HALT markers

Use `[:HALT ...]` markers to block progress on incomplete, ambiguous, or stale states:

| Marker | Meaning | Owning / Escalation Skill |
| --- | --- | --- |
| `[:HALT NEEDS CLARIFICATION]` | Missing external decision or information | `/spec-requirements` |
| `[:HALT UNRESOLVED]` | Multiple failed attempts to resolve ambiguity | Escalate to user |
| `[:HALT ADR CONFLICT: ADR-NNN]` | Contested architecture decision or spec violates ADR | `/spec-adr` |
| `[:HALT SECURITY: <desc>]` | Security-sensitive path without evidence | `/harness-verify` |
| `[:HALT INCONCLUSIVE]` | Evidence too sparse; cannot determine root cause or tight loop | `/spec-research` |
| `[:HALT STALE — spec amended <date>]` | Spec changed after plan/tasks approved; requires re-planning | `/spec-plan` |
| `[:HALT SYNC REQUIRED]` | Post-ship memory sync heading is missing; block `Done` | `/context-memory` |

All HALT markers must be resolved before phase completion. Task mutations (`task-start`, `task-done`, `task-block`) are mechanically blocked while any `[:HALT` substring exists in `spec.md`, `plan.md`, or `tasks.md`.

## 5. Handoff protocol

Before switching skills or closing a session:

1. Record decided and rejected choices (with depth, seam, and blast radius context).
2. List open risks, unresolved questions, and any active `[:HALT ...]` markers.
3. Reference context omitted for budget reasons.
4. Write the handoff to `.corebase-specharness/sessions/<slug>/session.md` with `session-checkpoint` or `session-end`.
5. Run `phase-check --skill <name>`, then `artifact-check --skill <name>` or `verify --skill <name>` as the skill requires.
6. Verify that required writes for the leaving skill exist before calling `skill-exit`.

Keep the handoff readable in under 30 seconds.

## 6. Decision points

Stop and record a decision when a choice changes public behavior, security, data shape, migration, performance, or component boundaries.

```text
- Question:
- Options (at least 2 viable options):
- Depth / seam / blast radius comparison:
- Reversibility: Easy | Moderate | Hard
- Chosen option:
- Rationale/trade-off:
- Proof or follow-up artifact: ADR | plan | spec | none
```

When the decision has material trade-offs and is hard to reverse, invoke `/spec-adr`. Do not choose silently.
