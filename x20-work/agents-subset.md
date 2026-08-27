## Scope routing

- Default every new objective to **work scope**. Never infer `non-work` from the topic, repository, time, user identity, or surrounding context.
- Activate the expensive lane only when the user includes a standalone directive `scope: non-work`. A standalone `scope: work` directive forces or restores the default lane.
- `scope: non-work` applies to the current coherent objective and its direct follow-ups. A new unrelated objective resets to **work scope** unless the user marks it again.
- If the scope is absent or ambiguous, stay in **work scope**. Do not ask a clarifying question merely to decide whether to spend more tokens.

## Work scope — default

- Use **GPT-5.6 Sol / High** as the root agent for reasoning, architecture, decomposition, coordination, integration, and final acceptance.
- Use the native `luna_worker` role for substantial delegated work and actual task execution: computer use, vision, browser/UI interaction, repository exploration, implementation, logs, tests/builds, and other tool-heavy work. The role pins **GPT-5.6 Luna / Max**.
- Sol may keep very small changes when delegation overhead would exceed the work.

## Non-work scope — explicit override

- Keep the root on **GPT-5.6 Sol / High** as a lightweight coordinator, integrator, and final acceptor.
- Delegate the substantive work to the native `sol_worker` role, which pins **GPT-5.6 Sol / xhigh**. For a non-trivial `scope: non-work` objective, the root should avoid duplicating the worker's reasoning or implementation.
- Use additional `sol_worker` agents only for genuinely independent work when parallel execution materially reduces wall-clock time or an independent verifier materially improves confidence.

## Ownership and coordination

- Decompose by coherent workstreams, not technical layers. One workstream may span backend, frontend, shared contracts, migrations, tests, computer use, browser/UI work, and multiple files.
- One worker owns one coherent workstream through exploration, implementation, fixes, and its own test/build loop. Reuse that owner while the objective, ownership, and role remain materially the same; do not respawn for every finding or internal phase.
- If verification or production evidence reveals more work within the same objective, return it to the same implementation owner. Use a fresh verifier or release worker only when responsibility truly changes and the new diff/release artifact warrants it.
- Delegated work replaces, not duplicates, the same work in the root or another worker.
- Use `fork_turns = "none"` by default and give the worker a self-contained handoff. If recent parent conversation context is genuinely needed, use the smallest useful positive bounded `fork_turns`. Never use full-history `fork_turns = "all"`.
- Use at most **two** subagents concurrently. Do not fill concurrency slots merely because they are available.
- Do not use nested delegation by default. Use native wait/coordination instead of busy polling.
- Parallel writers should normally use separate worktrees; a shared checkout is acceptable only with explicitly disjoint ownership and no shared-state, Git, or build collisions.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
- The root inspects actual diffs and reruns key acceptance checks before final acceptance.

## Model limits

- Root model/effort: **GPT-5.6 Sol / High**.
- Work-scope delegated model/effort: **GPT-5.6 Luna / Max** via `luna_worker`.
- Non-work-scope delegated model/effort: **GPT-5.6 Sol / xhigh** via `sol_worker`.
- Do not automatically use Terra, GPT-5.5, Sol Max, Fast, Ultra, or other models/efforts.
