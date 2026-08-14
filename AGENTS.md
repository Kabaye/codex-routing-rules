# Codex model routing

- Use **GPT-5.6 Sol / High** as the main agent: understand the task, make difficult decisions, split work, coordinate, and review the result.
- Use **GPT-5.6 Luna / Max** as the default delegated implementation model for repository exploration, coding, tests, build/fix loops, verification, deploy, monitoring, and other tool-heavy work.

## Subagents

- **Native Luna subagents are preferred.** Use Codex native multi-agent tools such as `spawn_agent`, `wait_agent`, `send_input`, `resume_agent`, and `close_agent` for Luna delegation when available. Spawn Luna with `model = "gpt-5.6-luna"` and `reasoning_effort = "max"`.
- Give each Luna agent a concrete role, scope, working directory, constraints, acceptance criteria, and validation commands. Keep delegated tasks self-contained.
- Use as many Luna agents as are genuinely useful; do not impose an arbitrary fixed maximum. Parallelize independent work, but avoid duplicate repository exploration and duplicated validation.
- Read-only agents may share the same checkout. Parallel writers should normally use separate worktrees; sharing one checkout is acceptable only with explicitly disjoint file ownership and no collisions through lockfiles, migrations, generated files, shared config, Git operations, or build state.
- Do not use nested delegation by default. Sol remains responsible for coordination, integrating results, and final validation.
- Do not keep Sol busy with frequent status polling. Use native agent waiting/coordination primitives and resume Sol when a child needs a decision, completes, fails, or times out. Routine heartbeats and large logs should stay outside the Sol context.
- Luna should return concise results: changed files, diff summary, checks, commit SHA when relevant, risks, and decisions required. When architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility need stronger judgment, Luna should return `DECISION REQUIRED` and Sol decides.
- For long-running deploy/monitoring tasks, Luna should own the waiting loop (Jenkins, Kubernetes rollout, health checks, etc.) rather than making Sol repeatedly poll external state.

- Sol may keep very small changes when delegation overhead would exceed the work.
- **Sol xhigh** is manual emergency escalation only. Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
