# CLI and artifact reference

> **Audience:** adopters, maintainers, platform engineers, and automation agents
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/manifest.json`, `kit/references/context-routes.yaml`,
> `kit/references/tool-providers-registry.json`,
> `kit/corebase-specharness/project/harness-config.yaml`,
> `kit/corebase-specharness/scripts/install.sh`, `kit/corebase-specharness/scripts/core/`

Workflow guidance lives in [WORKFLOW.md](WORKFLOW.md). This file is the
implementation reference.

## CLI invocation

From an installed project:

```bash
python3 corebase-specharness/scripts/core/cli.py <command> [options]
```

From this repository:

```bash
python3 kit/corebase-specharness/scripts/core/cli.py <command> --root kit
```

The CLI has one flat command registry of 27 commands. Skills are Markdown
procedures, not Python plugins.

## Common options

Options are defined per command rather than as parser-wide options.

| Option | Meaning |
| --- | --- |
| `-h`, `--help` | Show command help |
| `--root ROOT` | Repository root; otherwise resolve from the current location |
| `--json` | Print the normalized machine-readable response |
| `--dry-run` | Report the planned action without writing or executing it, where supported |
| `--feature FEATURE` | Feature slug, required by feature-scoped commands |

Run `<command> --help` for the exact accepted options.

## Command reference

### Lifecycle and verification

| Command | Required or notable options | Purpose |
| --- | --- | --- |
| `init` | `--root`; optional `--dry-run` | Create missing CoreBase SpecHarness directories and seed files without overwriting existing adopter content |
| `status` | optional `--feature`, `--next`, `--dry-run` | Read feature state; `--next` reports valid handoffs without choosing one |
| `status-set` | `--feature`, `--phase`; optional `--next-step`, `--verification-override`, `--override-reason`, `--dry-run` | Validate a lifecycle token; `Done` requires named verification evidence or an explicit audited override |
| `skill-enter` | `--skill`; feature when the route requires one; optional `--intent`, `--budget`, `--delta-from`, `--full`, `--add-source`, `--objective`, `--dry-run` | Load the named-skill pack, open or resume the session, and set the route `enter` state |
| `skill-exit` | `--skill`; feature when the route requires one; optional `--phase`, `--handoff`, `--progress`, `--handoff-file`, `--next-action`, `--blocker`, `--decision`, `--verification-override`, `--override-reason`, `--dry-run` | Checkpoint the session and set route exit; `Done` is reserved for `harness-verify` unless overridden |
| `phase-check` | `--feature` and either `--skill` or `--phase`; optional `--dry-run` | Evaluate route prerequisites or coarse phase preconditions plus deterministic readiness checks |
| `artifact-check` | `--feature` and either `--skill` or `--phase`; optional `--trace` | Validate feature artifact structure from `files_for`; optionally bidirectional AC/task traceability |
| `verify` | `--feature`; optional `--skill` or `--phase` (default `Verify`), `--fast`, `--dry-run` | Run readiness, artifact and traceability checks, confirmed gates, and the configured review provider |
| `doctor` | `--root` | Validate the embedded package and configuration; warn on deferred project setup or missing gates without failing |

`--skill` and `--phase` are mutually exclusive on `phase-check`,
`artifact-check`, and `verify`. Prefer `--skill`. `artifact-check` requires
one of those flags. Bare `verify --feature` still defaults to coarse
`--phase Verify` and emits a compatibility warning.

`verify` does not accept `--task`. Use `--skill` to scope readiness and
structure. Task mutations stay on `task-start` / `task-done` / `task-block`.

`verification.mode` in `corebase-specharness/project/harness-config.yaml` controls
enforcement:

- `advisory` reports incomplete evidence and returns `deferred`; verification
  remains false in `details.verified` / `details.passed`.
- `blocking` returns a failed result when required checks fail.

New installations use `advisory`. If the key is absent, the code fallback is
`blocking`.

Notable `details` fields:

| Command | Details consumers rely on |
| --- | --- |
| `init` | `onboarding_readiness` (`detected_stacks`, `portable_router`, `preserved_native_instruction_files`, `confirmed_gates`, `unknowns`, `recommended_next_skill`) |
| `status` | `features[]` with `slug`, `phase`, `delivery_profile`, `status`, `next_step`, `blockers`, `has_blocker` |
| `phase-check` | `allowed`, `meets_preconditions`, `enforcement_mode`, `mechanical_failures`, `transition`, `current_state`, `target_phase` |
| `artifact-check` | `structure`, `validation_errors`, `traceability`, `traceability_errors` when `--trace` |
| `verify` | `verified`, `passed`, `verification_mode`, `enforcement_mode`, `would_pass_static_checks`, nested `phase` / `artifacts` / `gate_results` / `provider`; top-level `traceability_errors` |
| `skill-enter` | `skill`, `route_phase`, `enter`, `status`, `session`, `pack`, `selected`, `skill_payload` |
| `skill-exit` | `skill`, `exit`, `handoff`, `missing_writes`, `status`, `session` |
| `doctor` | `ok`, `failed`, `checks[]` with `name` / `status` / `message` |

### Context

| Command | Purpose |
| --- | --- |
| `context-pack` | Plan the selected and omitted sources for a named skill route |
| `context-load` | Render the bounded context payload for a named skill route |
| `context-explain` | Explain source selection, omission, provenance, trust labels, channels, and budget use |

All context commands require `--skill`. They also accept `--feature`,
`--task`, `--intent`, `--budget`, `--delta-from`, `--full`, repeatable
`--add-source`, and `--dry-run`. They do not accept `--phase` or `--profile`.
When `--task T-NNN` is set, `tasks.md` is replaced by a compact payload for
that task plus its direct dependencies. When `--full` is omitted and a
session `last_context_fingerprint` cache exists, later loads keep only changed sources.

A feature is required when the route declares `feature: required`. Retrieved
excerpts redact detected secrets. When `retrieval.pinnable_sources` is
configured, `--add-source` is restricted to those globs.

### Sessions

| Command | Required or notable options | Purpose |
| --- | --- | --- |
| `session-start` | `--feature`, `--skill`; optional `--intent`, `--budget`, `--objective` | Create or resume `.corezero/sessions/<slug>/session.md` |
| `session-checkpoint` | `--feature` plus progress or handoff input; optional `--dry-run` | Append progress and handoff information |
| `session-end` | `--feature` plus handoff input; optional candidates and `--dry-run` | Persist the final handoff and optionally append candidate lessons |

Checkpoint and end commands accept `--progress`, `--handoff-file`,
`--next-action`, repeatable `--blocker`, and repeatable `--decision`.
`session-checkpoint` requires at least one of those inputs. `session-end`
requires `--next-action`, `--blocker`, `--decision`, or `--handoff-file`,
and also accepts repeatable `--candidate` and `--extract-file`. Ending a
session does not archive, move, or delete `session.md`.

Session path: `.corezero/sessions/<slug>/session.md`. Frontmatter is JSON,
not YAML. See [ARCHITECTURE.md](ARCHITECTURE.md).

### Tasks

| Command | Required or notable options | Purpose |
| --- | --- | --- |
| `task-check` | `--feature` | Parse `tasks.md`, validate dependencies and cycles, and list ready tasks |
| `task-start` | `--feature`, `--task`; optional `--note`, `--dry-run` | Move an unblocked canonical task to in-progress |
| `task-done` | `--feature`, `--task`; evidence and optional `--dry-run` | Mark a task complete and record proof evidence |
| `task-block` | `--feature`, `--task`; `--note`; optional `--dry-run` | Mark a task blocked with its reason |

`tasks.md` is the canonical task source. After each successful mutation the
CLI regenerates `tasks.json` in the same feature
directory. When `tasks.md` is absent, `tasks.json` is a read-only fallback.
Mutations refuse to write when only the sidecar exists. Canonical task IDs
use `T-NNN`. Older `TASK-*` IDs are not parsed. `task-done` accepts
repeatable `--evidence` and `--evidence-file`.

Task statuses: `Not Started`, `In Progress`, `Blocked`, `Done`, `Deferred`.

Allowed transitions:

| From | To |
| --- | --- |
| `Not Started` | `Not Started`, `In Progress`, `Blocked`, `Deferred` |
| `In Progress` | `Not Started`, `In Progress`, `Blocked`, `Done`, `Deferred` |
| `Blocked` | `Not Started`, `In Progress`, `Blocked`, `Deferred` |
| `Done` | `Done`, `In Progress` |
| `Deferred` | `Deferred`, `Not Started`, `In Progress` |

Sidecar shape:

```json
{
  "source": "tasks.md",
  "generated_at": "<isoformat seconds>",
  "errors": [],
  "task_count": 0,
  "tasks": [
    {
      "id": "T-001",
      "header": "...",
      "status": "Not Started",
      "done": false,
      "depends": [],
      "evidence": [],
      "acceptance_criteria": []
    }
  ],
  "markdown_hash": "<sha256 of tasks.md>"
}
```

Feature slug contract: `[a-z0-9][a-z0-9-]{0,62}` (1–63 characters,
lowercase, must start with an alphanumeric).

### Gates

| Command | Purpose |
| --- | --- |
| `gate-list` | List confirmed gates, categories, failure policy, requirement status, commands, and executable availability |
| `gate-check` | Validate configured gate executables without running the gates; `--fast` skips gates whose optional `paths` do not match git-changed files |

The shipped `gates` list is empty. Gate commands should be non-empty argv
lists. Shell commands require both `allow_shell: true` and a non-empty
`shell_rationale`. Supported `on_fail` values are `block`, `warn`, and
`continue`. `gate-check` skips `allow_shell` commands. Optional `paths`
globs let `--fast` skip a gate when no changed file matches.

### Tool providers

| Command | Required or notable options | Purpose |
| --- | --- | --- |
| `provider-list` | none | List the provider registry and current category selections |
| `provider-check` | optional `--category review\|code-intelligence` | Check selected provider configuration and executable availability |
| `provider-run` | `--category review\|code-intelligence`; optional `--action`, `--feature`, `--dry-run` | Run a declared local provider action |

| ID | Category | Executable | Declared local action |
| --- | --- | --- | --- |
| `open-code-review` | review | `ocr` | `run`: `ocr review` |
| `gitnexus` | code-intelligence | `gitnexus` | `refresh`: `gitnexus analyze` |
| `codebase-memory-mcp` | code-intelligence | `codebase-memory-mcp` | `refresh`: `codebase-memory-mcp index .` |

Both categories default to `active: none` and `mode: optional`. The installer
does not install, authenticate, enable, or check provider binaries. Provider
mode may be `optional` or `required`. Keep the kit seed optional. An adopter
who wants OpenCodeReview on every closeout sets `active: open-code-review` and
`mode: required` in their own `tool-providers.md` after installing `ocr`.

`provider-run` without `--action` defaults to `run` for `review` and `check`
for `code-intelligence`. `check` reports availability and does not execute a
binary.

### Memory

| Command | Options | Purpose |
| --- | --- | --- |
| `memory-audit` | optional `--mode advisory\|warn\|block` | Report line counts, token estimates, threshold labels, and `details.semantic_summary` |
| `memory-gate` | optional `--mode advisory\|warn\|block` | Evaluate durable-memory line thresholds with mode-specific exit behavior |

The default mode is `advisory`. `memory-audit` accepts `--mode` and ignores
it; it fails only on hard-cap. Mode-specific exit behavior belongs only to
`memory-gate`. These commands inspect the five repository memory files plus
`corebase-specharness/memories/domain/**/*.md`. Seeded thresholds are
`memory_warn_lines: 200` and `memory_hard_lines: 3200`. The code fallback is
`100` / `3200` if the key is absent.

### ADR generation

| Command | Required or notable options | Purpose |
| --- | --- | --- |
| `adr-generate` | optional `--feature`, `--title`, repeatable `--decision`, `--reversibility Easy\|Moderate\|Hard` (default `Moderate`), `--dry-run` | Generate a proposed ADR from explicit decisions or decisions recorded in the active session |

Non-dry-run generation writes under `corebase-specharness/project/adr/` as
`NNNN-<slug>.md` and updates `corebase-specharness/memories/repo/adr-log.md` with
status, reversibility, and summary when that file exists. It also appends
to `corebase-specharness/project/adr/index.md` when that file exists. Requires
`--decision`, `--title`, or session `metadata.decisions`. Optional
`--reversibility Easy|Moderate|Hard` defaults to `Moderate`.

## JSON result contract

Every command is normalized to this top-level response:

```json
{
  "command": "command-name",
  "status": "ok",
  "feature": "",
  "artifacts": [],
  "findings": [],
  "warnings": [],
  "errors": [],
  "next_action": "",
  "details": {}
}
```

`ok` and `deferred` produce process exit code `0`. `failed` produces exit
code `1`. Consumers must inspect `status`, `findings`, and command-specific
`details`. Exit code `0` does not mean verification passed when the result is
`deferred`.

`verify` also exposes `details.verified`, `details.passed`,
`details.verification_mode`, and top-level `traceability_errors`.

## Context profiles and limits

| Profile | Default payload tokens | Routed skills |
| --- | ---: | --- |
| `bootstrap` | 2,500 | `starter-init` |
| `research` | 4,000 | `spec-research` |
| `requirements` | 3,500 | `spec-requirements` |
| `planning` | 3,500 | `spec-plan`, `spec-tasks`, `spec-adr` |
| `implement` | 4,000 | `spec-implement` |
| `verify` | 3,500 | `harness-verify`, `harness-maintain`, `spec-testing-scenario` |
| `compact` | 2,500 | `context-memory` |

Shipped global and channel limits:

| Setting | Value |
| --- | ---: |
| `max_injected_tokens` | 6,000 |
| `reserve_tokens` | 1,500 |
| `max_bootstrap_tokens` | 800 |
| `max_project_tokens` | 1,200 |
| `max_feature_tokens` | 1,600 |
| `max_retrieved_tokens` | 1,600 |
| `max_source_excerpt_tokens` | 600 |
| `max_retrieval_files` | 6 |
| `max_tool_output_tokens` | 800 |
| `payload_budget` | 2,500 |

Effective payload ceiling with the new-install seed: `6000 - 1500 = 4500`.
Existing adopter config is not overwritten. See [MEMORY.md](MEMORY.md).

## Skill routes

`references/context-routes.yaml` is the canonical registry for all 11 direct
skills. See [SKILLS.md](SKILLS.md) for writes, enter/exit, and handoffs.

| Skill | Phase | Profile | Feature |
| --- | --- | --- | --- |
| `starter-init` | Bootstrap | `bootstrap` | optional |
| `spec-research` | Spec | `research` | required |
| `spec-requirements` | Spec | `requirements` | required |
| `spec-plan` | Plan | `planning` | required |
| `spec-tasks` | Plan | `planning` | required |
| `spec-implement` | Implement | `implement` | required |
| `harness-verify` | Verify | `verify` | required |
| `context-memory` | Verify | `compact` | optional |
| `harness-maintain` | Verify | `verify` | optional |
| `spec-adr` | Plan | `planning` | optional |
| `spec-testing-scenario` | Verify | `verify` | required |

## Feature artifacts

Durable feature artifacts live under `artifacts/features/<slug>/`.

| Artifact | Owner or producer | Notes |
| --- | --- | --- |
| `status.md` | envelope commands | Canonical lifecycle state and delivery profile; never a required write |
| `analysis.md` | `spec-research` | Research, debugging, or brownfield analysis |
| `proposal.md` | `spec-requirements` | Used for Moderate or Complex work |
| `requirements-review.md` | `spec-requirements` | Requirements review evidence when gaps exist |
| `spec.md` | `spec-requirements` | Requirements and acceptance criteria |
| `plan.md` | `spec-plan` | Technical plan |
| `tasks.md` | `spec-tasks`, `spec-implement`, task CLI | Canonical task graph and proof state |
| `tasks.json` | task mutations | Generated sidecar |
| `session-extracts.md` | `spec-implement`, `session-end`, `context-memory` | Candidate durable lessons; `## Post-Ship Sync` required before `Done` |
| `review.md` | `harness-verify` | Verification review |
| `testing-scenarios.md` | `spec-testing-scenario` | Optional scenario artifact |

