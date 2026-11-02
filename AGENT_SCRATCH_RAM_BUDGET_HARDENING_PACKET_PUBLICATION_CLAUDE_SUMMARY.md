# Agent Scratch RAM Budget Hardening — Packet Publication

Authoring chat: none

- Removed two clean, idle, agent-created `/tmp` worktrees (`custodian-coordination-82d0`, `custodian-main-validation-f6831452`, ~12 GB) with plain `git worktree remove`. `/tmp` is a 16 GB tmpfs; available RAM went 2.5 GB -> 13 GB.
- Authored draft/manual packet pair `agent-scratch-ram-budget-hardening-v1` and `review-agent-scratch-ram-budget-hardening-v1`; targeted authoring preflight PASS.
- Promoted both packets to ready/auto (preflight PASS, index written, check_ai_context 0 findings, changed validation 2/2) and landed via this publication workstream.
- Unresolved: which agent creates the `/tmp` worktrees is unknown (not repo code); check Codex config/wrapper. A tmpfs size cap is host config, listed as Deferred.
- Next: dispatcher keeps the implementation blocked until agent-validation-failure-attribution-v1 archives complete.
