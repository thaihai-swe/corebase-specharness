# Memory and context

> **Audience:** platform engineers, adopter maintainers, coding agents
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/references/context-routes.yaml`,
> `kit/corebase-specharness/scripts/core/context_engine.py`,
> `kit/corebase-specharness/project/harness-config.yaml`,
> `kit/corebase-specharness/scripts/core/handlers/diagnostics/memory.py`

## Memory tiers

| Tier | Primary paths | Load trigger | Role |
| --- | --- | --- | --- |
| Instruction | `corebase-specharness/rules/caveman.md`, `corebase-specharness/memories/repo/core-policies.md` | Every context load | Mandatory communication and policy bootstrap |
| Domain | `corebase-specharness/memories/domain/<name>/` (`glossary.md`, `patterns.md`, `anti-patterns.md`, `boundaries.md`, optional `spec.md`) | Intent match on `glossary.md` `triggers`, or an explicit route source | Adopter-owned domain language and invariants |
| Session and extracts | `.corezero/sessions/<slug>/session.md`, `artifacts/features/<slug>/session-extracts.md` | Session commands and route-declared feature artifacts | Working state and candidate observations |
| Durable repo memory | `learned-heuristics.md`, `project-knowledge-base.md`, `core-policies.md`, `adr-log.md` | Explicit skill route declarations | Compacted, evidence-backed repository knowledge |

The promotion flow is:

```text
Working observation → session checkpoint → session extract
→ context-memory triage → promote, merge, reject, or archive
```

`context-memory` owns this procedural review. The runtime does not
auto-promote memory.

## Context routing

`references/context-routes.yaml` is the only context-routing authority. Every
context compilation requires an explicit `--skill`. There is no compiled
context index and no phase-only fallback.

Compilation order in `build_context_pack`:

1. Universal bootstrap (`caveman.md`, `core-policies.md`).
2. Route-declared `sources`.
3. Route `feature_artifacts`, plus `status.md` as `Must` for every skill
   except `starter-init` when a feature is supplied. Missing feature
   artifacts are recorded as `Should`.
4. A compact `tasks.md` payload when `--task T-NNN` matches a checkbox
   header: the active task, its direct dependencies, and a progress line.
   The full `tasks.md` is omitted in that case.
5. Repeatable `--add-source` paths.
6. Intent-matched domain packs.
7. Bounded automatic local retrieval.

The engine discovers intent-matched domain packs beneath
`corebase-specharness/memories/domain/`. Nested packs live at
`corebase-specharness/memories/domain/<name>/glossary.md`. A pack is selected when its
`glossary.md` frontmatter has a `triggers: [...]` entry intersecting the
request-intent tokens. The shipped example pack is
`corebase-specharness/memories/domain/example/`. If no nested pack matches, a leftover
flat `corebase-specharness/memories/domain/glossary.md` is still accepted for older
installs. Up to configured `retrieval.max_domain_packs` (default 3) packs
and `max_domain_files` (default 5) files per pack (`glossary.md`,
`patterns.md`, `anti-patterns.md`, `boundaries.md`, `spec.md`) are added as
`Should` durable-memory sources.

```bash
python3 corebase-specharness/scripts/core/cli.py context-pack \
  --skill spec-plan --feature <slug> --intent "design change" --json

python3 corebase-specharness/scripts/core/cli.py context-load \
  --skill spec-plan --feature <slug> --intent "design change" --json

python3 corebase-specharness/scripts/core/cli.py context-explain \
  --skill spec-plan --feature <slug> --intent "design change" --json
