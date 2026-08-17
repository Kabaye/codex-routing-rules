# Install

This repo is intentionally manual: no installer scripts.

## 1. Install the Luna worker role

From the repository root, copy [`agents/luna-worker.toml`](agents/luna-worker.toml) into your Codex agents directory:

```powershell
New-Item -ItemType Directory -Force "$HOME\.codex\agents" | Out-Null
Copy-Item ".\agents\luna-worker.toml" "$HOME\.codex\agents\luna-worker.toml" -Force
```

The standalone role is discovered from `~/.codex/agents/`. It pins:

```text
agent_type = luna_worker
model      = gpt-5.6-luna
effort     = max
```

Do not add a default-subagent `[agents]` block to `config.toml`. The worker model and effort live in the standalone role file.

## 2. Update your global AGENTS.md

Open:

```text
~/.codex/AGENTS.md
```

Replace only your existing model/subagent-routing section with the contents of [`agents-subset.md`](agents-subset.md).

Keep all unrelated personal instructions in your `AGENTS.md`. The global file now contains only parent/orchestration rules; worker-specific behavior lives in `agents/luna-worker.toml`.

## 3. Generate models.json from your installed Codex

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

## 4. Update config.toml

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

Configure native multi-agent support like this:

```toml
[features]
multi_agent = true

[features.multi_agent_v2]
enabled = true
multi_agent_mode_hint_text = ""
```

If `[features]` already exists, merge `multi_agent = true` into that existing table instead of creating a second `[features]` table.

The empty `multi_agent_mode_hint_text` does **not** disable Multi-Agent V2 or native subagents. It suppresses the additional `<multi_agent_mode>` developer policy so routing stays controlled by `AGENTS.md` and the `luna_worker` role.

Do not replace the empty hint with a long proactive prompt. In the tested setup, an aggressive custom proactive policy expanded a narrow task and caused overlapping Luna workers and duplicate validation.

Do **not** add this old default-subagent form:

```toml
[agents]
enabled = true
default_subagent_model = "gpt-5.6-luna"
default_subagent_reasoning_effort = "max"
```

The installed Codex build used for this setup rejected that form. Use the standalone `~/.codex/agents/luna-worker.toml` role instead.

If Memories are enabled, route both background memory stages through Luna:

```toml
[memories]
extract_model = "gpt-5.6-luna"
consolidation_model = "gpt-5.6-luna"
```

For Codex CLI 0.147.0, memory extraction already defaults to `gpt-5.6-luna`, while memory consolidation defaults to `gpt-5.6-terra`. The `extract_model` line makes the existing default explicit; the `consolidation_model` line is the actual override that moves background consolidation from Terra to Luna.

This does **not** disable Memories and does not guarantee a specific usage reduction. It only changes the model used for those background memory stages. If `[memories]` already exists, merge these two keys into the existing table.

## 5. Restart Codex

Fully close and reopen Codex, then create a **new task/thread** so the standalone `luna_worker` role and updated global instructions are discovered cleanly.

Old tasks keep any previously injected multi-agent-mode prompt in their history. Setting `multi_agent_mode_hint_text = ""` prevents a new `<multi_agent_mode>` developer message; it does not inject a new message that cancels an old one in an existing task.

## Optional quick check

Check the installed role:

```powershell
Get-Content "$HOME\.codex\agents\luna-worker.toml"
```

Check the generated catalog and efforts:

```powershell
(Get-Content "$HOME\.codex\models.json" -Raw | ConvertFrom-Json).models |
    Select-Object slug, default_reasoning_level, multi_agent_version, supports_parallel_tool_calls,
        @{Name="efforts";Expression={($_.supported_reasoning_levels.effort -join ",")}}
```

Expected catalog shape:

```text
gpt-5.6-sol   high   v2   True   high,xhigh
gpt-5.6-luna  max    v2   True   max
```

Then start a new Sol High task and ask it to spawn `agent_type = "luna_worker"` with `fork_turns = "none"` and return only `LUNA_WORKER_OK`.

Verify in the subagent details or historical JSONL that the child actually ran as:

```text
role   = luna_worker
model  = gpt-5.6-luna
effort = max
```

Expected routing:

```text
Sol High    -> main/orchestrator
Sol xhigh   -> manual escalation only
luna_worker -> Luna Max delegated worker
```
