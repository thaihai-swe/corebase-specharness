# Diagram Index

> **Audience:** Maintainers
> **Status:** Source-repository documentation asset
> **Implementation authority:** the diagrams under `source/` and the Markdown guides under `documents/`

This index maps the Mermaid source files under `source/` to the consolidated maintainer guides that own them.

## Folder structure

- `source/` — Mermaid source files (.mmd) containing core diagrams and visual styles
- `source/_shared/` — shared palettes, styling classes, and color records
- `source/system-design/` — persistence classes, runtime models, and installed boundaries
- `source/architecture/` — components, data stacks, and context layout
- `source/workflow/` — lifecycle, exploration, data flows, and build steps
- `source/harness/` — gating, maintenance, and status machines
- `source/memory/` — memory hierarchy, triage, and post-ship sync

## Generated output

`generated/` is ignored presentation output. Treat Mermaid files under `source/` as the only editable source of truth. Do not add generated HTML/SVG files to the repository; refresh them locally or in the publishing pipeline when needed.

## Document Diagram Map

| Maintainer document | Diagram | Description |
| --- | --- | --- |
| `maintainer/ARCHITECTURE.md` | `source/architecture/system-architecture.mmd`<br/>`source/architecture/skills-repository-architecture.mmd`<br/>`source/architecture/skills-taxonomy.mmd`<br/>`source/system-design/installed-boundary.mmd` | 3-layer split + 5-layer topology.<br/>6-phase skill and package layout.<br/>11 skills + CLI surface including envelope verbs.<br/>Adopter flattened directory layout. |
| Runtime model reference | `source/system-design/runtime-model.mmd`<br/>`source/system-design/persistence-classes.mmd` | skill-enter / verify / Done sequence.<br/>Ownership class update logic. |
| `maintainer/MEMORY.md` | `source/architecture/context-stack.mmd`<br/>`source/architecture/context-routing.mmd`<br/>`source/memory/memory.mmd`<br/>`source/memory/self-improving-kb.mmd`<br/>`source/memory/post-ship-sync.mmd` | Data stack Layer 1-6 + session auto-delta.<br/>Named-route compilation and budget math.<br/>Memory hierarchy and generated run logs.<br/>Triage and promotion cycle.<br/>Sweep checklist sequence. |
| `maintainer/HARNESS.md` | `source/harness/gating-layers.mmd`<br/>`source/harness/harness-maintenance.mmd`<br/>`source/harness/verify-gate.mmd`<br/>`source/harness/status-machine.mmd`<br/>`source/workflow/code-intel-integration.mmd` | Constitution + 6-phase gate cascade.<br/>Assessment and maintain loop.<br/>Verify execution + mechanically protected Done.<br/>Feature status state machine from `state-machine.yaml`.<br/>Active provider configuration fallback. |
| `maintainer/WORKFLOW.md` | `source/workflow/delivery-lifecycle.mmd`<br/>`source/workflow/onboarding.mmd`<br/>`source/workflow/end-to-end-execution.mmd`<br/>`source/workflow/end-to-end-sequence.mmd`<br/>`source/workflow/dataflow.mmd`<br/>`source/workflow/traceability.mmd`<br/>`source/workflow/subagent-fanout.mmd` | Canonical 6-phase install-to-ship flow.<br/>Greenfield/brownfield onboarding tree.<br/>Sequence of single skill runs.<br/>Detailed CLI sequence with envelope verbs.<br/>Dataflow from analysis.md to PKB.<br/>REQ/AC/T/Proof + Post-Ship Sync chain.<br/>Subagent exploration boundary. |
| `maintainer/INSTALL.md` | `source/workflow/install-flow.mmd` | Local checkout, release archive, and `--dry-run` overwrite/seed loop. |
| `maintainer/RELEASING.md` | `source/workflow/release-flow.mmd` | Commit, semantic tags, auto-bump skip, and deploy pipeline. |

## Visual Styling and Palette

All diagrams use color and stroke styling to identify CoreBase SpecHarness subsystems. Reference `source/_shared/palette.md` for class definitions, color codes, and conventions.

## Refresh policy

Keep the source inventory in sync with this table. A new `.mmd` file must name its owning document above or be declared as a leftover presentation asset.

Refresh the affected source diagram when implementation or maintainer docs change. Keep labels aligned with the current `kit/` paths, CLI vocabulary (`skill-enter` / `skill-exit` / `--skill`), ownership classes (`overwrite` / `copyIfMissing`), and generated run files (`gate-runs.json`, `provider-runs.json`, `verification-runs.json`).
