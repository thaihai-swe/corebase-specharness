# How to apply the kit: usage guide and workflow

> **Audience:** adopters, developers, coding agents, platform engineers, and maintainers
> **Status:** matches `kit/` as of this edit; definitive operating guide and workflow reference
> **Authority:** `kit/skills/*/SKILL.md`, `kit/references/context-routes.yaml`,
> `kit/corebase-specharness/project/state-machine.yaml`, `kit/corebase-specharness/scripts/core/`

CoreBase SpecHarness is a **local, spec-driven delivery workflow**, not a library, a server,
or a starter template. You install it into an adopter repository, then drive
engineering work through named skills and the embedded Python CLI. The
repository files are the system of record. The harness provides deterministic
mechanical checks. The context compiler loads bounded context packs per named
skill. `/starter-init` is used only once to tailor an untailored repository.

---

## 1. What you are applying

After installation, an adopter repository contains:

```text
your-repo/
├── AGENTS.md                          portable agent router
├── manifest.json                      kit ownership and version identity
├── skills/
│   ├── _shared/                       shared status/artifact/handoff rules
│   └── <name>/SKILL.md                11 direct peer skill procedures
├── references/
│   ├── context-routes.yaml            skill routing authority
│   └── tool-providers-registry.json   optional provider registry
├── artifacts/features/<slug>/         durable feature evidence
├── .corezero/sessions/<slug>/         ephemeral session state
└── corebase-specharness/
    ├── scripts/core/cli.py            embedded Python runtime & harness
    ├── project/                       adopter project config & architecture
    ├── memories/                      durable project memory (repo & domain)
    ├── rules/                         shipped policy snippets (code-design, security, ponytail, caveman)
    └── generated/                     runtime logs (gate-runs, verification-runs)
```

You do not call Python modules directly from application code. The operating pattern is:

1. **Invoke a skill** (via agent slash command or reading `skills/<name>/SKILL.md`).
2. **Execute `skill-enter`** to initialize status, session, and bounded context.
3. **Write required feature artifacts** under `artifacts/features/<slug>/`.
4. **Execute `skill-exit`** with a declared handoff.
5. **Close features** with `/harness-verify` and `/context-memory`.

The runtime deterministically verifies that required artifacts, lifecycle tokens,
task dependency graphs, and test evidence exist.

### How requests execute and token costs are budgeted

1. **User Request & Entry**:
   When a user provides an intent or requests a skill, the agent calls `skill-enter --skill <name> --feature <slug> --intent "<intent>"`. This resolves route prerequisites, sets feature status in `status.md`, and creates/resumes `.corezero/sessions/<slug>/session.md`.
2. **Context Compilation & Token Estimation**:
   `context_engine.py` compiles the bounded context pack. Token estimates are calculated using `cl100k_base` BPE (via `tiktoken` when present) or `chars_per_token_estimate` (`len(text) / 4.0` in pure stdlib Python).
3. **Budget Enforcement**:
   The payload is capped at `min(profile_payload or --budget, max_injected_tokens - reserve_tokens)`. Mandatory `Must` files are always preserved (universal bootstrap is only ~410 tokens: `caveman.md` + `core-policies.md` [Purpose, Normative Rules]); `Should` files and local search excerpts are dropped if payload or channel caps (`bootstrap`, `project`, `feature`, `task`, `retrieved`, `durable_memory`) are reached.
4. **Skill Execution & Exit**:
   The agent performs the tasks defined in `skills/<name>/SKILL.md`, writes feature artifacts under `artifacts/features/<slug>/`, and runs `skill-exit` to validate artifact completeness and transition to the next lifecycle skill.

### Role ownership matrix

| Role | Owns |
| --- | --- |
| **Developer or repo owner** | Product decisions, requirements approval, gate confirmation, and acceptance feedback |
| **Coding agent** | Skill execution, bounded code inspection, artifact authoring, task implementation, proof, and handoffs |
| **CoreBase SpecHarness CLI** | Scaffolding, context assembly, session tracking, task state transitions, artifact schema checks, gate execution, and diagnostics |
| **Kit maintainer** | Embedded runtime implementation, manifest ownership, route/skill consistency, and release hygiene |

---

## 2. Install and validate

Python 3.10+ is required.

### 2.1 Install from kit source

From this kit checkout:

```bash
# Preview first
bash kit/corebase-specharness/scripts/install.sh /path/to/your-repo --dry-run

# Run installation
bash kit/corebase-specharness/scripts/install.sh /path/to/your-repo
```

The installer:
- Copies **kit-owned (`overwrite`)** files (`cli.py`, skills, routes, state machine, rules).
- Seeds **adopter-owned (`copyIfMissing`)** files only if missing (`harness-config.yaml`, memories, architecture).
- Backs up any overwritten files into `.corezero-backup-<timestamp>`.
- Automatically executes `doctor` to confirm installation integrity.

### 2.2 Verify target repository

From the target repository root:

```bash
cd /path/to/your-repo
python3 corebase-specharness/scripts/core/cli.py doctor --json
```

