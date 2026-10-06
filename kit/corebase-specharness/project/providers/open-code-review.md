# Provider: open-code-review

- Repository: https://github.com/alibaba/open-code-review
- Website: https://open-codereview.ai
- Package: `@alibaba-group/open-code-review`

`open-code-review` (`ocr`) is an optional review provider. CoreBase SpecHarness does not install it, configure it, or enable it by default. Initial kit installations keep `providers.review.active: none` and `mode: optional`. The `/harness-verify` skill can close out features without `ocr` installed on the system PATH.

This provider gives supplementary mechanical review evidence. It MUST NOT replace the mandatory two-axis review (standards and specification alignment) that `/harness-verify` executes.

---

## 1. Prerequisites and Installation

### Prerequisites
- Git version 2.41 or later.
- Node.js runtime for global package installation.

### Installation
Install the `ocr` CLI globally via npm:

```bash
npm install -g @alibaba-group/open-code-review
```

Verify that the binary exists on PATH:

```bash
ocr --version
```

---

## 2. Execution Modes

Select one of two execution modes before activation:

### Mode A: OCR-Managed Review (External LLM)
In this mode, `ocr` connects directly to an external LLM provider. Configure provider credentials and model selection interactively:

```bash
ocr config provider
ocr config model
ocr llm test
```

Supported LLM protocols include Anthropic, OpenAI Chat Completions, OpenAI Responses, and AWS Bedrock.

### Mode B: Delegation Mode (Zero External OCR API Keys)
In delegation mode, the host coding agent executes code review using its own model and context window. The `ocr` CLI handles only deterministic engineering tasks:
- Precise file selection and filtering.
- Review rule resolution and grouping.

No LLM API keys are required for the `ocr` binary in delegation mode.

---

## 3. Harness Activation

Enable the provider in `corebase-specharness/project/tool-providers.md` frontmatter:

```yaml
---
providers:
  review:
    active: open-code-review
    mode: optional   # Set to "required" only when OCR pass is mandatory
  code-intelligence:
    active: none
    mode: optional
---
```

### Verification Mode Semantics
- `mode: optional` (default): Missing executable or failed execution marks the provider check as `deferred`. Verification proceeds without blocking.
- `mode: required`: Missing executable, configuration failure, or non-zero exit code marks the provider check as `failed`. This blocks verification and prevents `Done` state.

Verify harness integration status:

```bash
python3 corebase-specharness/scripts/core/cli.py provider-check --category review --json
```

---

## 4. Lifecycle Integration (`/harness-verify`)

When enabled (`active: open-code-review`), `/harness-verify` triggers the provider action during mechanical verification:

```bash
python3 corebase-specharness/scripts/core/cli.py verify --feature <slug> --skill harness-verify
```

### Review Evidence Contract
- The harness runs the declared `run` action (`ocr review`).
- Results are recorded under `## Provider Review` in `artifacts/features/<slug>/review.md`.
- Empty output without an explicit clean confirmation constitutes incomplete evidence.
- Security-sensitive path findings must escalate through CoreBase SpecHarness security policy checks.

---

## 5. Command Reference

### Standard Diff Review (OCR-Managed Mode)

Always pass `--audience agent` in automated agent sessions to suppress interactive progress displays.

| Intent | Command |
| :--- | :--- |
| Workspace review (staged, unstaged, untracked) | `ocr review --audience agent` |
| Branch comparison | `ocr review --audience agent --from <base> --to <head>` |
| Specific commit review | `ocr review --audience agent --commit <sha>` |
| Full-file scan (no diff required) | `ocr scan --path <path>` |
| Machine-readable JSON output | `ocr review --audience agent --format json --output <path>` |
| Resume interrupted review | `ocr review --resume <session-id>` |
| Preview reviewable files | `ocr review --preview` |

### Delegation Mode Commands

Execute deterministic filtering and rule matching for host-agent review:

1. Preview reviewable files and git refs:
   ```bash
   ocr delegate preview --format json
   ```
2. Resolve rules for target files:
   ```bash
   ocr delegate rule --format json <path1> <path2>
   ```
3. Inspect diffs directly via git and evaluate each file against resolved rules.

---

## 6. Custom Review Rules

Configure repository-specific review rules in `.opencodereview/rule.json` at repository root:

```json
{
  "rules": [
    {
      "path": "**/*.py",
      "rule": "Ensure all functions include type annotations and error checks.",
      "merge_system_rule": true
    }
  ]
}
```

Verify rule resolution for target files:

```bash
ocr rules check <path-to-file>
```

---

## 7. Troubleshooting

### Command Not Found
If `ocr` is not recognized, verify npm global path installation:
```bash
npm install -g @alibaba-group/open-code-review
which ocr
```

### LLM Connection Failure
If `ocr review` reports provider connection errors in Mode A:
1. Verify configuration: `ocr config list`
2. Test connectivity: `ocr llm test`
3. Switch to Delegation Mode if external API access is unavailable.

### CLI Flag Incompatibility
The `--format` flag requires `ocr` version 1.9.0 or later. The `--output` flag requires `ocr` version 1.10.0 or later. Upgrade the CLI if flags are rejected:
```bash
npm install -g @alibaba-group/open-code-review@latest
```
