# Codex routing rules

Shared minimal setup for both PCs.

Files:

- [`agents-subset.md`](agents-subset.md) — merge this compact parent/orchestration section into `~/.codex/AGENTS.md`.
- [`agents/luna-worker.toml`](agents/luna-worker.toml) — standalone native `luna_worker` role that pins GPT-5.6 Luna / Max and contains worker-specific instructions.
- [`INSTALL.md`](INSTALL.md) — setup instructions, including the local Sol/Luna model catalog, Multi-Agent V2 config, Memories routing, and role installation.
- [`REMOVE.md`](REMOVE.md) — clean removal instructions for this setup.

Routing:

```text
Sol High    -> reasoning, architecture, coordination, final acceptance
Sol xhigh   -> manual escalation only
luna_worker -> Luna Max for substantial delegated work
```

One `luna_worker` owns one coherent workstream end-to-end; that workstream may span backend, frontend, shared contracts, migrations, tests, and multiple files. Additional workers are for genuinely independent work, not for duplicating the same exploration or implementation.

Worker-specific behavior now lives in the standalone role file instead of bloating global `AGENTS.md`. Sol spawns the role by `agent_type = "luna_worker"` with a fresh context; the role itself pins `gpt-5.6-luna` / `max`.

The model catalog is generated locally from `codex debug models`, then filtered to Sol + Luna and to the allowed efforts: Sol `high`/`xhigh`, Luna `max`. A frozen `models.json` is intentionally not stored here because the Codex catalog schema can change between CLI versions.

Native Multi-Agent V2 stays enabled, but `multi_agent_mode_hint_text` is intentionally empty. This avoids an extra custom multi-agent developer policy and leaves orchestration under `AGENTS.md` plus the native worker role.

If Memories are enabled, `INSTALL.md` pins both memory extraction and consolidation to Luna. On Codex CLI 0.147.0 extraction already defaults to Luna, while this changes consolidation from Terra to Luna.

Terra, GPT-5.5, Sol Max, Fast, and Ultra are not selected automatically by this policy.