Doctor must report `status: ok` and `failed: 0`.

The runtime discovers the repository root by walking upward until it finds both
`manifest.json` and `corebase-specharness/scripts/core/cli.py`. You can also pass `--root /path/to/your-repo`.

---

## 3. First-time setup (tailor once)

Perform this setup once per repository. Do not require `/starter-init` before every feature.

### 3.1 Invoke `/starter-init`

```bash
python3 corebase-specharness/scripts/core/cli.py init --json
python3 corebase-specharness/scripts/core/cli.py doctor --json
python3 corebase-specharness/scripts/core/cli.py memory-audit --json
```

`init` has two operational modes:
- `fresh-init`: Empty or uninitialized workspace. Scaffolds files, runs repository archaeology sweep, pre-fills memory, and sets up initial gate suggestions.
- `resync-drift`: `harness-config.yaml` already exists. Runs a read-only diff without overwriting existing adopter customizations.

### 3.2 Customize seeded adopter files

These files belong to the adopter and are never overwritten on kit upgrades:

```text
corebase-specharness/project/harness-config.yaml
corebase-specharness/project/architecture.md
corebase-specharness/project/tech-stack.md
corebase-specharness/project/product-sense.md
corebase-specharness/project/project-constraints.md
corebase-specharness/project/glossary.md
corebase-specharness/memories/repo/core-policies.md
corebase-specharness/memories/repo/project-knowledge-base.md
corebase-specharness/memories/repo/learned-heuristics.md
corebase-specharness/memories/repo/adr-log.md
```

Discover facts autonomously from repository code; ask product and policy questions in one frontier batch. Leave unknowns as `[UNKNOWN]`. Do not invent tech stack, gates, or policies.

### 3.3 Confirm verification gates

The default shipped `harness-config.yaml` has **no executable gates**:

```yaml
project_setup:
  status: deferred
verification:
  mode: advisory
gates: []
```

Add only commands you have actually confirmed locally, configured as argv lists:

```yaml
verification:
  mode: advisory

gates:
  - name: test
    command: ["python3", "-m", "pytest"]
    on_fail: block
    category: test
  - name: lint
    command: ["ruff", "check", "."]
    on_fail: block
    category: lint
```

Keep `mode: advisory` until gates are verified and stable. Advisory mode reports
gaps as warnings with `status: deferred` (exiting 0), but marks `details.verified: false`.
Once gates are trusted, switch to:

```yaml
verification:
  mode: blocking
```

Set `project_setup.status: ready` only after confirming real gates and reviewing context seeds.

### 3.4 Optional tool providers

Providers (such as Open Code Review, GitNexus, Codebase Memory MCP) are optional and never auto-enabled. New installs keep `active: none` and `mode: optional`. Configure them in:

```text
corebase-specharness/project/tool-providers.md
```

`open-code-review` is not required by default. `/harness-verify` still reviews
the diff on the standards and spec axes without `ocr`. After local setup, set
`providers.review.active: open-code-review`. Use `mode: required` only when
this project should fail `verify` if OCR is missing or fails.

Verify with:

```bash
python3 corebase-specharness/scripts/core/cli.py provider-check --json
```

---

## 4. The Canonical 6-Phase Lifecycle

CoreBase SpecHarness structures feature delivery around a disciplined 6-phase pipeline.
Every feature is a dedicated directory under `artifacts/features/<slug>/`.
The `<slug>` must be lowercase hyphenated alphanumeric (1–63 chars, matching `[a-z0-9][a-z0-9-]{0,62}`).

```text
[1. Discovery / Research]
   │  • /spec-research: Root-cause triage, brownfield mapping, ADI probes
   │  • writes analysis.md
   │  • Researching → ResearchComplete
   ▼
[2. Specification]
   │  • /spec-requirements: Problem statement, 3-wave grilling, AC-NNN contracts
   │  • writes spec.md (optional proposal.md, requirements-review.md)
   │  • Specifying → SpecApproved
   ▼
[3. Architecture & Planning]
   │  • /spec-plan: Deep module design, public seams, definition-of-ready
   │  • /spec-adr (optional): Lasting architectural decisions
   │  • writes plan.md
   │  • Planning → Planning
   ▼
[4. Work Breakdown]
   │  • /spec-tasks: Canonical tasks.md with T-NNN IDs & AC mapping
   │  • writes tasks.md (generates tasks.json sidecar)
   │  • TaskPlanning → PlanApproved
   ▼
[5. Execution & Verification]
   │  • /spec-implement: TDD loop, task-start / task-done with proof
   │  • /spec-testing-scenario (optional): Edge case & regression coverage
   │  • mutates project source and task evidence
   │  • Implementing → Implementing
   ▼
[6. Closeout & Memory Promotion]
   │  • /harness-verify: Strict/advisory gates, two-axis review.md
   │  • /context-memory: Post-ship sync & durable memory promotion
   │  • Verifying → Done only after verification-runs.json + Post-Ship Sync
```

