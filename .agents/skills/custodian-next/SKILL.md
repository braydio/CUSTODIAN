---
name: custodian-next
description: Continue the current CUSTODIAN workstream or claim the next eligible CUSTODIAN task packet using the repository dispatcher and durable Next Handoff metadata.
---

# CUSTODIAN Next

Use this skill when the user says "next CUSTODIAN task", "claim the next packet",
"continue the workstream", or invokes the installed `/prompts:custodian-next`
shortcut.

## Routing

1. **Do not create a second claim while already inside active work.**
   - Run `git branch --show-current`.
   - If the branch is `agent/<workstream-id>`, continue that workstream from its
     packet and current state. Do not claim another packet merely because one is
     available.
   - If ownership is unclear, use
     `python3 custodian/tools/agent/dispatch.py last-claim --json` as read-only
     recovery evidence. The dispatch receipt, not terminal history, is claim authority.

2. **Prefer the immediate continuation of the work the conversation just finished.**
   - Fetch current packet truth through the dispatcher/repository workflow.
   - Resolve the most recently completed/reviewed workstream from the current
     conversation and durable repo evidence.
   - Read its archived packet/closing summary `## Next Handoff`.
   - If `Next workstream` names an exact successor and that successor is eligible,
     claim it explicitly:
     ```bash
     python3 custodian/tools/agent/dispatch.py claim <next-workstream> --agent codex
     ```
   - A paired review named by the completed implementation is a normal immediate
     successor and should be preferred over unrelated global work.

3. **Respect refresh and dependency gates.**
   - If the handoff says ChatGPT/user planning refresh is required, the next packet
     is blocked/manual, or the named successor is otherwise not eligible, stop.
   - Report the exact blocker and recorded authoring/refresh chat URL.
   - Do not edit packet status, silently reinterpret scope, or skip to unrelated
     work just to keep the command moving.

4. **Fall back to the global queue only when there is no same-series continuation.**
   - If the durable handoff says `Next workstream: none`, the prior work has no
     named successor, or no prior CUSTODIAN workstream can be resolved from this
     session, run:
     ```bash
     python3 custodian/tools/agent/dispatch.py claim-next --agent codex
     ```

5. **After a successful claim, trust the structured receipt.**
   - Enter the returned worktree.
   - Read root `AGENTS.md`, `custodian/AGENTS.md`, and the returned task packet.
   - Treat the task packet as the complete brief. Do not ask the user to restate it.
   - Execute and finish through the normal workstream lifecycle.

## Result

Return one compact status:
- `CONTINUING <workstream>` when already in the active claimed worktree;
- `CLAIMED <workstream>` plus returned worktree when a claim succeeds;
- `REFRESH REQUIRED <workstream>` plus the exact recorded chat URL when planning
  is the gate;
- `BLOCKED <reason>` when a named continuation cannot proceed;
- `NO ELIGIBLE AUTO TASK` when the global dispatcher has no eligible work.
