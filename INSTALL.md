# Install

## 1. Install the Luna worker role

From the repository root, run:

```powershell
New-Item -ItemType Directory -Force "$HOME\.codex\agents" | Out-Null
Copy-Item ".\agents\luna-worker.toml" "$HOME\.codex\agents\luna-worker.toml" -Force
```

## 2. Update AGENTS.md

Open:

```text
~/.codex/AGENTS.md
```

Replace the existing model/subagent-routing section with the contents of [`agents-subset.md`](agents-subset.md).

## 3. Generate models.json

Temporarily comment out the existing `model_catalog_json` line in `~/.codex/config.toml`, then run:

```powershell
$catalog = (codex debug models | Out-String) | ConvertFrom-Json

$sol = $catalog.models | Where-Object { $_.slug -eq "gpt-5.6-sol" }
$luna = $catalog.models | Where-Object { $_.slug -eq "gpt-5.6-luna" }

$sol.default_reasoning_level = "high"
$sol.supported_reasoning_levels = @(
    $sol.supported_reasoning_levels |
    Where-Object { $_.effort -in @("high", "xhigh") }
)

$luna.default_reasoning_level = "max"
$luna.supported_reasoning_levels = @(
    $luna.supported_reasoning_levels |
    Where-Object { $_.effort -eq "max" }
)

$catalog.models = @($sol, $luna)

$json = $catalog | ConvertTo-Json -Depth 100
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$HOME\.codex\models.json", $json, $utf8)
```

## 4. Update config.toml

Open:

```text
~/.codex/config.toml
```

Set the top-level values:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
model_catalog_json = "C:/Users/YOUR_USER/.codex/models.json"
```

Replace `YOUR_USER` with the Windows username.

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

## 5. Restart Codex

Fully close Codex, reopen it, and start a new task/thread.
