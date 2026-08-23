# CoreBase SpecHarness Specification Requirements

> **Audience:** maintainers reviewing the as-built kit
> **Status:** as-built, now part of maintainer docs
> **Authority:** `kit/corebase-specharness/scripts/core/`, `kit/manifest.json`,
> `kit/references/context-routes.yaml`, `kit/corebase-specharness/project/state-machine.yaml`,
> `kit/skills/*/SKILL.md`, `kit/corebase-specharness/scripts/install.sh`
> **Version described:** `1.0.0` (`kit/manifest.json`)

This is not a product vision. It states what the current kit must keep doing
unless an explicit change request says otherwise.

Requirement IDs are documentation-only. They are not parsed by the runtime.
When this file disagrees with executable kit behavior, the kit wins.

Companion documents: [DESIGN.md](DESIGN.md) (why), [ARCHITECTURE.md](ARCHITECTURE.md)
(topology and technical design).
Operating lookup: [WORKFLOW.md](WORKFLOW.md), [HARNESS.md](HARNESS.md), [MEMORY.md](MEMORY.md),
[REFERENCE.md](REFERENCE.md).

---

## 1. Product intent

CoreBase SpecHarness is an embedded, agent-agnostic, skills-first spec-driven delivery
kit. It is copied into an adopter repository. A coding agent follows a named
skill procedure. The project-local Python CLI is the harness and context
compiler: deterministic context, session, task, lifecycle, artifact, gate,
provider, memory, and ADR operations. Install is not a starter-template
product; `/starter-init` only tailors an untailored repository.

The kit does **not**:

- choose a skill
- run as a service, daemon, or package-manager dependency
- infer or install project verification commands
- approve product decisions
- automatically promote durable memory
- create vendor-specific agent instruction files
- install optional tool providers

---

## 2. Actors and success

| Actor | Success condition |
| --- | --- |
| Repository owner / developer | Can install the kit, confirm gates, approve specs, and inspect every durable artifact as Markdown or YAML in the repo |
| Coding agent | Can invoke any of the 11 peer skills, load a bounded inspectable context pack, write declared artifacts, and hand off without a hidden orchestrator |
| Embedded CLI | Returns a stable JSON envelope, mutates only declared files, and fails loudly on illegal transitions or missing required writes |
| Kit maintainer | Can upgrade kit-owned files without overwriting adopter content, and can prove payload health with `doctor` plus `validate-static-audit.py` |

A feature is **not** verified because a command exited 0. Verification is true
only when `verify` reports `details.verified: true`. Advisory mode may exit 0
with `status: deferred` and `details.verified: false`.

---

## 3. Constraints

| ID | Requirement |
| --- | --- |
| C-01 | Runtime requires Python 3.10+ and a Bash-compatible shell. |
| C-02 | Runtime must stay stdlib-only. Optional `tiktoken` may refine token estimates; it is not a hard dependency. |
| C-03 | Adopter projects need a coding agent with repository filesystem and local command access. |
| C-04 | Installed paths are project-local. There is no `COREBASE_SPECHARNESS_ENGINE_DIR`, `bin/corebase-specharness`, or external engine root. |
| C-05 | Feature slugs must match `^[a-z0-9][a-z0-9-]{0,62}$`. |
| C-06 | Paths that escape a managed root, use `..`, or are absolute outside the repo must be rejected. |
| C-07 | Runtime and installer operate statelessly without creating or requiring `.corebase-specharness/generated/`. |

---

## 4. Installation and ownership

| ID | Requirement |
| --- | --- |
| I-01 | `bash kit/corebase-specharness/scripts/install.sh <target>` copies the embedded payload into the target repository. |
| I-02 | The installer must validate `manifest.json` shape and path safety before any target mutation. |
| I-03 | Manifest `overwrite` files replace kit-owned content after backing up existing copies. |
| I-04 | Manifest `copyIfMissing` files seed adopter-owned content and must not replace existing files or symlinks. |
| I-05 | Manifest groups must not overlap. Absolute paths and `..` segments are unsafe. |
| I-06 | Installer copy skips `.gitkeep`, `__pycache__`, `*.pyc`, `*.pyo`, and basenames starting with `test_`. |
| I-07 | A non-dry-run install restores executable bits on `install.sh` and `validate-static-audit.py`, and runs `doctor`. |
| I-08 | The installer must not install dependencies, infer gates, write Git hooks, or create vendor-specific instruction files. |
| I-09 | `--dry-run` reports planned copies without mutating the target. |
| I-10 | `init` may create missing directories and seed files in an uninitialized tree. It must not overwrite existing adopter files. |
| I-11 | An initialized root is a directory that contains both `manifest.json` and `corebase-specharness/scripts/core/cli.py`. Resolution walks upward from `--root` or cwd. |

