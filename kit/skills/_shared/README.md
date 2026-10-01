# Shared skill references

Cross-skill contracts that more than one skill loads on demand. This directory is exempt from the rule that every `skills/<name>/` must contain a `SKILL.md`.

Machine authority remains `state-machine.yaml` and `context-routes.yaml`. These files are the human twin.

| File | Contract |
| --- | --- |
| [`lifecycle-contracts.md`](lifecycle-contracts.md) | Phase tokens, exception states, HALT, handoff, decision points |
| [`artifact-contracts.md`](artifact-contracts.md) | Feature artifacts, AC/task linkage, verification evidence |
| [`context-protocol.md`](context-protocol.md) | Named-route loading, `--full` / auto-delta, token-cost rules |
| [`status-template.md`](status-template.md) | Seed template for `artifacts/features/<slug>/status.md` |
