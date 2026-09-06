# CoreBase SpecHarness

> **Skills-first, spec-driven delivery kit for AI coding agents.**
> Embedded CLI harness, bounded context compiler, durable memory, and explicit verification.

This file is the **installed adopter README**. It is seeded once (`copyIfMissing`)
and is not replaced on upgrade. The source-kit README lives in the GitHub
repository and covers maintainer checks, CI, and authority order.

---

## After install

```bash
python3 corebase-specharness/scripts/core/cli.py doctor --json
python3 corebase-specharness/scripts/core/cli.py init --json   # new / untailored repos
```

Invoke a skill via `skills/<name>/SKILL.md` (or `.agent/skills/<name>/SKILL.md`):

```bash
python3 corebase-specharness/scripts/core/cli.py skill-enter \
  --skill spec-plan --feature <slug> --intent "<request>" --json
python3 corebase-specharness/scripts/core/cli.py skill-exit \
  --skill spec-plan --feature <slug> --handoff spec-tasks --json
python3 corebase-specharness/scripts/core/cli.py verify \
  --feature <slug> --skill harness-verify --json
```

Upgrade from a later kit checkout or release archive (existing `README.md` is kept):

```bash
bash corebase-specharness/scripts/install.sh /path/to/this-repo
```

---

## Lifecycle

```
/spec-research → /spec-requirements → /spec-plan → /spec-tasks
                                              ↓
                         /context-memory ← /harness-verify ← /spec-implement
```

| Skill | Writes |
| :--- | :--- |
| `/starter-init` | `corebase-specharness/project/` |
| `/spec-research` | `artifacts/features/<slug>/analysis.md` |
| `/spec-requirements` | `artifacts/features/<slug>/spec.md` |
| `/spec-plan` | `artifacts/features/<slug>/plan.md` |
| `/spec-tasks` | `artifacts/features/<slug>/tasks.md` |
| `/spec-implement` | task evidence in `tasks.md` |
| `/harness-verify` | `artifacts/features/<slug>/review.md` |
| `/context-memory` | `corebase-specharness/memories/repo/` |
| `/spec-adr` | `corebase-specharness/memories/repo/adr-log.md` |
| `/spec-testing-scenario` | `artifacts/features/<slug>/testing-scenarios.md` |
| `/harness-maintain` | diagnostics only |

Prefer `--skill`. `--phase` is compatibility-only on `phase-check`,
`artifact-check`, and `verify`. Context, budgets, and session auto-delta:
`corebase-specharness/CONTEXT_AND_MEMORY.md`. Agent procedure: `AGENTS.md`.

---

## Ownership

| Group | Behavior |
| :--- | :--- |
| `overwrite` | Kit-owned. Backed up under `.corezero-backup-<random>/`, then replaced. |
| `copyIfMissing` | Adopter-owned seeds (this README, project files, memories). Never replaced. |

---

## Requirements

Python 3.10+ (stdlib only), Bash, any agent with filesystem and terminal access.
Token counts use `tiktoken` (`cl100k_base`) when installed, else `len(text) / 4`.
