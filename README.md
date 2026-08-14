# Codex routing rules

Shared minimal setup for both PCs.

Files:

- [`agents-subset.md`](agents-subset.md) — copy this section into your global `~/.codex/AGENTS.md`.
- [`models.json`](models.json) — shared filtered Sol/Luna model catalog.
- [`INSTALL.md`](INSTALL.md) — short manual setup instructions.

Routing:

```text
Sol High -> main agent, reasoning, decomposition, coordination, review
Luna Max -> native subagents for exploration, implementation, tests, verification, deploy/monitoring
```

Important lifecycle rule: reuse a Luna only while it stays in the same role/phase and working scope. When the phase changes (for example exploration -> implementation -> verification -> deploy), prefer a fresh Luna with a concise handoff.

Sol xhigh is manual-only. Terra, GPT-5.5, Sol Max, Fast, and Ultra are not selected automatically by this policy.
