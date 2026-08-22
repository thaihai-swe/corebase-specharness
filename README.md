# CoreBase SpecHarness

**Version 1.0.0**

CoreBase SpecHarness is an embedded, agent-agnostic kit for spec-driven delivery,
inspectable bounded context, task-oriented implementation, durable memory, and
explicit verification.

## Install

```bash
bash kit/corebase-specharness/scripts/install.sh /path/to/project
cd /path/to/project
python3 corebase-specharness/scripts/core/cli.py doctor --root . --json
```

The installer copies the embedded runtime and seeds adopter-owned content. It
does not install dependencies, configure integrations, infer project commands,
modify confirmed configuration, write Git hooks, or create vendor-specific
agent instruction files.

## Workflow

All 11 CoreBase SpecHarness skills are peer-level direct entrypoints. `/starter-init` is recommended only for an untailored repository. A common delivery route is `/spec-research` when needed, then `/spec-requirements`, `/spec-plan`, `/spec-tasks`, `/spec-implement`, `/harness-verify`, and optional `/context-memory`.

Project verification has no executable gates by default. After inspecting a repository, an agent may propose argv-safe checks. The adopter must explicitly confirm them in `corebase-specharness/project/harness-config.yaml` before `python3 corebase-specharness/scripts/core/cli.py verify` runs them.

New installs use `verification.mode: advisory`: CoreBase SpecHarness reports missing
artifacts, traceability gaps, and failed checks as `deferred` without claiming
work is verified or mechanically blocking the repository owner. A successful
exit in this mode is not verification; inspect `status` and `details.verified`.
Change the mode to `blocking` once project gates and lifecycle requirements are
trusted.

`corebase-specharness/project/state-machine.yaml` is the kit-owned lifecycle authority.
Adopters extend it only through `lifecycle_overrides` in
`corebase-specharness/project/harness-config.yaml`.

Before each named skill step, the agent compiles a bounded local context pack.
`python3 corebase-specharness/scripts/core/cli.py context-explain --skill <name> ... --json` shows the selected and
omitted sources, provenance, trust labels, and token budget. The pack includes
route-declared sources, intent-matched domain packs, and bounded automatic
local evidence retrieval; retrieved excerpts redact detected secrets.

Optional review and code-intelligence providers are disabled by default (`active: none`, `mode: optional`). CoreBase SpecHarness never installs `ocr` or other provider binaries. `/harness-verify` still performs two-axis review without them. After local setup, an adopter selects a provider in `corebase-specharness/project/tool-providers.md` and can inspect it with `provider-list` and `provider-check`. Set `mode: required` only when that project should fail closeout if the provider is missing.

## Requirements

- Python 3.10+
- Bash-compatible shell
- A coding agent with repository filesystem and local command access
