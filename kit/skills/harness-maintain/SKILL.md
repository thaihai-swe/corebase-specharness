---
id: skill-harness-maintain
name: harness-maintain
description: "Interpret deterministic harness diagnostics and propose bounded maintenance actions."
tags: ['harness', 'maintenance', 'diagnostics']
triggers: ['maintain harness', 'harness health', 'diagnose harness', 'improve harness']
---
# Harness Maintain

## At a Glance

| | |
|---|---|
| **Reads** | `harness-config.yaml`, `core-policies.md` |
| **Writes** | Optional: `learned-heuristics.md` `[DRAFT]` entries; user-approved config/policy edits |
| **Key CLI** | `python3 corebase-specharness/scripts/core/cli.py doctor --json`, `python3 corebase-specharness/scripts/core/cli.py gate-check --json`, `python3 corebase-specharness/scripts/core/cli.py verify --feature <slug>` |
| **Handoff** | Return to caller after the bounded procedure |
| **Session** | N/A (repo-level) |

## Overview

Interpret harness diagnostics, check kit manifest drift (if present), validate gates, draft heuristics from failures, diagnose agent quality. CLI owns mechanical inspection; this skill owns prioritization and user-approved actions. Use for harness health, orphans, scaffolding, `verify`/`gate-check` findings, or agent-quality diagnosis.

## Execution Modes & Profiles

| Mode | Trigger | Focus |
|---|---|---|
| `assess` | Periodic / post-install | Manifest drift, orphans, config health |
| `create` | Missing infrastructure | Scaffold `memories/domain/` and placeholders |
| `improve` | Diagnostic failures | Draft `[DRAFT]` heuristics from findings |
| `eval` | Release candidate | `core-policies.md` headings, manifest, gates, `eval-run` |
| `doctor` | Fix mode | Assess + Markdown links + clean `doctor` |
| `diagnose` | Quality degradation | Symptom → fix via `references/diagnosis-map.md` |

## Step-by-Step Execution Workflow

1. **Select mode**: `assess`, `create`, `improve`, `eval`, `doctor`, or `diagnose`.

2. **Execute**:
   - *Assess*: `python3 corebase-specharness/scripts/core/cli.py doctor --json`. Validate `harness-config.yaml`. Detect feature dirs lacking `status.md`.
   - *Create*: scaffold missing standard dirs or placeholders.
   - *Improve*: review `verify` / `gate-check`. Draft `[DRAFT]` entries; do not promote automatically. For a repeated agent failure, also add or snapshot an eval fixture (`eval-run --from-feature <slug>` or a new `evals/cases/` case) so the same defect fails the next `eval-run`.
   - *Eval*: audit `core-policies.md` headings (`## Purpose`, `## Normative Rules`, `## Known Broken Tests`, `## Memory Promotion Thresholds`, `## Security Policy`). Run continuous evaluation benchmarks: `python3 corebase-specharness/scripts/core/cli.py eval-run --json`. Run `python3 corebase-specharness/scripts/core/cli.py verify --feature <slug>` or `python3 corebase-specharness/scripts/core/cli.py doctor`. Compare kit manifest vs tree if present.
   - *Doctor*: Assess + check links in `skills/*/*.md` + re-run `python3 corebase-specharness/scripts/core/cli.py doctor --json`.
   - *Diagnose*: match symptom to `references/diagnosis-map.md`; propose targeted policy/heuristic fixes.

3. **Approve & close**:
   - Present drafts for explicit user approval.
   - Report repaired items and remaining manual work.

## Anti-Patterns & Red Flags

- Promoting `[DRAFT]` or editing `core-policies.md` without review.
- Editing Python engine files instead of manifest/config.
- Shipping without `eval` manifest consistency.
- Drafting a heuristic for a repeated agent failure without adding an eval fixture that would catch it.

## Core Rules

- `improve` drafts `[DRAFT]` only — user review REQUIRED before promotion.
- Releases require `eval` for 100% manifest consistency.
- CLI owns inspection; this skill owns recommendations.
- Failed gates need a fast, deterministic, red-capable command before a permanent heuristic.
- Periodically prune obsolete constraints.
