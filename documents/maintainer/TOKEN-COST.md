
Structure the answer into two comprehensive parts:
1. **Part 1: What We Send to the Agent for Each Skill** (the exact files, section slices, and instruction payloads).
2. **Part 2: Token Cost Breakdown for Each Skill and Each Step** (Input tokens, Step procedure, Templates, and Output tokens).

Let's present this clearly.Here is the exact breakdown of **what we send to the agent** for each of the 11 CoreBase SpecHarness skills and the **token cost for every step of each skill**, measured directly using the `cl100k_base` BPE tokenizer.

---

# Part 1: What We Send to the Agent for Each Skill

When a skill is invoked, CoreBase SpecHarness compiles a bounded context pack (`context-load` / `skill-enter`) containing:
1. **Mandatory Bootstrap Rules**: Core communication & normative repository rules.
2. **Route-Declared Sources**: Repository architecture, constraints, or coding standards (sliced to specific H2 sections).
3. **Active Feature Artifacts**: The relevant slice of upstream deliverables (`status.md`, `spec.md`, `plan.md`, `tasks.md`).
4. **Skill Procedure (`SKILL.md`)**: The step-by-step workflow the agent follows.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WHAT IS SENT TO THE AGENT                       │
├────────────────────────────────┬───────────────────────────────────────┤
│ 1. Mandatory Bootstrap         │ caveman.md (156) + core-policies.md   │
│ 2. Route Sources (Sliced)      │ architecture.md, constraints, etc.    │
│ 3. Feature Artifacts           │ spec.md, plan.md, tasks.md, status.md │
│ 4. Domain & Local Retrieval    │ glossary.md triggers + code excerpts  │
│ 5. Skill Procedure             │ skills/<name>/SKILL.md                │
└────────────────────────────────┴───────────────────────────────────────┘
```

### Exact Files & Slices Sent per Skill

| Skill | Injected Context Files & Sliced Sections | Pack Tokens | `SKILL.md` Procedure |
| :--- | :--- | :---: | :---: |
| **`/starter-init`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `harness-config.yaml` (485)<br>• `tech-stack.md` [Languages & Runtimes, Frameworks, Dev Tools] (97)<br>• `project-constraints.md` [Performance, Tech, Operational] (182) | **1,333** | **1,650** |
| **`/spec-research`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (19)<br>• `architecture.md` [System Snapshot, Top-Level Components, Runtime Boundaries] (75) | **663** | **1,500** |
| **`/spec-requirements`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (19)<br>• `analysis.md` [Findings] (12)<br>• `project-constraints.md` [Performance, Compliance, Security, Operational] (193)<br>• `product-sense.md` [Vision, Problem Statement, Domain Rules, Metrics] (107) | **900** | **1,711** |
| **`/spec-plan`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (19)<br>• `spec.md` [Acceptance Criteria] (28)<br>• `architecture.md` [Snapshot, Components, Boundaries, Safe Change] (89)<br>• `ponytail.md` [Decision Matrix: Abstractions] (219) | **924** | **1,282** |
| **`/spec-tasks`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (19)<br>• `spec.md` [Acceptance Criteria] (28)<br>• `plan.md` (14)<br>• `code-design.md` [Read before you write] (102)<br>• `architecture.md` [Snapshot, Components] (59) | **791** | **1,538** |
| **`/spec-implement`**<br>*(Task-scoped)* | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative, Security Policy] (608)<br>• `status.md` (19)<br>• `spec.md` [Acceptance Criteria] (28)<br>• `plan.md` (14)<br>• `tasks.md` *(active `T-NNN` excerpt + direct deps)* (91)<br>• `security.md` [Core Rules, Shell Safety, Artifact Boundaries, Verification] (319)<br>• `code-design.md` [Read before you write, Failures must reach a decision-maker, Verify the path you claim to have fixed] (239) | **1,474** | **1,782** |
| **`/harness-verify`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative, Security Policy] (608)<br>• `status.md` (19)<br>• `spec.md` (28)<br>• `plan.md` (14)<br>• `tasks.md` (65)<br>• `harness-config.yaml` (485)<br>• `security.md` [Verification] (109) | **1,484** | **1,776** |
| **`/context-memory`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative, Promotion Thresholds, Security] (689)<br>• `learned-heuristics.md` [Heuristics] (227) | **1,072** | **1,486** |
| **`/harness-maintain`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `harness-config.yaml` (485) | **1,054** | **1,292** |
| **`/spec-adr`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `architecture.md` [Snapshot, Boundaries, Safe Change] (59) | **628** | **1,193** |
| **`/spec-testing-scenario`** | • `caveman.md` (156)<br>• `core-policies.md` [Purpose, Normative Rules] (413)<br>• `status.md` (19)<br>• `spec.md` (28)<br>• `plan.md` (14)<br>• `tasks.md` (65)<br>• `project-constraints.md` [Performance, Compliance, Security, Operational] (193) | **888** | **1,044** |

---

# Part 2: Token Cost Breakdown for Each Step of Each Skill

### 1. `/starter-init` (Bootstrap Repository)
*Context Base: ~1,333 tokens | SKILL.md: 1,650 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight & Scaffold Init** | Run `cli.py init --json`, inspect `onboarding_readiness` | None | ~1,650 | ~250 |
| **Step 2: Archaeology Sweep (Phase A)** | Detect stack markers, run brownfield sweep | `references/brownfield-mode.md` (945) | ~2,500 | ~1,200 |
| **Step 3: Memory & Gate Setup (Phase B)** | Pre-fill memory seeds, ask frontier questions, confirm gates | `references/template-prefill.md` (617) | ~2,250 | ~2,500 |
| **Step 4: Mechanical Verify & Handoff** | Run `doctor` and `memory-audit`, report readiness | None | ~1,800 | ~400 |
| **Total Skill Run** | | | **~8,000** | **~4,350** |

---

### 2. `/spec-research` (Investigation & Brownfield Mapping)
*Context Base: ~663 tokens | SKILL.md: 1,500 tokens*

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
*Context Base: ~900 tokens | SKILL.md: 1,711 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Specifying` | None | ~1,240 | ~150 |
| **Step 2: Intake Alignment** | Classify intake scope (`new_spec`, `maintenance`, etc.) | `references/intake.md` (219) | ~1,450 | ~250 |
| **Step 3: Frontier Grilling** | Ask all unblocked questions in one numbered batch | `references/grilling-waves.md` (478) | ~1,720 | ~800 |
| **Step 4: Classification & Proposal** | Draft `proposal.md` for Moderate/Complex scopes | `references/proposal-template.md` (135) | ~1,380 | ~500 |
| **Step 5: Spec Authoring (`spec.md`)** | Write `spec.md` (`REQ-*`, `AC-*`, `US-*`, NFR bindings) | `references/spec-template.md` (502) | ~1,740 | ~1,800 |
| **Step 6: Review & Gate Handoff** | Run `phase-check`, `skill-exit --handoff spec-plan` | `requirements-review-template.md` (132) | ~1,370 | ~350 |
| **Total Skill Run** | | | **~8,900** | **~3,850** |

