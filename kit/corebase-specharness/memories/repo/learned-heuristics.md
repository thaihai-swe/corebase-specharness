# Learned Heuristics

## Purpose

Append-only ledger of evidence-backed operational heuristics discovered during feature delivery and debugging in this repository. Managed via `/context-memory`.

## Entry Template

<!--
### LH-<NNN>: <Concise Rule Title>
- **Trigger:** <When does this heuristic apply?>
- **Rule:** <Concrete rule or guidance to follow>
- **Evidence:** <Observable failure or feature experience that proved this>
-->

## Heuristics

### LH-001: Task validation proof must be machine-verifiable
- **Trigger:** Defining completion criteria in `tasks.md` or verifying feature implementation.
- **Rule:** Every task must specify a concrete command or test file that runs and exits 0 as its validation proof, rather than subjective text.
- **Evidence:** Subjective or unexecutable proof criteria lead to missed edge cases and unverified completions.

### LH-002: Isolate regression with a focused test before fixing
- **Trigger:** Investigating a bug or regression report.
- **Rule:** Write a failing test reproducing the exact defect before modifying production code; verify the test passes once fixed.
- **Evidence:** Speculative fixes without reproduction tests frequently introduce secondary regressions or mask root causes.
