# Install

This repo is intentionally manual: no installer scripts.

## 1. Update your global AGENTS.md

Open:

```text
~/.codex/AGENTS.md
```

Replace only your existing model/subagent-routing section with the contents of [`agents-subset.md`](agents-subset.md).

Keep all unrelated personal instructions in your `AGENTS.md`.

## 2. Generate models.json from your installed Codex

Do **not** copy a frozen model catalog from this repository. Codex model-catalog schema changes between CLI versions, so generate the catalog from the Codex version installed on that PC.

If `~/.codex/config.toml` already contains `model_catalog_json`, temporarily remove/comment that line before this step so a stale custom catalog cannot prevent `codex debug models` from starting.

Run in PowerShell:

```powershell
$catalog = (codex debug models | Out-String) | ConvertFrom-Json
$catalog.models = @($catalog.models | Where-Object { $_.slug -in @("gpt-5.6-sol", "gpt-5.6-luna") })
$json = $catalog | ConvertTo-Json -Depth 100
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$HOME\.codex\models.json", $json, $utf8)
```

The resulting `~/.codex/models.json` should contain exactly Sol and Luna while preserving **all schema fields emitted by the current CLI**.

## 3. Update config.toml

Open:

```text
~/.codex/config.toml
```

Ensure the top-level settings contain:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
model_catalog_json = "C:/Users/YOUR_USER/.codex/models.json"
```

Replace `YOUR_USER` with the Windows username on that PC.

If `[features]` already exists, merge these keys into that table instead of creating a second `[features]` table:

```toml
[features]
multi_agent = true
multi_agent_v2 = true
```

Do not add Fast/Ultra settings for this routing setup.

## 4. Restart Codex

Fully close and reopen Codex so it reloads `config.toml`, the generated model catalog, and global `AGENTS.md`.

## Optional quick check

Check the generated catalog:

```powershell
(Get-Content "$HOME\.codex\models.json" -Raw | ConvertFrom-Json).models |
  Select-Object slug, multi_agent_version, supports_parallel_tool_calls
```

Both models should be present; Luna should be `v2`, and `supports_parallel_tool_calls` should be present rather than missing.

Then start a Sol High session and ask it to spawn one native Luna Max subagent that replies only with `LUNA_NATIVE_OK`.

Expected routing:

```text
Sol High -> main/orchestrator
Luna Max -> native delegated workers
```
