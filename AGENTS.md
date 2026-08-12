# Codex model routing

- Use **GPT-5.6 Sol / High** as the main agent: understand the task, make difficult decisions, split work, and review the result.
- Use **GPT-5.6 Luna / Max** for implementation, repository exploration, tests, build/fix loops, deploy, monitoring, and other tool-heavy work.
- **Native Luna agents are forbidden:** never use `spawn_agent` or native/custom-agent configuration for Luna. Launch Luna strictly through the existing separate Codex CLI/thread flow.
- Sol may keep very small changes when delegation would cost more than the work.
- Give Luna a self-contained goal, scope, constraints, acceptance criteria, and validation commands.
- Luna returns only a concise summary: changed files, diff summary, checks, commit SHA, risks, and decisions required. Keep full transcripts and large logs outside Sol context.
- Do not keep Sol active by polling Luna logs every few seconds. Polling and waiting must run inside the Luna CLI session or a local wrapper; wake Sol only for `DECISION REQUIRED`, `COMPLETED`, `FAILED`, or `TIMEOUT`. Keep routine heartbeats and live logs outside Sol context.
- When architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility require judgment, Luna returns `DECISION REQUIRED` and Sol decides.
- Use one Luna worker by default, but there is no fixed maximum. Launch additional Luna CLI workers only when their tasks are genuinely independent and parallel execution is worthwhile. Read-only workers may share the same checkout. Parallel writers should normally use separate worktrees; they may share one checkout only when file ownership is explicitly disjoint and they cannot collide through shared lockfiles, migrations, generated files, configuration, Git operations, or build state. No nested delegation by default.
- Use a fresh Luna CLI session for an authorized deploy and rollout monitoring.
- **Sol xhigh** is manual emergency escalation only. Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