```

For skills with `feature: required`, `--feature` is mandatory.

A pack contains:

- universal communication and policy bootstrap
- route-declared feature artifacts and `Must` or `Should` sources
- a task excerpt when `--task` is supplied
- matching domain memory
- bounded automatic local evidence

`Must` sources are retained even if they overrun the requested payload or a
channel limit. The overrun is reported. `Should` sources may be omitted to
stay within budget. Use repeatable `--add-source <repository-relative-path>`
only for a focused expansion. `--add-source` must be repository-relative, must
not contain `..`, must not match an excluded path or sensitive filename, and
must exist. When `retrieval.pinnable_sources` is configured, the path must
also match one of those globs.

`--delta-from <previous-pack.json>` keeps only selected sources whose
content fingerprint changed. When `--delta-from` and `--full` are omitted
and a session exists at `.corezero/sessions/<slug>/session.md` with
`last_context_fingerprint` metadata, later loads use that cache
automatically. `--full` returns the complete pack.

## Token estimation and tokenizer modes

Token estimation is implemented in `corebase-specharness/scripts/core/_lib/token_counter.py`.

- **Exact tokenizer mode (`cl100k_base`)**:
  When `tiktoken` is available in Python, `estimate_tokens(text)` encodes using the OpenAI `cl100k_base` BPE vocabulary: `len(encoding.encode(text))`.
- **Heuristic mode (`chars_per_token_estimate`)**:
  When running on standard-library Python without `tiktoken`, `estimate_tokens(text)`
  computes `int(len(text) / 4.0)`.
- **Manifest observability**:
  Every generated context pack records `"tokenizer": "cl100k_base"` or `"tokenizer": "chars_per_token_estimate"` in its manifest so agents and diagnostics know whether numbers are exact or heuristic.

## Profiles and budgets

Configured in `corebase-specharness/project/harness-config.yaml` under `context`:

| Profile | Target direct skill | Default payload tokens |
| --- | --- | ---: |
| `bootstrap` | `/starter-init` | 2,500 |
| `research` | `/spec-research` | 4,000 |
| `requirements` | `/spec-requirements` | 3,500 |
| `planning` | `/spec-plan`, `/spec-tasks`, `/spec-adr` | 3,500 |
| `implement` | `/spec-implement` | 4,000 |
| `verify` | `/harness-verify`, `/harness-maintain`, `/spec-testing-scenario` | 3,500 |
| `compact` | `/context-memory` | 2,500 |

Shipped global and channel limits:

| Setting | Value |
| --- | ---: |
| `max_injected_tokens` | 6,000 |
| `reserve_tokens` | 1,500 |
| `max_bootstrap_tokens` | 800 |
| `max_project_tokens` | 1,200 |
| `max_feature_tokens` | 1,600 |
| `max_retrieved_tokens` | 1,000 |
| `max_source_excerpt_tokens` | 400 |
| `max_retrieval_files` | 4 |
| `max_tool_output_tokens` | 800 |
| `payload_budget` | 2,500 |

Budget math: the selected profile payload (or `--budget`) is capped by
`max_injected_tokens - reserve_tokens`, with a floor of 1. New-install
seed is reserve `1500` against `max_injected_tokens 6000`, so the
effective ceiling is **4500**. Profile payloads are capped at that
ceiling. Existing adopter `harness-config.yaml` is copy-if-missing and
keeps its previous seed.

Session FinOps thresholds (`thresholds` in the same file):

| Setting | Value | Purpose |
| --- | ---: | --- |
| `session_warn_tokens` | 40,000 | `status` and context commands warn that the session should be ended |
| `session_hard_tokens` | 80,000 | `status` and context commands report a hard-budget breach |

When a skill route includes `session.md`, the pack injects a bounded summary
(`Objective`, latest progress/handoff, and the last five recorded decisions)
instead of the append-only ledger.

## Token-cost levers

Lowering numeric seed budgets in `harness-config.yaml` is not the main lever:
kit packs already sit below profile ceilings, and `Must` sources stay even on
overflow. Real token savings come from:

1. **Task-scoped implement turns**: `spec-implement` calls `task-check`,
   locks `task-start`, then reloads `context-load --task T-NNN`. The compiler
   omits full `tasks.md` and passes only the active task and direct dependencies.
2. **Route section slices**: `references/context-routes.yaml` slices Markdown
   sources to specific H2 `sections:` instead of injecting full documents.
3. **Session auto-delta**: omitting `--full` lets `last_context_fingerprint` in
   `session.md` drop unchanged sources on later loads.
4. **Short intent keywords**: `--intent` scores inside route files; long
   essay prompts increase input cost without helping retrieval.
5. **Targeted `--add-source`**: explicit repo-relative paths replace broad
   tree scans.
6. **Memory compaction**: running `/context-memory` when `memory-audit` warns
   keeps instruction/bootstrap memory small.

## Dynamic task-scoped context injection

During implementation, full `tasks.md` files grow with historical checkboxes,
traceability lines, and completion timestamps. To keep context compact:

- When `context-load` or `skill-enter` is invoked with `--task <T-NNN>`,
  `context_engine.py` calls `_task_context_payload()`.
- It parses `tasks.md` with `core.task_graph.parse_tasks()` and extracts:
  1. High-level progress summary (e.g. `2/10 tasks completed`).
  2. Active task block (`id`, `header`, `status`, `depends`, `covers`, `proof`).
  3. Direct prerequisite task blocks (`depends on: T-001`).
- The full `tasks.md` is **omitted from the pack**, replacing 500–2,000 tokens
  with a compact 80–150 token payload.
- In `skills/spec-implement/SKILL.md`, the loop is: `task-check` $\rightarrow$ `task-start --task T-NNN` $\rightarrow$ `context-load --task T-NNN` $\rightarrow$ TDD code/proof $\rightarrow$ `task-done --evidence "..."`.

## Session auto-delta caching

CoreBase SpecHarness optimizes multi-turn conversations by computing SHA-256 content
fingerprints for every selected source in the context pack.

- **Baseline Storage**: On each successful context load,
  `record_context_pack()` persists `last_context_fingerprint` (a map of
  `{file_path: sha256_hash}`) and updates `token_usage_estimate` in the front
  matter of `.corezero/sessions/<slug>/session.md`.
- **Delta Comparison**: Subsequent `context-load` or `skill-enter` calls check
  `last_pack_manifest()`. If an existing fingerprint baseline exists and
  `--full` was not specified:
  - Each candidate file is hashed and compared against `session.md`.
  - Unchanged files are omitted from the pack.
  - New or modified files are marked with `delta_reason: "new"` or `"changed"`.
  - The pack metadata sets `delta: true`, records `baseline_selected` and
    `unchanged_selected`, and re-computes `estimated_tokens` for changed items only.
- **Token Impact**: Reduces prompt tokens from ~1,500–2,500 down to ~200–400 on
  consecutive turns (a 60–80% saving per turn).
- **Cache Invalidation**: Passing `--full` bypasses auto-delta and reloads all
  sources from disk.

## Bounded local evidence retrieval

Automatic retrieval in `_retrieve_local_evidence()` gathers repository
snippets based on the active `--intent`, `--feature`, and `--task` without
dumping files into the context window.

- **Configuration (`corebase-specharness/project/harness-config.yaml`)**:
  - `context.retrieval.roots`: Repositories can constrain search to active
    source trees (e.g. `[src, lib]`) instead of scanning root `"."`.
  - `context.retrieval.exclude`: Directories excluded from retrieval
    (default: `.git`, `.corezero`, `node_modules`, `dist`, `build`, `coverage`, `corebase-specharness/generated`).
  - `context.max_retrieval_files`: Maximum number of files admitted to
    candidate scoring (seed default: 4). Profiles may override with
    `retrieval_files` (`bootstrap`, `verify`, and `compact` seed `0`).
  - `context.max_source_excerpt_tokens`: Max tokens extracted per matching
    file (seed default: 400).
  - `context.max_retrieved_tokens`: Total token ceiling across all retrieved
    excerpts (seed default: 1,000).
- **Secret Redaction**: Every retrieved snippet passes through
  `redact_secrets()`, which scrubs API keys, AWS tokens, GitHub tokens, and
  private keys before context assembly.
- **Scoring & Suffix Ranking**: Candidates are scored by keyword occurrence in
  plain text files (<256 KB) and prioritized by file extension
  (`DEFAULT_SUFFIX_PRIORITY`).

## Durable memory and compaction lifecycle

Durable memory prevents repetitive mistakes while staying within bounded line
and token thresholds.

```text
[Feature Delivery]
       │
       ▼
