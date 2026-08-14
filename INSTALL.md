# Install

This repo is intentionally manual: no installer scripts.

## 1. Update your global AGENTS.md

Open your global Codex instructions:

```text
~/.codex/AGENTS.md
```

Replace your existing model/subagent-routing section with the contents of [`agents-subset.md`](agents-subset.md).

Do not replace unrelated personal instructions in your `AGENTS.md`.

## 2. Install the model catalog

Copy [`models.json`](models.json) to:

```text
~/.codex/models.json
```

This is the shared filtered catalog used on both PCs.

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

Ensure multi-agent is enabled. If `[features]` already exists, merge these keys into the existing table instead of creating a second `[features]` table:

```toml
[features]
multi_agent = true
multi_agent_v2 = true
```

Do not add Fast/Ultra settings for this routing setup.

## 4. Restart Codex

Fully close and reopen Codex so it reloads `config.toml`, the model catalog, and global `AGENTS.md`.

## Optional quick check

Start a Sol High session and ask it to spawn one native Luna Max subagent that replies only with `LUNA_NATIVE_OK`.

Expected routing after install:

```text
Sol High -> main/orchestrator
Luna Max -> native delegated workers
```