Session state is ephemeral at `.corezero/sessions/<slug>/session.md`. There is
no shipped `corebase-specharness/schemas/` directory.

`PHASE_FILES` used when `--phase` is given without `--skill`:

| Phase | Files |
| --- | --- |
| `Spec` | `status.md`, `spec.md` |
| `Plan` | `status.md`, `spec.md`, `plan.md`, `tasks.md` |
| `Implement` | `status.md`, `spec.md`, `plan.md`, `tasks.md` |
| `Verify` | `status.md`, `spec.md`, `plan.md`, `tasks.md` |
| `Done` | `status.md`, `spec.md`, `plan.md`, `tasks.md`, `review.md`, `session-extracts.md` |

`REQUIRED_HEADINGS` the runtime checks:

| File | Required text |
| --- | --- |
| `spec.md` | `## Metadata`, `## Problem Statement`, `## Acceptance Criteria` |
| `plan.md` | `## Metadata`, `## Approach` |
| `tasks.md` | `## Metadata`, `## Tasks` |
| `review.md` | `# `, `## Decision` |
| `status.md` | none |

## Lifecycle states

`corebase-specharness/project/state-machine.yaml` is the kit-owned lifecycle contract.
Adopters extend it only through `lifecycle_overrides` in `harness-config.yaml`.

