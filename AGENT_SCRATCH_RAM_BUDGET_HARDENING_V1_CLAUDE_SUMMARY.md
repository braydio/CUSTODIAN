# Agent Scratch RAM Budget Hardening V1 — Authoring Summary

Authoring chat: none

- Removed two clean, idle, agent-created `/tmp` worktrees (`custodian-coordination-82d0`, `custodian-main-validation-f6831452`, ~12 GB) with plain `git worktree remove`. `/tmp` is a 16 GB tmpfs; available RAM went 2.5 GB -> 13 GB.
- Authored draft/manual packet pair `agent-scratch-ram-budget-hardening-v1` and `review-agent-scratch-ram-budget-hardening-v1`; targeted authoring preflight PASS.
- Not promoted, indexed, pushed or landed. Depends on `agent-validation-failure-attribution-v1` (holds `validation-infrastructure`).
- Unresolved: which agent creates the `/tmp` worktrees is unknown (not repo code); check Codex config/wrapper. A tmpfs size cap is host config, listed as Deferred.
- Promotion: set both to `ready`/`auto`, rerun preflight, `task_packet_index.py --write`, land on origin/main.
