# CoreBase SpecHarness Design

> **Audience:** maintainers reviewing the as-built kit
> **Status:** as-built, now part of maintainer docs
> **Authority:** `kit/corebase-specharness/scripts/core/`, `kit/references/context-routes.yaml`,
> `kit/corebase-specharness/project/state-machine.yaml`, `kit/skills/*/SKILL.md`

This document explains *why* the kit is shaped the way it is and *how* the
requirements in [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md) are met. It is
not a proposal. Topology and technical design live in
[ARCHITECTURE.md](ARCHITECTURE.md). When
this file disagrees with executable kit behavior, the kit wins.

Operating lookup: [WORKFLOW.md](WORKFLOW.md),
[HARNESS.md](HARNESS.md), [MEMORY.md](MEMORY.md), [REFERENCE.md](REFERENCE.md).

---

## 1. Design thesis

CoreBase SpecHarness is a spec-driven delivery kit. The harness and context compiler are
layers inside it, not the product name. Install is copy-with-seed, not a
starter-template product.

Separate three things that most agent kits collapse:

| Layer | Owner | Changes when |
| --- | --- | --- |
| Procedure | `skills/<name>/SKILL.md` | Humans refine how an agent should think |
| Contract | `references/context-routes.yaml` + `state-machine.yaml` | Maintainers change what the runtime will load, require, and allow |
| Mechanics | `corebase-specharness/scripts/core/` | Maintainers change deterministic checks |

The agent chooses a skill. The route says what to load and what must exist.
The CLI checks files, tokens, and transitions. Nobody in this loop infers the
next product decision.

That split is the whole design. The recent upgrade did not replace it. It
collapsed a leftover *second* control plane (coarse phases vs status tokens vs
named skills) onto one evaluator.

---

## 2. Design principles (as implemented)

1. **Embedded, not hosted.** The kit is files in the adopter repo. Upgrade is
   copy-with-backup, not a service deploy.
2. **Skills first, CLI second.** Slash skills are the human interface. CLI
   commands are mechanical helpers, not a hidden workflow runner.
3. **Peers, not a pipeline object.** The common delivery order is guidance.
   Any skill can be entered directly.
4. **Files are the database.** Feature state, tasks, sessions, memory, and
   config are Markdown/YAML/JSON the owner can read without the CLI.
5. **Fail loud, verify explicitly.** Advisory mode can exit 0. It must not
   claim `verified: true`.
6. **Do not infer.** No skill chooser, no gate discovery, no memory promotion,
   no vendor instruction files.
7. **Stdlib and inspectable.** Python 3.10, no required third-party runtime
   deps, JSON envelopes, atomic writes, path containment.
8. **Upgrade in place.** Kit-owned files overwrite; adopter-owned files seed
   once.

---

## 3. Control-plane design

### 3.1 One evaluator

Before the upgrade, phase-check, skill-exit, and verify each assembled
readiness differently. The implemented design is:

```text
skill route + state machine
        ↓
check_readiness(root, feature, skill=, phase=, target_state=)
        ↓
phase-check / skill-exit / verify
```

`check_readiness` returns facts, not a CLI envelope:

- `failures`
- `current_state`, `target_phase`, `target_state`
- `transition_ok`, `skip_transition`
- `enforcement_mode`
- `route`, `lifecycle`

Handlers decide how to present those facts (`ok` / `deferred` / `failed`) and
whether to mutate status.

### 3.2 Two readiness scopes

| Input | Artifact source | Mechanical extras |
| --- | --- | --- |
| `--skill` | that route's `prerequisites` only | Done extras (`review.md` + Post-Ship Sync) |
| `--phase` | `state-machine.yaml` phase preconditions | Plan / Implement / Verify / Done extras |

This is intentional. `spec-testing-scenario` is a Verify-phase skill that only
needs `spec.md`. If it inherited the coarse Verify file set, it would demand
finished tasks it does not own.

Skills with no `enter`/`exit` skip token-transition checks. Closeout skills
`context-memory` and `harness-maintain` also skip them after `Done` /
`Abandoned`, so post-ship work does not look like an illegal transition.

### 3.3 Status tokens vs coarse phases

`status.md` stores a *token* (`Specifying`, `PlanApproved`, `Verifying`, …).
`phase_mapping` folds tokens into coarse labels (`Spec`, `Plan`, `Implement`,
`Verify`, `Done`) for artifact-check and compatibility `--phase`.

`Lifecycle.check_state_transition` is the token graph.
`Lifecycle.check_transition` is the coarse-phase reachability check used when
no explicit token is supplied.

`status-set` always uses the token graph. `skill-enter` uses it for `enter`.
`skill-exit` uses `check_readiness` plus `apply_status` for `exit`.

### 3.4 Required writes

Route `writes` are the exit contract. The design distinguishes:

