# Codex model routing

- Use **GPT-5.6 Sol / High** as the main agent: understand the task, make difficult decisions, split work, and review the result.
- Use **GPT-5.6 Luna / Max** for implementation, repository exploration, tests, build/fix loops, deploy, monitoring, and other tool-heavy work.

## Subagents

- Native Codex multi-agent spawning/control is disabled for delegated work. Do not use `spawn_agent`, `wait_agent`, multi-agent `send_input`, `resume_agent`, or `close_agent` unless the user explicitly overrides this policy for the current task. Messaging already-existing Codex tasks/threads is still allowed.
- **Luna must be CLI-backed only.** Launch delegated Luna work through `$HOME\.codex\bin\codex-luna-subagent.ps1`; never configure or launch Luna as a native/custom Codex agent. The default contract is `codex exec --model gpt-5.6-luna` with `model_reasoning_effort="max"` and `agents.enabled=false`.
- Give every Luna run a concrete name, role, working directory, sandbox, self-contained task, acceptance criteria, and validation commands. Keep its artifacts under the target workspace's `temp/codex-subagents` directory.
- Prefer `read-only` for exploration/advice/verification, `workspace-write` for explicit edit scopes, and `danger-full-access` only when the parent task already authorizes that level and it is genuinely required.
- Use one Luna worker by default, but there is **no fixed maximum**. Launch additional workers only when their tasks are genuinely independent and parallel execution is worthwhile. Read-only workers may share a checkout. Parallel writers should normally use separate worktrees; sharing one checkout is allowed only with explicitly disjoint file ownership and no collision through lockfiles, migrations, generated files, shared config, Git operations, or build state.
- For background work, use the wrapper's `-Background` mode and then its returned **blocking wait command** / `-WaitRun`. **Never keep Sol active by polling `console.log` every few seconds.** Waiting/polling must happen locally inside the wrapper; Sol should regain control only on `DECISION_REQUIRED`, `COMPLETED`, `FAILED`, or `TIMEOUT`.
- `last-message.md` is the normal parent-facing result. `console.log` is for human/debug inspection and should be read only on failure, timeout, missing final output, or explicit debugging. Keep routine heartbeats, build/deploy progress, and large logs outside Sol context.
- Long waits such as builds, Jenkins jobs, Kubernetes rollouts, deploys, and health monitoring should run inside the Luna task or through blocking local commands rather than repeated parent-agent turns.
- Luna returns a concise summary: changed files, diff summary, checks, commit SHA, risks, and decisions required. When architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility require stronger judgment, Luna returns `DECISION REQUIRED` and Sol decides.
- No nested delegation by default. Sol remains responsible for reviewing Luna results, integrating changes, and final validation.

- Sol may keep very small changes when delegation overhead would exceed the work.
- Use a fresh Luna CLI session for an authorized deploy and rollout monitoring.
- **Sol xhigh** is manual emergency escalation only. Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
