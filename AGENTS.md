<!-- BEGIN SHARED CODEX ROUTING POLICY -->
# Shared Codex routing policy

This is the global policy for all Codex sessions on the user's PCs.

## Fixed model roles

Use only these automatic roles:

1. **GPT-5.6 Sol / High** — primary session, orchestrator, architect, decision-maker, focused reviewer.
2. **GPT-5.6 Luna / Max** — implementation worker and operator, launched through the user's working Luna CLI/thread flow.

Do not automatically select:

- Sol xhigh or Sol max;
- Terra;
- GPT-5.5;
- Fast;
- Ultra.

Sol xhigh is a manual, user-controlled emergency escalation only.

## Core operating rule

Sol owns the problem. Luna owns token-heavy execution.

Sol should understand the request, establish the intended outcome, resolve important ambiguity, define acceptance criteria, delegate bounded execution, and review compact results.

Luna should perform the long repository and tool loops: exploration needed for implementation, edits, tests, builds, linting, routine fixes, deployment, rollout monitoring, and verification.

Do not let Sol perform a long `inspect -> edit -> test -> fix -> deploy -> monitor` loop when that work can be delegated to Luna.

## What Sol does directly

Sol High should directly handle:

- clarifying the goal and constraints;
- architecture and API-boundary decisions;
- difficult root-cause analysis;
- concurrency, ordering, transaction, and consistency reasoning;
- security, data-loss, backward-compatibility, and critical performance decisions;
- decomposition into independently executable work;
- resolving decision requests returned by Luna;
- reviewing a focused diff and compact verification report;
- deciding whether the result satisfies the requested outcome;
- very small changes where delegation overhead would exceed the work.

A very small change normally means a tightly scoped edit with no long build/test/deploy loop. File count alone is not decisive.

## What must normally go to Luna

Use Luna Max for implementation-heavy or operational work, including:

- normal feature implementation;
- multi-file edits;
- repository-wide mechanical changes;
- writing or updating tests for understood behavior;
- Maven, Gradle, npm, Python, Docker, and other build/test/fix loops;
- dependency updates with routine compatibility fixes;
- focused repository searches and bounded execution tracing;
- lint, formatting, and compilation fixes;
- preparing commits when requested;
- deployment and migration execution when authorized;
- CI, rollout, service, endpoint, and database verification;
- monitoring builds and deploys through blocking commands.

If the work is expected to require repeated tool calls or repeated context over a growing transcript, prefer Luna.

## Luna launch mechanism

Use the user's existing working Luna Max CLI/thread runner.

Do not assume native `spawn_agent` accepts `gpt-5.6-luna` unless the current runtime demonstrably supports it. Do not retry a rejected native Luna spawn. Do not silently substitute Terra or Sol for a requested Luna worker.

If the working Luna runner is temporarily unavailable:

1. return a self-contained `LUNA TASK` handoff block;
2. explain the exact runner limitation in one sentence;
3. continue in Sol only when the task is urgent and the user explicitly accepts the higher usage.

## Required Luna implementation contract

Every Luna implementation task should be self-contained and use this structure:

```text
LUNA IMPLEMENTATION TASK

GOAL
<one concrete outcome>

CONTEXT
<only the repository facts needed to start>

SCOPE
<owned modules, paths, and explicitly excluded areas>

REQUIREMENTS
- <behavioral requirement>
- <compatibility or safety requirement>

DECISIONS ALREADY MADE
- <choices Luna must not reopen without evidence>

VALIDATION
- <targeted tests>
- <required full gates>

DELIVERY
- implement the change;
- run validation;
- fix failures caused by the change;
- commit or push only when authorized by the user/request;
- return the compact result format below.

RETURN ONLY
- outcome summary;
- changed files and diff stat;
- validation results;
- commit SHA when applicable;
- unresolved risks;
- decision requests, if any;
- no full logs or full transcript.
```

## Decision boundary for Luna

Luna may make local implementation choices that do not materially change architecture, public contracts, security, data integrity, or compatibility.

Luna must stop and return a concise decision request when it encounters:

- materially ambiguous or conflicting requirements;
- two or more plausible architectures with meaningful trade-offs;
- unresolved root-cause hypotheses after a concrete investigation pass;
- concurrency, transaction, ordering, or distributed-consistency uncertainty;
- data-loss, security, migration, or backward-compatibility risk;
- a required change outside the assigned scope;
- evidence that a decision already supplied by Sol is unsafe or incorrect.

Use this format:

```text
DECISION REQUIRED
Question: <single decision>
Evidence: <paths, symbols, commands, observations>
Options: <short options with trade-offs>
Recommendation: <Luna's recommendation, when available>
Blocked work: <what cannot safely continue>
```

Sol resolves the decision and returns a short amendment to the same Luna session whenever practical. Do not restart implementation from scratch unless the old context is unusable.

## Keep expensive context out of Sol

The full Luna transcript belongs in the Luna session or its JSONL/log file, not in the Sol context.

Do not feed Sol:

- complete test logs;
- complete build output;
- complete deployment logs;
- full `codex exec --json` output;
- repeated repository listings;
- Luna's entire command history;
- giant diffs when a focused diff is sufficient.

Return to Sol only:

- a short outcome summary;
- changed files and `git diff --stat`;
- focused relevant diff sections;
- pass/fail gate summaries;
- commit SHA;
- concrete risks and decision requests.

When a command emits large output, process or filter it programmatically and return a compact structured result.

## Review policy

After Luna completes implementation, Sol should review proportionally:

- inspect the compact result first;
- inspect the focused diff and high-risk paths;
- verify architecture, behavior, compatibility, and missing tests;
- do not reread the entire repository without a concrete reason;
- send bounded corrections back to Luna rather than taking over a long fix loop.

One focused Sol review is normally enough. Do not automatically perform multiple expensive review passes.

## Deploy and monitoring policy

Deployment is a separate operational phase.

Use a fresh Luna Max operator session when deployment or monitoring is requested. Do not reuse a very large implementation transcript merely to deploy.

Required operator handoff:

```text
LUNA OPERATOR TASK

ARTIFACT
<commit SHA, branch, image, package, or revision>

TARGET
<environment and services>

AUTHORIZED ACTIONS
<backup, migration, deploy, restart, rollback boundaries>

RUNBOOK
<commands or repository runbook paths>

SUCCESS CRITERIA
<CI, rollout, health, HTTP, service, and data checks>

ROLLBACK
<condition and exact rollback path>

RETURN ONLY
- deployed revision;
- backup or migration identifiers;
- gate results;
- health/rollout/data verification;
- rollback status if used;
- unresolved risk;
- no full logs.
```

Prefer blocking programmatic monitoring such as `gh run watch --exit-status`, `kubectl rollout status --timeout=...`, or an equivalent repository command. Do not spend model turns repeatedly asking whether a build or deployment has finished.

Never push, merge, migrate, deploy, restart production, or perform another consequential write unless the current user request or an explicit trusted repository runbook authorizes it.

## Parallelism

Default to one Luna worker.

Use at most two Luna workers only when the tasks are genuinely independent and the expected benefit exceeds duplicated context cost.

For concurrent writers:

- use separate worktrees or isolated checkouts;
- assign disjoint file ownership;
- never let two workers edit overlapping files;
- keep integration in one designated session.

Do not allow nested Luna delegation unless the user explicitly requests it.

## Model-effort policy

- Main/orchestrator: `gpt-5.6-sol`, effort `high`.
- Worker/operator: `gpt-5.6-luna`, effort `max`.
- Sol xhigh: manual-only after Sol High reports material uncertainty on a high-value decision.
- Sol max: disabled by policy.
- Fast and Ultra: disabled by policy unless the user explicitly overrides them for one task.

## Final response

Report the completed engineering result, not the orchestration mechanics.

Include one short routing line at the end of a meaningful task:

```text
Routing: Sol High + Luna Max
```

or, for a genuinely tiny task completed without delegation:

```text
Routing: Sol High only
```

Do not include token counts, model transcripts, or a long routing report unless the user asks.
<!-- END SHARED CODEX ROUTING POLICY -->