Primary states:

```text
Researching
ResearchComplete
Specifying
SpecApproved
Planning
TaskPlanning
PlanApproved
Implementing
Verifying
Done
```

Supplementary states are `NeedsClarification`, `Blocked`, `Replanning`,
`ChangesRequested`, and `Abandoned`. Delivery profile vocabulary is
`Simple`, `Moderate`, or `Complex`. Profiles are skill-procedure depth
rules. The runtime defaults a new `status.md` to `Moderate` and reads the
field. They do not skip planning, tasks, proof, or verification.

Coarse phase names (`Spec`, `Plan`, `Implement`, `Verify`, `Done`,
`Bootstrap`) are labels on routes and a compatibility flag. They are
separate from the detailed `status.md` tokens.

## Generated and ephemeral state

| Path | Producer | Purpose |
| --- | --- | --- |
| `.corezero/sessions/<slug>/session.md` | `session-*` and `skill-enter` | Active resumable session and handoff state |
| `artifacts/features/<slug>/tasks.json` | `task-*` | Generated task graph sidecar and read-only fallback |
| `corebase-specharness/generated/gate-runs.json` | non-dry-run `verify` | Last 50 recorded feature gate-result sets |
| `corebase-specharness/generated/provider-runs.json` | non-dry-run `verify` | Last 50 recorded review-provider runs |
| `corebase-specharness/generated/verification-runs.json` | non-dry-run `verify` | Last 50 closeout evidence records; `Done` requires a matching `harness-verify` success |
| `corebase-specharness/generated/closeout-overrides.json` | `status-set` / `skill-exit` override | Last 50 explicit audited Done exceptions |
| `corebase-specharness/generated/.gitkeep` | installer | Preserve the ignored generated directory |
| `corebase-specharness/generated/harness-assessment.md` | `/harness-maintain` | Optional explicit maintenance assessment |

