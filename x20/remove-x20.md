# Remove x20

## 1. Remove the Sol worker role

Run in PowerShell:

```powershell
Remove-Item "$HOME\.codex\agents\sol-worker.toml" -ErrorAction SilentlyContinue
```

## 2. Remove the routing rules

Open:

```text
~/.codex/AGENTS.md
```

Delete the model/subagent-routing section that was copied from [`agents-subset.md`](agents-subset.md). Keep all unrelated instructions.

## 3. Restore config.toml

Open:

```text
~/.codex/config.toml
```

Remove these top-level values:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
```

Remove these setup-specific keys from their existing tables:

```toml
[features]
multi_agent = true

[features.multi_agent_v2]
enabled = true
multi_agent_mode_hint_text = ""
```

If one of those tables becomes empty, remove its empty table header too.

## 4. Restart Codex

Fully close Codex, reopen it, and start a new task/thread.
