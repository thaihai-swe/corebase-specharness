# CoreBase SpecHarness product overview

> **Audience:** product owners, solution architects, maintainers
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/corebase-specharness/scripts/core/` → `kit/manifest.json` →
> `kit/corebase-specharness/project/` → `kit/skills/*/SKILL.md`

CoreBase SpecHarness is a spec-driven delivery kit for coding agents. It ships 11
peer-level direct skills, a deterministic CLI, route-compiled context,
durable memory, advisory-by-default verification, and upgrade-safe package
ownership.

The kit improves repeatability and evidence. It does not replace the agent,
CI, code review, or human approval.

Primary product: spec-driven delivery. Skills and artifacts force research
→ spec → plan → tasks → implement → verify, with repository files as the
system of record.

Layers inside that product, not competing products:

| Label | Role |
| --- | --- |
| Spec-driven delivery kit | Primary product. Named skills write inspectable feature artifacts. |
| Harness engineering | Embedded mechanics. CLI, readiness, lifecycle tokens, gates, doctor, verify. |
| Context engineering | Embedded compiler. Named routes, bounded packs, budgets, retrieval, durable memory. |
| Starter template | Not the product. Install copies files and seeds adopter stubs. `/starter-init` only tailors an untailored repo. |

## What this is and is not

| This is | This is not |
| --- | --- |
| A project-local copy of skills, routes, memory seeds, and an embedded Python CLI | A server, daemon, or hosted engine |
| A skills-first spec-driven workflow whose system of record is repository files | A boilerplate starter template or app scaffold |
| A mechanical checker for artifacts, lifecycle tokens, tasks, gates, and memory size | A skill chooser, planner, or approver |
| An installer that copies `kit/` into a target using two ownership groups | A package manager, CI system, or provider installer |

There is no external runtime service, no `COREBASE_SPECHARNESS_ENGINE_DIR`, no
`bin/corebase-specharness` launcher, and no Python plugin registry for skills. Skills are
Markdown procedures at `skills/<name>/SKILL.md`. The CLI is mechanics behind
those procedures.

Package facts from `kit/manifest.json`:

| Field | Value |
| --- | --- |
| `name` | `corebase-specharness` |
| `version` | the SemVer string in that file (currently `1.0.0`) |
| `requires_python` | `>=3.10` |
| `homepage` | `https://github.com/thaihai-swe/CoreBase SpecHarness` |
| `description` | the string in that file (currently the spec-driven kit positioning) |

Runtime identity of an installed root: both `manifest.json` and
`corebase-specharness/scripts/core/cli.py` exist. `resolve_root` walks upward from
`--root` or the current directory until it finds that pair.

The embedded runtime uses only the Python standard library. If `tiktoken` is
installed, token counts use its `cl100k_base` encoding. Otherwise the runtime
uses the deterministic four-characters-per-token estimate in
`_lib/token_counter.py`.

## Product promise

The kit gives an agent a bounded operating loop:

1. Load only route-declared context sources plus bounded automatic local
   retrieval for the active skill and intent.
2. Capture requirements, decisions, plans, tasks, evidence, and handoffs as
   durable feature artifacts.
3. Check named-skill readiness (or coarse `--phase` compatibility) and
   explicitly confirmed repository verification commands.
4. Run gates and verify features deterministically in-memory.
5. Preserve adopter-owned project knowledge, memory baselines, and feature
   artifacts across kit upgrades.

## Skill-first interface

Developers invoke skills. Agents run the harness.

| You say | Agent does |
| --- | --- |
| `/starter-init` | Initializes structure and customizes project memory |
| `/spec-research` | Produces evidence-based analysis of unknown behavior |
| `/spec-requirements` | Writes the feature contract and acceptance criteria |
| `/spec-plan` | Designs the technical solution |
| `/spec-tasks` | Builds the sequenced task graph |
| `/spec-implement` | Executes tasks with proof and session continuity |
| `/harness-verify` | Runs gates, checks traceability, and closes the feature |
| `/context-memory` | Promotes only reusable lessons into durable memory |
| `/harness-maintain` | Audits harness health and diagnoses execution findings |
| `/spec-adr` | Records an architectural decision and updates its log |
| `/spec-testing-scenario` | Produces feature testing scenarios |

`python3 corebase-specharness/scripts/core/cli.py` is the deterministic CLI behind those
skills. It is not the primary developer interface. It does not choose the next
skill. Evidence and explicit `--handoff` values do.

If the coding agent supports slash skills, invoke the skill name directly.
Otherwise tell it to read `skills/<name>/SKILL.md` and follow that procedure.

## What ships

| Capability | What is implemented |
| --- | --- |
| Installable package | Manifest ownership with `overwrite` and `copyIfMissing` rules |
| Skill catalog | 11 direct peer skills plus `_shared` guidance |
| Deterministic CLI | 28 commands covering session, context, status, task, artifact, verification, gate, provider, memory, ADR, and evals |
| Lifecycle state | Feature tokens in `status.md`; kit-owned `state-machine.yaml` |
| Context routing | `corebase-specharness/references/context-routes.yaml`, profile payloads, and inspectable packs |
| Memory | Repository memory, domain packs, session state, and line-audit thresholds |
| Verification | Artifact structure/traceability, confirmed gates, inline verification, and doctor |
| Optional integrations | Local tool providers selected in `tool-providers.md` |

## Two state classes

The kit keeps two kinds of state in two places. Verification and closeout checks run inline.

| Class | Path | Lifetime | Owner |
| --- | --- | --- | --- |
| Durable feature evidence | `artifacts/features/<slug>/` | Lives with the feature | Adopter / delivery skills |
| Ephemeral session continuity | `.corebase-specharness/sessions/<slug>/session.md` | Resumable working state; not archived on `session-end`; fingerprints survive compact and a new chat | Envelope and session commands |

`status.md` is the durable feature-state authority. Do not hand-edit
`- Phase:`. Use `skill-enter`, `skill-exit`, or `status-set`.

## Split of responsibility

| Actor | Owns | Does not own |
| --- | --- | --- |
| Installer | Copy payload, seed missing files, chmod three scripts, run doctor | Tailoring memory, adding gates, running `/starter-init` |
| `init` CLI | Missing directories, missing seed stubs, `onboarding_readiness` report | Rewriting existing adopter files, inventing stack or gates |
| Skill Markdown | Procedure, judgment, required headings, HALT stop conditions, handoff choice | Deterministic file locks, task transitions, gate execution |
| Embedded CLI | Context packs, sessions, task graph, readiness, gates, doctor, memory size, ADR draft | Skill selection, semantic review, memory promotion |
| Adopter / human | Product decisions, gate confirmation, approval, acceptance | Kit implementation |

## Explicit boundaries

| Implemented | Procedure or partial | Not a guarantee |
| --- | --- | --- |
| Installer ownership, CLI lifecycle, artifact validation, context routing, gates, doctor, memory audit, provider checks | Requirement discovery, architecture judgment, review conclusions, memory promotion, client-specific agent integration | Removing prior LLM conversation content, proving arbitrary repository commands are safe, inferring business intent without research |

Delivery profiles `Simple`, `Moderate`, and `Complex` are skill-procedure
depth rules. The runtime defaults a new `status.md` to `Moderate` and reads
the field. Profiles do not skip planning, tasks, proof, or verification.

## Where to start

| Audience | Start here |
| --- | --- |
| New adopter | [INSTALL.md](INSTALL.md) → [WORKFLOW.md](WORKFLOW.md) |
| Platform engineer | [ARCHITECTURE.md](ARCHITECTURE.md) → [HARNESS.md](HARNESS.md) → [REFERENCE.md](REFERENCE.md) |
| As-built reviewer | [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md) → [DESIGN.md](DESIGN.md) → [ARCHITECTURE.md](ARCHITECTURE.md) |
| Memory and token cost owner | [MEMORY.md](MEMORY.md) → [TOKEN-COST.md](TOKEN-COST.md) |
| Release maintainer | [RELEASING.md](RELEASING.md) |

## Related documents

- Usage and operating notes: [WORKFLOW.md](WORKFLOW.md)
- Skill catalog: [SKILLS.md](SKILLS.md)
- Install and upgrade: [INSTALL.md](INSTALL.md)
- Memory and context: [MEMORY.md](MEMORY.md)
- Token cost (isolated vs session auto-delta): [TOKEN-COST.md](TOKEN-COST.md)
- Compact / new-chat reload: [MEMORY.md](MEMORY.md#conversation-vs-feature-session-compact-and-new-chat)
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Design thesis: [DESIGN.md](DESIGN.md)
- As-built requirements: [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md)
- Harness and gates: [HARNESS.md](HARNESS.md)
- CLI and schemas: [REFERENCE.md](REFERENCE.md)
- Release process: [RELEASING.md](RELEASING.md)
