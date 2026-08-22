# Kit architecture

> **Audience:** adopter maintainers, platform engineers, agents, and
> reviewers of the as-built kit
> **Status:** matches `kit/` as of this edit; as-built topology, modules,
> stores, subsystem specifications, and technical design
> **Authority:** `kit/` payload as installed into an adopter repository;
> `kit/manifest.json`, `kit/corebase-specharness/scripts/install.sh`,
> `kit/corebase-specharness/scripts/core/`, `kit/references/context-routes.yaml`,
> `kit/corebase-specharness/project/state-machine.yaml`

Companion to [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md) and
[DESIGN.md](DESIGN.md). Paths below are **installed** paths unless prefixed with
`kit/`.

---

## Executive summary and design principle

CoreBase SpecHarness is a **skills-first, spec-driven delivery kit** that equips AI coding
agents with deterministic, repo-native engineering discipline. Skills tell an
agent how to work. Project-local artifacts preserve inspectable evidence. The
embedded harness enforces mechanical contracts. The context compiler loads only
a bounded pack for the named skill. Install copies the kit; it is not a starter
template.

```text
User request → skill procedure → bounded context → feature artifacts
             → mechanical checks → configured gates → review and memory sync
```

The runtime maintains three non-negotiable boundaries:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       COREBASE SPECHARNESS THREE-LAYER SEPARATION                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. AGENT PROCEDURES (Markdown)                                             │
│     skills/<name>/SKILL.md + skills/_shared/*                               │
│     Owned by agent/human judgment; guides reasoning and output formats.     │
├─────────────────────────────────────────────────────────────────────────────┤
│  2. SYSTEM CONTRACTS (Declarative YAML / JSON)                              │
│     references/context-routes.yaml + corebase-specharness/project/state-machine.yaml    │
│     Single source of truth for routing, prerequisites, and lifecycle tokens. │
├─────────────────────────────────────────────────────────────────────────────┤
│  3. DETERMINISTIC MECHANICS (Stdlib Python CLI)                             │
│     corebase-specharness/scripts/core/ (cli.py, context_engine, harness, task_graph)   │
│     Enforces budgets, evaluates readiness, runs gates, and tracks state.    │
└─────────────────────────────────────────────────────────────────────────────┘
```

The runtime does not choose skills, infer project commands, approve decisions,
or automatically promote memory.

---

## 1. System context and topology

### 1.1 System context

CoreBase SpecHarness is copied into an adopter repository. There is no external runtime
service, engine directory, or background launcher.

```text
                          coding agent / human
                                   |
                     reads skills/<name>/SKILL.md
                     invokes python3 corebase-specharness/scripts/core/cli.py
                                   |
                                   v
+------------------------------------------------------------------+
|                     adopter repository                            |
|  AGENTS.md          portable agent router                        |
|  manifest.json      install ownership                            |
|  skills/            11 procedures + _shared                      |
|  references/        context-routes.yaml, provider registry       |
|  corebase-specharness/scripts/ embedded Python runtime + validators         |
|  corebase-specharness/project/ state machine, harness config, architecture  |
|  corebase-specharness/memories adopter durable memory                       |
|  corebase-specharness/rules    shipped policy snippets                      |
|  artifacts/features/<slug>/   durable feature evidence           |
|  .corezero/sessions/<slug>/   ephemeral session                  |
|  corebase-specharness/generated/         runtime audit JSON                 |
|  <project source>             only spec-implement writes here    |
+------------------------------------------------------------------+
```

Runtime identity of a root: `manifest.json` **and**
`corebase-specharness/scripts/core/cli.py`. `resolve_root` walks from `--root` or cwd
upward. If the hint is a file, it starts from that file's parent.

### 1.2 Five-layer system topology

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       COREBASE SPECHARNESS SYSTEM TOPOLOGY                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Layer 1 — Direct Peer Skills & Routing]                                   │
│  • 11 Direct Peer Skills (starter-init through harness-verify & memory)     │
│  • Routing Authority: references/context-routes.yaml                        │
│  • Optional External Specialist Skills: EXTERNAL_SKILLS.md                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Layer 2 — Context Compiler & Budget Engine]                               │
│  • Route source loader with Must / Should / Skip prioritization             │
│  • Domain pack trigger matching via glossary keywords                       │
│  • Session Auto-Delta caching (session.md last_context_fingerprint)         │
│  • Secret redaction & task-scoped context slimming                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Layer 3 — State Machine & Task Graph Engine]                              │
│  • Kit-owned lifecycle authority: state-machine.yaml (Schema v1)            │
│  • Canonical tasks.md with generated tasks.json sidecar                     │
│  • Cycle detection, dependency validation, and [:HALT brake protection     │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Layer 4 — Verification Harness & Diagnostics]                             │
│  • Unified readiness evaluator: harness/readiness.py                        │
│  • Git-diff-aware argv gate execution: harness/gates.py                     │
│  • Advisory-by-default vs. blocking enforcement modes                       │
│  • Diagnostic APIs: doctor, gate-check, memory-audit, providers             │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Layer 5 — File Stores & Persistence]                                      │
│  • Durable Feature Evidence: artifacts/features/<slug>/                     │
│  • Resumable Ephemeral Sessions: .corezero/sessions/<slug>/session.md      │
│  • Durable Repository Memory: corebase-specharness/memories/ & corebase-specharness/project/      │
│  • Disposable Runtime Logs: corebase-specharness/generated/*.json (Last 50 runs)       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Installed tree and component responsibilities

### 2.1 Installed tree

```text
<repo>/
  manifest.json
  README.md
  AGENTS.md
  EXTERNAL_SKILLS.md
  skills/
    _shared/                 status template, handoff/artifact rules
    <skill>/SKILL.md         11 peer skills
    <skill>/references/      skill-local templates (overwrite-owned)
  references/
    context-routes.yaml      routing authority
    tool-providers-registry.json
  artifacts/features/<slug>/
  .corezero/sessions/<slug>/session.md
  corebase-specharness/
    CONTEXT_AND_MEMORY.md
    MASTER_INDEX.md          adopter-owned after first seed
    scripts/
      install.sh
      validate-static-audit.py
      core/
        cli.py               command registry + envelope
        context_engine.py
        context_state.py
        task_graph.py
        _lib/                artifacts, contracts, routing, yaml, tokens
        handlers/            command implementations
        harness/             config, lifecycle, readiness, doctor, gates
    project/
      state-machine.yaml     kit-owned lifecycle
      harness-config.yaml    adopter-owned
      tool-providers.md      adopter-owned
      architecture.md, tech-stack.md, product-sense.md, ...
      providers/             optional provider guides
      adr/                   generated by adr-generate
    memories/
      repo/                  policies, heuristics, PKB, ADR log
      domain/<name>/         glossary + patterns
      archive/
    rules/                   caveman, security, ponytail, ...
    generated/               gate-runs.json, provider-runs.json, verification-runs.json
```

Installed scripts are `core/`, `install.sh`, and the two validators. Artifact
structure and traceability live in `corebase-specharness/scripts/core/_lib/artifact_schema.py`.

Source-repo extras that are **not** the installed payload: `documents/`,
repo-root `tests/` if present, `.github/`, `product-page/`, `scripts/`.

### 2.2 Component responsibilities

| Component | Responsibility | Authority |
| --- | --- | --- |
| Portable router | Directs agents to the skills-first workflow | `AGENTS.md` |
| Skill layer | Owns procedures, judgment, artifact-writing rules, and handoffs | `skills/*/SKILL.md`, `skills/_shared/` |
| Context router | Declares each named skill's phase, profile, artifacts, writes, handoffs, and sources | `references/context-routes.yaml` |
| Embedded CLI | Dispatches the flat command set and normalizes results | `corebase-specharness/scripts/core/cli.py` |
| Runtime engine | Implements context, sessions, tasks, readiness, gates, diagnostics, ADR | `corebase-specharness/scripts/core/` |
| Lifecycle definition | Kit-owned state machine | `corebase-specharness/project/state-machine.yaml` |
| Adopter configuration | Architecture, constraints, budgets, gates, providers, `lifecycle_overrides` | `corebase-specharness/project/` |
| Durable memory | Repository and domain knowledge | `corebase-specharness/memories/` |
| Delivery artifacts | Specifications, plans, tasks, reviews, evidence | `artifacts/features/<slug>/` |
| Ephemeral session state | Resumable per-feature handoff | `.corezero/sessions/<slug>/session.md` |
| Generated runtime state | Disposable outputs such as gate-run history | `corebase-specharness/generated/` |

---

## 3. Module map and subsystem technical design

### 3.1 Module map

```text
cli.py
  COMMANDS → import_module(handler)
       │
       ├─ handlers/lifecycle.py     init, status, phase-check, artifact-check, verify
       ├─ handlers/envelope.py      status-set, skill-enter, skill-exit
       ├─ handlers/sessions.py      session-start/checkpoint/end
       ├─ handlers/context.py       context-pack/load/explain
       ├─ handlers/tasks.py         task-check/start/done/block
       ├─ handlers/artifacts.py     check_requirements_readiness
       ├─ handlers/diagnostics/     gates, providers, memory, adr
       └─ harness/doctor.py         package health
              │
              ▼
       harness/readiness.py   check_readiness, mechanical_checks
       harness/lifecycle.py   Phase, Lifecycle
       harness/config.py      HarnessConfig + lifecycle_overrides
       harness/gates.py       Gate / GateResult
       context_engine.py      build_context_pack
       context_state.py       session files + atomic_write
       task_graph.py          parse / cycle / sidecar
       _lib/artifacts.py      slug + feature dir + status parse
       _lib/routing_metadata.py
       _lib/artifact_schema.py
       _lib/contracts.py
       _lib/doctor_checks.py