Generated runtime state must not ship in the kit except `.gitkeep`.

## Manifest ownership

The current package name is `corebase-specharness`. The version is the `version` field in
`kit/manifest.json`. Python `>=3.10` is required.

Ownership groups:

- `overwrite`: kit-owned files replaced during installation or upgrade; an
  existing file is backed up before replacement.
- `copyIfMissing`: adopter-owned seeds copied only when the destination does
  not exist.

Files outside the two groups are preserved by installer convention. The
full path lists live in [INSTALL.md](INSTALL.md).

## Installer reference

```bash
bash kit/corebase-specharness/scripts/install.sh <target_dir> [--dry-run]
```

`--non-interactive` is accepted as a compatibility no-op. Sequence, backup
path, copy filters, and rollback live in [INSTALL.md](INSTALL.md).

## Runtime module map

The embedded Python runtime lives under `corebase-specharness/scripts/core/` and requires
only the Python standard library. If `tiktoken` is available, token counts use
its `cl100k_base` encoding; otherwise the runtime uses the deterministic
four-characters-per-token estimate in `_lib/token_counter.py`.

### Command dispatch

`cli.py` defines argument parsing, imports a command's registered handler at
execution time, normalizes every handler result, prints JSON when requested,
and converts `ok` and `deferred` statuses to exit code `0`.

