# Codex routing rules

Three installable profiles. Install only one at a time.

## lite

`Luna Max -> luna_worker (Luna Max)`

Beginner-friendly profile: Luna Max is the only available model, leads the conversation in clear Russian, handles the actual work, and may run at most one Luna Max subagent when that genuinely helps. The profile generates a strict local model catalog that exposes only **Luna Max**.

- Install: [`lite/install-lite.md`](lite/install-lite.md)
- Remove: [`lite/remove-lite.md`](lite/remove-lite.md)

## x5

`Sol High -> luna_worker (Luna Max)`

Economical profile: Sol owns reasoning, architecture, coordination, and final acceptance; Luna owns substantial actual execution. Delegation stays conservative and avoids duplicate work.

- Install: [`x5/install-x5.md`](x5/install-x5.md)
- Remove: [`x5/remove-x5.md`](x5/remove-x5.md)

## x20

`Sol xhigh -> sol_worker (Sol xhigh)`

Performance profile: proactive delegation is allowed when parallel work materially reduces wall-clock time, when a fresh independent verifier materially improves confidence, or when independent release/monitoring work can run without blocking the root. It does not spawn agents for serial/dependent work, duplicated work, or merely because concurrency slots are available. The x20 profile uses Codex's default model catalog and does not create a custom `models.json`.

- Install: [`x20/install-x20.md`](x20/install-x20.md)
- Remove: [`x20/remove-x20.md`](x20/remove-x20.md)

Each profile contains its own `AGENTS.md` routing subset and standalone native worker role.
