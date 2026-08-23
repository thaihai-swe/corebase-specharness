# Maintainer documentation

> **Audience:** kit maintainers and adopter platform engineers
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/corebase-specharness/scripts/core/` → `kit/manifest.json` →
> `kit/corebase-specharness/project/state-machine.yaml` and seeded
> `kit/corebase-specharness/project/harness-config.yaml` →
> `kit/references/context-routes.yaml` → `kit/skills/*/SKILL.md` → this folder

This folder explains the installed kit. It is not the runtime. When a claim
here disagrees with executable kit behavior, the kit wins.

CoreBase SpecHarness is a spec-driven delivery kit. The harness and context compiler
are layers inside it. It is not a starter template.

Installed paths are adopter-repo relative (`corebase-specharness/scripts/core/cli.py`).
Source-maintainer commands use the `kit/` prefix.

Start at [WORKFLOW.md](WORKFLOW.md) for the adopter usage guide and operating notes, then [SKILLS.md](SKILLS.md),
[HARNESS.md](HARNESS.md), [MEMORY.md](MEMORY.md), and [REFERENCE.md](REFERENCE.md)
as lookup.

## Map

| File | Job |
| --- | --- |
| [OVERVIEW.md](OVERVIEW.md) | Product promise, package facts, and boundaries |
| [INSTALL.md](INSTALL.md) | Install, ownership lists, backup, upgrade, `init` vs installer |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Installed topology, subsystem design, control flows, and technical roadmap |
| [DESIGN.md](DESIGN.md) | Why the kit is shaped this way; as-built design thesis |
| [SPEC-REQUIREMENTS.md](SPEC-REQUIREMENTS.md) | Normative as-built requirements implied by the runtime |
| [WORKFLOW.md](WORKFLOW.md) | Usage guide, 6-phase lifecycle, transition graph, and command map |
| [SKILLS.md](SKILLS.md) | Eleven routes, per-skill contracts, writes, and handoffs |
| [HARNESS.md](HARNESS.md) | Readiness algorithm, gates, verify verdict, doctor, providers |
| [MEMORY.md](MEMORY.md) | Context packs, budgets, retrieval, memory audit, compact / new-chat auto-delta |
| [SESSION-AUTO-DELTA.md](SESSION-AUTO-DELTA.md) | Session auto-delta feature: union baseline, H2 slice diffs, skip-before-budget, `--full` |
| [TOKEN-COST.md](TOKEN-COST.md) | Isolated vs session-delta pack tokens, step costs, compact / new-chat usage |
| [REFERENCE.md](REFERENCE.md) | CLI options, envelope fields, artifacts, runtime module map |
| [RELEASING.md](RELEASING.md) | Kit-maintainer release only |

## Validation

```bash
python3 kit/corebase-specharness/scripts/core/cli.py doctor --root kit --json
python3 kit/corebase-specharness/scripts/validate-static-audit.py --root kit
python3 -m compileall -q kit/corebase-specharness/scripts/core
bash kit/corebase-specharness/scripts/install.sh /tmp/corebase-specharness-docs-check --dry-run
```

In this sandbox, `compileall` needs `PYTHONPYCACHEPREFIX` pointed at an
in-workspace directory.
