# Codex model routing

- Use **GPT-5.6 Sol / High** as the main agent: understand the task, make difficult decisions, split work, and review the result.
- Use **GPT-5.6 Luna / Max** as the default delegated worker for implementation, repository exploration, tests, build/fix loops, deploy, monitoring, and other tool-heavy work.

## Subagents

- Prefer **native Codex multi-agent tools** for Luna. Spawn Luna with `model="gpt-5.6-luna"` and `reasoning_effort="max"`; use the normal native agent lifecycle (`spawn_agent`, `wait_agent`, `send_input`, `resume_agent`, `close_agent`) as needed.
- Give every Luna agent a concrete role, scope, working directory/ownership boundary, self-contained task, acceptance criteria, and validation commands.
- Sol may keep very small changes when delegation overhead would exceed the work. Long or repetitive repository/tool loops should normally go to Luna.
- There is **no fixed maximum number of Luna agents**. Launch additional agents only when their tasks are genuinely independent and parallel execution is useful.
- Read-only agents may inspect the same checkout concurrently. Parallel writers should normally use separate worktrees; sharing one checkout is acceptable only with explicitly disjoint file ownership and no likely collision through lockfiles, migrations, generated files, shared configuration, Git operations, or build state.
- Do not create unnecessary nested agent trees. The Sol parent remains responsible for decomposition, reviewing child results, resolving conflicts, integration, and final validation.
- Use native waiting/control rather than keeping Sol busy with frequent progress polling. Routine heartbeats, long build/deploy logs, and repeated status output should stay out of the Sol context; wake/re-engage Sol when a child needs a decision, completes, fails, or materially changes the plan.
- Luna should return concise results: changed files, diff summary, checks, commit SHA when relevant, risks, and decisions still required. When architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility require stronger judgment, return a clear `DECISION REQUIRED` summary and let Sol decide.
- For an authorized deploy or long operational workflow, a dedicated Luna agent may own deployment, blocking rollout/build monitoring, health checks, and verification instead of making Sol babysit the operation.

- **Sol xhigh** is manual emergency escalation only. Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