Kit-owned (`overwrite`) includes runtime, skills, shared skill references,
routes, provider registry, rules, `state-machine.yaml`, and validators.

Adopter-owned (`copyIfMissing`) includes project constraints, architecture,
product sense, glossary, harness config, tool-provider selection, memory
seeds, and `artifacts/features/README.md`.

---

## 5. Skills and routing

| ID | Requirement |
| --- | --- |
| S-01 | The kit ships exactly 11 peer skills. Each is a direct entrypoint. |
| S-02 | `/starter-init` is recommended only for an untailored repository. It is not a mandatory first step for later features. |
| S-03 | A recommended delivery sequence exists as guidance only: research when needed, then requirements, plan, tasks, implement, verify, optional memory. |
| S-04 | Every skill directory except `skills/_shared/` must contain `SKILL.md` with frontmatter `{id, name, description, tags, triggers}`. |
| S-05 | `id` must be `skill-<dir>`; `name` must equal the directory name. Extra frontmatter keys fail doctor. |
| S-06 | `references/context-routes.yaml` is the routing authority. Every skill must have exactly one route, and every route must name a shipped skill. |
| S-07 | Every route must declare `{skill, phase, profile, feature, prerequisites, feature_artifacts, writes, handoff, sources}`. Writes are strings or `{path, required}`. `required_handoffs` is forbidden. |
| S-08 | `feature` is `required` or `optional`. Required routes reject commands that omit `--feature`. |
| S-09 | `phase` must be a state-machine phase. Optional `enter` / `exit` must be declared states. |
| S-10 | Route `handoff` targets must be shipped skill names. |
| S-11 | Route sources are `{path, tier, sections}` with tier in `{Must, Should, Skip}`. Declared files and H2 sections must exist in the kit. |
| S-12 | Agent procedure lives in `SKILL.md`. Runtime behavior lives in the route registry, state machine, and CLI. Procedure prose must not become a second runtime. |
| S-13 | External skills listed in `EXTERNAL_SKILLS.md` are not CoreBase SpecHarness routes and must not be passed to `context-load` or treated as lifecycle gates. |

Shipped skills and their implemented route facts:

| Skill | Phase | Enter / exit | Feature | Required writes checked on exit |
| --- | --- | --- | --- | --- |
| `starter-init` | Bootstrap | none | optional | none (directory writes are optional) |
| `spec-research` | Spec | Researching → ResearchComplete | required | `analysis.md` |
| `spec-requirements` | Spec | Specifying → SpecApproved | required | `spec.md` (`proposal.md`, `requirements-review.md` optional) |
| `spec-plan` | Plan | Planning → Planning | required | `plan.md` |
| `spec-tasks` | Plan | TaskPlanning → PlanApproved | required | `tasks.md` |
| `spec-implement` | Implement | Implementing → Implementing | required | none beyond `status.md` (`session-extracts.md`, `project-source` optional) |
| `harness-verify` | Verify | Verifying → Done | required | `review.md` |
| `context-memory` | Verify | none | optional | none (memory directories optional) |
| `harness-maintain` | Verify | none | optional | none |
| `spec-adr` | Plan | none | optional | none (`corebase-specharness/project/adr` optional) |
| `spec-testing-scenario` | Verify | none | required | `testing-scenarios.md` |

---

## 6. CLI envelope

| ID | Requirement |
| --- | --- |
| E-01 | All operations go through `python3 corebase-specharness/scripts/core/cli.py <command>`. |
| E-02 | The command registry is flat. Removed leftovers (`context-index`, `task-next`, namespaces, telemetry, dashboards, upgrade commands) must stay absent. |
| E-03 | Every handler returns the envelope `{command, status, feature, artifacts, findings, warnings, errors, next_action, details}`. Missing keys are filled by the CLI. |
| E-04 | `--json` prints that envelope. Text mode prints warnings and errors to stderr. |
| E-05 | Process exit is `0` for `ok` and `deferred`, else `1`. Uncaught exceptions become `status: failed`. |
| E-06 | `--root` is per-command, not a global parser option. |
| E-07 | `--dry-run`, where accepted, must not write files or execute gates. |
| E-08 | `status` values in use are `ok`, `failed`, `deferred`, and (providers) `unavailable`. |