### 4.1 Stage-by-stage contract

| Phase | Direct Skill | Input Artifacts | Output Artifacts | State Transition | Exit / Transition Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Discovery / Research** | `/spec-research` | User prompt / issue description | `analysis.md` | `Researching` $
ightarrow$ `ResearchComplete` | Root cause isolated or brownfield mapped; hypotheses tested with evidence. |
| **2. Specification** | `/spec-requirements` | `analysis.md` (if researched), `product-sense.md` | `spec.md`, optional `proposal.md` | `Specifying` $
ightarrow$ `SpecApproved` | Problem statement defined, 3-wave grilling complete, all acceptance criteria assigned `AC-*` IDs. |
| **3. Architecture & Planning** | `/spec-plan`, optional `/spec-adr` | `spec.md`, `architecture.md` | `plan.md`, optional `corebase-specharness/project/adr/` | `Planning` $
ightarrow$ `Planning` | Public seams and deep modules designed, definition-of-ready met, lasting decisions logged in ADR. |
| **4. Work Breakdown** | `/spec-tasks` | `spec.md`, `plan.md` | `tasks.md` (sidecar `tasks.json`) | `TaskPlanning` $
ightarrow$ `PlanApproved` | Granular `T-NNN` tasks sequenced, 100% of ACs covered by tasks, no cycles, first task unblocked. |
| **5. Execution** | `/spec-implement`, optional `/spec-testing-scenario` | `spec.md`, `plan.md`, `tasks.md` | Project source, `tasks.md`, `testing-scenarios.md` | `Implementing` $
ightarrow$ `Implementing` | Single-task execution loop: `task-start` $
ightarrow$ edit $
ightarrow$ run proof $
ightarrow$ `task-done --evidence`. |
| **6. Closeout & Memory** | `/harness-verify`, `/context-memory` | `spec.md`, `plan.md`, `tasks.md`, code | `review.md`, `session-extracts.md`, durable memories | `Verifying` $
ightarrow$ `Done` | All tasks Done with proof, two-axis review passed, confirmed gates pass, Post-Ship Sync recorded. |

### 4.2 Lifecycle guardrails

1. **Forward Progression Only**: Skills move state tokens forward. Setting `SpecApproved`, `PlanApproved`, or `Done` is the final step after internal verification checklists pass.
2. **Explicit Deviation & Re-Entry**: If planning reveals missing requirements or implementation reveals a design gap, re-enter the earlier skill explicitly (e.g., setting `status.md` to `Specifying` or `Replanning` with a documented reason). Silent phase-skipping is prohibited.
3. **Single Active Task Discipline**: During implementation, agents must work on exactly **one** `In Progress` task at a time (`task-start` $
ightarrow$ `task-done`).
4. **Mechanically Protected Closeout**: Only `/harness-verify` is authorized to transition a feature to `Done`. It requires a matching record in `corebase-specharness/generated/verification-runs.json` and a `## Post-Ship Sync` section in `session-extracts.md`.

### 4.3 Side skills

| Skill | Use when |
| --- | --- |
| `/spec-adr` | A lasting architectural decision with trade-offs must be recorded |
| `/spec-testing-scenario` | QA or human reviewers need a manual testing and regression script |
| `/harness-maintain` | Doctor, gates, or harness configuration are drifting |

Do not pass external skill names to `context-load` or `skill-enter`. External skills (such as UI/UX or design helpers) are auxiliary tools, not CoreBase SpecHarness lifecycle routes.

---

## 5. Operating loop for one skill

This is the standard execution loop for feature-bound delivery skills (`spec-research` through `harness-verify`):

```text
skill-enter → do the work in skills/<name>/SKILL.md
            → write the required artifacts
            → run applicable checks
            → skill-exit
```

### 5.1 Enter

```bash
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill spec-plan   --feature checkout-retry   --intent "design checkout retry architecture"   --json
```

`skill-enter` performs four operations:
1. Loads the route definition from `references/context-routes.yaml`.
2. Ensures `status.md` exists (defaulting delivery profile to `Moderate`) and writes the enter state.
3. Opens or resumes `.corezero/sessions/<slug>/session.md`.
4. Compiles and loads the bounded context pack for that skill.

Do not hand-edit `- Phase:` in `status.md`.

### 5.2 Inspect and adjust context

```bash
# Explain what was included and omitted from the context pack
python3 corebase-specharness/scripts/core/cli.py context-explain   --skill spec-plan   --feature checkout-retry   --intent "design checkout retry architecture"   --json

# Add a specific repo file if omitted by standard routing
python3 corebase-specharness/scripts/core/cli.py context-load   --skill spec-plan   --feature checkout-retry   --add-source path/to/file.py   --json
```

Context commands require `--skill`. They do not accept `--phase`. Use `--task <T-NNN>` for task-scoped context slimming during implementation.

Task-scoped implement loop (do not re-run `skill-enter` between tasks):

