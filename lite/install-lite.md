# Install lite

## 1. Install the Luna worker role

From the repository root, run:

```powershell
New-Item -ItemType Directory -Force "$HOME\.codex\agents" | Out-Null
Remove-Item "$HOME\.codex\agents\sol-worker.toml" -ErrorAction SilentlyContinue
Copy-Item ".\lite\agents\luna-worker.toml" "$HOME\.codex\agents\luna-worker.toml" -Force
```

## 2. Update AGENTS.md

Open:

```text
~/.codex/AGENTS.md
```

Replace the existing model/subagent-routing section with the contents of [`agents-subset.md`](agents-subset.md).

## 3. Update config.toml

Open:

```text
~/.codex/config.toml
```

Set the top-level values:

```toml
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
```

Remove the `model_catalog_json` line if it is present.

Merge these values into the existing config tables:

```toml
[features]
multi_agent = true

[features.multi_agent_v2]
enabled = true
multi_agent_mode_hint_text = ""

[memories]
extract_model = "gpt-5.6-luna"
consolidation_model = "gpt-5.6-luna"
```

## 4. Restart Codex

Fully close Codex, reopen it, and start a new task/thread.