```

Import rule: handlers call harness functions directly. They do not spawn
`cli.py` as a subprocess. Static audit requires every shipped `core.*` module to
be reachable from `cli.py` or the command registry. `harness/readiness.py` stays
imported from envelope and lifecycle so it is not flagged unreachable.
`core/readiness.py` is a forbidden leftover.

`check_readiness` is the single evaluator used by `phase-check`, `skill-exit`,
and `verify`. `files_for(root, skill=)` or `files_for(root, phase=)` resolves
the artifact set. `--skill` and `--phase` are mutually exclusive.

---

### 3.2 Context Compiler (`context_engine.py`)

The Context Compiler prevents prompt pollution and token overflow by assembling
a strictly budgeted, verifiable context pack for each skill invocation.

```text
Compilation Sequence:
1. Universal Bootstrap: caveman.md (Must) + core-policies.md (Must)
2. Route-Declared Sources: context-routes.yaml (Must / Should tiers)
3. Feature Artifacts: status.md (Must) + spec.md / plan.md (Route declared)
4. Active Task Excerpt: Extracted task block when --task T-NNN is supplied
5. Add-Sources: Validated repository-relative paths matching pinnable_sources
6. Domain Memory Packs: Triggered by keyword intersection in glossary.md
7. Bounded Local Retrieval: Path-scoped keyword search with secret redaction
8. Token Estimate & Budget Pruning:
   Tokens = tiktoken cl100k_base when available, else len(text) / 4.0
   Ceiling = min(profile_payload or --budget, max_injected_tokens - reserve_tokens)
   Must sources are guaranteed (warnings emitted on overflow);
   Should sources drop on payload or channel overflow.
