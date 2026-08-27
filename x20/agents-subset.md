## Agent routing

- Use **GPT-5.6 Sol / xhigh** as the root agent for reasoning, architecture, decomposition, coordination, integration, and final acceptance.
- All delegated agents must use the native `sol_worker` role, which pins **GPT-5.6 Sol / xhigh**. Do not use other models or per-spawn model/effort overrides.
- Use `fork_turns = "none"` by default and give the worker a self-contained handoff. If the worker genuinely needs recent parent conversation context, use the smallest useful positive bounded `fork_turns`. Never use full-history `fork_turns = "all"`.
- Delegate proactively only when it has concrete value: parallel work can materially reduce wall-clock time, a fresh independent verifier materially improves confidence, or independent release/monitoring work can proceed without blocking the root.
- Do not spawn agents for serial/dependent work, duplicated exploration or implementation, merely because a task is large, or merely because concurrency slots are available.
- Use at most **two subagents concurrently**. Do not fill concurrency slots merely because they are available.

### Ownership and coordination

- Decompose by coherent workstreams, not by technical layers. One workstream may span backend, frontend, shared contracts, migrations, tests, computer use, browser/UI work, and multiple files.
- For one serial workstream where the root would only wait for a child, keep the work in the root. When two or more genuinely independent workstreams exist, prefer parallel `sol_worker` agents and let the root own only distinct work.
- One worker owns its workstream through its own implementation/fix/test loop. Do not create a new agent for every finding or internal phase change.
- Delegated work replaces, not duplicates, the same work in the root or another worker.
- Use a fresh worker for independent verification when it materially adds confidence, and a fresh worker for an authorized release/deploy when that responsibility is distinct. If verification or production evidence reveals more work within the same objective, return it to the same implementation owner; use fresh verification/release workers for the resulting new diff or release artifact as needed.
- Do not use nested delegation by default. Parallel writers should normally use separate worktrees; a shared checkout is acceptable only with explicitly disjoint ownership and no shared-state, Git, or build collisions.
- Use native wait/coordination instead of busy polling. Workers return concise evidence; the root inspects actual diffs and reruns key acceptance checks before final acceptance.
- Production writes, pushes, migrations, and deploys require explicit authorization or an existing repository runbook.

### Model limits

- **GPT-5.6 Sol / xhigh** is the only root and sub-agent model/effort in this profile.
- Do not automatically use Luna, Terra, GPT-5.5, Sol High, Sol Max, Fast, or Ultra.
