# Codex routing rules

Four installable profiles. Install only one at a time.

## lite

`Luna Max -> luna_worker (Luna Max)`

Beginner-friendly profile: Luna Max is the only available model, leads the conversation in clear Russian, handles the actual work, and may run at most one Luna Max subagent when that genuinely helps. The profile generates a strict local model catalog that exposes only **Luna Max**.

- Install: [`lite/install-lite.md`](lite/install-lite.md)
- Remove: [`lite/remove-lite.md`](lite/remove-lite.md)

## x5

`Sol xhigh -> luna_worker (Luna Max)`

Economical delegated-work profile: Sol xhigh remains the root for reasoning, architecture, coordination, and final acceptance; Luna Max owns substantial actual execution. Delegation stays conservative and avoids duplicate work. Memories are routed through Luna.

- Install: [`x5/install-x5.md`](x5/install-x5.md)
- Remove: [`x5/remove-x5.md`](x5/remove-x5.md)

## x20-work

`Sol xhigh root -> Luna Max delegated agents by default`

Work profile with a hard Luna-first gate: before explicit user authorization, every delegated agent is **Luna Max**, regardless of task complexity, verification needs, release responsibility, or available concurrency. Sol xhigh subagents become eligible only when the user explicitly instructs the current objective to use **Sol X High agents** (for example, `используй агентов Sol X High`). That instruction unlocks coordinator discretion rather than forcing Sol everywhere: the root may mix Luna Max and Sol xhigh per coherent workstream, keeping operational/tool-heavy work on Luna when appropriate and reserving Sol xhigh for work where stronger reasoning materially helps. A new unrelated objective returns to Luna-only delegation. The profile allows at most two concurrent subagents and routes Memories through Luna.

- Install: [`x20-work/install-x20-work.md`](x20-work/install-x20-work.md)
- Remove: [`x20-work/remove-x20-work.md`](x20-work/remove-x20-work.md)

## x20

`Sol xhigh -> sol_worker (Sol xhigh)`

Performance profile: proactive delegation is allowed when parallel work materially reduces wall-clock time, when a fresh independent verifier materially improves confidence, or when independent release/monitoring work can run without blocking the root. It does not spawn agents for serial/dependent work, duplicated work, or merely because concurrency slots are available. The profile is technically capped at two concurrent subagents and uses Codex's default model catalog.

- Install: [`x20/install-x20.md`](x20/install-x20.md)
- Remove: [`x20/remove-x20.md`](x20/remove-x20.md)

Each profile contains its own `AGENTS.md` routing subset and standalone native worker role(s).
