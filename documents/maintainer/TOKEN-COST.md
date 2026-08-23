
Structure the answer into two comprehensive parts:
1. **Part 1: What We Send to the Agent for Each Skill** (the exact files, section slices, and instruction payloads).
2. **Part 2: Token Cost Breakdown for Each Skill and Each Step** (Input tokens, Step procedure, Templates, and Output tokens).

Here is the exact breakdown of **what we send to the agent** for each of the 11 CoreBase SpecHarness skills and the **token cost for every step of each skill**, measured with the `cl100k_base` BPE tokenizer against the kit seed on 2026-08-23.

**How this is used**

The user does not run Python. They invoke skills: `/spec-research`,
`/spec-requirements`, `/spec-plan`, `/spec-tasks`, `/spec-implement`,
`/harness-verify`. The agent runs `skill-enter` for that skill. `--full` is
an agent-only flag, not a user command.

- **Scenario A — isolated first load**: the first skill on a feature, or a
  new feature slug. The pack is complete.
- **Scenario B — sequential auto-delta (default)**: the user keeps calling
  skills for the **same feature in the same uncompacted chat**. The agent
  omits `--full`. Later skills inject only new or changed files and H2
  sections.
- **Scenario C — compact or new chat, same feature**: hashes in `session.md`
  survive. The live window does not. The user types the skill and says
  reload everything. The agent passes `--full` on that enter, then omits
  it again for later skills in that chat. Full explanation:
  [MEMORY.md — Conversation vs feature session](MEMORY.md#conversation-vs-feature-session-compact-and-new-chat).

**How to read the pack numbers**

- **Isolated / `--full`**: first skill in a session, a new feature slug, the agent passed `--full` (compact, new chat, user reload, or stale pack). Every route source is a candidate; bootstrap files are injected again.
- **Session auto-delta**: later skill on the **same feature in the same uncompacted chat**. The compiler unions SHA-256 fingerprints in `session.md` (`last_context_fingerprint`, `last_context_slices`) and injects only new or changed files, and only new or changed H2 sections. Skipped sources do not consume payload or channel budgets.
- Feature artifact tokens below used tiny probe stubs (`status.md` 9, `analysis.md` 10, `spec.md` 14, `plan.md` 6, checkbox `tasks.md` excerpt 45–78). Real features scale those rows; bootstrap and route-rule tokens are kit-stable.
- `SKILL.md` procedure tokens are the current files under `kit/skills/<name>/SKILL.md`.

---

# Part 1: What We Send to the Agent for Each Skill

When a skill is invoked, CoreBase SpecHarness compiles a bounded context pack (`context-load` / `skill-enter`) containing:
1. **Mandatory Bootstrap Rules**: Core communication & normative repository rules.
2. **Route-Declared Sources**: Repository architecture, constraints, or coding standards (sliced to specific H2 sections).
3. **Active Feature Artifacts**: The relevant slice of upstream deliverables (`status.md`, `spec.md`, `plan.md`, `tasks.md`).
4. **Skill Procedure (`SKILL.md`)**: The step-by-step workflow the agent follows.

Session auto-delta does not change the *route*. It changes whether an already-loaded file or H2 section is **re-injected**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WHAT IS SENT TO THE AGENT                       │
├────────────────────────────────┬───────────────────────────────────────┤
│ 1. Mandatory Bootstrap         │ caveman.md (156) + core-policies.md   │
│ 2. Route Sources (Sliced)      │ architecture.md, constraints, etc.    │
│ 3. Feature Artifacts           │ spec.md, plan.md, tasks.md, status.md │
│ 4. Domain & Local Retrieval    │ glossary.md triggers + code excerpts  │
│ 5. Skill Procedure             │ skills/<name>/SKILL.md                │
│ 6. Session auto-delta          │ skip unchanged files/H2s after skill 1│
└────────────────────────────────┴───────────────────────────────────────┘
```

### Exact files & slices — isolated first load (`--full` or no session baseline)

| Skill | Injected Context Files & Sliced Sections | Isolated Pack | `SKILL.md` |
| :--- | :--- | :---: | :---: |
| **`/starter-init`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `harness-config.yaml` (485)<br>• `tech-stack.md` [Languages & Runtimes, Frameworks, Dev Tools] (97)<br>• `project-constraints.md` [Performance, Tech, Operational] (182) | **1,333** | **1,777** |
| **`/spec-research`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `architecture.md` [System Snapshot, Top-Level Components, Runtime Boundaries] (75) | **653** | **1,545** |
| **`/spec-requirements`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `analysis.md` (10)<br>• `product-sense.md` [Vision, Problem Statement, Domain Rules, Metrics] (107)<br>• `project-constraints.md` [Performance, Compliance, Security, Operational] (193) | **888** | **1,754** |
| **`/spec-plan`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `spec.md` (14)<br>• `architecture.md` [Snapshot, Components, Boundaries, Safe Change] (89)<br>• `ponytail.md` [Decision Matrix: Abstractions] (219)<br>• `code-design.md` **omitted** (`channel budget exceeded: bootstrap`) | **900** | **1,320** |
| **`/spec-tasks`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `spec.md` (14)<br>• `plan.md` (6)<br>• `code-design.md` [Read before you write] (102)<br>• `architecture.md` [Snapshot, Components] (59) | **759** | **1,577** |
| **`/spec-implement`**<br>*(`--task T-001`)* | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative, Security Policy] (608)<br>• `status.md` (9)<br>• `spec.md` (14)<br>• `plan.md` (6)<br>• `session.md` summary (22)<br>• `tasks.md` active-task excerpt (45)<br>• `security.md` [Core Rules, Shell Safety, Artifact Boundaries, Verification] (319)<br>• `code-design.md` [Read before you write, Abstraction Check, Layering, Failures, Verify the path] (567) | **1,746** | **1,845** |
| **`/harness-verify`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative, Security Policy] (608)<br>• `status.md` (9)<br>• `spec.md` (14)<br>• `plan.md` (6)<br>• `tasks.md` (57)<br>• `harness-config.yaml` (485)<br>• `security.md` [Verification] (109) | **1,444** | **1,824** |
| **`/context-memory`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative, Promotion Thresholds, Security] (689)<br>• `status.md` (9)<br>• `session-extracts.md` (12)<br>• `learned-heuristics.md` [Heuristics] (227) | **1,093** | **1,610** |
| **`/harness-maintain`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `harness-config.yaml` (485) | **1,063** | **1,355** |
| **`/spec-adr`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `spec.md` (14)<br>• `plan.md` (6)<br>• `architecture.md` [Snapshot, Boundaries, Safe Change] (59)<br>• `code-design.md` **omitted** (`channel budget exceeded: bootstrap`) | **657** | **1,235** |
| **`/spec-testing-scenario`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (9)<br>• `spec.md` (14)<br>• `plan.md` (6)<br>• `tasks.md` (57)<br>• `project-constraints.md` [Performance, Compliance, Security, Operational] (193) | **848** | **1,047** |

Isolated `/spec-plan` and `/spec-adr` drop `code-design.md` because bootstrap (`caveman.md` + `core-policies.md`) already fills `max_bootstrap_tokens` (1200). Session auto-delta skips those unchanged bootstrap files **before** budget, so the same `Should` source can be selected.

### Sequential session auto-delta (same feature, same uncompacted chat, omit `--full`)

Canonical order measured: `/spec-research` → `/spec-requirements` → `/spec-plan` → `/spec-adr` → `/spec-tasks` → `/spec-implement` (`T-001` then `T-002`) → `/harness-verify` → `/spec-testing-scenario` → `/context-memory` → `/harness-maintain`.

| Skill (after prior in session) | What is actually injected | Skipped as unchanged | Sequential pack |
| :--- | :--- | :--- | :---: |
| **`/spec-research`** (first) | Full isolated research pack | — | **653** |
| **`/spec-requirements`** | `analysis.md` (10), `product-sense.md` (107), `project-constraints.md` (193) | `caveman.md`, `core-policies.md`, `status.md` | **310** |
| **`/spec-plan`** | `spec.md` (14), `session.md` (22), `architecture.md` **[Safe Change Guidance] only** (14), `ponytail.md` (219), `code-design.md` [Abstraction, Layering, DDD] (500) | `caveman.md`, `core-policies.md`, `status.md`; architecture H2s already loaded by research | **769** |
| **`/spec-adr`** | `plan.md` (6) | bootstrap, status, spec, architecture, overlapping `code-design.md` H2s | **6** |
| **`/spec-tasks`** | `plan.md` (6) if not already loaded; `code-design.md` **[Read before you write] only** (102) | bootstrap, status, spec, session, architecture | **108** |
| **`/spec-implement`** (`T-001`) | `core-policies.md` **[Security Policy] only** (195), task excerpt (45), `security.md` (319), `code-design.md` [Failures, Verify the path] (137) | `caveman.md`, plan, status, spec, session | **696** |
| **`/spec-implement`** (`T-002`) | changed task excerpt only (78) | all other implement sources | **78** |
| **`/harness-verify`** | `tasks.md` (57), `harness-config.yaml` (485) | bootstrap, status, spec, plan, session, `security.md` [Verification] | **542** |
| **`/spec-testing-scenario`** | nothing new on this probe (constraints already loaded by requirements) | entire isolated pack | **0** |
| **`/context-memory`** | `core-policies.md` **[Memory Promotion Thresholds] only** (80), `session-extracts.md` (12), `learned-heuristics.md` (227) | `caveman.md`, status, session | **319** |
| **`/harness-maintain`** | nothing new (`harness-config.yaml` already loaded by verify) | entire isolated pack | **0** |

Delivery-path pack total (`research` → `requirements` → `plan` → `tasks` → `implement T-001`):

| Mode | Pack tokens |
| :--- | ---: |
| Isolated (each skill `--full`) | **4,946** |
| Sequential session auto-delta | **2,536** |
| Second implement turn (`T-002`) | **78** vs isolated **1,746** |

Pass `--full` when the session cache is stale (files edited on disk after they were loaded), after a conversation compact, on the first skill of a new chat for the same feature, when the user asks to reload everything, or when you need the complete pack for inspection. `session-end` does not clear fingerprints. Inspect skips with `context-explain --json` (`delta`, `delta_omitted`, `unchanged_selected`). Skips are not warnings.

---

# Part 2: Token Cost Breakdown for Each Step of Each Skill

Context-base figures below show **isolated pack + `SKILL.md`**. When the skill runs later in the same session, replace the isolated pack with the sequential pack from Part 1.

### 1. `/starter-init` (Bootstrap Repository)
*Context Base: ~1,333 tokens isolated | SKILL.md: 1,777 tokens. Not part of a feature session, so auto-delta does not apply.*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight & Scaffold Init** | Run `cli.py init --json`, inspect `onboarding_readiness` | None | ~1,650 | ~250 |
| **Step 2: Archaeology Sweep (Phase A)** | Detect stack markers, run brownfield sweep | `references/brownfield-mode.md` (945) | ~2,500 | ~1,200 |
| **Step 3: Memory & Gate Setup (Phase B)** | Pre-fill memory seeds, ask frontier questions, confirm gates | `references/template-prefill.md` (617) | ~2,250 | ~2,500 |
| **Step 4: Mechanical Verify & Handoff** | Run `doctor` and `memory-audit`, report readiness | None | ~1,800 | ~400 |
| **Total Skill Run** | | | **~8,000** | **~4,350** |

---

### 2. `/spec-research` (Investigation & Brownfield Mapping)
*Context Base: ~653 tokens isolated (first session load) | SKILL.md: 1,545 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Researching` | None | ~1,000 | ~150 |
| **Step 2: Context & Domain Alignment** | Match intent keywords to domain `triggers` | `domain/<name>/glossary.md` (~150) | ~1,150 | ~100 |
| **Step 3: Mode Execution** | Bug diagnosis / ADI reasoning / code exploration | `debugging-checklist.md` (688), `analysis-template.md` (533) | ~1,600 – 2,500 | ~1,500 – 3,000 |
| **Step 4: Artifact Authoring** | Author `artifacts/features/<slug>/analysis.md` | `references/analysis-template.md` (533) | ~1,450 | ~1,200 |
| **Step 5: Handoff** | Run `skill-exit --handoff spec-requirements` | None | ~1,000 | ~200 |
| **Total Skill Run** | | | **~6,000** | **~3,500** |

---

### 3. `/spec-requirements` (What & Why Specification)
*Context Base: ~888 isolated / **~310 after `/spec-research`** | SKILL.md: 1,754 tokens*

Bootstrap (`caveman.md`, `core-policies.md`) and `status.md` are not re-injected after research.

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Specifying` | None | ~1,240 isolated / ~660 after research | ~150 |
| **Step 2: Intake Alignment** | Classify intake scope (`new_spec`, `maintenance`, etc.) | `references/intake.md` (219) | ~1,450 | ~250 |
| **Step 3: Frontier Grilling** | Ask all unblocked questions in one numbered batch | `references/grilling-waves.md` (478) | ~1,720 | ~800 |
| **Step 4: Classification & Proposal** | Draft `proposal.md` for Moderate/Complex scopes | `references/proposal-template.md` (135) | ~1,380 | ~500 |
| **Step 5: Spec Authoring (`spec.md`)** | Write `spec.md` (`REQ-*`, `AC-*`, `US-*`, NFR bindings) | `references/spec-template.md` (502) | ~1,740 | ~1,800 |
| **Step 6: Review & Gate Handoff** | Run `phase-check`, `skill-exit --handoff spec-plan` | `requirements-review-template.md` (132) | ~1,370 | ~350 |
| **Total Skill Run** | | | **~8,900** isolated; pack is **~578 cheaper** after research | **~3,850** |

---

### 4. `/spec-plan` (Architecture & Technical Design)
*Context Base: ~900 isolated / **~769 after `/spec-requirements`** | SKILL.md: 1,320 tokens*

After requirements, plan skips bootstrap and `status.md`, injects only architecture **Safe Change Guidance**, and **can include** `code-design.md` (500) because skipped bootstrap no longer fills the bootstrap channel.

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Planning` | None | ~1,260 isolated / ~1,110 after requirements | ~150 |
| **Step 2: Solution Authoring** | Draft technical architecture & data structures | `references/plan-template.md` (314) | ~1,570 | ~1,500 |
| **Step 3: Module & Seam Map** | Design deep modules and test seams | `references/deep-modules.md` (650) | ~1,910 | ~800 |
| **Step 4: Design-it-Twice & DoR** | Evaluate 2 approaches if complex; check DoR | `references/definition-of-ready.md` (155) | ~1,420 | ~500 |
| **Step 5: Alignment & Handoff** | Run `skill-exit --handoff spec-tasks` | None | ~1,260 | ~200 |
| **Total Skill Run** | | | **~7,420** isolated | **~3,150** |

---

### 5. `/spec-tasks` (Work Breakdown & Sequencing)
*Context Base: ~759 isolated / **~108 after `/spec-plan`** | SKILL.md: 1,577 tokens*

After plan, tasks injects only the new `code-design.md` H2 **Read before you write** (and `plan.md` if `/spec-adr` did not already load it).

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `TaskPlanning` | None | ~1,130 isolated / ~480 after plan | ~150 |
| **Step 2: Task Breakdown** | Create `T-001`..`T-NNN` using Expand/Migrate/Contract | `references/tasks-template.md` (473) | ~1,600 | ~1,800 |
| **Step 3: Traceability Check** | Verify 100% AC-to-task mapping | None | ~1,200 | ~350 |
| **Step 4: Task Graph Validation** | Run `cli.py task-check` to verify no dependency cycles | None | ~1,150 | ~200 |
| **Step 5: DoR & Handoff** | Run `skill-exit --handoff spec-implement`, set `PlanApproved` | None | ~1,130 | ~200 |
| **Total Skill Run** | | | **~6,210** isolated; pack is **~651 cheaper** after plan | **~2,700** |

---

### 6. `/spec-implement` (TDD Implementation Loop)
*Context Base: ~1,746 isolated (`--task T-001`) / **~696 after `/spec-tasks`** / **~78 on the next task** | SKILL.md: 1,845 tokens*
*Cost is per task iteration ($N \times \text{tasks}$):*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Implementing` | None | ~2,150 isolated / ~1,100 after tasks | ~150 |
| **Step 2: Task Lock & Reload** | `task-start --task T-NNN` $\rightarrow$ `context-load --task T-NNN` | Task excerpt (active task + direct deps only) | ~1,400 isolated / **~78–696 auto-delta** | ~200 |
| **Step 3: Baseline & TDD Loop** | Write failing test at public seam $\rightarrow$ write code $\rightarrow$ pass | `references/tdd-loop.md` (546) + target code | ~2,600 | ~1,500 – 3,000 |
| **Step 4: Mechanical Validation** | Run task test proof + `cli.py verify` | Test output | ~2,200 | ~300 |
| **Step 5: Logging & Task Close** | Run `task-done --evidence "..."`, extract candidates | None | ~1,600 | ~350 |
| **Cost per Task** | *(Later tasks re-inject only the changed task excerpt)* | | **~7,950** first task isolated; later tasks drop pack to **~78** | **~3,000** |

---

### 7. `/harness-verify` (Mechanical & Two-Axis Review Gate)
*Context Base: ~1,444 isolated / **~542 after implement** | SKILL.md: 1,824 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Verifying` | None | ~1,980 isolated / ~1,080 after implement | ~150 |
| **Step 2: Mechanical Gate Audit** | Run `cli.py verify` (gates, artifacts, traceability) | Gate outputs | ~2,100 | ~400 |
| **Step 3: Two-Axis Isolated Review** | Axis 1: Standards & Fowler smells<br>Axis 2: Spec alignment line by line | `references/review-template.md` (683) + `git diff` | ~2,800 | ~2,500 |
| **Step 4: Security & Provider Audit** | Check security policies and review provider outcome | None | ~2,100 | ~350 |
| **Step 5: Post-Ship Sync & Exit** | Write `review.md` verdict, write `Post-Ship Sync`, exit `Done` | None | ~2,200 | ~800 |
| **Total Skill Run** | | | **~11,180** isolated; pack is **~902 cheaper** after implement | **~4,200** |

---

### 8. `/context-memory` (Durable Memory Promotion & Triage)
*Context Base: ~1,093 isolated / **~319 after verify** | SKILL.md: 1,610 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight Audit** | Run `memory-audit` and `memory-gate` | None | ~1,730 isolated / ~960 after verify | ~250 |
| **Step 2: Extraction Triage** | Review `[CANDIDATE]` lessons; promote or archive | `references/extraction-triage.md` (706) | ~2,440 | ~1,200 |
| **Step 3: Verify & Return** | Run `memory-audit --json` to verify line limits | None | ~1,800 | ~200 |
| **Total Skill Run** | | | **~5,970** isolated | **~1,650** |

---

### 9. `/spec-adr` (Architectural Decision Record)
*Context Base: ~657 isolated / **~6 after `/spec-plan`** | SKILL.md: 1,235 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Steps 1 & 2: Pre-flight & Trade-offs** | Identify decision need, evaluate 2–3 options | None | ~1,340 isolated / ~690 after plan | ~600 |
| **Steps 3 & 4: Draft ADR & Ledger** | Write `corebase-specharness/project/adr/ADR-NNN.md` | `references/adr-template.md` (240) | ~1,580 | ~1,000 |
| **Step 5: Handoff** | Return to caller | None | ~1,340 | ~150 |
| **Total Skill Run** | | | **~4,260** isolated | **~1,750** |

---

### 10. `/spec-testing-scenario` (Edge Case & Manual QA Matrix)
*Context Base: ~848 isolated / **~0 after verify** on this probe (constraints already loaded) | SKILL.md: 1,047 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Steps 1 & 2: Pre-flight & Discovery** | Discover boundary values, concurrency, security edges | None | ~1,225 isolated / ~380 after verify | ~600 |
| **Steps 3 & 4: Authoring & Return** | Author `testing-scenarios.md` | `testing-scenarios-template.md` (259) | ~1,480 | ~1,200 |
| **Total Skill Run** | | | **~2,705** isolated | **~1,800** |

---

### 11. `/harness-maintain` (Harness & Gate Drift Maintenance)
*Context Base: ~1,063 isolated / **~0 after verify** when `harness-config.yaml` is already in the session | SKILL.md: 1,355 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight Diagnostic** | Run `doctor --json`, `gate-check --json` | None | ~1,490 isolated / ~430 after verify | ~250 |
| **Step 2: Diagnosis & Repair** | Fix harness drift, resync baseline | `references/diagnosis-map.md` (1,054) | ~2,540 | ~1,000 |
| **Step 3: User Confirmation** | Confirm changes with adopter | None | ~1,500 | ~250 |
| **Total Skill Run** | | | **~5,530** isolated | **~1,500** |
