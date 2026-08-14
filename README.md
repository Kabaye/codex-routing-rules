# Codex routing rules

Shared minimal setup for both PCs.

Files:

- [`agents-subset.md`](agents-subset.md) — copy/merge this section into your global `~/.codex/AGENTS.md`.
- [`INSTALL.md`](INSTALL.md) — short setup instructions, including generation of a local Sol/Luna model catalog from the Codex CLI installed on that PC.

Routing:

```text
Sol High  -> main agent, reasoning, decomposition, coordination, review
Sol xhigh -> manual escalation only
Luna Max  -> native subagents for exploration, implementation, tests, verification, deploy/monitoring
```

The model catalog is **generated locally from `codex debug models`**, then filtered to Sol + Luna and to the allowed efforts: Sol `high`/`xhigh`, Luna `max`. A frozen `models.json` is intentionally not stored here because the Codex catalog schema can change between CLI versions.

Native Multi-Agent V2 is configured with an explicit **proactive delegation policy**. This avoids Codex's default `ExplicitRequestOnly` guidance on Sol High while keeping native Luna V2 subagents available.

Important lifecycle rule: reuse a Luna only while it stays in the same role/phase and working scope. When the phase changes (for example exploration -> implementation -> verification -> deploy), prefer a fresh Luna with a concise handoff.

Sol High is the default. Sol xhigh is manual-only. Terra, GPT-5.5, Sol Max, Fast, and Ultra are not selected automatically by this policy.
