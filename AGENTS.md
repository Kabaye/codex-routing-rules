# Codex model routing

Use only two normal roles:

- **GPT-5.6 Sol / High** — main agent, orchestrator, architecture, difficult decisions, and final review.
- **GPT-5.6 Luna / Max** — implementation, repository exploration, tests, build/fix loops, deploy, monitoring, and other tool-heavy work.

## Default workflow

1. Start the task in **Sol High**.
2. Sol clarifies the goal, constraints, risks, and acceptance criteria.
3. Sol keeps very small changes itself, but delegates long or repetitive execution to Luna Max through the existing working CLI/thread flow.
4. Luna returns only a compact result: changed files, diff summary, checks, commit SHA, risks, and decisions still required. Do not return full transcripts or large logs to Sol.
5. Sol resolves open decisions, reviews the focused result, and decides whether more work is required.
6. When deployment is requested and authorized, prefer a fresh Luna Max operator session for deploy, blocking rollout monitoring, health checks, and verification.

## Delegation rules

- Use one Luna worker by default; use at most two only for independent tasks.
- Parallel writing requires separate worktrees and non-overlapping file ownership.
- Do not allow nested delegation unless explicitly requested.
- Luna must stop and return a `DECISION REQUIRED` summary when architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility require stronger judgment.
- Keep raw JSONL, full test output, build logs, and deployment logs outside the Sol context.
- Production writes, pushes, migrations, and deploys still require authorization from the current request or an explicit repository runbook.

## Model limits

- **Sol xhigh**: manual emergency escalation only.
- Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Do not assume native `spawn_agent` supports Luna; use the existing working Luna CLI/thread mechanism.
