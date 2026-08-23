# CoreBase SpecHarness

> **Skills-first, spec-driven delivery kit for AI coding agents.**
> Embedded CLI harness, bounded context compiler, durable memory, and explicit verification.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](manifest.json)
[![Python](https://img.shields.io/badge/python-%3E%3D3.10-3776AB.svg?logo=python&logoColor=white)](https://python.org)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-Python%20std%20library-brightgreen.svg)](#requirements)

---

## Overview

**CoreBase SpecHarness** transforms AI coding agents into disciplined, spec-driven engineering partners. It embeds a deterministic Python CLI, 11 peer-level agent skills, a bounded context compiler, and a robust verification harness directly into your repository.

- **Lives in your repository:** Zero background servers, daemons, or remote dependencies.
- **Works with any agent:** Compatible with Claude Desktop, Cursor, Windsurf, Roo Code, GitHub Copilot, DeepSeek Harness, or any tool supporting Markdown skills and terminal execution.
- **Enforces a system of record:** All requirements, design plans, task breakdowns, execution logs, and verification reports persist in git-trackable Markdown and JSON files.

```
       ┌────────────────────────────────────────────────────────┐
       │             11 Peer-Level Agent Skills                 │
       │  (Procedure & Judgment in Markdown: skills/ & .agent/) │
       └───────────────────────────┬────────────────────────────┘
                                   │ Invokes CLI
       ┌───────────────────────────▼────────────────────────────┐
       │           Embedded Deterministic Python CLI            │
       │      (corebase-specharness/scripts/core/cli.py)        │
       ├───────────────────────────┬────────────────────────────┤
       │   Bounded Context Engine  │ Lifecycle & State Machine  │
       │   • 8-step compiler       │ • 6 core phases            │
       │   • Session auto-delta    │ • Confirmed project gates  │
       │   • Token budget caps     │ • Advisory / Blocking mode │
       └───────────────────────────┴────────────────────────────┘
```

---

## Key Highlights

- **11 Peer-Level Skills:** Research, requirements, architecture design, task breakdown, TDD implementation, verification, memory curation, ADR drafting, and harness diagnostics.
- **Bounded Context Compiler:** Compiles targeted context slices from route declarations and intent matching, capping tokens (4,500 token active budget) to prevent context saturation.
- **Session Auto-Delta:** Accumulates SHA-256 slice fingerprints across consecutive skill turns in the same chat, cutting context injection by **49% to 80%** without losing state.
- **Advisory-by-Default Verification:** Runs structural checks and confirmed project gates (`test`, `lint`, `typecheck`). New installs report findings as `deferred` rather than falsely claiming success or hard-blocking adopters.
- **Dual-State Separation:** Durable feature artifacts (`artifacts/features/<slug>/`) live with your code; ephemeral session continuity (`.corebase-specharness/sessions/<slug>/session.md`) keeps working state inspectable and recoverable.
- **Safe In-Place Upgrades:** Manifest-driven installation cleanly divides kit-owned files (`overwrite`, automatically backed up to `.corezero-backup-<random>/`) from adopter-owned files (`copyIfMissing` seeds).

---

## Quick Start

### 1. Installation

Install or upgrade the embedded payload into your target project:

```bash
# Preview changes (dry run)
bash corebase-specharness/scripts/install.sh /path/to/your-repo --dry-run

# Live install
bash corebase-specharness/scripts/install.sh /path/to/your-repo
```

The installer:
1. Copies the embedded runtime (`corebase-specharness/scripts/core/`).
2. Copies the 11 peer skills to `skills/` and mirrors them to `.agent/skills/` for standard agent discovery.
3. Seeds initial configuration, project context, and domain memory templates.
4. Executes `doctor` to verify payload integrity and report setup status.

### 2. Verify Installation Health

```bash
cd /path/to/your-repo
python3 corebase-specharness/scripts/core/cli.py doctor --json
```

### 3. Initialize & Tailor (New Repositories)

For a fresh repository, invoke `/starter-init` or run:

```bash
python3 corebase-specharness/scripts/core/cli.py init --json
```

This scaffolds missing memory directories and reports detected stacks, existing instruction files, and onboarding readiness.

---

## The Spec-Driven Lifecycle

CoreBase SpecHarness follows a structured 6-phase delivery route. Every phase has dedicated skill contracts and durable artifact outputs:

```
  ┌──────────────┐      ┌──────────────────────┐      ┌─────────────┐
  │ /spec-research│ ───► │  /spec-requirements  │ ───► │  /spec-plan │
  │ (Exploration) │      │  (Contract & ACs)    │      │  (Design)   │
  └──────────────┘      └──────────────────────┘      └──────┬──────┘
                                                             │
  ┌────────────────┐      ┌─────────────────┐                │
  │ /context-memory│ ◄─── │ /harness-verify │ ◄──────────────┤
  │ (Knowledge)    │      │ (Gate Closeout) │                ▼
  └────────────────┘      └────────▲────────┘         ┌─────────────┐
                                   │                  │ /spec-tasks │
                                   └───────────────── │ (Sequencing)│
                                  /spec-implement     └─────────────┘
                                  (TDD Execution)
```

### Core Skills & Artifacts

| Skill | Purpose | Key Artifact |
| :--- | :--- | :--- |
| **`/starter-init`** | Scaffolds workspace and tailors project context | `project/harness-config.yaml` |
| **`/spec-research`** | Investigates unknown codebase behavior and debugs root causes | `artifacts/features/<slug>/analysis.md` |
| **`/spec-requirements`** | Gathers user intent, acceptance criteria, and constraints | `artifacts/features/<slug>/spec.md` |
| **`/spec-plan`** | Formulates technical architecture and public interface design | `artifacts/features/<slug>/plan.md` |
| **`/spec-tasks`** | Generates sequenced, actionable work items and dependencies | `artifacts/features/<slug>/tasks.md` |
| **`/spec-implement`** | Executes tasks iteratively under red-green TDD discipline | `artifacts/features/<slug>/tasks.md` |
| **`/harness-verify`** | Runs mechanical gates, checks traceability, and signs off | `artifacts/features/<slug>/review.md` |
| **`/context-memory`** | Triages and promotes reusable heuristics to repo memory | `memories/repo/` |
| **`/spec-adr`** | Drafts and registers formal Architectural Decision Records | `memories/repo/adr-log.md` |
| **`/spec-testing-scenario`** | Expands acceptance criteria into explicit test scenarios | `artifacts/features/<slug>/testing-scenarios.md` |
| **`/harness-maintain`** | Diagnoses harness anomalies, route drift, and line caps | Diagnostic reports |

---

## Agent Usage & CLI Commands

Developers invoke skills through slash commands or by directing their agent to `skills/<name>/SKILL.md` (or `.agent/skills/<name>/SKILL.md`). The agent executes the underlying CLI commands:

### Standard Skill Execution Flow

```bash
# 1. Enter skill & load route-specific context
python3 corebase-specharness/scripts/core/cli.py skill-enter \
  --skill spec-plan \
  --feature add-oauth \
  --intent "design google and github oauth2 strategy" \
  --json

# 2. Inspect context composition and token budgets
python3 corebase-specharness/scripts/core/cli.py context-explain \
  --skill spec-plan \
  --feature add-oauth \
  --intent "design google and github oauth2 strategy" \
  --json

# 3. Check task state during implementation
python3 corebase-specharness/scripts/core/cli.py task-check --feature add-oauth

# 4. Exit skill and hand off to the next lifecycle step
python3 corebase-specharness/scripts/core/cli.py skill-exit \
  --skill spec-plan \
  --feature add-oauth \
  --handoff spec-tasks \
  --json

# 5. Run verification gates before feature closeout
python3 corebase-specharness/scripts/core/cli.py verify \
  --feature add-oauth \
  --skill harness-verify \
  --json
```

### CLI Command Catalog

The embedded CLI provides 27 deterministic subcommands across 8 functional groups:

- **Lifecycle & Envelope:** `skill-enter`, `skill-exit`, `status-set`, `status`
- **Context Engine:** `context-load`, `context-pack`, `context-explain`
- **Session Tracking:** `session-start`, `session-checkpoint`, `session-end`
- **Task Management:** `task-start`, `task-done`, `task-block`, `task-check`
- **Verification & Gates:** `verify`, `phase-check`, `artifact-check`, `gate-check`, `gate-list`
- **Diagnostics & Health:** `doctor`, `memory-audit`, `memory-gate`
- **Architecture Decisions:** `adr-generate`
- **Tool Providers:** `provider-list`, `provider-check`, `provider-run`

---

## Architecture & System Design

```
corebase-specharness/
├── manifest.json                           # Package manifest & ownership definitions
├── AGENTS.md                               # Universal top-level agent instruction router
├── EXTERNAL_SKILLS.md                      # Catalog for optional external specialist skills
├── references/
│   ├── context-routes.yaml                 # Skill routing declarations & source mapping
│   └── tool-providers-registry.json        # Optional provider registry
├── skills/ & .agent/skills/                # 11 peer skills + _shared contracts
├── corebase-specharness/
│   ├── scripts/
│   │   ├── core/                           # Embedded Python CLI runtime
│   │   ├── install.sh                      # Idempotent installer & upgrader
│   │   └── validate-static-audit.py        # Static reachability validator
│   ├── project/
│   │   ├── state-machine.yaml              # Lifecycle state definitions & transitions
│   │   ├── harness-config.yaml             # Adopter-confirmed gates & config
│   │   ├── architecture.md                 # Adopter system architecture
│   │   ├── tech-stack.md                   # Adopter stack conventions
│   │   └── tool-providers.md               # Provider configuration
│   └── memories/
│       ├── repo/                           # Core policies, heuristics, adr-log
│       └── domain/                         # Patterns, boundaries, anti-patterns
└── artifacts/
    └── features/<feature-slug>/            # Feature specifications, plans, tasks, reviews
```

### Token Budgets & Session Auto-Delta

The Context Compiler enforces strict token limits to protect agent attention:

| Context Channel | Budget Cap | Notes |
| :--- | :--- | :--- |
| **Max Injected Context** | `4,500 tokens` | Derived from 6,000 max ceiling minus 1,500 reserve |
| **Bootstrap Context** | `1,200 tokens` | AGENTS.md, tech stack, policies |
| **Project Context** | `1,200 tokens` | Architecture, constraints, glossary |
| **Feature Artifacts** | `1,600 tokens` | Upstream specs, plans, tasks |
| **Retrieved Excerpts** | `1,000 tokens` | Max 4 files, 400 tokens per excerpt |

**Session Auto-Delta:** Within the same conversation, consecutive skills omit previously injected, unmodified H2 sections. Passing `--full` resets the baseline when starting a new chat or following context compaction.

---

## Requirements

- **Runtime:** Python 3.10+ (standard library only; no pip dependencies required)
- **Shell:** Bash (macOS, Linux, WSL)
- **Token Counting:** Uses `tiktoken` (`cl100k_base`) if available; falls back to exact 4-char estimation.
- **Agent Environment:** Any coding agent with filesystem and terminal execution capabilities.