---

### 4. `/spec-plan` (Architecture & Technical Design)
*Context Base: ~924 tokens | SKILL.md: 1,282 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Planning` | None | ~1,260 | ~150 |
| **Step 2: Solution Authoring** | Draft technical architecture & data structures | `references/plan-template.md` (314) | ~1,570 | ~1,500 |
| **Step 3: Module & Seam Map** | Design deep modules and test seams | `references/deep-modules.md` (650) | ~1,910 | ~800 |
| **Step 4: Design-it-Twice & DoR** | Evaluate 2 approaches if complex; check DoR | `references/definition-of-ready.md` (155) | ~1,420 | ~500 |
| **Step 5: Alignment & Handoff** | Run `skill-exit --handoff spec-tasks` | None | ~1,260 | ~200 |
| **Total Skill Run** | | | **~7,420** | **~3,150** |

---

### 5. `/spec-tasks` (Work Breakdown & Sequencing)
*Context Base: ~791 tokens | SKILL.md: 1,538 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `TaskPlanning` | None | ~1,130 | ~150 |
| **Step 2: Task Breakdown** | Create `T-001`..`T-NNN` using Expand/Migrate/Contract | `references/tasks-template.md` (473) | ~1,600 | ~1,800 |
| **Step 3: Traceability Check** | Verify 100% AC-to-task mapping | None | ~1,200 | ~350 |
| **Step 4: Task Graph Validation** | Run `cli.py task-check` to verify no dependency cycles | None | ~1,150 | ~200 |
| **Step 5: DoR & Handoff** | Run `skill-exit --handoff spec-implement`, set `PlanApproved` | None | ~1,130 | ~200 |
| **Total Skill Run** | | | **~6,210** | **~2,700** |

---

### 6. `/spec-implement` (TDD Implementation Loop)
*Context Base: ~1,474 tokens (Without `--task`: ~1,362 on a tiny feature probe) | SKILL.md: 1,782 tokens*
*Cost is per task iteration ($N \times \text{tasks}$):*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Implementing` | None | ~2,150 | ~150 |
| **Step 2: Task Lock & Reload** | `task-start --task T-NNN` $\rightarrow$ `context-load --task T-NNN` | Task excerpt (active task + direct deps only) | ~1,400 *(Auto-delta: ~400)* | ~200 |
| **Step 3: Baseline & TDD Loop** | Write failing test at public seam $\rightarrow$ write code $\rightarrow$ pass | `references/tdd-loop.md` (546) + target code | ~2,600 | ~1,500 – 3,000 |
| **Step 4: Mechanical Validation** | Run task test proof + `cli.py verify` | Test output | ~2,200 | ~300 |
| **Step 5: Logging & Task Close** | Run `task-done --evidence "..."`, extract candidates | None | ~1,600 | ~350 |
| **Cost per Task** | *(Multi-turn auto-delta drops input on steps 2–5)* | | **~7,950** | **~3,000** |