| Handler surface | Commands | Responsibility |
| --- | --- | --- |
| `handlers/lifecycle.py` | `init`, `status`, `phase-check`, `artifact-check`, `verify` | Scaffolding, feature status, readiness, artifact checks, gate execution, review-provider invocation, verification aggregation |
| `handlers/envelope.py` | `status-set`, `skill-enter`, `skill-exit` | Validated `status.md` writes, skill enter/exit envelope, suggested handoff |
| `handlers/context.py` | `context-pack`, `context-load`, `context-explain` | Route-driven context planning, payload rendering, selection explanations |
| `handlers/sessions.py` | `session-start`, `session-checkpoint`, `session-end` | Session creation, checkpoints, handoff text, candidate-memory extraction |
| `handlers/tasks.py` | `task-check`, `task-start`, `task-done`, `task-block` | Task graph validation, ready-work reporting, state transitions, proof evidence |
| `harness/doctor.py` | `doctor` | Package, ownership, route, skill, command, provider, static-surface, and configuration checks |
| `handlers/diagnostics/gates.py` | `gate-check`, `gate-list` | Confirmed gate configuration and executable availability |
| `handlers/diagnostics/providers.py` | `provider-list`, `provider-check`, `provider-run` | Optional review and code-intelligence providers |
| `handlers/diagnostics/memory.py` | `memory-audit`, `memory-gate` | Read-only durable-memory size and threshold diagnostics |
| `handlers/diagnostics/governance.py` | `adr-generate` | ADR draft generation from explicit input or recorded session decisions |