```text
task-check
  → task-start --task T-NNN
  → context-load --skill spec-implement --task T-NNN   # omit --full
  → edit + prove
  → task-done --evidence "..."
  → next T-NNN or skill-exit
```

`--task` replaces full `tasks.md` with the active task plus direct
dependencies. Session auto-delta then keeps unchanged files out of later
loads unless `--full` is passed.

Memory lifecycle after a passing `/harness-verify`:

```text
[CANDIDATE] in session-extracts.md
  → ## Post-Ship Sync (required for Done)
  → /context-memory triage (promote / merge / defer / discard)
  → memory-audit; compact if warn or hard-cap
```

### 5.3 Session checkpoint

```bash
python3 corebase-specharness/scripts/core/cli.py session-checkpoint   --feature checkout-retry   --progress "completed module seam specification"   --next-action "run artifact-check and handoff to spec-tasks"   --json
```

### 5.4 Readiness checks

Prefer `--skill`. `--phase` remains a compatibility path on `phase-check`, `artifact-check`, and `verify`. Do not pass both.

```bash
python3 corebase-specharness/scripts/core/cli.py phase-check   --feature checkout-retry --skill spec-plan --json

python3 corebase-specharness/scripts/core/cli.py artifact-check   --feature checkout-retry --skill spec-plan --trace --json
```

### 5.5 Exit

```bash
python3 corebase-specharness/scripts/core/cli.py skill-exit   --skill spec-plan   --feature checkout-retry   --handoff spec-tasks   --json
```

`skill-exit` fails if:
- Required output artifacts are missing (`plan.md` for `spec-plan`, `spec.md` for `spec-requirements`, `review.md` for `harness-verify`).
- Readiness checks fail.
- `--handoff` names a skill not declared in the route.
- The lifecycle state transition is illegal.

Use `status-set` only for exception states: `Blocked`, `Replanning`, `NeedsClarification`.

---

## 6. What each delivery skill must produce

All feature artifacts reside in `artifacts/features/<slug>/`.

| Skill | Required Write | Enter $
ightarrow$ Exit State | Typical Next Skill |
| --- | --- | --- | --- |
| `spec-research` | `analysis.md` | `Researching` $
ightarrow$ `ResearchComplete` | `spec-requirements` |
| `spec-requirements` | `spec.md` | `Specifying` $
ightarrow$ `SpecApproved` | `spec-plan` |
| `spec-plan` | `plan.md` | `Planning` $
ightarrow$ `Planning` | `spec-tasks` |
| `spec-tasks` | `tasks.md` | `TaskPlanning` $
ightarrow$ `PlanApproved` | `spec-implement` |
| `spec-implement` | code + task evidence | `Implementing` $
ightarrow$ `Implementing` | `harness-verify` |
| `harness-verify` | `review.md` | `Verifying` $
ightarrow$ `Done` | `context-memory` |

These five skills have **no enter/exit tokens**:
- `starter-init`
- `context-memory`
- `harness-maintain`
- `spec-adr`
- `spec-testing-scenario`

### Skill details

- **`/spec-research`**: Modes: `bug-diagnosis`, `brownfield-map`, `ambiguity-resolution`. Output: `analysis.md`. If evidence is inconclusive, write `[:HALT INCONCLUSIVE]` and do not exit as complete.
- **`/spec-requirements`**: Modes: `full-intake`, `clarify-reentry`. Output: `spec.md` with `REQ-*` and `AC-*` identifiers. Runtime requires headings: `## Metadata`, `## Problem Statement`, `## Acceptance Criteria`.
- **`/spec-plan`**: Designs module boundaries, public seams, and DoR. Applies Clean Architecture and DDD principles from `corebase-specharness/rules/code-design.md`. Output: `plan.md`. Runtime requires headings: `## Metadata`, `## Approach`.
- **`/spec-tasks`**: Strategies: `mvp-first`, `incremental`, `parallel-team`. Output: `tasks.md` with `T-NNN` identifiers and `Covers: AC-*`. Runtime requires headings: `## Metadata`, `## Tasks`.
- **`/spec-implement`**: Single active task loop. After `task-start`, reloads `context-load --task T-NNN` so coding turns omit full `tasks.md`. Mutates code, records proof, and updates task evidence via CLI.
- **`/harness-verify`**: Executes readiness checks, artifact traceability, confirmed gates, and code review. Writes `review.md` (requires `# ` and `## Decision`). Authorizes closeout to `Done`.

---

## 7. Feature artifacts and task loop

### 7.1 Feature directory structure

```text
artifacts/features/checkout-retry/
├── status.md                durable feature state & profile
├── analysis.md              optional, from research
├── spec.md                  REQ-*, AC-* requirements
├── plan.md                  technical architecture & approach
├── tasks.md                 canonical T-NNN task graph
├── tasks.json               generated machine sidecar
├── review.md                verify verdict & two-axis review
├── session-extracts.md      candidates & Post-Ship Sync
└── testing-scenarios.md     optional QA/regression guide
```

### 7.2 Core coherence rules enforced by runtime

