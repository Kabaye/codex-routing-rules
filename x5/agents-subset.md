## Agent routing

- Use **GPT-5.6 Sol / High** as the main agent for reasoning, architecture, decomposition, coordination, integration, and final acceptance.
- Use the native `luna_worker` role for substantial delegated work and actual task execution: computer use, vision, browser/UI interaction, repository exploration, implementation, logs, tests/builds, and other tool-heavy work. Its role file pins **GPT-5.6 Luna / Max**; do not add per-spawn model/effort overrides.
- Use `fork_turns = "none"` by default and give the worker a self-contained handoff. If the worker genuinely needs recent parent conversation context, use the smallest useful positive bounded `fork_turns`. Never use full-history `fork_turns = "all"`.
- Sol may keep very small changes when delegation overhead would exceed the work.

### Ownership and coordination

- One `luna_worker` owns one coherent workstream end-to-end. A workstream may span backend, frontend, shared contracts, migrations, tests, and multiple files. Reuse that owner through its own implementation/fix/test loop; do not respawn for every finding or internal phase change.
- Add another worker only for genuinely independent work. Delegated work should replace, not duplicate, the same exploration or implementation in Sol.
- Use a fresh worker when responsibility truly changes, such as independent verification or release/deploy. After `interrupt_agent`, start a fresh worker for a new objective or role instead of reactivating it with `followup_task`.
- If verification or production evidence reveals more work within the same objective, return it to the same owner; after the owner produces a new diff or release artifact, use fresh verification or release workers as needed.
- Do not use nested delegation by default. Parallel writers should normally use separate worktrees; a shared checkout is acceptable only with explicitly disjoint ownership and no shared-state, Git, or build collisions.
- Use native wait/coordination instead of frequent Sol polling. Sol inspects the actual diff and reruns key acceptance checks before final acceptance.

### Model limits

- **Sol High** is the normal parent/orchestrator effort; **Sol xhigh** is manual escalation only.
- **Luna Max** is the only delegated worker model/effort in this setup. Do not automatically use Sol Max, Terra, GPT-5.5, Fast, or Ultra.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.