`core.handlers.diagnostics` is the public aggregate for gate, provider,
memory, and ADR handlers.

### Engines and state

| Module | Callers | Responsibility |
| --- | --- | --- |
| `context_engine.py` | context and session handlers | Build bounded context packs from named skill routes |
| `context_state.py` | session, task, lifecycle, and ADR handlers | Atomic text writes plus session create/load/update |
| `task_graph.py` | task and lifecycle handlers | Parse `T-NNN` tasks, detect cycles, select ready work, mutate status and evidence |
| `handlers/artifacts.py` | readiness checks | Compute requirements readiness and AC-to-task mapping |
| `handlers/common.py` | all handler families | Root and feature validation, normalized result construction, handoff text, candidate appends |

### Harness modules

| Module | Responsibility |
| --- | --- |
| `harness/config.py` | Parse and validate `harness-config.yaml`, merge `lifecycle_overrides` onto `state-machine.yaml` |
| `harness/gates.py` | Represent and execute configured gates |
| `harness/lifecycle.py` | Represent configured phases and evaluate artifact preconditions and transitions |
| `harness/readiness.py` | One evaluator for route prerequisites or coarse `--phase` preconditions, mechanical extras, and legal transitions |
| `harness/doctor.py` | Package-health checks used by `doctor` |
| `harness/exceptions.py` | Define `ConfigError` |

