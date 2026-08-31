# Install x20-work

## 1. Install both worker roles

From the repository root, run:

```powershell
New-Item -ItemType Directory -Force "$HOME\.codex\agents" | Out-Null
Copy-Item ".\x20-work\agents\luna-worker.toml" "$HOME\.codex\agents\luna-worker.toml" -Force
Copy-Item ".\x20-work\agents\sol-worker.toml" "$HOME\.codex\agents\sol-worker.toml" -Force
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

$sol.default_reasoning_level = "xhigh"
$sol.multi_agent_version = "v2"
$sol.supported_reasoning_levels = @(
    [pscustomobject]@{
        effort = "xhigh"
        description = "Extra-high reasoning effort"
    }
)

$luna.default_reasoning_level = "max"
$luna.multi_agent_version = "v2"
$luna.supported_reasoning_levels = @(
    [pscustomobject]@{
        effort = "max"
        description = "Maximum reasoning effort"
    }
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
model_reasoning_effort = "xhigh"
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
max_concurrent_threads_per_session = 3

[memories]
extract_model = "gpt-5.6-luna"
consolidation_model = "gpt-5.6-luna"
```

`max_concurrent_threads_per_session = 3` means the root plus at most two concurrently active subagents.

## 5. Restart Codex

Fully close Codex, reopen it, and start a new task/thread.

By default, all delegated agents are Luna Max. Sol X High subagents become available only when the user explicitly instructs the current objective to use Sol X High agents, for example:

```text
используй агентов Sol X High
```

That instruction unlocks Sol X High; it does not force every subagent to use it. After explicit authorization, the Sol xhigh root decides per coherent workstream whether Luna Max or Sol xhigh is the better fit. Operational/tool-heavy work may stay on Luna, while reasoning-heavy implementation may use Sol xhigh when useful. No other condition, label, scope, or inferred need unlocks Sol X High subagents.
