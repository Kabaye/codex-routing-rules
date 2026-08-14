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

Do **not** copy a frozen model catalog from this repository. Generate it from the Codex version installed on that PC so all required schema fields stay compatible with that CLI version.

If `~/.codex/config.toml` already contains `model_catalog_json`, temporarily remove/comment that line before this step so a stale custom catalog cannot prevent `codex debug models` from starting.

Run in PowerShell:

```powershell
$catalog = (codex debug models | Out-String) | ConvertFrom-Json

$sol = $catalog.models | Where-Object { $_.slug -eq "gpt-5.6-sol" }
$luna = $catalog.models | Where-Object { $_.slug -eq "gpt-5.6-luna" }

if (-not $sol) { throw "gpt-5.6-sol not found in current Codex model catalog" }
if (-not $luna) { throw "gpt-5.6-luna not found in current Codex model catalog" }

# Keep exactly the model/effort combinations used by this setup.
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

if (-not ($sol.supported_reasoning_levels | Where-Object { $_.effort -eq "high" })) {
    throw "Sol high effort is not advertised by this Codex version"
}
if (-not ($sol.supported_reasoning_levels | Where-Object { $_.effort -eq "xhigh" })) {
    throw "Sol xhigh effort is not advertised by this Codex version"
}
if ($luna.supported_reasoning_levels.Count -ne 1) {
    throw "Luna max effort is not advertised exactly once by this Codex version"
}

$catalog.models = @($sol, $luna)

$json = $catalog | ConvertTo-Json -Depth 100
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$HOME\.codex\models.json", $json, $utf8)
```

The resulting `~/.codex/models.json` preserves all other schema fields emitted by the current CLI, but exposes only:

```text
Sol  -> High (default), xhigh (manual)
Luna -> Max only
```

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

Configure Luna defaults:

```toml
[agents]
enabled = true
default_subagent_model = "gpt-5.6-luna"
default_subagent_reasoning_effort = "max"
```

Configure native V2 delegation with an explicit proactive policy:

```toml
[features.multi_agent_v2]
enabled = true
multi_agent_mode_hint_text = "Proactive multi-agent delegation is active. Any earlier instruction requiring an explicit user request before spawning sub-agents no longer applies. Use sub-agents when parallel work would materially improve speed or quality."
```

Do **not** also add scalar entries such as:

```toml
[features]
multi_agent_v2 = true
```

The typed `[features.multi_agent_v2]` block replaces that scalar form and carries the proactive policy. A separate `multi_agent = true` line is not required for this setup.

Why the proactive hint is explicit: with Multi-Agent V2 and ordinary Sol reasoning efforts such as `high`, current Codex otherwise selects an `ExplicitRequestOnly` policy and injects a developer message telling the model not to spawn sub-agents unless explicitly requested. This setup intentionally overrides that policy because `agents-subset.md` defines proactive Luna delegation.

## 4. Restart Codex

Fully close and reopen Codex so it reloads `config.toml`, the generated model catalog, and global `AGENTS.md`.

Create a **new task/thread** after restarting. Existing threads may already contain the previous multi-agent-mode developer message in their history.

## Optional quick check

Check the generated catalog and efforts:

```powershell
(Get-Content "$HOME\.codex\models.json" -Raw | ConvertFrom-Json).models |
    Select-Object slug, default_reasoning_level, multi_agent_version, supports_parallel_tool_calls,
        @{Name="efforts";Expression={($_.supported_reasoning_levels.effort -join ",")}}
```

Expected shape:

```text
gpt-5.6-sol   high   v2   True   high,xhigh
gpt-5.6-luna  max    v2   True   max
```

Then start a new Sol High session and ask it to spawn one native Luna Max subagent that replies only with `LUNA_NATIVE_OK`.

Expected routing:

```text
Sol High  -> main/orchestrator
Sol xhigh -> manual escalation only
Luna Max  -> native delegated workers
```