1. `spec.md` must define `AC-*` identifiers.
2. `tasks.md` must define `T-NNN` identifiers with `Covers: AC-*`.
3. 100% of `AC-*` items in `spec.md` must be covered in `tasks.md`.
4. Completing a task requires explicit validation evidence (`--evidence`).
5. `Done` requires `review.md` and a `## Post-Ship Sync` heading in `session-extracts.md`.

### 7.3 Canonical task format in `tasks.md`

```markdown
- [ ] T-001 Add retry budget calculation
  - Status: Not Started
  - Depends on:
  - Covers: AC-01
  - Validation evidence:
```

### 7.4 Task execution CLI commands

Never edit task checkboxes or `tasks.json` by hand. The coding turn loop:

```bash
# 1. Check next ready / unblocked tasks
python3 corebase-specharness/scripts/core/cli.py task-check --feature checkout-retry

# 2. Lock one task to In Progress
python3 corebase-specharness/scripts/core/cli.py task-start   --feature checkout-retry --task T-001

# 3. Reload task-scoped context (omits full tasks.md; keeps only active task + deps)
python3 corebase-specharness/scripts/core/cli.py context-load   --skill spec-implement --feature checkout-retry --task T-001 --intent "retry budget"

# 4. Edit code, run test proof, then mark complete with evidence
python3 corebase-specharness/scripts/core/cli.py task-done   --feature checkout-retry --task T-001   --evidence "pytest tests/test_retry.py passed with 100% coverage"

# (If blocked):
python3 corebase-specharness/scripts/core/cli.py task-block   --feature checkout-retry --task T-001   --note "Upstream API schema is missing retry-after header"
```

Allowed task state transitions:
- `Not Started` $
ightarrow$ `In Progress`, `Blocked`, `Deferred`
- `In Progress` $
ightarrow$ `Done`, `Blocked`, `Not Started`, `Deferred`
- `Blocked` $
ightarrow$ `In Progress`, `Not Started`, `Deferred`
- `Done` $
ightarrow$ `In Progress` (reopen)
- `Deferred` $
ightarrow$ `Not Started`, `In Progress`

`[:HALT reason]` placed in `spec.md`, `plan.md`, or `tasks.md` blocks all task mutations until resolved.

---

## 8. Close a feature and promote memory

```bash
# 1. Enter harness-verify
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill harness-verify --feature checkout-retry

# 2. Run phase check, verification gates, and artifact traceability
python3 corebase-specharness/scripts/core/cli.py phase-check   --feature checkout-retry --skill harness-verify

python3 corebase-specharness/scripts/core/cli.py verify   --feature checkout-retry --skill harness-verify

python3 corebase-specharness/scripts/core/cli.py artifact-check   --feature checkout-retry --skill harness-verify --trace

# 3. Write review.md
# 4. If all pass, ensure session-extracts.md has "## Post-Ship Sync"
python3 corebase-specharness/scripts/core/cli.py skill-exit   --skill harness-verify --feature checkout-retry   --handoff context-memory
```

If verification fails:

```bash
python3 corebase-specharness/scripts/core/cli.py skill-exit   --skill harness-verify --feature checkout-retry   --phase ChangesRequested   --handoff spec-implement
```

Read `details.verified`. Advisory mode can exit 0 while `verified` is still `false`. That is not a passing closeout.

After `Done`, invoke `/context-memory` to triage `[CANDIDATE]` lessons from `session-extracts.md` into durable repository memory.

---

## 9. Lifecycle state transitions

`corebase-specharness/project/state-machine.yaml` is the kit-owned lifecycle authority.

### Happy path

```text
Researching → ResearchComplete → Specifying → SpecApproved
  → Planning → TaskPlanning → PlanApproved
  → Implementing → Verifying → Done
```

### Exception and recovery transitions

```text
Specifying ↔ NeedsClarification
Implementing → Planning | Specifying | Replanning
Verifying → ChangesRequested | Planning | Implementing
ChangesRequested → Replanning | Implementing | Planning
Replanning → Planning | TaskPlanning
{Researching, ResearchComplete, Specifying, SpecApproved, Planning,
 TaskPlanning, PlanApproved, Replanning, Implementing, Verifying} → Blocked
Blocked → Specifying | Planning | Implementing | Verifying | Abandoned
{Researching, ResearchComplete, Specifying, NeedsClarification,
 SpecApproved, Planning, TaskPlanning, PlanApproved, Replanning,
 Implementing, Verifying, ChangesRequested, Blocked} → Abandoned
```

---

## 10. Command quick reference

Run all commands from the adopter repository root. Prefix each with `python3 corebase-specharness/scripts/core/cli.py`.

### Diagnostic & health

