# Codex routing rules

Small shared source of truth for both PCs.

- [`AGENTS.md`](AGENTS.md) — Sol High as the main/orchestrator and native Luna Max subagents for delegated execution.
- `models.json` — shared filtered Codex model catalog snapshot when present.

Current routing:

```text
Sol High  -> main agent, reasoning, decomposition, coordination, review
Luna Max  -> native subagents for implementation, tests, build/deploy/monitoring and other tool-heavy work
```

Native Luna is now preferred. The old CLI Luna wrapper has been removed.

Use the repository as the source of truth for the short routing policy on both PCs. Sol xhigh remains manual-only; Terra, GPT-5.5, Sol Max, Fast, and Ultra are not selected automatically by the policy.
