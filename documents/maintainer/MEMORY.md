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
| Instruction | `corebase-specharness/memories/repo/core-policies.md` | Every context load | Mandatory policy bootstrap |
| Domain | `corebase-specharness/memories/domain/<name>/` (`glossary.md`, `patterns.md`, `anti-patterns.md`, `boundaries.md`, optional `spec.md`) | Intent match on `glossary.md` `triggers`, or an explicit route source | Adopter-owned domain language and invariants |
| Session and extracts | `.corebase-specharness/sessions/<slug>/session.md`, `artifacts/features/<slug>/session-extracts.md` | Session commands and route-declared feature artifacts | Working state and candidate observations |
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

1. Universal bootstrap (`core-policies.md`).
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
and a session exists at `.corebase-specharness/sessions/<slug>/session.md` with
`last_context_fingerprint` metadata, later loads use that cache
automatically. The cache is the union of every pack loaded in the session,
not only the last skill, and compares H2 slices when a file was loaded by
section. `--full` returns the complete pack. Auto-delta is valid only while
the skipped files are still in **this conversation**. After a conversation
compact or on the first skill of a new chat for the same feature, the agent
must pass `--full`. The compiler does not detect those events. See
[Conversation vs feature session](#conversation-vs-feature-session-compact-and-new-chat).

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
| `max_bootstrap_tokens` | 1,200 |
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
3. **Session auto-delta**: omitting `--full` in the same uncompacted chat
   lets `last_context_fingerprint` / `last_context_slices` in `session.md`
   drop unchanged sources on later loads. After compact or a new chat on
   the same feature, pass `--full` once, then omit it again. Measured
   isolated vs sequential pack tokens are in [TOKEN-COST.md](TOKEN-COST.md).
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
  `record_context_pack()` merges `last_context_fingerprint` (a map of
  `{file_path: sha256_hash}`) and `last_context_slices` (a map of
  `{file_path: {section_or_empty: sha256_hash}}`) into the front matter of
  `.corebase-specharness/sessions/<slug>/session.md`, and updates `token_usage_estimate`.
  The baseline is the union of every pack loaded in this session, so a source
  injected by `/spec-requirements` remains known to `/spec-plan`.
- **Delta Comparison**: Subsequent `context-load` or `skill-enter` calls check
  `last_pack_manifest()`. If an existing fingerprint baseline exists and
  `--full` was not specified:
  - Each candidate file is hashed and compared against `session.md`.
  - Unchanged files are omitted from the pack.
  - If a later skill requests extra H2 sections of a file already loaded,
    only the new or changed sections are injected.
  - New or modified files are marked with `delta_reason: "new"` or `"changed"`.
  - The pack metadata sets `delta: true`, records `baseline_selected`,
    `unchanged_selected`, and `delta_omitted`, and re-computes
    `estimated_tokens` for changed items only. Skipped sources are not
    warnings.
- **Token Impact**: On a kit-seed probe (`cl100k_base`), the delivery path
  `/spec-research` → `/spec-requirements` → `/spec-plan` → `/spec-tasks` →
  `/spec-implement` (`--task T-001`) injects **2,536** pack tokens sequentially
  vs **4,946** if each skill loaded in isolation. The second implement turn
  injects only the changed task excerpt (78 tokens). Full tables:
  [TOKEN-COST.md](TOKEN-COST.md).
- **Cache Invalidation**: Passing `--full` bypasses auto-delta and reloads
  the **current skill’s** complete route pack from disk. It does not wipe
  `session.md`, start a new feature, or replay earlier skills’ packs.
  `session-end` sets `closed` and does **not** clear
  `last_context_fingerprint` / `last_context_slices`.

## Conversation vs feature session (compact and new chat)

The user only types skills (`/spec-research`, `/spec-requirements`,
`/spec-plan`, …). They do not run Python. Auto-delta is an optimization
inside `skill-enter` / `context-load`. It has one assumption: **files
already injected are still in this conversation**. Conversation compact
and a new chat both break that assumption. The compiler cannot see either
event.

### Two memories that do not talk to each other

| Store | Path / lifetime | What it holds | Who updates it |
| --- | --- | --- | --- |
| Chat (this conversation) | The model’s token window | File bodies actually shown to the agent | Compact, new chat, or normal turn eviction |
| Feature session (disk) | `.corebase-specharness/sessions/<slug>/session.md` | SHA-256 hashes of injected files and H2 sections (`last_context_fingerprint`, `last_context_slices`) | Every successful `context-load` / `skill-enter` via `record_context_pack()` |

The next skill only asks the disk file: “have I already injected this
exact text for this feature?” It never asks the chat: “do you still have
that text in front of you?”

Hashes **union** across skills. `/spec-plan` still knows files
`/spec-research` and `/spec-requirements` injected. `session-end` does
not delete those maps. Reopening the same slug keeps them.

`--full` is an agent flag, not a user command. The user types the skill
and, when needed, says reload context / reload everything.

### What a later skill actually does

You type `/spec-plan`. The agent enters that skill. The compiler:

1. Looks up the plan route (files and H2s plan needs).
2. Reads `session.md` for that feature slug.
3. For each candidate:
   - **Same hash** → skip. Do not paste. Do not spend budget on it.
   - **File never seen** → inject the requested slice.
   - **File seen, extra H2s needed** → inject only the new headings.
   - **File changed on disk** (hash differs) → inject the new text.
4. Then applies token budgets to what is still left.

Skip happens **before** budget. Sequential `/spec-plan` can include
`code-design.md` that isolated plan often drops, because bootstrap was
skipped and the bootstrap channel still has room. Measured packs:
[TOKEN-COST.md](TOKEN-COST.md).

### Case 1 — compact this conversation

Same chat, same feature. The window was compacted.

| Still true after compact | Usually no longer true |
| --- | --- |
| Fingerprints in `session.md` | Full bodies of `core-policies.md`, architecture H2s |
| Feature files on disk (`spec.md`, `plan.md`) | Those files sitting in the live prompt |
| Feature slug | |

Typical sequence:

1. `/spec-research` — full pack. Hashes written. Chat contains those files.
2. `/spec-requirements` — injects only new sources. Chat still has bootstrap.
3. User compact. Product replaces a long prefix with a summary. File bodies are often gone.
4. User types `/spec-plan` with no reload phrase.

At step 4 the compiler still skips `core-policies.md`,
`status.md`, and architecture H2s research already loaded. Plan only gets
what is new. The agent has a summary plus that small delta — **not** the
skipped rule files.

That is a stale pack. On the next skill, pass `--full`. That enter injects
the complete pack **for that skill’s route**. Hashes refresh for what was
just injected. Later skills in this compacted chat can delta again.

`/context-memory` compacting a **memory Markdown file on disk** is a
different action. That rewrite changes the file hash. If a later skill
still needs that file, it is treated as changed and re-injected. It does
not restore dropped chat history.

### Case 2 — new chat, same feature

The new conversation is empty. `session.md` is not. It still has hashes
from the previous chat.

The first skill in the new chat, if the agent omits `--full`, skips almost
every overlapping file. The agent may run `/spec-plan` (or implement, or
verify) without bootstrap rules.

Correct first move: type the skill **and** reload context. After that,
same-chat sequential skills omit `--full` again.

### Case 3 — new feature

A new slug creates `.corebase-specharness/sessions/<new-slug>/session.md` with empty
hashes. The first skill is a full pack with no extra phrase.
Compact/new-chat rules from the previous feature do not apply.

### Side-by-side

| User action | Chat still has the old files? | Disk still has hashes? | Next skill without reload | What the user types | What the agent does |
| --- | --- | --- | --- | --- | --- |
| Keep calling skills in the same uncompacted chat | Yes | Yes | Delta (correct) | `/spec-plan` | Omit `--full` |
| Compact, then next skill | Often no | Yes | Delta (under-injects) | Skill + reload everything | Pass `--full` once |
| New chat, same feature | No | Yes | Delta (under-injects) | First skill + reload everything | Pass `--full` on first enter |
| New feature | No | No (new `session.md`) | Full pack | The skill | Omit `--full` |
| Files edited on disk after they were loaded | Maybe a stale copy in chat | Old hashes | Re-injects **changed** files only | Reload if the whole pack is needed | `--full` if the whole route pack is required |
| `/context-memory` compacted a memory file | Maybe an old copy | Hash will change | That file is re-injected if the next route still needs it | Nothing extra for auto-delta | Omit `--full` unless chat compact also happened |

### What `--full` does and does not do

**Does**

- Inject the complete pack for **that** skill’s route (bootstrap plus that skill’s files/H2s).
- Refresh hashes for what was just injected.
- Restore the “files are in this chat” assumption for later skills in **this** chat.

**Does not**

- Wipe `session.md`.
- Start a new feature.
- Replay every previous skill’s pack. `/spec-plan` with `--full` loads
  **plan’s** full pack, not research + requirements + plan stacked.
- Help the next new chat. A later new chat needs `--full` again on its
  first skill.
- Get detected automatically. There is no conversation id in `session.md`.

### Failure if nobody reloads

The agent still runs the skill. It is not given `core-policies.md` /
overlapping architecture again. It may follow a
summary, guess, or miss a rule that was supposed to stay in context.
Auto-delta is safe only while this conversation still holds what was
skipped.

Agent procedure: `kit/skills/_shared/context-loading.md`.

## Bounded local evidence retrieval

Automatic retrieval in `_retrieve_local_evidence()` gathers repository
snippets based on the active `--intent`, `--feature`, and `--task` without
dumping files into the context window.

- **Configuration (`corebase-specharness/project/harness-config.yaml`)**:
  - `context.retrieval.roots`: Repositories can constrain search to active
    source trees (e.g. `[src, lib]`) instead of scanning root `"."`.
  - `context.retrieval.exclude`: Directories excluded from retrieval
    (default: `.git`, `.corebase-specharness`, `node_modules`, `dist`, `build`, `coverage`).
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
   • Normative rule?      ──► Amend core-policies.md (## Normative Rules)
   • Domain concept?      ──► Add to memories/domain/<name>/ or glossary.md
   • One-off / noise?     ──► Discard with reason in session-extracts.md
       │
       ▼
4. Compaction Mode (when memory-audit warns):
   • Create snapshot backup (.bak and .ids_before)
   • Compress prose by 30–50% (convert prose paragraphs to bullets)
   • Mandatory rule: preserve every ## heading and every stable ID (LH-*, ADR-*, AC-*)
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
.git  .corebase-specharness  .venv  node_modules  vendor  dist  build
coverage  __pycache__  corebase-specharness  skills  references  artifacts
```

`retrieval.exclude` from `harness-config.yaml` is unioned onto that set. The
seeded exclude list is `.git`, `.corebase-specharness`, `node_modules`, `dist`, `build`,
`coverage`.

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
procedure. That rewrites durable Markdown on disk. It is not conversation
compact and does not reset auto-delta hashes.

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
| Core normative rules | `core-policies.md` | Repo-wide rule that prevents recurring failure |
| Domain language or patterns | `corebase-specharness/memories/domain/<name>/` | Terminology, patterns, anti-patterns, or boundaries |
| Resolved domain terms | `corebase-specharness/project/glossary.md` | Terms crystallized during grilling or research |

Only verified, evidence-backed lessons are promoted. One-off feature noise
stays in feature artifacts. Merge a semantic duplicate instead of appending
a second `LH-*` or duplicate rule.

Compaction reduces prose volume while preserving:

- stable identifiers (`LH-*`, `ADR-*`, `AC-*`)
- Markdown `##` section headings

Superseded heuristics are archived in
`corebase-specharness/memories/archive/deprecated-heuristics.md`.

## Adopter-owned memory files

| File | Purpose | Edit policy |
| --- | --- | --- |
| `corebase-specharness/memories/repo/core-policies.md` | Adopter constitution: normative rules, `## Known Broken Tests`, `## Security Policy` | Stable — edit when global repository rules change |
| `corebase-specharness/memories/repo/project-knowledge-base.md` | Adopter system facts and `## Preserved Behavior Baseline` | As system design evolves |
| `corebase-specharness/memories/repo/learned-heuristics.md` | Operational lessons (`LH-*`) | Append via `/context-memory` |
| `corebase-specharness/memories/repo/adr-log.md` | ADR summaries (`ADR-*`) | Appended via `/spec-adr` and `adr-generate` |
| `corebase-specharness/memories/domain/<name>/` | Domain packs | Updated during delivery and post-ship sync |

## Common patterns

| Situation | Action |
| --- | --- |
| Context source omitted | Run `context-explain --skill <name> --feature <slug> --json` |
| Conversation compacted, or new chat on an existing feature | Next skill with reload context; agent passes `--full`. Not the same as `/context-memory` file compaction. |
| Memory file growing large | Run `memory-audit --json`; invoke `/context-memory` compaction |
| Pre-commit or CI check | Run `memory-gate --mode advisory --json` |
| New domain discovered | Create `corebase-specharness/memories/domain/<name>/` with `glossary.md` and related files |
| Duplicate rules identified | Consolidate into a single normative policy in `core-policies.md` |

## Related documents

- Workflow guide: [WORKFLOW.md](WORKFLOW.md)
- Token cost (isolated vs session auto-delta): [TOKEN-COST.md](TOKEN-COST.md)
- Compact / new-chat auto-delta (this document): [Conversation vs feature session](#conversation-vs-feature-session-compact-and-new-chat)
- Harness and gates: [HARNESS.md](HARNESS.md)
- Kit architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Installation guide: [INSTALL.md](INSTALL.md)