```bash
python3 corebase-specharness/scripts/core/cli.py doctor --json
python3 corebase-specharness/scripts/core/cli.py status
python3 corebase-specharness/scripts/core/cli.py status --feature <slug>
python3 corebase-specharness/scripts/core/cli.py memory-audit --json
python3 corebase-specharness/scripts/core/cli.py memory-gate --json
python3 corebase-specharness/scripts/core/cli.py gate-list --json
python3 corebase-specharness/scripts/core/cli.py gate-check --json
python3 corebase-specharness/scripts/core/cli.py provider-check --json
python3 corebase-specharness/scripts/core/cli.py adr-generate --title "<title>" --json
```

### Envelope & session

```bash
python3 corebase-specharness/scripts/core/cli.py skill-enter --skill <name> --feature <slug> --intent "..." --json
python3 corebase-specharness/scripts/core/cli.py skill-exit --skill <name> --feature <slug> --handoff <next> --json
python3 corebase-specharness/scripts/core/cli.py status-set --feature <slug> --phase Blocked --next-step "..." --json
python3 corebase-specharness/scripts/core/cli.py session-checkpoint --feature <slug> --progress "..." --next-action "..." --json
python3 corebase-specharness/scripts/core/cli.py session-end --feature <slug> --next-action "..." --json
```

### Context compiler

```bash
python3 corebase-specharness/scripts/core/cli.py context-pack --skill <name> --feature <slug> --intent "..." --json
python3 corebase-specharness/scripts/core/cli.py context-load --skill <name> --feature <slug> --task <T-NNN> --intent "..." --json
python3 corebase-specharness/scripts/core/cli.py context-explain --skill <name> --feature <slug> --intent "..." --json
```

### Verification & artifacts

```bash
python3 corebase-specharness/scripts/core/cli.py phase-check --feature <slug> --skill <name> --json
python3 corebase-specharness/scripts/core/cli.py artifact-check --feature <slug> --skill <name> --trace --json
python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill <name> --json
```

### Task graph

```bash
python3 corebase-specharness/scripts/core/cli.py task-check --feature <slug> --json
python3 corebase-specharness/scripts/core/cli.py task-start --feature <slug> --task T-NNN --json
python3 corebase-specharness/scripts/core/cli.py task-done --feature <slug> --task T-NNN --evidence "..." --json
python3 corebase-specharness/scripts/core/cli.py task-block --feature <slug> --task T-NNN --note "..." --json
```

---

## 11. Ownership and upgrade contracts

### Kit-owned (`overwrite`)
Replaced on upgrade after backup. Do not customize in place:
```text
corebase-specharness/scripts/core/**
skills/**
references/context-routes.yaml
corebase-specharness/project/state-machine.yaml
corebase-specharness/rules/**
AGENTS.md
```

### Adopter-owned (`copyIfMissing`)
Preserved on upgrade. Customize freely:
```text
corebase-specharness/project/harness-config.yaml
corebase-specharness/project/architecture.md
corebase-specharness/project/*.md
corebase-specharness/memories/**
artifacts/features/**
.corezero/sessions/**
```

---

## 12. Rules that make the kit fail if ignored

1. **Do not start coding before `spec.md`, `plan.md`, and `tasks.md` exist.**
2. **Do not complete a task without fresh validation evidence (`--evidence`).**
3. **Do not set `Done` without `review.md` and `## Post-Ship Sync` in `session-extracts.md`.**
4. **Do not treat advisory `verify` exit 0 as verified if `details.verified` is false.**
5. **Do not pass `--skill` and `--phase` together.**
6. **Do not hand-edit `- Phase:` in `status.md` or task checkboxes in `tasks.md`.**
7. **Do not invent missing repository facts during `/starter-init`.**
8. **Do not configure verification gates you have not actually executed and tested.**

---

## 13. Complete Step-by-Step Feature Walkthrough (End-to-End Concrete Example)

Here is a full real-world walkthrough for delivering a feature (e.g. `checkout-retry-queue`) from inception to closeout.

### 13.1 Step 1: Investigation & Root Cause (`/spec-research`)

```bash
# 1. Enter research
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill spec-research   --feature checkout-retry-queue   --intent "investigate why payment gateway timeout drops orders instead of queuing for retry"   --json
```

- **Execute**: Run a reproducer test showing the dropped order bug. Isolate the failure seam.
- **Write**: `artifacts/features/checkout-retry-queue/analysis.md` with `## Findings`, `## High Risk Paths`, `## Kaizen Countermeasures`.
- **Exit**:
  ```bash
  python3 corebase-specharness/scripts/core/cli.py skill-exit     --skill spec-research     --feature checkout-retry-queue     --handoff spec-requirements     --json
  ```

---

### 13.2 Step 2: Requirements Specification (`/spec-requirements`)

```bash
# 1. Enter specification
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill spec-requirements   --feature checkout-retry-queue   --intent "define requirements for persistent checkout retry queue"   --json
```

- **Execute**: Review `analysis.md` and `product-sense.md`. Conduct frontier grilling wave to resolve ambiguity (retry count, backoff multiplier, idempotency window).
- **Write**: `artifacts/features/checkout-retry-queue/spec.md` with `REQ-01`, `REQ-02`, and verifiable `AC-01`, `AC-02`.
- **Check & Exit**:
  ```bash
  python3 corebase-specharness/scripts/core/cli.py phase-check --feature checkout-retry-queue --skill spec-requirements --json
  python3 corebase-specharness/scripts/core/cli.py skill-exit     --skill spec-requirements     --feature checkout-retry-queue     --handoff spec-plan     --json
  ```

