# Session auto-delta

> **Audience:** platform engineers, adopter maintainers, coding agents
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/corebase-specharness/scripts/core/context_engine.py`,
> `kit/corebase-specharness/scripts/core/context_state.py`,
> `kit/corebase-specharness/scripts/core/handlers/context.py`,
> `kit/corebase-specharness/references/context-routes.yaml`

Session auto-delta is the context compiler's incremental loading and caching engine. It eliminates redundant prompt tokens across consecutive skills in the same feature delivery session by diffing files and Markdown H2 sections against an accumulated session baseline before enforcing budget limits.

---

## 1. Problem and objectives

In CoreBase SpecHarness, delivering a feature walks a multi-phase skill lifecycle:
`/spec-research` → `/spec-requirements` → `/spec-plan` → `/spec-tasks` → `/spec-implement` → `/harness-verify`.

Each skill requires context:
- Mandatory instruction bootstrap (`core-policies.md`).
- Project architecture, constraints, and coding rules.
- Upstream feature deliverables (`status.md`, `spec.md`, `plan.md`, `tasks.md`).

Without intelligent delta loading:
1. **Redundant token spend:** Over 60%–80% of prompt payload on later turns re-injects identical files already present in the active chat window.
2. **Channel budget starvation:** Mandatory bootstrap (~366 tokens) loaded before budget checks fills channel caps (e.g. `max_bootstrap_tokens: 1200`), crowding out optional `Should` files (such as `code-design.md`).
3. **Single-turn amnesia:** Naive delta mechanisms only compare against the immediate predecessor skill, forgetting context loaded two skills prior.
4. **All-or-nothing file re-injection:** Needing one additional section from a 1,000-token architecture doc forced reloading the full document.

Session auto-delta solves these challenges by accumulating multi-skill baselines, diffing individual H2 headings, and applying delta skips before budget calculations.

---

## 2. Architectural pipeline

```text
                      Candidate Route Files & Slices
                                    │
                                    ▼
       ┌────────────────────────────────────────────────────────┐
       │             Step 1: Session Baseline Lookup             │
       │   Read session.md: last_context_fingerprint & slices   │
       └────────────────────────────┬───────────────────────────┘
                                    │
                                    ▼
       ┌────────────────────────────────────────────────────────┐
       │             Step 2: Fine-Grained H2 Diffing            │
       │  • File unchanged? ──────────────> delta_omitted (skip) │
       │  • Only 1 new H2 section needed? ─> Slice & inject H2  │
       │  • File changed / brand new? ─────> Full slice inject  │
       └────────────────────────────┬───────────────────────────┘
                                    │
                                    ▼
       ┌────────────────────────────────────────────────────────┐
       │             Step 3: Budget Math on Remainder           │
       │  Skipped files DO NOT count toward payload/channel caps│
       └────────────────────────────┬───────────────────────────┘
                                    │
                                    ▼
       ┌────────────────────────────────────────────────────────┐
       │             Step 4: Union Merge into session.md        │
       │  Merge fingerprints & slices (accumulates all skills)  │
       └────────────────────────────────────────────────────────┘
```

---

## 3. Core mechanisms

### 3.1 Accumulated union baseline
Instead of overwriting previous pack manifests, `record_context_pack()` merges SHA-256 fingerprints into the frontmatter of `.corebase-specharness/sessions/<slug>/session.md`:

```yaml
---
{
  "feature": "my-feature",
  "skill": "spec-plan",
  "last_context_tokens": 769,
  "token_usage_estimate": 1732,
  "last_context_fingerprint": {
    "corebase-specharness/memories/repo/core-policies.md": "a1b2c3...",
    "corebase-specharness/project/architecture.md": "d4e5f6..."
  },
  "last_context_slices": {
    "corebase-specharness/project/architecture.md": {
      "System Snapshot": "7a8b9c...",
      "Safe Change Guidance": "1f2e3d..."
    }
  }
}
---
```

When `/spec-requirements` loads bootstrap, downstream skills (`/spec-plan`, `/spec-tasks`) recognize that those files were already injected earlier in the session.

### 3.2 Fine-grained H2 section diffing
When candidate sources declare specific Markdown `##` headings:
- The engine hashes individual sections via `_slice_fingerprints()`.
- If a prior skill loaded sections `[A, B]` and the current skill requests `[A, B, C]`, only section `C` is extracted, tokenized, and injected.
- The item is flagged with `delta_reason: "changed"`.
- If an entire file was previously loaded without section filters (`""` slice key), all subsequent sub-section requests for that file are skipped automatically.

