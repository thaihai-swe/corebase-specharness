# Security Rules

Implementation safety for code and scripts. Permission tiers live in `corebase-specharness/memories/repo/core-policies.md` `## Security Policy`.

Apply when work touches secrets, auth, shell, external input, or cross-boundary data.

## Core Rules

- Never hardcode credentials, tokens, or private endpoints.
- Treat env vars, config, CLI args, API payloads, and generated artifacts as untrusted unless proven otherwise.
- Prefer allowlists over ad hoc string filtering for paths, command options, and external IDs.
- Do not suppress validation or error handling to make a check pass.
- Do not widen file-system or shell access without documenting why.

## Shell and Script Safety

- Keep shell commands explicit and narrowly scoped.
- Avoid passing unchecked user-controlled text into shell evaluation.
- Prefer direct argument passing over string-built shell fragments.
- When a script mutates files, make the target set obvious and reviewable.

## File and Artifact Boundaries

- Distinguish kit-managed files from adopter-owned files before editing.
- Preserve `artifacts/` and adopter-owned seeded docs unless the task explicitly changes them.
- Generated placeholders are not current truth unless refreshed in this run.

## Verification

- Security-relevant changes are not complete without fresh verification evidence.
- If a change alters trust boundaries, update matching docs and rules in the same change wave.

### Principle

More rules → more freedom. Constraints increase autonomy by making incorrect paths fail fast. When an agent hits a boundary, widen it (if the action was correct) or keep it (if wrong). See CC-008.
