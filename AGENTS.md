# Codex model routing

- Use **GPT-5.6 Sol / High** as the main agent: understand the task, make difficult decisions, split work, and review the result.
- Use **GPT-5.6 Luna / Max** through the existing CLI/thread flow for implementation, repository exploration, tests, build/fix loops, deploy, monitoring, and other tool-heavy work.
- Sol may keep very small changes when delegation would cost more than the work.
- Give Luna a self-contained goal, scope, constraints, acceptance criteria, and validation commands.
- Luna returns only a concise summary: changed files, diff summary, checks, commit SHA, risks, and decisions required. Keep full transcripts and large logs outside Sol context.
- When architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility require judgment, Luna returns `DECISION REQUIRED` and Sol decides.
- Use one Luna worker by default; at most two for independent tasks. Parallel writers need separate worktrees and non-overlapping files. No nested delegation by default.
- Use a fresh Luna session for an authorized deploy and rollout monitoring.
- **Sol xhigh** is manual emergency escalation only. Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