1. Candidate Extraction: Append non-trivial findings as [CANDIDATE] in session-extracts.md
       │
       ▼
2. Verification Gate: /harness-verify verifies gates, writes review.md + ## Post-Ship Sync
       │
       ▼
3. Post-Ship Sync: /context-memory triages candidates:
   • Recurring heuristic? ──► Append/Merge into learned-heuristics.md (LH-NNN)
   • Normative rule?      ──► Amend core-policies.md (CC-NNN)
   • Domain concept?      ──► Add to memories/domain/<name>/ or glossary.md
   • One-off / noise?     ──► Discard with reason in session-extracts.md
       │
       ▼
4. Compaction Mode (when memory-audit warns):
   • Create snapshot backup (.bak and .ids_before)
   • Compress prose by 30–50% (convert prose paragraphs to bullets)
   • Mandatory rule: preserve every ## heading and every stable ID (LH-*, CC-*, ADR-*, REQ-*, AC-*)
   • Validate .ids_after matches .ids_before exactly
       │
       ▼
5. Decay & Archival:
   • Tombstone superseded heuristics in learned-heuristics.md
   • Append full deprecated entries to memories/archive/deprecated-heuristics.md
```

Channels and their limits:

| Channel | Limit source | Used for |
| --- | --- | --- |
| `bootstrap` | `max_bootstrap_tokens` | Universal communication and policy files |
| `project` | `max_project_tokens` | Route project sources |
| `feature` | `max_feature_tokens` | Feature artifacts and `status.md` |
| `task` | `max_feature_tokens` | Active-task excerpt |
| `retrieved` | `max_retrieved_tokens` | Automatic local evidence |
| `durable_memory` | `max_project_tokens` | Domain packs |
| `explicit` | `max_project_tokens` | `--add-source` |

`Must` sources ignore both the payload ceiling and channel limits and report
the overrun.

## Retrieval policy

Automatic retrieval applies suffix priorities, filters by
`retrieval.suffix_allowlist` when configured, permits pinning repository-
relative glob patterns declared in `retrieval.pinnable_sources`, and redacts
detected secrets.

Built-in exclusions (`DEFAULT_RETRIEVAL_EXCLUDES`):

```text
.git  .corezero  .venv  node_modules  vendor  dist  build
coverage  __pycache__  corebase-specharness  skills  references  artifacts
```

`retrieval.exclude` from `harness-config.yaml` is unioned onto that set. The
seeded exclude list is `.git`, `.corezero`, `node_modules`, `dist`, `build`,
`coverage`, `corebase-specharness/generated`.

Additional filters:

- `.gitignore` patterns (non-negated, non-comment lines)
- sensitive filenames: `.env`, `.env.local`, `.env.production`, `id_rsa`,
  `id_ed25519`, and any name starting `.env`
- binary suffixes: `.png`, `.jpg`, `.jpeg`, `.gif`, `.pdf`, `.zip`, `.gz`,
  `.lock`
- `suffix_allowlist` when configured (case-insensitive)
- `suffix_priority` overrides, otherwise the built-in map
  (`.md` 50, `.rst` 45, `.txt` 40, common source 35, yaml/json/toml 30,
  ini/cfg 25)

Secret-redaction pattern classes:

- key / secret / token / password assignments with a value of 8+ characters
- AWS-style `AKIA` / `ASIA` keys
- GitHub tokens matching `gh[opusr]_`
- PEM private-key blocks

Default retrieval settings when the keys are absent: `max_domain_packs` 3,
`max_domain_files` 5, `roots` `["."]`.

## Diagnostics

```bash
python3 corebase-specharness/scripts/core/cli.py memory-audit --json
python3 corebase-specharness/scripts/core/cli.py memory-gate --mode advisory --json
```

Evaluated paths:

- `corebase-specharness/memories/repo/core-policies.md`
- `corebase-specharness/memories/repo/learned-heuristics.md`
- `corebase-specharness/memories/repo/project-knowledge-base.md`
- `corebase-specharness/memories/repo/adr-log.md`
- any `corebase-specharness/memories/domain/**/*.md`

`memory-audit` accepts `--mode` in the parser and **ignores it**. It returns
`failed` only when any inspected file reaches the hard cap. Warning-level
files are reported as warnings with status `ok`. `details.semantic_summary`
also reports active vs archived heuristics and ADR counts.

`memory-gate` return behavior depends on `--mode`:

- `advisory`: report warnings and hard-cap breaches without failing
- `warn`: fail if any file reaches `memory_warn_lines` or `memory_hard_lines`
- `block`: fail if any file reaches `memory_hard_lines`

Seeded thresholds in `harness-config.yaml` are `memory_warn_lines: 200` and
`memory_hard_lines: 3200`. The code fallback is `100` / `3200` if the key is
absent.

These commands are read-only. Compaction is an explicit `/context-memory`
procedure.

## Promotion and compaction

`/context-memory` modes (procedure, not runtime):

| Mode | Trigger | Output |
| --- | --- | --- |
| `post-ship-sync` | After `/harness-verify` writes `## Post-Ship Sync` and exits to `Done` | Triage `[CANDIDATE]` items |
| `audit-mode` | `memory-audit` / budget debugging | Size and token report |
| `compaction-mode` | File exceeds line/token threshold | Reduce prose 30–50% while keeping `##` headings and stable IDs |
| `decay-archival` | Superseded `LH-*` | Move body to `deprecated-heuristics.md` |

