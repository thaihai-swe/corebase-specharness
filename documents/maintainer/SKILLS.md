# Skill catalog

> **Audience:** adopters, developers, coding agents, and maintainers
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/skills/*/SKILL.md`, `kit/skills/_shared/`,
> `kit/references/context-routes.yaml`

## Skill model

CoreBase SpecHarness ships 11 peer-level agent procedures. Each procedure lives at:

```text
skills/<name>/SKILL.md
```

Every skill can be invoked directly. The common delivery route is a suggested
handoff sequence, not a hierarchy. Use `/starter-init` only when the
repository is untailored.

Skills are Markdown procedures, not Python plugins. The Python CLI supplies
deterministic context, session, task, artifact, gate, provider, memory, and
ADR operations.

`references/context-routes.yaml` is the only routing authority. It contains
exactly one route for each shipped skill.

`corebase-specharness/project/state-machine.yaml` owns lifecycle tokens.
`skills/_shared/status-phases.md` is human guidance and must stay subordinate
to that YAML.

## Selecting a skill

| Situation | Direct entrypoint |
| --- | --- |
| Untailored repository or onboarding drift | `/starter-init` |
| Unknown behavior, bug, incident, or brownfield subsystem | `/spec-research` |
| Need to define or refine requirements and acceptance criteria | `/spec-requirements` |
| Approved requirements need a technical design | `/spec-plan` |
| Approved design needs an executable task graph | `/spec-tasks` |
| Approved tasks are ready for implementation | `/spec-implement` |
| Implementation needs final evidence-backed verification | `/harness-verify` |
| Durable lessons need promotion, audit, archival, or compaction | `/context-memory` |
| Harness configuration or agent quality needs assessment | `/harness-maintain` |
| A material technical decision needs an ADR | `/spec-adr` |
| Manual QA needs repeatable test scenarios | `/spec-testing-scenario` |

## Shipped skills

Phase, profile, feature requirement, prerequisites, writes, enter/exit, and
handoffs come from `references/context-routes.yaml`. Triggers come from each
skill's frontmatter. `status.md` is never a required write.

| Skill | Route | Enter → exit | Required write | Prerequisites | Triggers | Suggested handoff |
| --- | --- | --- | --- | --- | --- | --- |
| `/starter-init` | Bootstrap; `bootstrap`; feature optional | none | none (writes `corebase-specharness/project`, `corebase-specharness/memories/repo`) | none | `init`, `start`, `setup`, `install` | `/spec-research`, `/spec-requirements` |
| `/spec-research` | Spec; `research`; feature required | `Researching` → `ResearchComplete` | `analysis.md` | none | `research`, `explore`, `brownfield`, `unknown`, `incident`, `5 whys` | `/spec-requirements`, `/spec-adr` |
| `/spec-requirements` | Spec; `requirements`; feature required | `Specifying` → `SpecApproved` | `spec.md` | none | `requirement`, `spec`, `feature` | `/spec-plan`, `/spec-research` |
| `/spec-plan` | Plan; `planning`; feature required | `Planning` → `Planning` | `plan.md` | `spec.md` | `plan`, `design`, `architecture`, `technical design` | `/spec-tasks`, `/spec-research`, `/spec-adr` |
| `/spec-tasks` | Plan; `planning`; feature required | `TaskPlanning` → `PlanApproved` | `tasks.md` | `spec.md`, `plan.md` | `task`, `breakdown`, `estimate`, `milestone` | `/spec-implement`, `/spec-plan` |
| `/spec-implement` | Implement; `implement`; feature required | `Implementing` → `Implementing` | none (optional project source, `tasks.md`, `session-extracts.md`) | `spec.md`, `plan.md`, `tasks.md` | `implement`, `code`, `build`, `deliver` | `/harness-verify`, `/spec-plan`, `/spec-requirements` |
| `/harness-verify` | Verify; `verify`; feature required | `Verifying` → `Done` | `review.md` | `spec.md`, `plan.md`, `tasks.md` | `verify`, `gate`, `test`, `validation` | `/context-memory`, `/spec-implement`, `/spec-plan` |
| `/context-memory` | Verify; `compact`; feature optional | none | none (writes memory dirs; optional `session-extracts.md`) | none | `memory`, `heuristic`, `learned`, `update memory`, `compact`, `compress`, `memory full`, `token budget` | `/harness-verify` |
| `/harness-maintain` | Verify; `verify`; feature optional | none | none (optional `corebase-specharness/generated/harness-assessment.md`) | none | `maintain harness`, `harness health`, `diagnose harness`, `improve harness` | none |
| `/spec-adr` | Plan; `planning`; feature optional | none | none (writes `corebase-specharness/project/adr`; optional `adr-log.md`) | none | `adr`, `decision`, `architecture decision` | none |
| `/spec-testing-scenario` | Verify; `verify`; feature required | none | `testing-scenarios.md` | `spec.md` | `testing scenario`, `test scenarios`, `test guide`, `manual test`, `testing-scenarios` | none |

Directory writes (`corebase-specharness/project`, `corebase-specharness/memories/repo`,
`corebase-specharness/memories/domain`, `corebase-specharness/project/adr`, `project-source`) are
normalized as `kind: directory` and are **not** required by `skill-exit`.
String file writes default to required. Object writes honor `{path, required}`.

Optional writes from the route registry:

- `spec-research`: `status.md`
- `spec-requirements`: `proposal.md`, `requirements-review.md`, `status.md`
- `spec-plan`, `spec-tasks`, `spec-implement`, `harness-verify`: `status.md`
- `spec-implement`: `tasks.md`, `session-extracts.md`, `project-source`
- `context-memory`: `session-extracts.md`
- `harness-maintain`: `learned-heuristics.md`

## Headings: runtime versus procedure

The runtime checks these headings via `REQUIRED_HEADINGS` in
`artifact_schema.py`. Missing ones become `artifact-check` warnings (or
errors in blocking mode).

| File | Runtime-checked |
| --- | --- |
| `spec.md` | `## Metadata`, `## Problem Statement`, `## Acceptance Criteria` |
| `plan.md` | `## Metadata`, `## Approach` |
| `tasks.md` | `## Metadata`, `## Tasks` |
| `review.md` | `# `, `## Decision` |
| `status.md` | none |

Additional headings named in a `SKILL.md` (research `## Findings`, verify
traceability tables, and similar) are **procedure, not runtime**.

## Per-skill contracts

Each subsection is the operational contract. Full prose stays in
`skills/<name>/SKILL.md`.

### `/starter-init`

| Field | Value |
| --- | --- |
| Feature | optional |
| Enter / exit | none |
| Prerequisites | none |
| Required write | none |
| Route sources | `harness-config.yaml` (`Must`); `project-constraints.md` (`Should`, Performance / Technology / Operational Constraints); `tech-stack.md` (`Should`, Languages & Runtimes / Frameworks / Development Tools) |
| Handoffs | `spec-research`, `spec-requirements` |
| Skill-local refs | `references/brownfield-mode.md`, `references/template-prefill.md` |

Modes: `fresh-init`, `resync-drift`. CLI: `init`, `doctor`, `memory-audit`.
Discover repository facts autonomously. Ask only product, policy, and gate
decisions in one frontier batch. Do not invent missing project facts. Mark
`[UNKNOWN]` or `[DEFERRED]`.

### `/spec-research`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | `Researching` → `ResearchComplete` |
| Prerequisites | none |
| Required write | `analysis.md` |
| Feature artifacts | `status.md` |
| Route sources | `architecture.md` (`Should`, System Snapshot / Top-Level Components / Runtime Boundaries) |
| Handoffs | `spec-requirements`, `spec-adr` |
| Skill-local refs | `analysis-template.md`, `debugging-checklist.md` |

Modes: `bug-diagnosis`, `brownfield-map`, `ambiguity-resolution`. Procedure
headings in `analysis.md`: `## Metadata`, `## Findings`, `## High Risk Paths`,
`## Open Questions`, `## Kaizen Countermeasures`,
`## Recommendation & Next Step`. Sparse evidence: `[:HALT INCONCLUSIVE]`.

### `/spec-requirements`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | `Specifying` → `SpecApproved` |
| Prerequisites | none |
| Required write | `spec.md` |
| Feature artifacts | `status.md`, `analysis.md` |
| Route sources | `product-sense.md` (`Must`); `project-constraints.md` (`Must`, Performance / Compliance / Security / Operational) |
| Handoffs | `spec-plan`, `spec-research` |
| Skill-local refs | `intake.md`, `grilling-waves.md`, `proposal-template.md`, `spec-template.md`, `requirements-review-template.md` |

Modes: `full-intake`, `clarify-reentry`. Write `REQ-*` and `AC-*`.
`proposal.md` is procedure-required for Moderate and Complex, route-optional
for `skill-exit`. ADR contradiction: `[:HALT ADR CONFLICT: ADR-NNN]`.

### `/spec-plan`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | `Planning` → `Planning` |
| Prerequisites | `spec.md` |
| Required write | `plan.md` |
| Feature artifacts | `status.md`, `spec.md`, session `session.md` |
| Route sources | `architecture.md` (`Must`, System Snapshot / Top-Level Components / Runtime Boundaries / Safe Change Guidance); `ponytail.md` (`Must`, Decision Matrix); `code-design.md` (`Should`, Abstraction Check & Deep Modules) |
| Handoffs | `spec-tasks`, `spec-research`, `spec-adr` |
| Skill-local refs | `plan-template.md`, `definition-of-ready.md` |

Profiles: `simple-plan`, `moderate-plan`, `complex-plan`. Material
trade-offs invoke `/spec-adr`. Unverified technical risk on Complex halts to
`/spec-research`.

### `/spec-tasks`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | `TaskPlanning` → `PlanApproved` |
| Prerequisites | `spec.md`, `plan.md` |
| Required write | `tasks.md` |
| Feature artifacts | `status.md`, `spec.md`, `plan.md`, session `session.md` |
| Route sources | `architecture.md` (`Should`, System Snapshot / Top-Level Components); `code-design.md` (`Must`, Read before you write) |
| Handoffs | `spec-implement`, `spec-plan` |
| Skill-local refs | `tasks-template.md` |

Strategies: `mvp-first`, `incremental`, `parallel-team`. IDs are `T-NNN`
only. Run `task-check` before exit.

### `/spec-implement`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | `Implementing` → `Implementing` |
| Prerequisites | `spec.md`, `plan.md`, `tasks.md` |
| Required write | none |
| Feature artifacts | `status.md`, `spec.md`, `plan.md`, `tasks.md`, session `session.md` |
| Route sources | `security.md` (`Must`, Core Rules / Shell and Script Safety / File and Artifact Boundaries / Verification); `code-design.md` (`Must`, Read before you write / Abstraction Check & Deep Modules / Failures must reach a decision-maker / Verify the path you claim to have fixed) |
| Handoffs | `harness-verify`, `spec-plan`, `spec-requirements` |

Modes: `task-execution`, `mid-task-resumption`, `task-blocked`. Lock with
`task-start`. Complete with `task-done --evidence`. Stale spec after plan
approval: `[:HALT STALE — spec amended after plan approved]`.

### `/harness-verify`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | `Verifying` → `Done` (or `--phase ChangesRequested`) |
| Prerequisites | `spec.md`, `plan.md`, `tasks.md` |
| Required write | `review.md` |
| Feature artifacts | `status.md`, `tasks.md`, `plan.md`, `spec.md`, session `session.md` |
| Route sources | `security.md` (`Must`, Verification); `harness-config.yaml` (`Must`) |
| Handoffs | `context-memory`, `spec-implement`, `spec-plan` |
| Skill-local refs | `review-template.md` |

Passes: `mechanical-gate`, `alignment-audit`, `design-conformance`,
`security-audit`. Sole authority to exit to `Done`. Requires `## Post-Ship
Sync` in `session-extracts.md` first. Missing heading: `[:HALT SYNC REQUIRED]`.

### `/context-memory`

| Field | Value |
| --- | --- |
| Feature | optional |
| Enter / exit | none |
| Prerequisites | none |
| Required write | none |
| Feature artifacts | `status.md`, `session-extracts.md`, session `session.md` |
| Route sources | `learned-heuristics.md` (`Must`, Heuristics). Bootstrap also injects `core-policies.md` (`Purpose`, `Normative Rules`, `Memory Promotion Thresholds`, `Security Policy`). |
| Handoffs | `harness-verify` |
| Skill-local refs | `extraction-triage.md` |

Modes: `post-ship-sync`, `audit-mode`, `compaction-mode`, `decay-archival`.
Promote only evidence-backed recurring lessons; merge duplicates; preserve
stable IDs during compaction. The runtime does not auto-promote. CLI:
`memory-audit`, `memory-gate`, `session-end`.

### `/harness-maintain`

| Field | Value |
| --- | --- |
| Feature | optional |
| Enter / exit | none |
| Prerequisites | none |
| Required write | none |
| Feature artifacts | `status.md` |
| Route sources | `harness-config.yaml` (`Must`) |
| Handoffs | none |
| Skill-local refs | `diagnosis-map.md` |

Modes: `assess`, `create`, `improve`, `eval`, `doctor`, `diagnose`. Optional
write: `corebase-specharness/generated/harness-assessment.md`. Policy or config changes
require user review. Diagnose maps shallow wrappers and vibe-debugging to
deletion-test and tight-loop fixes.

### `/spec-adr`

| Field | Value |
| --- | --- |
| Feature | optional |
| Enter / exit | none |
| Prerequisites | none |
| Required write | none |
| Feature artifacts | `status.md`, `spec.md`, `plan.md` |
| Route sources | `architecture.md` (`Must`, System Snapshot / Runtime Boundaries / Safe Change Guidance) |
| Handoffs | none |
| Skill-local refs | `adr-template.md` |

Modes: `adr-major`, `adr-lightweight`, `adr-review`. CLI: `adr-generate`.
Writes `corebase-specharness/project/adr/NNNN-<slug>.md` and updates `adr-log.md` with
status, reversibility, and summary when that file exists. Compare at least
two options on depth, seam, blast radius, and reversibility.

### `/spec-testing-scenario`

| Field | Value |
| --- | --- |
| Feature | required |
| Enter / exit | none |
| Prerequisites | `spec.md` |
| Required write | `testing-scenarios.md` |
| Feature artifacts | `status.md`, `spec.md`, `plan.md`, `tasks.md` |
| Route sources | `project-constraints.md` (`Should`) |
| Handoffs | none |
| Skill-local refs | `testing-scenarios-template.md` |

Modes: `happy-path`, `edge-case`, `full-suite`. Optional and non-gating. Does
not block `Done`. Scenarios observe public seams, not private implementation
state.

## Common delivery route

This is the canonical 6-phase lifecycle. It is a suggested handoff path, not
a hierarchy. Any skill remains a direct entrypoint. See
[WORKFLOW.md](WORKFLOW.md#4-the-canonical-6-phase-lifecycle) for entry and
exit criteria.

```text
[1. Discovery / Research]
   /starter-init               recommended only for an untailored repository
   /spec-research              when behavior, risk, or root cause is unknown
        │  writes analysis.md   Researching → ResearchComplete
        ▼
[2. Specification]
   /spec-requirements          problem statement, grilling, AC-* contracts
        │  writes spec.md       Specifying → SpecApproved
        ▼
[3. Architecture & Planning]
   /spec-plan                  deep modules, public seams, definition-of-ready
   /spec-adr                   optional lasting architectural decision
        │  writes plan.md       Planning
        ▼
[4. Work Breakdown]
   /spec-tasks                 T-NNN graph, AC coverage, tasks.json sidecar
        │  writes tasks.md      TaskPlanning → PlanApproved
        ▼
[5. Execution]
   /spec-implement             one T-NNN at a time with proof
   /spec-testing-scenario      optional AC-linked manual scenarios
        │  mutates source       Implementing
        ▼
[6. Closeout & Memory]
   /harness-verify             gates, two-axis review.md, protected Done
   /context-memory             post-ship triage of [CANDIDATE] lessons
        │  writes review.md     Verifying → Done
```

## Handoff behavior

The route registry declares suggested handoffs, but evidence and stop
conditions decide the actual next action.

| Current skill | Normal handoff | Deviate when |
| --- | --- | --- |
| `/starter-init` | `/spec-research` for brownfield or `/spec-requirements` for greenfield | Onboarding facts or gates remain `[UNKNOWN]` |
| `/spec-research` | `/spec-requirements` | Evidence is inconclusive, or a contested decision needs `/spec-adr` |
| `/spec-requirements` | `/spec-plan` | Clarification remains unresolved, research is missing, or an ADR conflict exists |
| `/spec-plan` | `/spec-tasks` | Technical risk needs research, or a material choice needs `/spec-adr` |
| `/spec-tasks` | `/spec-implement` | The task graph is cyclic, incomplete, or reveals a design gap |
| `/spec-implement` | `/harness-verify` | A blocker requires replanning or requirements clarification |
| `/harness-verify` | `/context-memory` after passing evidence; otherwise `/spec-implement` or `/spec-plan` | Verification findings determine the re-entry point |

`skill-exit --handoff` must name a declared handoff, or a shipped CoreBase SpecHarness
skill when the route declares none. Before switching skills, record decisions,
risks, unresolved questions, omitted context, and the next action in the
active session. See `skills/_shared/handoff-rules.md`.

## Context loading

```bash
python3 corebase-specharness/scripts/core/cli.py context-load \
  --skill <name> \
  [--feature <slug>] \
  [--task <T-NNN>] \
  --intent "<request>"

python3 corebase-specharness/scripts/core/cli.py context-explain \
  --skill <name> \
  [--feature <slug>] \
  --intent "<request>" \
  --json
```

Context commands require `--skill`. Feature-bound routes also require
`--feature`. The CLI obtains the route profile automatically.

A pack contains universal communication and policy bootstrap, route-declared
feature artifacts and `Must` or `Should` sources, a task excerpt when
`--task` is supplied, matching domain memory, and bounded automatic local
evidence. `Must` sources are retained even if they overrun the requested
payload. Use repeatable `--add-source <repository-relative-path>` only for a
focused expansion.

## Session and artifact contracts

Feature sessions live at `.corezero/sessions/<slug>/session.md`. Auto-delta
skips files already hashed there. That is safe only in the same uncompacted
chat. After compact or on the first skill of a new chat for the same
feature, the agent passes `--full`. `session-end` does not clear hashes.
See [MEMORY.md](MEMORY.md#conversation-vs-feature-session-compact-and-new-chat)
and `kit/skills/_shared/context-loading.md`.

```bash
python3 corebase-specharness/scripts/core/cli.py skill-enter \
  --skill <name> --feature <slug> --intent "<request>"

python3 corebase-specharness/scripts/core/cli.py session-checkpoint \
  --feature <slug> --progress "<summary>" --next-action "<next action>"

python3 corebase-specharness/scripts/core/cli.py session-end \
  --feature <slug> --next-action "<handoff>"
```

`session-end` may append candidate lessons to
`artifacts/features/<slug>/session-extracts.md`. It does not archive, move, or
delete the active session file.

Shared artifact rules:

- feature artifacts live under `artifacts/features/<slug>/`
- `status.md` records lifecycle state and delivery profile
- `spec.md` defines `REQ-*` and `AC-*`
- `plan.md` defines the technical approach and proof surfaces
- `tasks.md` uses canonical `T-NNN` IDs and maps tasks to acceptance criteria
- completed tasks require fresh proof evidence
- `review.md` records final verification findings and disposition
- ADRs live in `corebase-specharness/project/adr/` as `NNNN-<slug>.md`

## Shared skill contracts

`skills/_shared/` contains cross-skill references. `_shared` is not an
invokable skill.

| File | Contract |
| --- | --- |
| `status-phases.md` | Human lifecycle vocabulary; subordinate to `state-machine.yaml` |
| `status-template.md` | Baseline `status.md` structure |
| `artifact-rules.md` | Artifact ownership, tracer-bullet slices, expand-contract sequencing, and AC/task linkage |
| `context-loading.md` | Named-route loading, source tiers, intent-matched domain packs, and explicit expansion |
| `decision-points.md` | Choices that require two options, depth/seam comparison, reversibility, and an explicit record |
| `halt-rules.md` | Standard `[:HALT ...]` markers, owning skills, and stop conditions |
| `handoff-rules.md` | Session handoff content and required closeout checks |
| `verification-rules.md` | Public-seam proofs, two-axis review, and evidence requirements before task or phase completion |

Named HALT vocabulary from `halt-rules.md` (`NEEDS CLARIFICATION`,
`UNRESOLVED`, `ADR CONFLICT`, `SECURITY`, `INCONCLUSIVE`, `STALE`,
`SYNC REQUIRED`) is procedure. The runtime only looks for the substring
`[:HALT` when mutating tasks, and for `contains_stale` only if an adopter
adds that check via `lifecycle_overrides`.

## Runtime support

- Envelope: `skill-enter`, `skill-exit`, `status-set`
- Context: `context-pack`, `context-load`, `context-explain`
- Sessions: `session-start`, `session-checkpoint`, `session-end`
- Tasks: `task-check`, `task-start`, `task-done`, `task-block`
- Delivery checks: `phase-check`, `artifact-check`, `verify`
- Harness diagnostics: `doctor`, `gate-check`, `gate-list`
- Providers: `provider-list`, `provider-check`, `provider-run`
- Memory: `memory-audit`, `memory-gate`
- Decisions: `adr-generate`

## Skill contract validation

Each shipped `SKILL.md` must have exactly these frontmatter fields:

```yaml
id: skill-<directory-name>
name: <directory-name>
description: <non-empty string>
tags: [at-least-one-tag]
triggers: [at-least-one-trigger]
```

The skill name must match its directory and have a matching route. The route
must declare `skill`, `phase`, `profile`, `feature`, `prerequisites`,
`feature_artifacts`, `writes`, `handoff`, and `sources`. Route handoffs must
target existing CoreBase SpecHarness skills. Declared source files and requested sections
must exist. CLI commands embedded in skill Markdown must exist in the live
command registry.

```bash
python3 kit/corebase-specharness/scripts/validate-static-audit.py --root kit
python3 kit/corebase-specharness/scripts/core/cli.py doctor --root kit --json
```

## Adding or changing a CoreBase SpecHarness skill

A new direct skill requires coordinated kit changes:

1. Add `kit/skills/<name>/SKILL.md` with valid frontmatter and a bounded
   procedure.
2. Add only skill-specific references beneath its directory; place genuinely
   cross-skill contracts under `kit/skills/_shared/`.
3. Add a route to `kit/references/context-routes.yaml`.
4. Add the skill path to `manifest.json` under `files.overwrite`.
5. Update `kit/skills/README.md` and this catalog.
6. Run skill consistency, static audit, doctor, and Python compilation checks.

Do not add a Python plugin merely to register a Markdown skill.

## Optional external engineering skills

Repository documentation, technical documentation, diagrams, and
design-pattern analysis are maintained outside CoreBase SpecHarness. CoreBase SpecHarness does not
install, route, load, or validate them.

Do not pass external skill names to:

```bash
python3 corebase-specharness/scripts/core/cli.py context-load --skill <external-skill>
```

They do not own CoreBase SpecHarness lifecycle transitions, task state, acceptance
decisions, or final verification. See `kit/EXTERNAL_SKILLS.md`.

## Related documents

- External specialist installation: `kit/EXTERNAL_SKILLS.md`
- Workflow guide: [WORKFLOW.md](WORKFLOW.md)
- Memory and budgets: [MEMORY.md](MEMORY.md)
- Harness and gates: [HARNESS.md](HARNESS.md)
- CLI reference: [REFERENCE.md](REFERENCE.md)
