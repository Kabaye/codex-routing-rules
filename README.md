# Codex routing rules

Shared global Codex policy for both of my PCs.

The policy is intentionally limited to two active model roles:

- **GPT-5.6 Sol / High** — main session, architecture, decomposition, difficult decisions, focused review.
- **GPT-5.6 Luna / Max** — implementation, tests, build/fix loops, deploy, rollout monitoring, and routine repository work.

`Sol xhigh` is manual-only. Terra, GPT-5.5, Fast, Ultra, and Sol Max are not selected automatically by these rules.

## Workflow

```text
Sol High
  -> defines the task and acceptance criteria
  -> launches a bounded Luna Max implementation session
  -> receives a compact result, not the full transcript
  -> reviews the focused diff and resolves decisions
  -> launches a fresh Luna Max operator session for deploy/monitoring when requested
```

The complete policy is in [`AGENTS.md`](AGENTS.md).

## Install on each PC

The repository is private, so authenticate GitHub CLI first.

```powershell
gh auth login
gh repo clone Kabaye/codex-routing-rules "$HOME\codex-routing-rules"
& "$HOME\codex-routing-rules\scripts\install.ps1"
```

The installer:

- merges the managed routing block into `~/.codex/AGENTS.md`;
- also updates a non-empty `~/.codex/AGENTS.override.md`, because that file has global precedence;
- preserves unrelated instructions;
- creates timestamped backups;
- sets the top-level Codex default to `gpt-5.6-sol` with `high` effort;
- removes only a top-level `service_tier = "fast"` override;
- does not alter profiles, MCP servers, providers, plugins, sandbox rules, or project configuration.

To install only the rules and leave `config.toml` untouched:

```powershell
& "$HOME\codex-routing-rules\scripts\install.ps1" -SkipConfig
```

Restart Codex after installation because global `AGENTS.md` guidance is loaded at the start of a run/session.

## Update both PCs

Run on each machine:

```powershell
& "$HOME\codex-routing-rules\scripts\update.ps1"
```

The updater performs a fast-forward-only `git pull` and reapplies the managed block. It refuses to pull when the local clone has uncommitted changes.

## Files

```text
AGENTS.md                 Global Sol/Luna routing policy
config.toml.example       Minimal Sol High default configuration
scripts/install.ps1       Safe, idempotent installer
scripts/update.ps1        Pull and reapply on a PC
```

## Important operating constraints

- Use the existing working Luna Max CLI/thread runner; do not assume native `spawn_agent` supports Luna.
- Keep full Luna JSONL, command logs, and build output outside the Sol context.
- Return only changed files, diff summary, checks, commit SHA, risks, and decision requests.
- Use one Luna implementer by default and at most two only for independent work in separate worktrees.
- Use a fresh Luna operator session for production deploy and monitoring.
- Production writes, pushes, merges, migrations, and deploys still require authorization from the current user request or an explicit repository runbook.

## Official Codex references

- Global instructions: https://learn.chatgpt.com/docs/agent-configuration/agents-md
- CLI and `codex exec`: https://learn.chatgpt.com/docs/developer-commands?surface=cli
- Configuration reference: https://learn.chatgpt.com/docs/config-file/config-reference
