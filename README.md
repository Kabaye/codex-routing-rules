# Codex routing rules

Small shared source of truth for both PCs:

- [`AGENTS.md`](AGENTS.md) — the short Sol High / Luna Max routing and delegation policy.
- [`codex-luna-subagent.ps1`](codex-luna-subagent.ps1) — the shared Luna CLI wrapper.

Copy the policy into the global Codex `AGENTS.md` you already use, and copy the wrapper to:

```powershell
$HOME\.codex\bin\codex-luna-subagent.ps1
```

The wrapper keeps Luna non-native (`codex exec`, `agents.enabled=false`). `-Background` returns a `WaitCommand`; the parent should execute that blocking wait once instead of repeatedly polling `console.log`. Normal results come from `last-message.md`; `console.log` is only for failure/debugging.