Shipped commands: `init`, `status`, `status-set`, `skill-enter`, `skill-exit`,
`context-pack`, `context-load`, `context-explain`, `session-start`,
`session-checkpoint`, `session-end`, `task-check`, `task-start`, `task-done`,
`task-block`, `phase-check`, `artifact-check`, `verify`, `doctor`,
`gate-check`, `gate-list`, `provider-list`, `provider-check`, `provider-run`,
`memory-audit`, `memory-gate`, `adr-generate`.

---

## 7. Skill envelope

| ID | Requirement |
| --- | --- |
| V-01 | `skill-enter` loads the named route, creates `status.md` from the shared template when missing, sets the route `enter` token when declared, opens or resumes the feature session, and returns the context pack. |
| V-02 | If the current token is already the enter token, or is mapped to the same coarse phase and cannot legally move to `enter`, `skill-enter` must not force an illegal transition. |
| V-03 | `skill-exit` rejects a `--handoff` that is not in the route `handoff` list. If that list is empty, the target must still be a shipped skill. |
| V-04 | Missing required route `writes` fail `skill-exit` with `missing write: <path>`. |
| V-05 | Route `writes` declare required vs optional. A string with a suffix is required. `{path, required: false}` is optional. Suffix-less paths are directories and are never required. `status.md` must be optional; the envelope writes it. |
| V-06 | Directory-style writes and paths without a suffix are not existence-checked. There is no Python `OPTIONAL_WRITES` set and no `required_handoffs` key. |
| V-07 | When `--feature` and an exit token are present, `skill-exit` must call `check_readiness` and refuse to write status or checkpoint the session if readiness fails. |
| V-08 | `status-set` validates the token against declared states and legal transitions, then writes `- Phase:` and optional `- Next step:`. |
| V-09 | An empty or unknown current token may move to any declared state. Same-state writes are legal. |
| V-10 | Skills with no `enter` and no `exit` skip token-transition checks in readiness. |
| V-11 | `context-memory` and `harness-maintain` also skip transition checks when the feature is already `Done` or `Abandoned`. |

---

## 8. Lifecycle and readiness

| ID | Requirement |
| --- | --- |
| L-01 | `corebase-specharness/project/state-machine.yaml` is the kit-owned lifecycle authority. |
| L-02 | Adopters extend it only through `lifecycle_overrides` in `harness-config.yaml`. Redeclared phase preconditions merge additively. The kit file is not replaced. |
| L-03 | `harness-config.yaml` must not contain a top-level `phases` key. |
| L-04 | The machine declares phases, states, a complete `phase_mapping`, and `{from, to}` transitions. Every state maps to a known phase. |
| L-05 | Coarse phases are labels: `Bootstrap`, `Spec`, `Plan`, `Implement`, `Verify`, `Done`. Durable status tokens are the finer states. |
| L-06 | `check_readiness(root, feature, *, skill="", phase="", target_state="")` is the only readiness evaluator. |
| L-07 | Named-skill readiness uses that route's `prerequisites` only. It does not inherit the coarse phase file set. |
| L-08 | `--phase` without `--skill` remains a compatibility path and uses state-machine phase preconditions plus mechanical extras. |
| L-09 | Mechanical extras for coarse phases: Plan requires requirements readiness; Implement requires a non-empty acyclic `tasks.md` and every AC mapped to a task; Verify requires every task done with evidence; Done requires `session-extracts.md` with `## Post-Ship Sync`. |
| L-10 | Named-skill Done extras additionally require `review.md` plus the Post-Ship Sync heading. Coarse `--phase Done` requires the heading but, in the current evaluator, does not re-check `review.md` (the phase precondition already requires the file). |
| L-11 | `phase-check` is read-only. Advisory mode converts failures to `deferred`; blocking mode returns `failed`. |
| L-12 | Envelope key `mechanical_failures` remains in `phase-check` details even though the logic now lives in `readiness.py`. |

Coarse phase preconditions in the shipped state machine:

| Phase | Configured artifacts | Extra mechanical checks |
| --- | --- | --- |
| Bootstrap | none | none |
| Spec | `spec.md`, `status.md` | none |
| Plan | `spec.md` | requirements readiness (AC IDs, no orphan links) |
| Implement | `plan.md`, `tasks.md` | ≥1 task, no cycle, every AC mapped |
| Verify | `spec.md`, `tasks.md` | all tasks done, done tasks have evidence |
| Done | `review.md`, `session-extracts.md` | `## Post-Ship Sync` present |

---

## 9. Feature artifacts

| ID | Requirement |
| --- | --- |
| A-01 | Feature artifacts live in `artifacts/features/<slug>/`. |
| A-02 | Canonical files: `status.md`, `analysis.md`, `spec.md`, `proposal.md`, `requirements-review.md`, `plan.md`, `tasks.md`, `tasks.json`, `review.md`, `session-extracts.md`, `testing-scenarios.md`. |
| A-03 | `status.md` is created from `skills/_shared/status-template.md`. Agents must not hand-edit `- Phase:`. |
| A-04 | `spec.md` is the requirements authority. Functional requirements use `REQ-*`. Acceptance criteria use `AC-*` / `AC_*`. |
| A-05 | `tasks.md` is canonical task state. `tasks.json` is a generated sidecar and read-only fallback. |
| A-06 | Task IDs are `T-NNN`. Older `TASK-*` IDs are not parsed. |
| A-07 | Task statuses are `{Not Started, In Progress, Blocked, Done, Deferred}` with the implemented transition table. |
| A-08 | `task-done` requires explicit validation evidence (`Validation evidence:` or `Proof:`). |
| A-09 | `task-start` is blocked by unfinished or missing dependencies. |
| A-10 | `task-block` requires `--note`. |
| A-11 | An active `[:HALT` marker in `spec.md`, `plan.md`, or `tasks.md` blocks task status changes. |
| A-12 | Cycles, duplicate IDs, missing dependencies, and checkbox/status disagreement fail `task-check`. |
| A-13 | `artifact-check` requires exactly one of `--skill` or `--phase` and uses `files_for(root, skill=, phase=)`. `--skill` checks route prerequisites only (not the skill's own writes). `--phase` uses `PHASE_FILES` as the coarse compatibility fallback. |
| A-14 | Required headings: `spec.md` (`## Metadata`, `## Problem Statement`, `## Acceptance Criteria`); `plan.md` (`## Metadata`, `## Approach`); `tasks.md` (`## Metadata`, `## Tasks`); `review.md` (`# `, `## Decision`). |
| A-15 | Bidirectional traceability: every spec AC is linked from `tasks.md`; task-linked ACs exist in `spec.md`; done tasks have evidence; a review that requests changes must name remediation task IDs. |
| A-16 | `verify` always runs artifact-check with `--trace`. `verify --skill` is preferred. Bare `verify --feature` still defaults to coarse `--phase Verify` and emits a compatibility warning. |

Coarse `artifact-check --phase` file sets (`PHASE_FILES` fallback):

| Phase | Required files |
| --- | --- |
| Spec | `status.md`, `spec.md` |
| Plan / Implement / Verify | `status.md`, `spec.md`, `plan.md`, `tasks.md` |
| Done | previous plus `review.md`, `session-extracts.md` |

`--skill` does not use this table. Required writes stay on `skill-exit`.

---

## 10. Context

| ID | Requirement |
| --- | --- |
| X-01 | Context commands require `--skill`. Unknown skills fail. |
| X-02 | Required-feature skills fail context commands without `--feature`. |
| X-03 | Context load fails if route `prerequisites` are missing. |
| X-04 | Every pack includes always-on bootstrap sources: `corebase-specharness/rules/caveman.md` and `core-policies.md` sections `Purpose` and `Normative Rules` (plus `Security Policy` for implement/verify/ADR skills). |
| X-05 | Packs then add route sources, declared feature artifacts (with bounded `session.md` summary: `Objective`, latest progress/handoff, and recent decisions), `status.md` (except `starter-init`), optional compact `--task` payload (active task + direct dependencies; full `tasks.md` omitted), `--add-source` pins, intent-matched domain packs, and bounded local retrieval. |
| X-06 | Domain packs match `--intent` words against `triggers:` in `corebase-specharness/memories/domain/<name>/glossary.md`. |
| X-07 | Local retrieval redacts detected secrets, skips excluded/sensitive/binary/oversize files, and respects `.gitignore` plus configured excludes. |
| X-08 | Must sources are retained even when they exceed budget. Should/Skip sources may be omitted. Missing Must files fail the pack. |
| X-09 | `--add-source` must be a readable repo-relative file, not excluded, and must match `retrieval.pinnable_sources` when that list is set. |
| X-10 | `context-pack` and `context-explain` plan without file bodies. `context-load` returns the pack-selected text (section slice, excerpt, or retrieval summary) plus an operational `skill_payload` (`At a Glance` and step-by-step sections) that points to the full on-disk procedure. It does not re-read whole files when the pack already selected content. |
| X-11 | `context-load` must not read paths outside the repository root. |
| X-12 | Token budget is `min(requested or profile payload, max_injected_tokens - reserve_tokens)`. Default seed: 6000 max, 1500 reserve, profile payloads 2500–4000. Existing adopter config is copy-if-missing and keeps its old seed. |
| X-13 | Channel caps apply to non-Must sources: bootstrap, project, feature/task, retrieved, durable_memory, explicit. |
| X-14 | Packs expose tokenizer mode (`cl100k_base` or `chars_per_token_estimate`), fingerprints, and optional `--delta-from` change sets. When `--full` is omitted, an existing session `last_context_fingerprint` / `last_context_slices` in `session.md` is the accumulated delta baseline for the session. Later skills inject only new or changed files and only new or changed H2 sections. |
| X-15 | Session token usage is accumulated in `session.md` `token_usage_estimate`. `status` and context commands warn at `thresholds.session_warn_tokens` (seed 40000) and report a hard-budget breach at `thresholds.session_hard_tokens` (seed 80000). |
| X-16 | Auto-delta is valid only while skipped sources remain in the live conversation. The compiler does not detect conversation compact or a new chat. The agent must pass `--full` after compact, on the first skill of a new chat for the same feature, when the user asks to reload context, or when the pack is known stale. `--full` is an agent flag; the user invokes skills and, when needed, says reload context. |

`reserve_tokens` still shrinks the injectable ceiling. New-install seed: 6000 max, 1500 reserve, ceiling 4500.

---

## 11. Sessions

| ID | Requirement |
| --- | --- |
| N-01 | Sessions live at `.corebase-specharness/sessions/<slug>/session.md`. |
| N-02 | Session files have JSON front matter plus Markdown body with `Objective`, `Progress`, and `Handoff`. |
| N-03 | `session-start` / `skill-enter` create or resume. A closed session is reopened rather than overwritten. |
| N-04 | `session-checkpoint` appends progress/handoff and records decisions in metadata. It requires an existing session. |
| N-05 | `session-end` requires a handoff, may append memory candidates to `session-extracts.md`, and marks the session closed. It does not delete `session.md` and does not clear `last_context_fingerprint` / `last_context_slices`. |
| N-06 | Writes use a lock plus atomic replace. |
| N-07 | A later `session-start` / `skill-enter` reopens a closed session in place and keeps the fingerprint maps. The first skill of a new conversation on that feature must pass `--full`. |

---

## 12. Verification, gates, and providers

| ID | Requirement |
| --- | --- |
| G-01 | New installs ship `gates: []` and `verification.mode: advisory`. |
| G-02 | Valid modes are `advisory` and `blocking`. Unknown values behave as `blocking` at read time and fail config validation if set explicitly. |
| G-03 | The runtime never infers project commands. Gates are added only after explicit adopter confirmation. |
| G-04 | Gate `command` is a non-empty argv list unless `allow_shell: true` and `shell_rationale` is non-empty. |
| G-05 | `on_fail` is `block`, `warn`, or `continue`. Default comes from `gate_defaults.on_fail` (`block` in the seed). |
| G-06 | `verify` composes phase-check, artifact-check with trace, confirmed gates, and the review provider. `--skill` is preferred and scopes both checks. `--phase` remains the compatibility path and defaults to `Verify` when `--skill` is omitted. `--skill` and `--phase` together fail. |
| G-07 | `details.verified` is true only when not dry-run and phase, artifacts, traceability, blocking gates, and required providers all pass. |
| G-08 | Advisory `verify` exits 0 with `status: deferred` when unverified. Blocking `verify` fails. |
| G-09 | Dry-run evaluate static checks but must not execute gates or claim a verdict. |
| G-10 | Verification runs inline during `verify` and closeout `skill-exit`, evaluating gates and artifact criteria in-memory. |
| G-11 | Providers are optional. Categories are `review` and `code-intelligence`. Modes are `optional` and `required`. |
| G-12 | Active provider `none` is valid. Unknown active IDs fail the provider contract. |
| G-13 | `verify` runs the review provider action `run`. Unconfigured optional providers are deferred, not failures. |
| G-14 | Provider commands are argv lists from `references/tool-providers-registry.json`. CoreBase SpecHarness does not install those executables. |
| G-15 | Shipped registry IDs: `open-code-review`, `gitnexus`, `codebase-memory-mcp`. |

---

## 13. Memory and ADR

| ID | Requirement |
| --- | --- |
| M-01 | Durable memory is adopter-owned Markdown under `corebase-specharness/memories/` and `corebase-specharness/project/`. |
| M-02 | `memory-audit` and `memory-gate` are read-only size diagnostics. They do not compact or promote. |
| M-03 | Hard-cap files fail `memory-audit`. `memory-gate --mode block` fails on hard caps; `--mode warn` fails on warn or hard; `--mode advisory` reports and exits 0. |
| M-04 | Seed thresholds: warn 200 lines, hard 3200 lines. |
| M-05 | Promotion, compaction, and archival are `/context-memory` agent procedures, not CLI mutations. |
| M-06 | `adr-generate` drafts `corebase-specharness/project/adr/NNNN-<slug>.md` from `--decision`, `--title`, or session metadata. Feature is optional. Optional `--reversibility Easy\|Moderate\|Hard` defaults to `Moderate` and is written into `adr-log.md`. |
| M-07 | Closeout to `Done` via `harness-verify` requires `review.md` and `session-extracts.md` with `## Post-Ship Sync`. |

---

## 14. Diagnostics and release validation

| ID | Requirement |
| --- | --- |
| D-01 | `doctor` checks manifest, ownership overlap, removed leftovers, routes, command registry, providers, kit-owned lifecycle escape transitions, static reachability, and harness config. |
| D-02 | `core/readiness.py` is a forbidden leftover. The evaluator is `core/harness/readiness.py` and must remain imported from lifecycle/envelope so static audit marks it reachable. |
| D-03 | Runtime commands and doctor do not read `skills/*/SKILL.md`. Skill procedure text is agent-owned. |
| D-04 | `validate-static-audit.py` fails on unreachable shipped modules and unresolvable `core.*` imports. Paths containing `tests` are skipped. |
| D-05 | CI compiles the runtime, runs source-repo `unittest` under `tests/`, runs the static-audit validator, runs `doctor --root kit`, validates page docs, and smoke-tests a clean install. `tests/` is not part of the installed payload. There is no pytest step. See [RELEASING.md](RELEASING.md). |
| D-06 | Installer and static audit must keep skipping `test_*` basenames so repo-root tests are not copied into adopter trees. |

---

## 15. Non-goals (current contract)

The implementation must not grow these without an explicit redesign:

- orchestrator, workflow engine, or skill chooser
- database, plugin bus, or RPC layer
- hidden phase runner that sequences the 11 skills
- automatic gate inference
- automatic memory promotion
- restoration of removed leftovers listed in `check_surface_integrity`

---

## 16. Known implementation gaps that a review should treat as facts

These are current behavior, not accidental omissions in this spec:

1. `PHASE_FILES` remains the coarse `--phase` fallback for `artifact-check`. `--skill` uses route prerequisites via `files_for`.
2. `phase-check --phase` and `verify --phase` remain compatibility flags. `--skill` is the preferred input.
3. `reserve_tokens` shrinks the injectable ceiling. New-install seed is 6000 − 1500. Existing adopter `harness-config.yaml` is not overwritten.

---

## 17. Acceptance for this as-built specification

A reviewer can accept this specification when:

1. Every SHALL above is traceable to a file under `kit/`.
2. No requirement depends solely on `product-page/`.
3. Advisory vs blocking, required writes, and single readiness evaluator match `readiness.py`, `envelope.py`, and `lifecycle.py`.
4. The 11-skill table matches `references/context-routes.yaml`.