| Source | Destination | Criteria |
| --- | --- | --- |
| Session extracts | `learned-heuristics.md` (`LH-*`) | Recurring or hard safety lesson; merge duplicates |
| Feature or architecture facts | `project-knowledge-base.md` | Facts that outlive the feature |
| Core normative rules | `core-policies.md` (`CC-*`) | Repo-wide rule that prevents recurring failure |
| Domain language or patterns | `corebase-specharness/memories/domain/<name>/` | Terminology, patterns, anti-patterns, or boundaries |
| Resolved domain terms | `corebase-specharness/project/glossary.md` | Terms crystallized during grilling or research |

Only verified, evidence-backed lessons are promoted. One-off feature noise
stays in feature artifacts. Merge a semantic duplicate instead of appending
a second `LH-*` or `CC-*`.

Compaction reduces prose volume while preserving:

- stable identifiers (`LH-*`, `CC-*`, `ADR-*`, `REQ-*`, `AC-*`)
- Markdown `##` section headings

Superseded heuristics are archived in
`corebase-specharness/memories/archive/deprecated-heuristics.md`.

## Adopter-owned memory files

| File | Purpose | Edit policy |
| --- | --- | --- |
| `corebase-specharness/memories/repo/core-policies.md` | Adopter constitution: `CC-*` rules, `## Known Broken Tests`, `## Security Policy` | Stable — edit when global repository rules change |
| `corebase-specharness/memories/repo/project-knowledge-base.md` | Adopter system facts and `## Preserved Behavior Baseline` | As system design evolves |
| `corebase-specharness/memories/repo/learned-heuristics.md` | Operational lessons (`LH-*`) | Append via `/context-memory` |
| `corebase-specharness/memories/repo/adr-log.md` | ADR summaries (`ADR-*`) | Appended via `/spec-adr` and `adr-generate` |
| `corebase-specharness/memories/domain/<name>/` | Domain packs | Updated during delivery and post-ship sync |

## Common patterns

| Situation | Action |
| --- | --- |
| Context source omitted | Run `context-explain --skill <name> --feature <slug> --json` |
| Memory file growing large | Run `memory-audit --json`; invoke `/context-memory` compaction |
| Pre-commit or CI check | Run `memory-gate --mode advisory --json` |
| New domain discovered | Create `corebase-specharness/memories/domain/<name>/` with `glossary.md` and related files |
| Duplicate rules identified | Consolidate into a single normative policy in `core-policies.md` |

## Related documents

- Workflow guide: [WORKFLOW.md](WORKFLOW.md)
- Harness and gates: [HARNESS.md](HARNESS.md)
- Kit architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Installation guide: [INSTALL.md](INSTALL.md)