---

### 13.3 Step 3: Technical Design & Deep Modules (`/spec-plan` + `/spec-adr`)

```bash
# 1. Enter planning
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill spec-plan   --feature checkout-retry-queue   --intent "design background retry worker and idempotency store"   --json
```

- **Execute**: Apply `code-design.md` (Clean Architecture & Deep Modules). Design public seam `PaymentRetryService.enqueue(order_id, payload)`.
- **Optional ADR**:
  ```bash
  python3 corebase-specharness/scripts/core/cli.py adr-generate     --feature checkout-retry-queue     --title "Use PostgreSQL SKIP LOCKED for Durable Retry Queue"     --reversibility Moderate     --json
  ```
- **Write**: `artifacts/features/checkout-retry-queue/plan.md` with DoR checklist.
- **Exit**:
  ```bash
  python3 corebase-specharness/scripts/core/cli.py skill-exit     --skill spec-plan     --feature checkout-retry-queue     --handoff spec-tasks     --json
  ```

---

### 13.4 Step 4: Work Breakdown & AC Mapping (`/spec-tasks`)

```bash
# 1. Enter task planning
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill spec-tasks   --feature checkout-retry-queue   --json
```

- **Write**: `artifacts/features/checkout-retry-queue/tasks.md`:
  ```markdown
  # Tasks: Checkout Retry Queue

  ## Metadata
  - Feature: checkout-retry-queue
  - Total Tasks: 2

  ## Tasks

  - [ ] T-001 Create retry_queue table and enqueue handler
    - Status: Not Started
    - Depends on: None
    - Covers: AC-01
    - Validation evidence: pytest tests/test_retry_queue_db.py

  - [ ] T-002 Implement background retry worker with exponential backoff
    - Status: Not Started
    - Depends on: T-001
    - Covers: AC-02
    - Validation evidence: pytest tests/test_retry_worker.py
  ```
- **Validate & Exit**:
  ```bash
  python3 corebase-specharness/scripts/core/cli.py task-check --feature checkout-retry-queue --json
  python3 corebase-specharness/scripts/core/cli.py skill-exit     --skill spec-tasks     --feature checkout-retry-queue     --handoff spec-implement     --json
  ```

---

### 13.5 Step 5: TDD Implementation Loop (`/spec-implement`)

```bash
# 1. Enter implementation
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill spec-implement   --feature checkout-retry-queue   --json

# 2. Iterate Task T-001
python3 corebase-specharness/scripts/core/cli.py task-start --feature checkout-retry-queue --task T-001 --json
python3 corebase-specharness/scripts/core/cli.py context-load --skill spec-implement --feature checkout-retry-queue --task T-001 --json
# ... write test -> implement code -> run pytest tests/test_retry_queue_db.py ...
python3 corebase-specharness/scripts/core/cli.py task-done --feature checkout-retry-queue --task T-001 --evidence "pytest tests/test_retry_queue_db.py passed (8/8)" --json

# 3. Iterate Task T-002
python3 corebase-specharness/scripts/core/cli.py task-start --feature checkout-retry-queue --task T-002 --json
python3 corebase-specharness/scripts/core/cli.py context-load --skill spec-implement --feature checkout-retry-queue --task T-002 --json
# ... write test -> implement worker -> run pytest tests/test_retry_worker.py ...
python3 corebase-specharness/scripts/core/cli.py task-done --feature checkout-retry-queue --task T-002 --evidence "pytest tests/test_retry_worker.py passed (12/12)" --json

# 4. Exit to verification
python3 corebase-specharness/scripts/core/cli.py skill-exit   --skill spec-implement   --feature checkout-retry-queue   --handoff harness-verify   --json
```

---

### 13.6 Step 6: Two-Axis Verification & Closeout (`/harness-verify`)

```bash
# 1. Enter verification
python3 corebase-specharness/scripts/core/cli.py skill-enter   --skill harness-verify   --feature checkout-retry-queue   --json

# 2. Run mechanical gates and traceability
python3 corebase-specharness/scripts/core/cli.py verify --feature checkout-retry-queue --skill harness-verify --json
python3 corebase-specharness/scripts/core/cli.py artifact-check --feature checkout-retry-queue --skill harness-verify --trace --json

# 3. Author review.md with Pass verdict
# 4. Ensure session-extracts.md has "## Post-Ship Sync" section

# 5. Exit to Done
python3 corebase-specharness/scripts/core/cli.py skill-exit   --skill harness-verify   --feature checkout-retry-queue   --handoff context-memory   --json
```

---

### 13.7 Step 7: Memory Promotion & Session Handoff (`/context-memory`)

