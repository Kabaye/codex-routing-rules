# Remove x20-work

## 1. Remove both worker roles

Run in PowerShell:

```powershell
Remove-Item "$HOME\.codex\agents\luna-worker.toml" -ErrorAction SilentlyContinue
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
model_reasoning_effort = "high"
model_catalog_json = "C:/Users/YOUR_USER/.codex/models.json"
```

Remove these setup-specific keys from their existing tables:

```toml
[features]
multi_agent = true

[features.multi_agent_v2]
enabled = true
multi_agent_mode_hint_text = ""
max_concurrent_threads_per_session = 2

[memories]
extract_model = "gpt-5.6-luna"
consolidation_model = "gpt-5.6-luna"
```

If one of those tables becomes empty, remove its empty table header too.

## 4. Remove models.json

Run in PowerShell:

```powershell
Remove-Item "$HOME\.codex\models.json" -ErrorAction SilentlyContinue
```

## 5. Restart Codex

Fully close Codex, reopen it, and start a new task/thread.
