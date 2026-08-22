# CoreBase SpecHarness documentation index

> **Audience:** maintainers of the source repository
> **Status:** documentation entrypoint and source-authority guide

CoreBase SpecHarness is a skills-first spec-driven delivery kit. The harness and
context compiler are layers inside that kit. Install copies files into an
adopter repo; `/starter-init` only tailors an empty one. `kit/` is both the
source payload and the installer source; installation places
`corebase-specharness/scripts/core/` in each adopter project.

## Surface ownership

| Surface | Location | Canonical authority |
| --- | --- | --- |
| Install payload and ownership | `kit/` | `kit/manifest.json` |
| Installer and upgrade behavior | `kit/corebase-specharness/scripts/install.sh` | Installer implementation |
| Embedded CLI, lifecycle, routing, and diagnostics | `kit/corebase-specharness/scripts/core/` | Executable implementation |
| Project-state defaults | `kit/corebase-specharness/project/` | State machine and configuration files |
| Agent procedures | `kit/skills/*/SKILL.md` | Individual skill contract |
| Maintainer explanation | `documents/maintainer/` | Subordinate to all kit authorities above |
| Public-site presentation | `product-page/` | Presentation only; never source authority |

When sources disagree, resolve in this order:

1. Executable behavior in `kit/corebase-specharness/scripts/core/` and installed paths in `kit/`.
2. `kit/manifest.json` for installed ownership and path membership.
3. `kit/corebase-specharness/project/state-machine.yaml` and project configuration for lifecycle states, transitions, and configured behavior.
4. `kit/references/context-routes.yaml` for named-skill routes.
5. `kit/skills/*/SKILL.md` for agent procedure.
6. Maintainer documentation, then public-site presentation.

Generated files and diagrams are derived output, never source authority.

## Maintainer documentation map

| Document | Purpose |
| --- | --- |
| `maintainer/README.md` | Folder map and authority order |
| `maintainer/OVERVIEW.md` | Product promise, package facts, and boundaries |

| `maintainer/INSTALL.md` | Install, ownership lists, backup, upgrade, and `init` vs installer |
| `maintainer/ARCHITECTURE.md` | Installed topology, subsystem design, control flows, and technical roadmap |
| `maintainer/DESIGN.md` | Why the kit is shaped this way; as-built design thesis |
| `maintainer/SPEC-REQUIREMENTS.md` | Normative as-built requirements implied by the runtime |
| `maintainer/WORKFLOW.md` | Usage guide, canonical 6-phase lifecycle, transition graph, and command map |
| `maintainer/SKILLS.md` | Eleven routes, per-skill contracts, writes, and handoffs |
| `maintainer/HARNESS.md` | Readiness algorithm, verify verdict, gates, doctor, and providers |
| `maintainer/MEMORY.md` | Context compilation, budgets, retrieval policy, and memory audit |
| `maintainer/REFERENCE.md` | CLI options, envelope fields, artifacts, and runtime module map |
| `maintainer/RELEASING.md` | Versioning, CI smoke, archive layout, and upgrade procedure |

## Documentation rules

- Describe installed paths relative to an adopter project, and source paths relative to this repository; do not conflate them.
- Quote manifest arrays as they are implemented: string patterns in `overwrite` and `copyIfMissing`.
- Treat kit-owned `corebase-specharness/project/state-machine.yaml` as lifecycle authority; adopter changes belong in `harness-config.yaml` under `lifecycle_overrides`.
- Treat `tasks.md` as canonical task state and feature-local `tasks.json` as its generated sidecar and read-only fallback.
- Treat `corebase-specharness/generated/` as runtime/generated state and verify individual filenames against implementation before listing them.
- Use `python3 corebase-specharness/scripts/core/cli.py` in adopter examples. Source-maintainer checks may invoke scripts beneath `kit/` directly.
- Prefer `--skill`. Document `--phase` only as compatibility on `phase-check`, `artifact-check`, and `verify`.
- Keep public, PRD, SAD, kit, and page changes separate unless the requested scope includes them.
- Commercial package files live at the source-repo root: `LICENSE`, `SECURITY.md`, `SUPPORT.md`, `CHANGELOG.md`.
- Worked examples live in `examples/` and are not part of the installed payload.

## Maintainer validation

```bash
python3 kit/corebase-specharness/scripts/core/cli.py doctor --root kit --json
python3 kit/corebase-specharness/scripts/validate-static-audit.py --root kit
python3 -m unittest discover -s tests -v
bash kit/corebase-specharness/scripts/install.sh /tmp/corebase-specharness-docs-index-check --dry-run
python3 -m compileall -q kit/corebase-specharness/scripts/core
```