- **Required feature files** (`analysis.md`, `spec.md`, `plan.md`, `tasks.md`,
  `review.md`, `testing-scenarios.md`): missing → `skill-exit` fails.
- **Optional / directory writes**: `{path, required: false}` or a suffix-less
  path: ignored.
- **`status.md`**: envelope-owned; routes must mark it `required: false`.

This is a behavior change from the older warn-only exit. It is now the
contract.

---

## 4. Skill and routing design

### 4.1 Why a YAML registry exists

`SKILL.md` is prose. Agents need it. The runtime cannot parse “writes
`spec.md`” out of a paragraph reliably. `context-routes.yaml` is the
machine-readable twin:

- which coarse phase the skill belongs to
- enter/exit tokens
- whether `--feature` is required
- prerequisite files
- feature artifacts to load
- writes to enforce
- legal handoff names
- context sources and tiers
- context profile name

Doctor keeps the two surfaces aligned.

### 4.2 Why skills are peers

A brownfield bugfix may start at `spec-implement`. An already-specified change
may start at `spec-plan`. Forcing `/starter-init` on every feature would
overwrite adopter judgment. The installer and `init` only scaffold; they do
not tailor.

### 4.3 Envelope sequence

The designed agent loop for a feature-bound skill:

```text
skill-enter
  → ensure status.md
  → apply enter token if declared and legal
  → start or resume session
  → context-load (bounded pack + operational SKILL.md summary)
agent follows SKILL.md, writes artifacts
skill-exit
  → validate handoff name
  → fail on missing required writes
  → check_readiness(skill, target_state=exit)
  → apply_status(exit)
  → checkpoint session
```

The CLI never invokes the next skill.

---

## 5. Context design

The context engine exists because dumping the repo into the model is
unverifiable. The pack is a *manifest*:

- selected path, tier, reason, channels, tokens, provenance, trust, fingerprint
- omitted path and reason
- budget, reserve, profile, tokenizer mode

Selection order:

1. Always-on bootstrap policy.
2. Route-declared sources (Must/Should/Skip, optional H2 sections).
3. Feature artifacts from the route, plus `status.md`.
4. Active-task excerpt when `--task` is set.
5. Explicit `--add-source`.
6. Intent-matched domain packs (`glossary.md` `triggers:`).
7. Bounded local retrieval with secret redaction.

Budget rules:

- Profile payload or `--budget`, capped by `max_injected_tokens - reserve_tokens`.
- Token counts come from `estimate_tokens()`: `cl100k_base` via `tiktoken` when
  installed, otherwise `int(len(text) / 4.0)`. The pack records the mode in
  `tokenizer`.
- Must sources always stay, even if they overflow. Overflow becomes a warning.
- Non-Must sources drop when payload or channel caps are exceeded.
- Retrieval has its own file count and excerpt-token caps.
- When `--full` is omitted, session auto-delta runs **before** budget math.
  `record_context_pack()` unions SHA-256 file and H2-section fingerprints into
  `session.md`. A later skill injects only new or changed files and only new
  or changed sections. Skipped sources do not consume channel caps, so a
  later `Should` file is not crowded out by bootstrap already loaded earlier
  in the session. Measured costs: [TOKEN-COST.md](TOKEN-COST.md).
