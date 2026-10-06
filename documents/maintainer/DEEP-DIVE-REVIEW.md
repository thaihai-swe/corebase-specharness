# CoreBase SpecHarness Deep-Dive Review & Evolutionary Architecture

> **Audience:** Solution Architects, Kit Maintainers, Platform Engineers  
> **Status:** Matches as-built implementation in `kit/` as of September 2026  
> **Authority:** Subordinate to executable code (`kit/corebase-specharness/scripts/core/`) and manifest (`kit/manifest.json`).

---

## 1. Executive Summary & Purpose

CoreBase SpecHarness is a **deterministic governance runtime for AI-assisted software engineering**. The CLI checks files, tokens, and transitions; it does not choose or run the next skill.

Unlike standard agent tooling that relies on conversational memory, implicit prompting, or broad workspace dumping, CoreBase SpecHarness enforces an **executable specification harness**:
1. **Contract-First Delivery:** Work proceeds through explicit artifacts (`spec.md` $\to$ `plan.md` $\to$ `tasks.md` $\to$ `review.md`).
2. **Deterministic State Machine:** Transitions between phases (`Specifying`, `SpecApproved`, `PlanApproved`, `Implementing`, `Verifying`, `Done`) are guarded by an embedded Python engine rather than LLM self-reporting.
3. **Budget-Bounded Context Packs:** Compiles targeted token payloads based on explicit routing declarations in `corebase-specharness/references/context-routes.yaml`, preventing model context bloat and degradation over extended sessions.

---

## 2. Core Architectural Subsystems

### 2.1 Skill Catalog (`kit/skills/`)
The catalog ships **11 peer-level direct entrypoint skills** structured around strict role boundaries:
- `/spec-research`: Root-cause investigation, spikes, and public-seam freeze tests. Prohibited from writing production code.
- `/spec-requirements`: Synthesizes user stories with verifiable requirements and `AC-*` acceptance criteria.
- `/spec-plan`: High-level technical design, module map seams, dependency direction, and Design-it-Twice evaluation.
- `/spec-tasks`: Compiles technical designs into an acyclic task DAG (`T-NNN`) where each node maps to $\ge 1$ `AC-*` and defines concrete entry/exit commands.
- `/spec-implement`: Tracer-bullet execution under a strict Red/Green/Refactor loop. Enforces "fix the code, not the test" on bug fixes.
- `/harness-verify`: Two-axis verification across code implementation and test coverage. Executes verification gates and regression eval suites.
- `/context-memory`: Evidence-based memory promotion, triage of `[CANDIDATE]` items, and 30–50% prose compaction preserving stable IDs.
- Specialized/Utility: `/spec-adr` (immutable decision records), `/spec-testing-scenario` (manual QA fixtures), `/harness-maintain` (kit self-diagnostics), and `/starter-init` (repo tailoring).

### 2.2 Deterministic Context Engine (`context_engine.py`)
- **Route-Driven Packaging:** Context is never assembled ad-hoc. The engine looks up routes in `corebase-specharness/references/context-routes.yaml` and enforces declared prerequisites.
- **Hierarchical Tiering:**
  - `Must`: Universal bootstrap (`core-policies.md` Normative Rules), `status.md`, and required feature artifacts. Never dropped for budget.
  - `Should`: Domain packs (`memories/domain/` matched by intent keywords), non-critical references. Dropped when channel limits or profile budgets are exceeded.
- **Task Slicing:** When `--task T-NNN` is supplied to `context-load`, the full `tasks.md` file is excluded, replaced by a slice containing only the active task and its direct prerequisites.
- **Session Auto-Delta:** Accumulates SHA-256 fingerprints of injected files/sections in `.corebase-specharness/sessions/<slug>/session.md`. Unchanged sections are omitted in subsequent skill loads within the same chat session.

### 2.3 Multi-Tier Memory Management
1. **Ephemeral Session Memory (`.corebase-specharness/sessions/<slug>/`)**:
   - Tracks session lifecycle, checkpoints, decisions, and unverified candidate observations (`session-extracts.md`).
2. **Durable Repository Memory (`corebase-specharness/memories/repo/`)**:
   - `core-policies.md`: Invariant rules (security, code style, normative constraints).
   - `learned-heuristics.md`: Tagged `LH-*` heuristic catalog.
   - `adr-log.md`: Immutable ledger of architectural decisions.
   - `project-knowledge-base.md`: Topology and infrastructure facts.
3. **Decay & Compaction Governance (`handlers/diagnostics/memory.py`)**:
   - `memory-gate` and `memory-audit` enforce soft and hard line limits (`memory_warn_lines: 200`, `memory_hard_lines: 3200`).
   - Compaction rules enforce cutting 30–50% of prose while keeping all `##` headings and stable IDs (`LH-*`, `ADR-*`, `T-*`, `AC-*`).

### 2.4 Finite-State Workflow Runtime (`lifecycle.py`, `envelope.py`, `task_graph.py`)
- **Phase Machine:** Defined in `project/state-machine.yaml` with explicit forward paths and formal rollback states (`NeedsClarification`, `Replanning`, `ChangesRequested`, `Blocked`, `Abandoned`).
- **Enforcement Envelopes:**
  - `skill-enter`: Verifies artifact prerequisites on disk before granting entry and writing the phase token.
  - `skill-exit`: Mechanically checks required output writes before confirming handoff.
- **Task DAG Validator (`task_graph.py`)**:
  - Validates `T-NNN` syntax, cycle absence, and coverage maps. Prevents task start/done transitions out of dependency order.

---

## 3. Evaluative Architecture Suggestions

To advance CoreBase SpecHarness from an execution harness to a resilient AI engineering platform, the following architectural enhancements are recommended:

### 3.1 Design & Governance: Pre-Commit Write-Scope Enforcer
- **Current Observation:** The task graph lists file targets for each `T-NNN`, but write isolation relies on agent self-discipline. Unchecked agents can cause cross-file churn.
- **Proposal:** Implement a mechanical write-boundary check (`cli.py write-check --feature <slug> --task <T-NNN>`) or a Git pre-commit hook that queries `git status --porcelain` and rejects unstaged/staged edits outside the declared file scope of the active task.

### 3.2 Workflow: Fast-Track Bugfix Pipeline
- **Current Observation:** Isolated, trivial one-liner bug fixes must navigate the standard 6-phase lifecycle (`spec-requirements` $\to$ `spec-plan` $\to$ `spec-tasks` $\to$ `spec-implement` $\to$ `harness-verify`), creating unnecessary ceremony.
- **Proposal:** Formalize a `Fast-Track` flow in `state-machine.yaml`:
  - Direct route: `spec-research` (repro test) $\to$ `spec-implement` (single T-001) $\to$ `harness-verify`.
  - Allowed when change profile is `Simple` and diff surface is $\le 2$ files.

### 3.3 Context Engine: AST Skeletonization for Code References
- **Current Observation:** Local evidence retrieval injects verbatim function bodies and implementation blocks, consuming significant retrieval channel tokens.
- **Proposal:** For secondary reference files, generate structural AST skeletons (signatures, types, public seams) to fit 3× more architecture context into the bounded retrieval channel.

### 3.4 Runtime & Verification: Incident-to-Telemetry Closed Loop
- **Current Observation:** The eval harness (`eval-run`) operates on static fixture files and recorded feature artifacts (`--from-feature`).
- **Proposal:** Add an ingest adapter for production/CI logs (`eval-run --from-trace <log-path>`). The harness parses failure stack traces and auto-populates a reproducer fixture under `evals/cases/` to close the loop between production regressions and continuous evals.
