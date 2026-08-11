# Codex routing rules

A small shared rule for both PCs. The actual policy is in [`AGENTS.md`](AGENTS.md).

The intended setup is deliberately simple:

```text
Sol High  -> main agent, reasoning, decomposition, review
Luna Max  -> implementation, tests, build/deploy/monitoring loops
```

Use the repository as the source of truth. On each PC, pull the latest version and copy or link the short `AGENTS.md` policy into the global Codex instructions you already use.

There are no installers, update scripts, generated configs, or automatic model-catalog changes in this repository.