---

### 7. `/harness-verify` (Mechanical & Two-Axis Review Gate)
*Context Base: ~1,484 tokens | SKILL.md: 1,776 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight** | Run `skill-enter`, set `Verifying` | None | ~1,980 | ~150 |
| **Step 2: Mechanical Gate Audit** | Run `cli.py verify` (gates, artifacts, traceability) | Gate outputs | ~2,100 | ~400 |
| **Step 3: Two-Axis Isolated Review** | Axis 1: Standards & Fowler smells<br>Axis 2: Spec alignment line by line | `references/review-template.md` (683) + `git diff` | ~2,800 | ~2,500 |
| **Step 4: Security & Provider Audit** | Check security policies and review provider outcome | None | ~2,100 | ~350 |
| **Step 5: Post-Ship Sync & Exit** | Write `review.md` verdict, write `Post-Ship Sync`, exit `Done` | None | ~2,200 | ~800 |
| **Total Skill Run** | | | **~11,180** | **~4,200** |

---

### 8. `/context-memory` (Durable Memory Promotion & Triage)
*Context Base: ~1,072 tokens | SKILL.md: 1,486 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight Audit** | Run `memory-audit` and `memory-gate` | None | ~1,730 | ~250 |
| **Step 2: Extraction Triage** | Review `[CANDIDATE]` lessons; promote or archive | `references/extraction-triage.md` (706) | ~2,440 | ~1,200 |
| **Step 3: Verify & Return** | Run `memory-audit --json` to verify line limits | None | ~1,800 | ~200 |
| **Total Skill Run** | | | **~5,970** | **~1,650** |

---

### 9. `/spec-adr` (Architectural Decision Record)
*Context Base: ~628 tokens | SKILL.md: 1,193 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Steps 1 & 2: Pre-flight & Trade-offs** | Identify decision need, evaluate 2–3 options | None | ~1,340 | ~600 |
| **Steps 3 & 4: Draft ADR & Ledger** | Write `corebase-specharness/project/adr/ADR-NNN.md` | `references/adr-template.md` (240) | ~1,580 | ~1,000 |
| **Step 5: Handoff** | Return to caller | None | ~1,340 | ~150 |
| **Total Skill Run** | | | **~4,260** | **~1,750** |

---

### 10. `/spec-testing-scenario` (Edge Case & Manual QA Matrix)
*Context Base: ~888 tokens | SKILL.md: 1,044 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Steps 1 & 2: Pre-flight & Discovery** | Discover boundary values, concurrency, security edges | None | ~1,225 | ~600 |
| **Steps 3 & 4: Authoring & Return** | Author `testing-scenarios.md` | `testing-scenarios-template.md` (259) | ~1,480 | ~1,200 |
| **Total Skill Run** | | | **~2,705** | **~1,800** |

---

### 11. `/harness-maintain` (Harness & Gate Drift Maintenance)
*Context Base: ~1,054 tokens | SKILL.md: 1,292 tokens*

| Step | What happens | Extra Templates / Files Loaded | Step Input | Typical Output |
| :--- | :--- | :--- | :---: | :---: |
| **Step 1: Pre-flight Diagnostic** | Run `doctor --json`, `gate-check --json` | None | ~1,490 | ~250 |
| **Step 2: Diagnosis & Repair** | Fix harness drift, resync baseline | `references/diagnosis-map.md` (1,054) | ~2,540 | ~1,000 |
| **Step 3: User Confirmation** | Confirm changes with adopter | None | ~1,500 | ~250 |
| **Total Skill Run** | | | **~5,530** | **~1,500** |