```

#### Compiler optimizations
- **Session Auto-Delta**: Uses `last_context_fingerprint` in
  `.corezero/sessions/<slug>/session.md` to compute SHA-256 fingerprint diffs.
  Re-injects only modified files, saving 60–80% of context tokens across
  multi-turn iterations. `--full` bypasses the cache.
- **In-Memory Fingerprinting**: Computes hashes directly from loaded memory
  buffers without redundant disk re-reads.
- **Budget Ceiling**: Budget math enforces `min(budget, max_injected_tokens - reserve_tokens)`.
  With default settings (`max_injected_tokens: 6000`, `reserve_tokens: 1500`),
  effective ceiling is 4,500 tokens.

---

### 3.3 State Engine & Task Graph (`task_graph.py`, `context_state.py`)

Feature progression is governed by `state-machine.yaml` and granular task
transitions.

```text
Status Graph:
Researching ──► ResearchComplete ──► Specifying ──► SpecApproved
                                                         │
                                                         ▼
Verifying ◄── Implementing ◄── PlanApproved ◄── TaskPlanning ◄── Planning
    │
    ▼
  Done (Protected by verify record + Post-Ship Sync)
```

- **Human-Canonical `tasks.md`**: Tasks use strict `T-NNN` identifiers with
  `Covers: AC-*` traceability, `Depends on:`, and `Validation evidence:`.
- **Machine Sidecar `tasks.json`**: Generated deterministically on task
  mutations. Acts as a read-only fallback if `tasks.md`
  is inaccessible.
- **`[:HALT` Human-in-the-Loop Brake**: An agent or human can place `[:HALT reason]`
  anywhere in feature artifacts. The task engine immediately rejects transitions
  until resolved.
- **Atomic File Operations**: All disk writes use locked atomic replacement
  (sibling temporary file, `fsync`, `os.replace`) to prevent state corruption.

---

### 3.4 Verification Harness (`harness/readiness.py`, `harness/gates.py`)

Verification merges mechanical preconditions, artifact structure, requirement
traceability, and repository-native gates into a single verdict.

```text
verify Execution Matrix:
┌─────────────────────────┐
│ check_readiness()       │ ──► Prerequisite artifacts & state transition valid
├─────────────────────────┤
│ artifact_check(trace)   │ ──► Required headings & AC-to-Task traceability complete
├─────────────────────────┤
│ Configured Gates        │ ──► Git-diff-filtered argv execution (on_fail=block)
├─────────────────────────┤
│ Review Provider         │ ──► Local reviewer execution (optional/advisory)
└─────────────────────────┘
            │
            ▼
details.verified = (readiness_ok AND artifacts_ok AND gates_passed AND review_ok)
```

#### Advisory vs. blocking semantics
- **Advisory Mode (`verification.mode: advisory`)**: Default for new installs.
  Reports missing gates and gaps as `status: deferred`. Exits 0 to allow human
  evaluation without breaking scripts, but sets `details.verified: false`.
- **Blocking Mode (`verification.mode: blocking`)**: Strict enforcement for
  mature repositories. Any gate or traceability failure returns `status: failed`
  and exits 1.
- **Mechanically Protected `Done`**: Transition to `Done` requires a matching
  successful run in `corebase-specharness/generated/verification-runs.json` and a
  `## Post-Ship Sync` header in `session-extracts.md`, or an explicit
  `--verification-override --override-reason "..."`.

---

## 4. Control flows

### 4.1 Install and initialization

```text
install.sh <target>
  validate manifest (shape, safety, sources exist)
  copy overwrite  → backup then replace
  copy copyIfMissing → skip existing
  mkdir generated; chmod validators
  cli.py doctor --root <target>
```

`init` is a later in-repo seeder, not the installer. It creates missing
memory/project files and appends `corebase-specharness/generated/*` to `.gitignore`.
See [INSTALL.md](INSTALL.md).

### 4.2 Skill enter and exit

```text
skill-enter --skill S --feature F --intent ...
  skill_route(S)
  require --feature if route.feature == required
  ensure status.md from skills/_shared/status-template.md
  if route.enter: apply_status(enter) unless already compatible
  start_session → build_context_pack → create/reopen session.md
  context_load  → selected content + operational SKILL.md summary

skill-exit --skill S --feature F [--handoff H] [--phase token]
  validate H against route.handoff (or shipped skills if handoff list empty)
  missing = required writes not on disk
  target = --phase or route.exit
  check_readiness(skill=S, target_state=target)
  if any errors: status=failed; do not write status; do not checkpoint
  else apply_status(target); checkpoint_session
```

### 4.3 Readiness evaluation

```text
check_readiness(root, feature, skill=, phase=, target_state=)
  resolve route if skill
  phase = route.phase or --phase   # required
  load HarnessConfig + Lifecycle (kit machine ⊕ lifecycle_overrides)
  if skill:
      failures = missing route.prerequisites
      if target/phase == Done: require review.md + Post-Ship Sync
  else:
      failures = Phase.check_preconditions
      mechanical extras for Plan / Implement / Verify / Done
  unless skip_transition:
      if target_state: check_state_transition(current, token)
      else:            check_transition(current, phase)
  return facts
```

`phase-check` wraps those facts with advisory/blocking presentation.
`verify` prefers `--skill`. Bare `verify --feature` still defaults to
`--phase Verify` and warns that this is coarse compatibility. See
[HARNESS.md](HARNESS.md).

### 4.4 Context pack compilation

```text
build_context_pack(skill, feature, intent, task, budget, add_sources)
  fail if unknown skill, missing required feature, missing prerequisites
  budget = min(request or profile.payload, max_injected_tokens - reserve)
  candidates =
      always-on bootstrap
    + route sources
    + feature_artifacts + status.md (omit full tasks.md when --task is set)
    + compact task payload when --task matches
    + --add-source
    + domain packs (glossary triggers ∩ intent)
    + local retrieval excerpts (redacted)
  sort: always-on, then Must, then score, then smaller, then path
  keep Must even if over budget
  drop non-Must on payload or channel overflow
  optional --delta-from or session last_context_fingerprint keeps only fingerprint changes
  --full disables session auto-delta
```

### 4.5 Task lifecycle

```text
tasks.md  --parse→  [{id, done, depends, status, evidence, acs}]
                 ↘ detect_cycle / validate_task_consistency
task-start / done / block
  reject illegal transition, HALT, unfinished deps, missing evidence/note
  rewrite that task block
  sync tasks.json sidecar
```

`tasks.json` is never the write authority. Token and task graphs live in
[WORKFLOW.md](WORKFLOW.md).

### 4.6 Verification and closeout

```text
verify --feature F [--skill S | --phase Verify]
  files   = files_for(skill=S | phase)
  phase   = evaluate_phase_check(skill or phase)
  arts    = evaluate_artifact_check(skill or phase, trace=True)
  gates   = [gate.run(root) for gate in config.get_gates()]
  review  = run_provider(category=review, action=run)
  append generated/gate-runs.json, provider-runs.json, verification-runs.json
  verified = (not dry_run)
             and phase.meets_preconditions
             and no artifact/trace errors
             and all on_fail=block gates passed
             and (review ok, or not required)
  status = ok | deferred (advisory) | failed (blocking)
```

---

## 5. Data architecture and persistence stores

### 5.1 Feature store

`artifacts/features/<slug>/`

| File | Writer | Reader |
| --- | --- | --- |
| `status.md` | envelope (`skill-enter`/`exit`, `status-set`) | status, readiness, context |
| `analysis.md` | spec-research | spec-requirements, context |
| `spec.md` | spec-requirements | plan/tasks/implement/verify, traceability |
| `proposal.md` | spec-requirements (optional) | humans |
| `requirements-review.md` | spec-requirements (optional) | humans |
| `plan.md` | spec-plan | tasks/implement/verify |
| `tasks.md` | spec-tasks, spec-implement, task-* | task graph, readiness, verify |
| `tasks.json` | task mutations | load fallback |
| `review.md` | harness-verify | Done readiness, traceability |
| `session-extracts.md` | session-end, context-memory | Done readiness |
| `testing-scenarios.md` | spec-testing-scenario | humans / QA |

Slug containment: `canonical_feature_dir` resolves under
`artifacts/features/` and rejects path escape.

### 5.2 Session store

`.corezero/sessions/<slug>/session.md` is Markdown with JSON frontmatter, not
YAML:

```text
---
{
  "feature": "<slug>",
  "phase": "<route phase>",
  "skill": "<skill>",
  "created_by": "corebase-specharness",
  "selected": ["..."],
  "omitted": ["..."],
  "started_at": "<isoformat seconds>",
  "updates": 0,
  "decisions": [],
  "closed": false,
  "ended_at": "<isoformat seconds, set on session-end>",
  "last_context_tokens": 0,
  "token_usage_estimate": 0
}
---

# Session

## Objective

## Progress

## Handoff
## Progress Update / Handoff Update / Session Reopened   # appended
```

Writes lock the target file itself, then `atomic_write` (sibling tempfile,
`fsync`, `os.replace`). No leftover `.lock` sidecars are written.
`session-checkpoint` appends `## Progress Update` and
`## Handoff Update` blocks and increments `updates`. Recorded `--decision`
values accumulate in `metadata.decisions` for `adr-generate`. `session-end` sets
`closed` and does not delete the file. A later `session-start` reopens a closed
session and appends `## Session Reopened`.

### 5.3 Lifecycle store

`corebase-specharness/project/state-machine.yaml` (kit overwrite):
- `phases[]` with `{artifact, check}` preconditions (`exists`, `contains_stale`)
- `states[]`
- `phase_mapping` (must cover every state)
- `transitions[]` `{from, to}`

`harness-config.yaml` (adopter seed):
- `lifecycle_overrides` `{phases, states, phase_mapping, transitions}`
- `verification.mode`
- `gates[]`
- `thresholds`
- `context` budgets, profiles, retrieval

Merge: named phases append unseen preconditions; states de-dupe; mappings
overlay; transitions concatenate. The shipped state machine does not use
`contains_stale`. That check applies only when an adopter adds it through
`lifecycle_overrides`. `harness-config.yaml` must not contain a top-level
`phases` key.

### 5.4 Route store

`references/context-routes.yaml`:

```yaml
skills:
  - skill: spec-plan
    phase: Plan
    enter: Planning
    exit: Planning
    profile: planning
    feature: required
    prerequisites: [spec.md]
    feature_artifacts: [status.md, spec.md, {kind: session, name: session.md}]
    writes: [plan.md, status.md]
    handoff: [spec-tasks, spec-research, spec-adr]
    sources:
      - {path: corebase-specharness/project/architecture.md, tier: Must, sections: [...]}
```

Every shipped skill has exactly one route. Writes are strings or
`{path, required}`. `status.md` must be optional; the envelope writes it.
`required_handoffs` is forbidden.

### 5.5 Generated store

`corebase-specharness/generated/` is runtime-only. The kit must not ship files other than
`.gitkeep`. `verify` and `provider-run` append capped JSON arrays (last 50
records) to `gate-runs.json`, `provider-runs.json`, and `verification-runs.json`.
`init` appends `corebase-specharness/generated/*` to `.gitignore`.

---

## 6. State machines and trust boundaries

### 6.1 Feature tokens

Shipped states: `Researching`, `ResearchComplete`, `Specifying`,
`SpecApproved`, `Planning`, `TaskPlanning`, `PlanApproved`, `Implementing`,
`Verifying`, `Done`, `NeedsClarification`, `Blocked`, `Replanning`,
`ChangesRequested`, `Abandoned`.

Happy path:

```text
Researching → ResearchComplete → Specifying → SpecApproved
  → Planning → TaskPlanning → PlanApproved
  → Implementing → Verifying → Done
```

Implemented back-edges include implement→plan/specify/replan, verify→changes or
implement or plan, blocked from in-flight tokens, and abandon from every in-flight
token including `ResearchComplete`, `TaskPlanning`, `PlanApproved`, `Replanning`,
`NeedsClarification`, `Blocked`, and `ChangesRequested`. Same-state writes are
legal. Unknown/empty current state may enter any declared state.

### 6.2 Task tokens

```text
Not Started → In Progress → Done
     │              │
     └──── Blocked ─┘
            Deferred ↔ Not Started / In Progress
Done → In Progress          # reopen
```

Checkbox `[x]` must agree with Status when Status is explicit. `task-done`
requires evidence. `task-block` requires `--note`. `[:HALT` in `spec.md`,
`plan.md`, or `tasks.md` blocks task mutations.

### 6.3 Trust and safety boundaries

| Boundary | Mechanism |
| --- | --- |
| Feature path | slug regex + resolve-under `artifacts/features` |
| Context add-source | repo-relative, no `..`, not excluded, optional pinnable glob |
| Context load | skip files whose resolved path is outside root |
| Retrieval | exclude VCS/vendor/generated, skip binaries/secrets filenames, redact patterns |
| Gates | argv default; shell only with rationale |
| Writes | atomic replace + `locked()` on status/session/extracts |
| Upgrade | overwrite vs copyIfMissing; backup dir `.corezero-backup-*` |
| Leftovers | doctor `check_surface_integrity` fail-if-present list |

The runtime does not sandbox the agent. It contains *its own* file writes and
context reads.

---

## 7. Doctor and CI architecture

### 7.1 Doctor checks

`doctor` is the installed health surface. Checks, in order:

1. `manifest` — SemVer, required keys, missing sources, shipped generated files
2. `ownership` — overwrite ∩ copyIfMissing
3. `surfaces` — removed leftovers still on disk
4. `context_routes` — fields, phases, states, source files/sections
5. `commands` — every registry handler importable and unique
6. `providers` — registry + selected IDs
7. `upgrade_contracts` — kit-owned `Blocked` and `Abandoned` escape transitions
8. `static_audit` — reachability of shipped `core.*` modules
9. `configuration` — `HarnessConfig` loads

### 7.2 CI validation pipeline

Source-repo CI additionally verifies:
- `python3 -m compileall -q kit/corebase-specharness/scripts/core`
- static audit validator against `kit/` (`validate-static-audit.py`)
- `doctor --root kit`
- product-page validator (`scripts/validate-product-page.py`)
- source-repo `python3 -m unittest discover -s tests -v`
- clean install smoke (`context-load --skill starter-init`, provider
  list/check/run, assert removed commands `context-index` and `task-next`
  stay gone)

Source-repo `tests/` is stdlib `unittest`. It is not copied into adopter
trees. The installer skips `test_*` basenames. There is no pytest step.
See [RELEASING.md](RELEASING.md).

---

## 8. Codebase maintainability and redundancy reduction

The following architectural optimizations maintain strict separation of
concerns and zero dead-code overhead:

1. **Eliminate Double Compilation in `skill-enter`**:
   - Reuse the compiled context pack from `start_session` within `context_load`
     rather than executing `build_context_pack` twice.
2. **Consolidate Audit Log Appender**:
   - Share `_append_generated_record` from `handlers/common.py` across `verify`
     (`gate-runs.json`, `verification-runs.json`) and `envelope.py` (`closeout-overrides.json`).
3. **Consolidate Manifest Projection**:
   - Factor repetitive dictionary formatting in `handlers/context.py` into a
     unified `_pack_manifest(pack)` helper.
4. **Relocate Pseudo-Handler `handlers/artifacts.py`**:
   - Move `check_requirements_readiness` into `harness/readiness.py` or
     `_lib/artifact_schema.py` to maintain a clean 1:1 mapping between `handlers/`
     and CLI verbs.

---

## 9. Strategic implementation roadmap

| Milestone | Capability | Focus Area | Impact | Priority |
| :--- | :--- | :--- | :--- | :--- |
| **M1** | **`cli.py next` Command** | Developer Ergonomics | Eliminates workflow confusion by suggesting next steps deterministically. | **P0** |
| **M1** | **Strict AC Traceability Gate** | Quality & Verification | Blocks closeout if any AC lacks task linkage or verification proof. | **P0** |
| **M2** | **Fast-Track Bugfix Route** | Workflow Agility | Streamlines isolated 1-task changes without spec ceremony overhead. | **P1** |
| **M2** | **Compiler Redundancy Cleanup** | Engine Performance | Eliminates duplicate pack builds and in-memory file re-reads. | **P1** |
| **M3** | **Parallel Tier-1 Gate Runner** | Verification Latency | Runs independent linters/type-checks concurrently before running test suites. | **P2** |
| **M3** | **AST Skeleton Extraction** | Token Compression | Generates signature-only AST skeletons for secondary context files. | **P2** |

### 9.1 Guided Step Recommendation (`cli.py next`)

A high-value developer ergonomics command that inspects current repository and
feature state to output the exact next step:

```bash
python3 corebase-specharness/scripts/core/cli.py next --feature <slug> --json
```

**Output Contract:**
```json
{
  "command": "next",
  "status": "ok",
  "feature": "payment-retry",
  "current_state": "SpecApproved",
  "recommended_skill": "spec-plan",
  "recommended_cli": "python3 corebase-specharness/scripts/core/cli.py skill-enter --skill spec-plan --feature payment-retry --intent 'design technical architecture'",
  "reason": "spec.md is approved with 3 ACs. plan.md does not exist yet.",
  "blockers": []
}
```

### 9.2 Fast-Track Bugfix Profile Specification

To eliminate unnecessary ceremony for isolated, single-task bugfixes, the
**Fast-Track Delivery Profile** streamlines the pipeline without bypassing
verification:

```text
Fast-Track Flow:
1. /spec-requirements (Fast-Track mode)
   - Binds issue description into a focused spec.md with 1-2 ACs.
2. /spec-tasks (Direct entry)
   - Generates tasks.md containing a single task (T-001) linked to AC-001.
3. /spec-implement
   - Executes fix with focused unit proof.
4. /harness-verify
   - Executes change-filtered gates and records review.md verdict.
```

---

## 10. Reviewer invariants, ownership, and related documents

### 10.1 Invariants a reviewer can test

1. `doctor --root kit` is `ok`.
2. Every `skills/*/SKILL.md` name has a route; every route has a skill.
3. `skill-exit` without `spec.md` after `spec-requirements` is `failed`.
4. `skill-exit` without `proposal.md` is not a missing-write failure.
5. `phase-check --skill spec-testing-scenario` and `artifact-check --skill spec-testing-scenario` do not demand `tasks.md`.
6. `phase-check --phase Verify` and `artifact-check --phase Verify` do demand the coarse Verify file set / finished tasks.
7. Advisory `verify --phase Verify` can be exit 0 with `details.verified: false`. `verify --skill spec-testing-scenario` does not fail structure for missing tasks.
8. `check_readiness` is imported by both envelope and lifecycle.
9. `core/readiness.py` does not exist.
10. Installer dry-run plus real install still leave adopter `harness-config.yaml` untouched on a second install.

### 10.2 Ownership

`kit/manifest.json` assigns paths to one of two classes:

- **Kit-owned (`overwrite`)**: runtime, skills, routes, rules,
  `state-machine.yaml`. Replaced on upgrade after backup.
- **Adopter-owned (`copyIfMissing`)**: project constraints, architecture,
  `harness-config.yaml`, memory seeds. Initialized once.

Adopter-created data is preserved because it is not matched by an overwrite
entry. This includes `artifacts/features/`, `.corezero/` sessions, and
generated runtime state.

### 10.3 Architectural invariants

- The kit is fully project-local and uses only Python's standard library at
  runtime (`tiktoken` is optional).
- Skills own agent procedure and judgment; the CLI owns deterministic mechanics.
- Named routes, not generated indexes or phase fallbacks, are the context authority.
- `--skill` is preferred. `--phase` remains compatibility on `phase-check`,
  `artifact-check`, and `verify`.
- Adopter gates and provider selection remain explicit configuration.
- `status.md` is durable feature state, `.corezero/sessions/` is ephemeral
  continuity, and `corebase-specharness/generated/` is disposable runtime state.
- Upgrade ownership is determined only by `overwrite` and `copyIfMissing`.

### 10.4 Related documents

- Usage and operating notes: [WORKFLOW.md](WORKFLOW.md)
- Skill catalog: [SKILLS.md](SKILLS.md)
- Design thesis: [DESIGN.md](DESIGN.md)
- As-built requirements: [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md)
- Memory and budgets: [MEMORY.md](MEMORY.md)
- Harness and gates: [HARNESS.md](HARNESS.md)
- CLI reference: [REFERENCE.md](REFERENCE.md)
- Install and upgrade: [INSTALL.md](INSTALL.md)
- Release process: [RELEASING.md](RELEASING.md)
- Source authority: [../INDEX.md](../INDEX.md)
