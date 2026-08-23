# Harness: readiness, gates, and diagnostics

> **Audience:** platform engineers, adopter maintainers
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/corebase-specharness/scripts/core/`,
> `kit/corebase-specharness/project/harness-config.yaml`,
> `kit/corebase-specharness/project/state-machine.yaml`,
> `kit/corebase-specharness/project/tool-providers.md`,
> `kit/references/tool-providers-registry.json`,
> `kit/skills/harness-verify/SKILL.md`,
> `kit/skills/harness-maintain/SKILL.md`

## Harness architecture

CoreBase SpecHarness separates deterministic workflow checks from adopter-confirmed
project commands and optional tool providers.

```text
phase / skill readiness
  + artifact structure
  + AC-to-task traceability
  + confirmed project gates
  + optional review provider
        │
        ▼
      verify (in-memory evaluation)
```

The embedded runtime does not infer or install project verification commands.
A new installation has no executable gates and uses
`verification.mode: advisory`. The implementing agent proposes
repository-native commands, and the adopter explicitly confirms them in
`corebase-specharness/project/harness-config.yaml`.

If the `verification.mode` key is later deleted, `HarnessConfig.verification_mode()`
falls back to **`blocking`**. The seeded file is `advisory`. Document both.

## One readiness evaluator

`corebase-specharness/scripts/core/harness/readiness.py` is the only evaluator.
`phase-check`, `skill-exit`, and `verify` all call `check_readiness`.

```text
check_readiness(root, feature, skill=, phase=, target_state=)
```

Algorithm, in order:

1. If `--skill` is set, load that route. Unknown skills raise. If `--phase`
   was omitted, use the route's `phase`.
2. If neither skill nor phase remains, raise `--phase or --skill is required`.
3. Load `HarnessConfig` and `Lifecycle`. Unknown phase names raise.
4. File-set check:
   - `--skill`: `files_for(..., skill=)` prerequisites must exist under the
     feature directory.
   - `--phase` only: `Phase.check_preconditions` from the (possibly
     overridden) state machine.
5. Append `mechanical_checks` (see below).
6. Transition check, unless `skip_transition` is true.
7. Return facts. Handlers decide presentation and mutation.

Returned facts, not a CLI envelope:

- `failures`
- `current_state`, `target_phase`, `target_state`
- `transition_ok`, `skip_transition`
- `enforcement_mode`
- `route`, `lifecycle`

`skip_transition` is true when:

- the current token is `Done` or `Abandoned` and the skill is
  `context-memory` or `harness-maintain`, or
- the route has neither `enter` nor `exit`.

`--skill` is preferred. `--phase` remains a compatibility path on
`phase-check`, `artifact-check`, and `verify`. Passing both fails.

`phase-check --skill` uses that route's `prerequisites` instead of the coarse
phase file set, and skips lifecycle-token transition checks when the route has
no enter/exit. Skills without enter/exit therefore do not inherit
`Spec`/`Verify` file requirements they do not own.

Handlers map facts to envelope status:

| Situation | Envelope |
| --- | --- |
| No failures | `ok` |
| Failures and `advisory` | `deferred`, findings as warnings, exit 0 |
| Failures and `blocking` | `failed`, findings as errors, exit 1 |

## Deterministic checks

| Check | Implementation | Behavior |
| --- | --- | --- |
| Lifecycle state machine | `state-machine.yaml`, `HarnessConfig`, `Lifecycle` | Declares phases, states, mapping, and transitions; extended via `lifecycle_overrides` |
| Task graph | `task_graph.py`, `task-check`, `task-start` | Detects cycles and missing dependencies; starting a task with unfinished dependencies is blocked |
| Task sidecar | `sync_task_sidecar` | Regenerates `tasks.json` on mutations; read-only fallback when `tasks.md` is missing |
| Task proof | `task-done` | Requires explicit validation evidence before `Done` |
| HALT markers | `task_graph.py` | Blocks task *mutations* while `spec.md`, `plan.md`, or `tasks.md` contains `[:HALT` |
| Phase readiness | `phase-check` and `readiness.py` | Route prerequisites or coarse `--phase` preconditions, mechanical extras, and legal transitions |
| Artifact structure | `artifact-check` and `artifact_schema.py` | `files_for` resolves route prerequisites (`--skill`) or `PHASE_FILES` (`--phase`) |
| Traceability | `artifact-check --trace` and `verify` | AC-to-task linkage, orphan task-linked ACs, evidence on completed tasks, and review-remediation linkage when `review.md` exists |
| Memory size | `memory-audit` and `memory-gate` | Repository memory plus `corebase-specharness/memories/domain/**/*.md` against line limits |

`contains_stale` in `harness/lifecycle.py` fails a phase precondition when the
named artifact contains `[:HALT`. The shipped state machine does not use it.
It applies only if an adopter adds that check through `lifecycle_overrides`.
The engine does not interpret named HALT tokens (`INCONCLUSIVE`, `STALE`,
and so on). Those remain skill-procedure stop conditions.

### Mechanical extras

When `--skill` is set, `mechanical_checks` adds extras only for a `Done`
target:

- `session-extracts.md` must exist and contain `## Post-Ship Sync`
- `review.md` must exist

When `--skill` is omitted, `mechanical_checks` adds:

| Phase | Configured artifact preconditions | Additional engine checks |
| --- | --- | --- |
| `Spec` | `spec.md`, `status.md` | None |
| `Plan` | `spec.md` | Requirements readiness (`AC-*` present and mapped) |
| `Implement` | `plan.md`, `tasks.md` | At least one task, no cycle, every AC mapped to a task |
| `Verify` | `spec.md`, `tasks.md` | Every task complete and every completed task carrying evidence |
| `Done` | `review.md`, `session-extracts.md` | A `## Post-Ship Sync` record in `session-extracts.md` |

Skill-scoped `Done` also requires `review.md`. Adopters may extend phases,
states, mappings, and transitions through `lifecycle_overrides` in
`harness-config.yaml`. Redeclared phase preconditions merge additively. They
do not replace the kit-owned state-machine file.

`lifecycle_overrides` merge rules:

- `phases`: named merge; extra `preconditions` append when the
  `(artifact, check)` pair is new
- `states`: append, de-duplicated
- `phase_mapping`: overlay
- `transitions`: append
- any other key fails config load
- top-level `phases` in `harness-config.yaml` itself is rejected

## Project gates

`corebase-specharness/project/harness-config.yaml` is adopter-owned and installed with
`copyIfMissing` semantics. The seed contains `gates: []`. Add only commands
that have been inspected and explicitly confirmed:

```yaml
gate_defaults:
  on_fail: block

verification:
  mode: advisory

gates:
  - name: lint
    command: ["npm", "run", "lint"]
    category: lint
    on_fail: block

  - name: test
    command: ["npm", "test"]
    category: test
    timeout_seconds: 600
    on_fail: block
```

Gate commands should be non-empty argv lists. A string command is accepted
only when `allow_shell: true` and a non-empty `shell_rationale` is also
present.

| Field | Behavior |
| --- | --- |
| `name` | Required gate identifier |
| `command` | Required argv list, or a shell string when `allow_shell: true` |
| `category` | Optional descriptive category |
| `required` | Defaults to `true`; when `false`, the implicit failure policy is `warn` |
| `on_fail` | `block`, `warn`, or `continue`; defaults from `gate_defaults.on_fail` |
| `timeout_seconds` | Optional per-gate timeout; otherwise `thresholds.timeout_seconds` (seeded `300`) |
| `allow_shell` | Enables shell execution; defaults to `false` |
| `shell_rationale` | Required explanation when shell execution is enabled |
| `paths` | Optional list of repository-relative globs. Used only with `--fast` |

The runner executes gates from the repository root, combines stdout and
stderr, limits captured output to 64 KiB, stores `output_tail` as the last
2000 characters, and terminates timed-out process groups with `SIGTERM` then
`SIGKILL`. A missing argv[0] is reported as `UNAVAILABLE: tool '...' not found`.

```bash
python3 corebase-specharness/scripts/core/cli.py gate-list --json
python3 corebase-specharness/scripts/core/cli.py gate-check --json
python3 corebase-specharness/scripts/core/cli.py gate-check --fast --json
python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify --json
python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify --fast --json
python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify --dry-run --json
```

`gate-check` validates executable availability for argv-based gates. It does
not execute the gates, and it skips shell-enabled commands. `verify` is the
command that executes confirmed gates.

`verify` runs gates and review providers in-memory and outputs JSON or ANSI results.

## Verification pipeline

`verify --feature <slug> --skill harness-verify` runs:

1. `check_readiness` for `--skill` when given, else `--phase` (default
   `Verify`).
2. `artifact-check --trace` with the same skill or phase scope.
3. All confirmed gates from `harness-config.yaml`.
4. The selected review-provider action (`run`).
5. Reports verified status and findings in JSON output.
6. Reports phase, artifact, traceability, gate, and provider outcomes.

`verify` does not accept `--task`. Use `--skill` to scope readiness and
structure. Task mutations stay on `task-start` / `task-done` / `task-block`.

`details.verified` (also `details.passed`) is true only when all of these
hold:

- the command is not a dry-run
- phase `meets_preconditions` is true
- artifact `validation_errors` is empty
- `traceability_errors` is empty
- every failed gate has `on_fail != block`
- the review-provider result is `ok`, or the provider is not required and
  the result is `deferred` or `unavailable`

The envelope also exposes `details.verification_mode` (alias of
`enforcement_mode`) and a top-level `traceability_errors` field.

Dry-run evaluates static checks and does not issue a verification verdict.
`details.would_pass_static_checks` reports whether the static half would have
passed.

### Advisory and blocking

| Mode | Result when findings remain |
| --- | --- |
| `advisory` | Returns `status: deferred`, reports findings as warnings, and exits 0; `details.verified` remains `false` |
| `blocking` | Returns `status: failed`, reports findings as errors, and exits non-zero |

Advisory mode does not turn failed checks into passing evidence. Consumers
must inspect `details.verified` rather than treating a successful process
exit as proof of verification.

Seeded `verification.mode` is `advisory`. Code fallback when the key is
absent is `blocking`.

### Closeout authorization and project setup

`Done` is a mechanical closeout state. The normal path is only
`skill-exit --skill harness-verify`: readiness requires `review.md` and a
`## Post-Ship Sync` heading, while the central lifecycle writer executes
inline verification against configured gates, artifacts, and traceability.

`status-set` cannot normally set `Done`; it requires an explicit
`--verification-override --override-reason "..."`. A different skill cannot normally exit
to Done. An advisory exit code and `review.md` alone never authorize Done.

The adopter-owned config seeds `project_setup.status: deferred`. `doctor` warns
rather than fails until setup is `ready` and also warns when no gates exist.
`/starter-init` changes the marker only after the adopter reviews project
context and explicitly confirms repository-native gates. CoreBase SpecHarness never infers
gates.

### `/harness-verify`

The skill owns the work the mechanical command cannot determine by itself:

- fresh-evidence review
- AC-to-task-to-proof mapping
- design conformance against `plan.md`
- dropped-behavior review
- security review against repository policy
- the final decision in `review.md`
- transition of `status.md` to `Done` after required verification and memory
  sync

The CLI does not write `review.md` or perform semantic design or security
review. Those are procedural responsibilities of `/harness-verify`.

## Optional tool providers

Provider selection is adopter-owned in `corebase-specharness/project/tool-providers.md`.
The kit default is opt-in, not required. New installs select `none` in both
supported categories so fresh environments do not need `ocr`, `gitnexus`, or
MCP binaries:

```yaml
providers:
  review:
    active: none
    mode: optional
  code-intelligence:
    active: none
    mode: optional
```

Do not change the shipped seed to `active: open-code-review` or
`mode: required`. CoreBase SpecHarness never installs or authenticates OCR. `/harness-verify`
already performs two-axis review without it. Required OCR belongs in a specific
adopter repo after `ocr` is installed and configured:

```yaml
providers:
  review:
    active: open-code-review
    mode: required
```

| Category | Provider | Local action |
| --- | --- | --- |
| `review` | `open-code-review` | `run` → `ocr review` |
| `code-intelligence` | `gitnexus` | `refresh` → `gitnexus analyze` |
| `code-intelligence` | `codebase-memory-mcp` | `refresh` → `codebase-memory-mcp index .` |

```bash
python3 corebase-specharness/scripts/core/cli.py provider-list --json
python3 corebase-specharness/scripts/core/cli.py provider-check --json
python3 corebase-specharness/scripts/core/cli.py provider-run --category review --feature <slug> --json
python3 corebase-specharness/scripts/core/cli.py provider-run --category code-intelligence --action refresh --json
```

An unavailable optional provider returns `deferred`. An unavailable required
provider returns `failed`. `verify` automatically requests the review
provider's `run` action. Code-intelligence semantic queries remain
provider-specific; the CoreBase SpecHarness CLI only runs actions declared in the
registry.

`provider-run` without `--action` defaults to `run` for `review` and
`check` for `code-intelligence`. `check` does not execute a provider binary;
it reports availability and points at the provider guide. Declared execute
actions for code-intelligence are `refresh`.

## Diagnostics

### Package doctor

```bash
python3 corebase-specharness/scripts/core/cli.py doctor --json
```

`doctor` runs eleven named package-health checks from `harness/doctor.py`.
The first ten fail the command when they fail. `project_setup` is advisory
and never fails package health:

| Name | What it checks |
| --- | --- |
| `manifest` | Manifest contracts |
| `ownership` | Overlap between overwrite-owned and adopter-owned manifest entries |
| `surfaces` | Removed leftover surfaces must not reappear |
| `context_routes` | Route validity against the state machine and skill tree |
| `skills` | Skill metadata and command references |
| `commands` | CLI command registration and handler availability |
| `providers` | Provider registry and selection validity |
| `upgrade_contracts` | Kit-owned `Blocked` and `Abandoned` escape transitions |
| `static_audit` | Source reachability and case-insensitive path uniqueness |
| `configuration` | `HarnessConfig` loads without error |
| `project_setup` | Advisory warning when setup is not `ready` or no gates are confirmed |

It does not generate a dashboard or rebuild a context index.

Leftover paths `check_surface_integrity` rejects if they reappear:

```text
corebase-specharness/scripts/core/harness/cli.py
corebase-specharness/scripts/core/tool_providers.py
corebase-specharness/scripts/core/dashboard_generator.py
corebase-specharness/scripts/core/capability_recommender.py
corebase-specharness/scripts/core/catalog_generator.py
corebase-specharness/scripts/core/_lib/context_index.py
corebase-specharness/scripts/core/_lib/budget.py
corebase-specharness/scripts/core/_lib/telemetry_roi.py
corebase-specharness/scripts/core/_lib/telemetry_store.py
corebase-specharness/scripts/core/handlers/configuration.py
corebase-specharness/scripts/core/handlers/handoff.py
corebase-specharness/scripts/core/handlers/upgrades.py
corebase-specharness/scripts/core/readiness.py
.corebase-specharness/engine
.corebase-specharness/scripts
```

### Memory diagnostics

```bash
python3 corebase-specharness/scripts/core/cli.py memory-audit --json
python3 corebase-specharness/scripts/core/cli.py memory-gate --mode advisory --json
```

Thresholds come from `thresholds.memory_warn_lines` and
`thresholds.memory_hard_lines`. Seeded values are `200` and `3200`. The code
fallback is `100` / `3200` if the key is absent.

`memory-audit` accepts `--mode` in the parser and **ignores it**. It fails
only when any inspected file reaches the hard cap.

`memory-gate` modes:

- `advisory`: report without failing
- `warn`: fail if any file reaches the warning or hard limit
- `block`: fail if any file reaches the hard limit

These commands are explicit diagnostics. `session-end` does not run them.

### `/harness-maintain`

`/harness-maintain` interprets deterministic diagnostics and proposes bounded,
user-approved maintenance. The skill, not the `doctor` CLI handler, owns
any proposed repair in terminal output. Policy,
heuristic, or configuration changes require user review.

## Extensibility

| Extension | Ownership and mechanism |
| --- | --- |
| Project gates | Adopter-owned: edit `gates` in `harness-config.yaml` |
| Verification enforcement | Adopter-owned: set `verification.mode` to `advisory` or `blocking` |
| Context settings | Adopter-owned: edit the preserved harness configuration |
| Provider selection | Adopter-owned: select a registry provider in `tool-providers.md` |
| Provider definitions | Kit-owned: update `references/tool-providers-registry.json` |
| Harness runtime | Kit-owned: update `corebase-specharness/scripts/core/` |
| Harness skills | Kit-owned: update `skills/harness-verify/` or `skills/harness-maintain/` with their routes |

## Related documents

- Workflow guide: [WORKFLOW.md](WORKFLOW.md)
- Memory and budgets: [MEMORY.md](MEMORY.md)
- Kit structure: [ARCHITECTURE.md](ARCHITECTURE.md)
- CLI reference: [REFERENCE.md](REFERENCE.md)
- Install and upgrade: [INSTALL.md](INSTALL.md)
