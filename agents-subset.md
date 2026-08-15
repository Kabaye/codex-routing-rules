## Agent routing

- Use **GPT-5.6 Sol / High** as the main agent: understand the task, make difficult decisions, decompose work, coordinate agents, integrate results, and review the final outcome.
- Use **GPT-5.6 Luna / Max** as the default delegated model for repository exploration, implementation, tests, build/fix loops, verification, deployment, monitoring, and other tool-heavy work.
- Prefer **native Codex subagents**. Spawn Luna with `model = "gpt-5.6-luna"` and `reasoning_effort = "max"`. When overriding the child model, use a bounded or empty history fork rather than a full-history fork.
- Give every Luna agent a concrete role, scope, constraints, acceptance criteria, validation commands, and file/system ownership where relevant.

### Luna lifecycle

- Prefer a **fresh Luna agent when the role or phase changes**. Reuse an existing Luna only while its objective, role, working scope, and assumptions remain materially the same.
- Do not repurpose one long-lived Luna across `exploration -> implementation -> independent verification -> release/deploy`. Close completed agents and spawn a fresh Luna with a concise handoff for the next phase.
- Reuse is appropriate inside one phase: for example, an implementation Luna may keep fixing its own tests/build errors until that implementation is complete.
- Prefer a fresh verification Luna after non-trivial implementation when an independent check is valuable.
- Use a fresh release/deploy Luna for an authorized deployment; a new master/final-SHA deployment should normally get a fresh release agent too.

### Parallelism and coordination

- Use one Luna for one bounded objective. Add more only for genuinely independent work, and avoid duplicate exploration or validation.
- Read-only agents may share a checkout. Parallel writers should normally use separate worktrees; sharing one checkout is acceptable only with explicitly disjoint ownership and no collisions through lockfiles, migrations, generated files, shared config, Git operations, or build state.
- Do not use nested delegation by default. Sol remains responsible for orchestration, integration, conflict prevention, and final validation.
- Do not keep Sol busy with frequent status polling. Use native `wait_agent`/coordination primitives; resume Sol when a child needs a decision, completes, fails, or times out. Routine heartbeats and large logs stay outside Sol context.
- Luna returns concise results: changed files, diff summary, checks, commit SHA when relevant, risks, and decisions required.
- If architecture, ambiguity, concurrency, transactions, consistency, security, data-loss risk, or backward compatibility require stronger judgment, Luna returns `DECISION REQUIRED` and Sol decides.
- Long-running Jenkins/Kubernetes/build/deploy monitoring should be owned by the Luna phase agent rather than implemented as repeated Sol polling.

### Model limits

- Sol may keep very small changes when delegation overhead would exceed the work.
- **Sol High** is the normal parent/orchestrator effort.
- **Sol xhigh** is available for manual escalation when High is insufficient; do not select it automatically.
- **Luna Max** is the only Luna effort used by this routing setup.
- Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
