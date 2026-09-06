---
id: skill-context-memory
name: context-memory
description: "Maintain repository memory through evidence-backed updates, promotion, audit, and safe compaction."
tags: ['context', 'memory', 'heuristics', 'compaction']
triggers: ['memory', 'heuristic', 'learned', 'update memory', 'compact', 'compress', 'memory full', 'token budget']
---
# Context Memory

## At a Glance

| | |
|---|---|
| **Reads** | `core-policies.md`, `learned-heuristics.md`, `project-knowledge-base.md`, `session-extracts.md`, `CONTEXT_AND_MEMORY.md` |
| **Writes** | Optional: `learned-heuristics.md`, `core-policies.md`, domain `patterns.md`, `deprecated-heuristics.md`, `session-extracts.md` |
| **Key CLI** | `python3 corebase-specharness/scripts/core/cli.py memory-audit --json`, `python3 corebase-specharness/scripts/core/cli.py memory-gate --json`, `python3 corebase-specharness/scripts/core/cli.py session-end --feature <slug>` |
| **Handoff** | Return to caller after the bounded procedure |
| **Session** | Mark extracts triaged; `session-end` |

## Overview

Maintain durable memory so later agents do not repeat mistakes. Modes: post-ship sync, audit, compaction, decay. Use after `/harness-verify` writes `## Post-Ship Sync` and exits `Done`; also to triage `[CANDIDATE]` items, audit size, or compact over-budget files.

## Execution Modes & Profiles

| Mode | Trigger | Output |
|---|---|---|
| `post-ship-sync` | Passing verify | Sweep extracts; promote triaged candidates |
| `audit-mode` | `memory-audit` / budget debug | Line counts, tokens, threshold breaches |
| `compaction-mode` | Over line/token threshold | Cut prose 30–50%; keep `##` headings and `LH-*` |
| `decay-archival` | Outdated LH-* | Move to `deprecated-heuristics.md` |

## Step-by-Step Execution Workflow

1. **Pre-flight**:
   - `python3 corebase-specharness/scripts/core/cli.py memory-audit --json`.
   - `python3 corebase-specharness/scripts/core/cli.py memory-gate --json`.

2. **Mode**:
   - *Post-Ship Sync*: process every `[CANDIDATE]` per `references/extraction-triage.md`. Promote only with recurrence or independent evidence. Merge duplicates. Stamp `<!-- triaged: true, date: YYYY-MM-DD -->`.
     - **Incident-to-eval**: If a candidate records a repeated agent failure, a missed AC, or a skill/prompt regression, convert it to an eval fixture before promotion. Prefer `python3 corebase-specharness/scripts/core/cli.py eval-run --from-feature <slug>` when the feature artifacts still exist; otherwise add `evals/cases/case_<slug>.json` with a rubric that fails on the same defect. Do not promote the heuristic until the fixture exists.
   - *Audit*: report size/token findings. Doc drift → `EXTERNAL_SKILLS.md`.
   - *Compact*: snapshot `<file>.bak` and `<file>.ids_before`. Cut 30–50% to bullets without rewriting meaning. Keep every `##` heading and stable ID (`LH-*`, `INV-*`, `ADR-*`, `T-*`, `AC-*`). Halt if `.ids_after` ≠ `.ids_before`. Stop if draft would cut >60%.
   - *Decay*: keep `LH-*` heading, mark `[ARCHIVED]`, append body to `deprecated-heuristics.md`. Do not reuse IDs.

3. **Verify & close**:
   - Re-run `python3 corebase-specharness/scripts/core/cli.py memory-audit --json`.
   - `python3 corebase-specharness/scripts/core/cli.py session-end --feature <slug>`.

## Anti-Patterns & Red Flags

- Promoting single-session noise without recurrence.
- Promoting a repeated agent failure without an eval fixture that would catch it.
- Deleting `LH-*` during compaction.
- Cutting >60% of prose.
- Splitting files without `promotions.md`.

## Core Rules

- Promoted edits MUST trace to a recorded observation.
- Single-session items are deferred unless hard safety/data-loss.
- Stable IDs MUST NEVER be deleted during compaction.
- Record only observed facts.