- Auto-delta assumes skipped sources are still in **this conversation**.
  Hashes live in `session.md`; file bodies live in the chat. The compiler
  cannot detect conversation compact or a new chat. `session-end` does not
  clear fingerprints. After compact, or on the first skill of a new chat for
  the same feature, the agent passes `--full`. The user only types the skill
  and, when needed, says reload context. Full rules:
  [MEMORY.md](MEMORY.md#conversation-vs-feature-session-compact-and-new-chat).

`context-pack` / `context-explain` are the inspectable forms and omit file
bodies. `context-load` returns the pack-selected text: declared H2 slices,
task excerpts, and retrieval summaries. It does not re-read whole files when
the pack already chose content.

Intent never searches the whole world. Keyword scoring stays inside files
already admitted to the candidate set, plus the retrieval walk.

See [MEMORY.md](MEMORY.md) for budget math, retrieval policy, and compact /
new-chat auto-delta rules.

---

## 6. Artifact and task design

### 6.1 Feature directory as the unit of work

A feature is a slug and a directory. All durable delivery evidence for that
slug lives there. Sessions are the only ephemeral sibling
(`.corebase-specharness/sessions/<slug>/`).

### 6.2 Spec → tasks → proof

Traceability is string IDs, not a graph database:

- `REQ-*` and `AC-*` in `spec.md`
- `T-NNN` in `tasks.md`, with AC mentions and `Depends on:`
- `Validation evidence:` / `Proof:` on done tasks
- `review.md` for the closeout verdict

`tasks.md` stays human-editable. `tasks.json` is regenerated on mutation so
automation can read a stable schema without parsing Markdown twice. If
`tasks.md` is missing, the sidecar is a read-only fallback and cannot be
mutated.

### 6.3 HALT as a human brake

`[:HALT` in spec/plan/tasks is an agent-authored stop. The task graph refuses
status changes while it is present. That is cheaper and more visible than a
workflow lock table.

See [WORKFLOW.md](WORKFLOW.md) for the token and task transition graphs.

---

## 7. Verification design

Verification is a *composition*, not a new engine:

```text
files_for(skill= | phase=)
        ↓
evaluate_phase_check + evaluate_artifact_check(trace=True)
confirmed gates (argv, timeout, on_fail)
review provider (optional/required)
```

`verified` is the AND of those, and only when not dry-run.

Advisory vs blocking is a presentation policy on the same facts. Advisory
keeps exit 0 and `deferred` so a repo owner can adopt the kit before trusting
gates. Blocking turns the same findings into `failed`.

Gates are adopter-confirmed argv. The seed is empty on purpose. Shell strings
are allowed only with an explicit rationale so accidental `sh -c` does not
become the default.

Providers are a thin registry + local executable check. `verify` only auto-runs
the `review` category. Code-intelligence stays opt-in via `provider-run`.

See [HARNESS.md](HARNESS.md) for the verify verdict and doctor checks.

---

## 8. Memory design

Durable memory is files the adopter owns. The CLI measures; the
`/context-memory` skill decides.

Tiers:

| Store | Role |
| --- | --- |
| `corebase-specharness/memories/repo/` | Repo-wide policies, heuristics, PKB, ADR log |
| `corebase-specharness/memories/domain/<name>/` | Intent-triggered domain packs |
| `corebase-specharness/memories/archive/` | Deprecated heuristics |
| `corebase-specharness/project/` | Architecture, constraints, stack, ADRs |
| `session-extracts.md` | Feature-local candidates waiting for triage |

Promotion is manual. `memory-gate` can warn or block on line counts so memory
does not silently become a second repository dump.

Done requires a `## Post-Ship Sync` heading so closeout cannot skip the
memory step without leaving a visible hole. The heading is the mechanical
proof; the skill writes the content.

---

## 9. Install and ownership design

Two manifest groups exist so upgrades are boring:

- **overwrite**: runtime, skills, routes, rules, state machine. Replaced
  every install, after backup.
- **copyIfMissing**: project knowledge and harness config. Seeded once.

`state-machine.yaml` is kit-owned so the token graph does not fork silently.
Adopters add constraints through `lifecycle_overrides` (additive
preconditions, extra states, extra transitions).

`init` is a second, narrower seeder for trees that already have the runtime
but are missing memory files. It also records onboarding readiness (detected
stacks, native instruction files, confirmed gates) without writing those
instruction files.

Installer skips `test_*` so maintainer tests do not leak into adopter
projects. Doctor forbids a list of removed leftovers so old layouts cannot
quietly return.

See [INSTALL.md](INSTALL.md) for ownership lists and backup behavior.

---

## 10. Interface design

### 10.1 JSON envelope

Every command is automation-safe:

```json
{
  "command": "skill-exit",
  "status": "ok",
  "feature": "example",
  "artifacts": ["..."],
  "findings": [],
  "warnings": [],
  "errors": [],
  "next_action": "/spec-tasks",
  "details": {}
}
```

`next_action` is a suggestion, often a skill name or a follow-up CLI
invocation. It is not executed.

### 10.2 Exit codes

`ok` and `deferred` exit 0. That is deliberate: advisory verification must
be readable by humans (`details.verified`) rather than by shell `&&`.

### 10.3 Agent router

Installed `AGENTS.md` is the portable priority list. CoreBase SpecHarness does not write
`CLAUDE.md` / `.cursorrules` / Copilot files. If those exist, `init` reports
them as preserved native files.

See [REFERENCE.md](REFERENCE.md) for command options and envelope `details`.

---

## 11. What this design refuses

These were considered and are not in the implementation:

- A skill orchestrator that runs the delivery sequence.
- A SQLite/JSON document store for status.
- A plugin bus for providers.
- Generating vendor-specific agent files.
- Inferring `pytest` / `npm test` into `harness-config.yaml`.
- Making `context-load` a semantic search service.
- Treating coarse phases as the durable status.

The upgrade decision was: keep this design, collapse the leftover control
plane onto `check_readiness`, and make required writes fail.

---

## 12. Review questions this design answers

| Question | Implemented answer |
| --- | --- |
| Who chooses the next skill? | The agent or the human. The CLI only suggests `next_action`. |
| What is the source of lifecycle truth? | `state-machine.yaml` tokens in `status.md`. |
| What is the source of context truth? | `context-routes.yaml` plus always-on bootstrap files. |
| When is work verified? | `verify` → `details.verified: true`. |
| What may an upgrade overwrite? | Manifest `overwrite` only. |
| Why do some Verify skills not need finished tasks? | Route-scoped readiness uses `prerequisites`, not the coarse phase set. |
