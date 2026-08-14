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

Configure native subagents through `[agents]`:

```toml
[agents]
enabled = true
default_subagent_model = "gpt-5.6-luna"
default_subagent_reasoning_effort = "max"
```

Do **not** enable these flags for this setup:

```toml
[features]
multi_agent = true
multi_agent_v2 = true
```

If you added those two lines from an older version of this guide, remove them. In current Codex, `multi_agent_v2 = true` is an explicit backend override. The generated Sol/Luna catalog already marks these models with their correct `multi_agent_version`, so forcing the feature flag is unnecessary and can change orchestration behavior.

If you already have a `[features]` table for unrelated features, keep the table and remove only the `multi_agent` / `multi_agent_v2` entries.

## 4. Restart Codex

Fully close and reopen Codex so it reloads `config.toml`, the generated model catalog, and global `AGENTS.md`.

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

Then start a Sol High session and ask it to spawn one native Luna Max subagent that replies only with `LUNA_NATIVE_OK`.

Expected routing:

```text
Sol High  -> main/orchestrator
Sol xhigh -> manual escalation only
Luna Max  -> native delegated workers
```
