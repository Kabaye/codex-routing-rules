## Agent routing

- Use **GPT-5.6 Sol / xhigh** as the root agent for reasoning, architecture, decomposition, coordination, integration, and final acceptance.
- **Hard default:** every delegated agent must use the native `luna_worker` role, which pins **GPT-5.6 Luna / Max**. This applies to implementation, exploration, computer use, vision, browser/UI work, tests/builds, verification, release/deploy work, monitoring, and every other delegated responsibility.
- Task complexity, urgency, expected quality, parallelism, verification value, release responsibility, available concurrency slots, or any other inferred condition never authorizes a Sol xhigh subagent. If uncertain, use `luna_worker`.
- The native `sol_worker` role may be used only when the user explicitly instructs the current objective to use **Sol X High agents**, for example `используй агентов Sol X High` or `используя агентов Sol X High`. Merely mentioning Sol X High, using this profile, saying `non-work`, asking for maximum quality, or implying that stronger agents would help is not authorization.
- Explicit Sol X High-agent authorization applies only to the current coherent objective and its direct follow-ups. A new unrelated objective returns to Luna Max-only delegation unless the user explicitly authorizes Sol X High agents again.
- When a `sol_worker` is legitimately spawned, include the exact marker `SOL_XHIGH_AGENTS_EXPLICITLY_REQUESTED` in its handoff. Never include that marker unless the user's current objective explicitly authorized Sol X High agents.
- Do not ask the user whether to upgrade a task to Sol X High agents. Without explicit authorization, continue with Luna Max.

## Ownership and coordination

- Decompose by coherent workstreams, not technical layers. One workstream may span backend, frontend, shared contracts, migrations, tests, computer use, browser/UI work, and multiple files.
- One worker owns one coherent workstream through exploration, implementation, fixes, and its own test/build loop. Reuse that owner while the objective, ownership, and role remain materially the same; do not respawn for every finding or internal phase.
- If verification or production evidence reveals more work within the same objective, return it to the same implementation owner. Use a fresh verifier or release worker only when responsibility truly changes and the new diff/release artifact warrants it; unless Sol X High agents were explicitly authorized, that fresh worker is also `luna_worker`.
- Delegated work replaces, not duplicates, the same work in the root or another worker.
- Use `fork_turns = "none"` by default and give the worker a self-contained handoff. If recent parent conversation context is genuinely needed, use the smallest useful positive bounded `fork_turns`. Never use full-history `fork_turns = "all"`.
- Use at most **two subagents concurrently**. Do not fill concurrency slots merely because they are available.
- Do not use nested delegation by default. Use native wait/coordination instead of busy polling.
- Parallel writers should normally use separate worktrees; a shared checkout is acceptable only with explicitly disjoint ownership and no shared-state, Git, or build collisions.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
- The root inspects actual diffs and reruns key acceptance checks before final acceptance.

## Model limits

- Root model/effort: **GPT-5.6 Sol / xhigh**.
- Default and mandatory delegated model/effort: **GPT-5.6 Luna / Max** via `luna_worker`.
- **GPT-5.6 Sol / xhigh** via `sol_worker` is allowed only after an explicit user instruction to use Sol X High agents for the current objective.
- Do not automatically use Terra, GPT-5.5, Sol High, Sol Max, Fast, Ultra, or other models/efforts.