`harness/lifecycle.py` does not own lifecycle state or write a generated
state file. Phases live in `state-machine.yaml`, not in
`harness-config.yaml`. `contains_stale` is implemented there and unused
unless an adopter adds that check via `lifecycle_overrides`.

### Shared library modules

| Module | Responsibility |
| --- | --- |
| `_lib/ansi.py` | Optional ANSI styling and terminal rendering |
| `_lib/artifact_schema.py` | Heading and structure validation, AC/task ID extraction, bidirectional traceability, `files_for` |
| `_lib/artifacts.py` | Feature slug validation, path containment, status parsing, feature listing |
| `_lib/contracts.py` | Validate `manifest.json` structure and ownership |
| `_lib/doctor_checks.py` | Manifest, surfaces, routes, commands, providers, reachability |
| `_lib/locking.py` | Advisory lock on the target file for mutating operations |
| `_lib/root.py` | Resolve an initialized kit or adopter repository root |
| `_lib/routing_metadata.py` | Parse `context-routes.yaml`, normalize writes, resolve source paths |
| `_lib/token_counter.py` | Estimate tokens and report whether the tokenizer is exact or heuristic |
| `_lib/yaml_reader.py` | Parse the bounded YAML subset used by routes, harness config, skill frontmatter, and provider configuration |

### Authoritative external inputs

- `manifest.json` defines the install payload and ownership groups.
- `references/context-routes.yaml` is the only skill context-routing
  authority.
- `references/tool-providers-registry.json` declares supported optional
  providers.
- `corebase-specharness/project/state-machine.yaml` is the lifecycle authority.
- `corebase-specharness/project/harness-config.yaml` defines `lifecycle_overrides`,
  advisory or blocking verification, gates, context budgets, and memory
  thresholds.
- `corebase-specharness/project/tool-providers.md` selects optional providers.

`_lib/doctor_checks.py` rejects leftover modules if they reappear, including
`harness/cli.py`, `tool_providers.py`, `dashboard_generator.py`,
`capability_recommender.py`, `catalog_generator.py`, `_lib/context_index.py`,
`_lib/budget.py`, `_lib/telemetry_roi.py`, `_lib/telemetry_store.py`,
`handlers/configuration.py`, `handlers/handoff.py`, `handlers/upgrades.py`,
`core/readiness.py`, `.corezero/engine`, and `.corezero/scripts`.

## Maintainer validation

```bash
python3 -m compileall -q kit/corebase-specharness/scripts/core
python3 kit/corebase-specharness/scripts/validate-static-audit.py --root kit
python3 kit/corebase-specharness/scripts/core/cli.py doctor --root kit --json
```

A clean-install smoke test should install into a temporary directory and run
the installed `doctor`, `context-load`, and provider diagnostics. In this
sandbox, `compileall` needs `PYTHONPYCACHEPREFIX` pointed at an in-workspace
directory.

## Supported extension points

| Extension | Mechanism |
| --- | --- |
| Project gates | Add explicitly confirmed argv commands to `harness-config.yaml` |
| Context budgets and retrieval | Edit adopter-owned `context` settings in `harness-config.yaml` |
| Domain memory | Add bounded files below `corebase-specharness/memories/domain/` |
| Tool providers | Select registered providers in `tool-providers.md` |
| Project knowledge | Maintain adopter-owned files under `corebase-specharness/project/` and `corebase-specharness/memories/repo/` |

Adding a new direct skill is a kit change, not an adopter-local extension.

## Related documents

- Workflow guide: [WORKFLOW.md](WORKFLOW.md)
- Memory and budgets: [MEMORY.md](MEMORY.md)
- Kit structure: [ARCHITECTURE.md](ARCHITECTURE.md)
- Harness and gates: [HARNESS.md](HARNESS.md)
- Install and upgrade: [INSTALL.md](INSTALL.md)