```bash
# 1. Triage candidate observations from session-extracts.md
#    - Promote proven operational lessons into corebase-specharness/memories/repo/learned-heuristics.md (LH-NNN)
#    - Update corebase-specharness/memories/repo/project-knowledge-base.md with durable architecture facts

# 2. Check memory size
python3 corebase-specharness/scripts/core/cli.py memory-audit --json

# 3. End session
python3 corebase-specharness/scripts/core/cli.py session-end \
  --feature checkout-retry-queue \
  --next-action "/context-memory" \
  --json
```

---

## 14. Context Engineering, Slicing & FinOps Optimization Rules

CoreBase SpecHarness cuts token consumption by up to 50% compared to traditional codebase-dumping approaches:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        HOW CONTEXT IS OPTIMIZED                        │
├─────────────────────────┬──────────────────────────────────────────────┤
│ 1. Mandatory Bootstrap  │ Sliced to ~410 tokens (caveman + policies)   │
│ 2. Task-Scoped Slicing  │ context-load --task T-NNN (drops tasks.md)   │
│ 3. Session Auto-Delta   │ Drops unchanged files via SHA-256 fingerprint│
│ 4. Bounded Retrieval    │ Capped at 6 files, 600 tokens, redacts secret│
└─────────────────────────┴──────────────────────────────────────────────┘
```

1. **Mandatory Bootstrap Slicing**: Universal bootstrap (`caveman.md` + `core-policies.md` [Purpose, Normative Rules]) consumes only **~410 tokens**. Security policies are injected only on implement, verify, and ADR skills.
2. **Task-Scoped Implementation (`--task T-NNN`)**: Context compilation loads only the active task and direct dependencies, omitting massive whole-feature `tasks.md` graphs.
3. **Session Auto-Delta Caching**: The engine calculates a SHA-256 fingerprint of compiled payloads. Subsequent `context-load` calls within the same session omit unchanged files automatically unless `--full` is explicitly passed.
4. **Bounded Retrieval & Secret Redaction**: Keyword-triggered local code searches and domain packs are capped at `max_retrieval_files: 6` and `max_source_excerpt_tokens: 600`. All excerpts pass through automatic regex secret redaction.

---

## 15. Troubleshooting, Diagnosing & Resolving Common Halts

When an agent encounters an unresolvable blocker or ambiguity, it writes a standard `[:HALT ...]` tag:

| Halt Marker | Trigger Condition | How to Resolve |
|---|---|---|
| `[:HALT INCONCLUSIVE]` | Research could not establish a deterministic failing reproduction command. | Provide missing credentials, test environments, or logs, then re-enter `/spec-research`. |
| `[:HALT NEEDS CLARIFICATION]` | Missing external decision or information. | Answer the frontier grilling questions and re-enter `/spec-requirements`. |
| `[:HALT UNRESOLVED]` | Multiple failed attempts to resolve ambiguity. | Escalate to the user; do not invent the missing decision. |
| `[:HALT ADR CONFLICT: ADR-NNN]` | Proposed specification or plan contradicts a locked Architecture Decision Record. | Revoke the proposal or use `/spec-adr` to formally supersede the old ADR. |
| `[:HALT STALE — spec amended <date>]` | Specification was modified after plan or tasks were approved. | Re-enter `/spec-plan` to adjust architecture and regenerate tasks. |
| `[:HALT SECURITY: <desc>]` | Security-sensitive path without evidence. | Add proof and re-enter `/harness-verify`. |
| `[:HALT SYNC REQUIRED]` | `## Post-Ship Sync` heading is missing from `session-extracts.md`. | Add the heading, then invoke `/context-memory`. |

### Diagnosing Quality Degradation with `/harness-maintain`

If agents produce repetitive bugs, shallow wrappers, or declare completion prematurely, run `/harness-maintain`:
```bash
python3 corebase-specharness/scripts/core/cli.py doctor --json
python3 corebase-specharness/scripts/core/cli.py gate-check --json
```
Consult `skills/harness-maintain/references/diagnosis-map.md` to map failure symptoms to root-cause fixes:
- **Shallow wrappers** $
ightarrow$ Enforce Deletion Test & Deep Modules in `code-design.md`.
- **Repeated regressions** $
ightarrow$ Add an automated test gate in `harness-config.yaml`.
- **Premature done** $
ightarrow$ Enforce public-seam proof requirement in `task-done --evidence`.

---

## Related documents

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Skill catalog: [SKILLS.md](SKILLS.md)
- Token cost breakdown: [TOKEN-COST.md](TOKEN-COST.md)
- Design thesis: [DESIGN.md](DESIGN.md)
- As-built requirements: [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md)
- Memory & context budgets: [MEMORY.md](MEMORY.md)
- Harness & verification: [HARNESS.md](HARNESS.md)
- CLI & artifact reference: [REFERENCE.md](REFERENCE.md)
- Install & upgrade: [INSTALL.md](INSTALL.md)
- Release process: [RELEASING.md](RELEASING.md)
- Source authority index: [../INDEX.md](../INDEX.md)
