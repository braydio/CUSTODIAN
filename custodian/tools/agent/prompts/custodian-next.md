---
description: Continue the current CUSTODIAN workstream or claim its immediate next packet; otherwise claim the next eligible CUSTODIAN packet.
---

Use the repository-local `custodian-next` skill and execute it now.

Interpret this shortcut contextually:

- If this Codex session is already in a live `agent/<workstream-id>` checkout,
  continue that workstream. Do not claim another packet.
- Otherwise prefer the exact `Next workstream` from the most recently completed
  CUSTODIAN packet/review discussed in this session, using its durable archived
  packet or closing summary as authority.
- If that successor is eligible, claim it explicitly with
  `python3 custodian/tools/agent/dispatch.py claim <id> --agent codex`.
- If that continuation requires ChatGPT/user refresh, is blocked/manual, or has
  an unsatisfied dependency, stop and report the blocker and exact recorded
  refresh-chat URL. Do not jump to unrelated work.
- If there is no same-series successor, use
  `python3 custodian/tools/agent/dispatch.py claim-next --agent codex`.
- After a claim, enter the returned worktree, read `AGENTS.md`,
  `custodian/AGENTS.md`, and the packet, then execute the packet without asking
  the user to restate the brief.