### 3.3 Skip-before-budget evaluation
Delta evaluation occurs **before** channel and payload budget enforcement:
- Skipped sources are appended to `delta_omitted` with `provenance: "session_delta"`.
- Skipped sources consume **0 tokens** against channel limits (`bootstrap`, `project`, `feature`, `task`, `retrieved`, `durable_memory`).
- This allows optional `Should` sources (e.g. `code-design.md`) to be selected on later turns without exceeding `max_bootstrap_tokens`.

### 3.4 Inspectable pack manifest
Every compiled pack exposes explicit delta diagnostics:
- `delta: true | false` — whether delta baseline comparison was active.
- `delta_from` — baseline source (`"session"` or path to baseline JSON).
- `baseline_selected` — count of unique paths tracked in the baseline.
- `unchanged_selected` — count of sources skipped as unchanged.
- `delta_omitted` — detailed list of skipped sources and token savings.

---

## 4. Conversation vs feature session contract

The system operates across two independent storage environments:

| Storage class | Location / Lifetime | Content | Invalidation trigger |
|---|---|---|---|
| **Chat Memory** | Model Context Window (ephemeral) | Actual rendered text bodies | Conversation compact, context truncation, new chat |
| **Session Cache** | `.corebase-specharness/sessions/<slug>/session.md` (disk) | SHA-256 hash maps (`fingerprints`, `slices`) | Persists across compacts, closes (`session-end`), and reopens |

### The `--full` reload rule
Because the Python CLI cannot inspect the host model's window, it relies on explicit protocol discipline:

| Scenario | Agent action | Rationale |
|---|---|---|
| Same uncompacted chat, sequential skills | Omit `--full` (default delta) | Previous files remain visible in prompt window. |
| After conversation compact | Pass `--full` on next `skill-enter` | Host model evicted text bodies; disk hashes must be re-synced. |
| First skill in a **new chat** on an existing feature | Pass `--full` on first `skill-enter` | New chat has empty prompt context; disk cache contains old hashes. |
| User requests context reload | Pass `--full` | Forces full route pack reload from disk. |
| New feature slug | Omit `--full` | New session file has empty baseline; full pack loads automatically. |

`session-end` marks a session closed but **does not** delete `session.md` or clear hash maps. Reopening a session in a new chat still requires `--full` on the first turn.

---

## 5. Lifecycle token profile

Measured on kit seed with standard `cl100k_base` BPE tokenizer across the canonical delivery lifecycle:

| Skill / Step | Injected Content | Delta Omissions | Pack Tokens |
|---|---|---|:---:|
| **1. `/spec-research`** | Full research pack (Bootstrap + Status + Architecture) | None (initial baseline) | **497** |
| **2. `/spec-requirements`** | `analysis.md`, `product-sense.md`, `project-constraints.md` | `core-policies.md`, `status.md` | **310** |
| **3. `/spec-plan`** | `spec.md`, `code-design.md`, **only** `Safe Change Guidance` | Bootstrap rules, status, prior architecture H2s | **606** |
| **4. `/spec-tasks`** | `plan.md`, `code-design.md` [Read before you write] | All bootstrap, status, spec, architecture | **108** |
| **5. `/spec-implement` (`T-001`)** | `core-policies.md` [Security Policy], task excerpt, `security.md` | General bootstrap, status, spec, plan | **696** |
| **6. `/spec-implement` (`T-002`)** | Active task `T-002` excerpt only | All general files and rules | **78** |

- **Sequential lifecycle pack cost:** **2,373 tokens**
- **Isolated per-turn pack cost:** **4,783 tokens**
- **Lifecycle token savings:** **~49% net reduction**

---

## 6. Related documents

- Memory architecture & budget configuration: [MEMORY.md](MEMORY.md)
- Complete per-skill step and token breakdown: [TOKEN-COST.md](TOKEN-COST.md)
- Context compiler architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Agent context loading procedure: `kit/skills/_shared/context-protocol.md`
