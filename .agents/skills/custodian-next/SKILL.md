---
name: custodian-next
description: Continue the current CUSTODIAN workstream or claim the next eligible CUSTODIAN task packet using the repository dispatcher and durable Next Handoff metadata.
---

# CUSTODIAN Next

Use this skill when the user says "next CUSTODIAN task", "claim the next packet",
"continue the workstream", explicitly invokes `$custodian-next`, or selects
**CUSTODIAN Next** from `/skills` / the slash picker.

## Routing

1. **Do not create a second claim while already inside active work.**
   - Run `git branch --show-current`.
   - If the branch is `agent/<workstream-id>`, continue that workstream from its
     packet and current state. Do not claim another packet merely because one is
     available.
   - If that active workstream is waiting on required/conditional Dropbox visual
     review, return `HUMAN REVIEW REQUIRED <workstream>` with the exact recorded
     Authoring chat URL and `REVIEW_MANIFEST.json` path. Do not fall through to
     another claim. After the ChatGPT/user decision returns, continue the same
     workstream, run the manifest cleanup command unless retention was explicit,
     then close it normally.
   - If ownership is unclear, use
     `python3 custodian/tools/agent/dispatch.py last-claim --json` as read-only
     recovery evidence. The dispatch receipt, not terminal history, is claim authority.

2. **Prefer the immediate continuation of the work the conversation just finished.**
   - Fetch current packet truth through the dispatcher/repository workflow.
   - Resolve the most recently completed/reviewed workstream from durable repo evidence.
   - Read its archived packet/closing summary `## Next Handoff`.
   - If an exact successor is eligible and `ChatGPT/user planning refresh required: no`,
     claim it and continue without handing routine control back to the user.
   - After that successor finishes, persist its `<TASK>_CLAUDE_SUMMARY.md` and
     repeat this same routing step through the named same-series chain.
   - A paired review is an immediate successor but must run in a fresh reviewer
     context; that freshness requirement does not turn it into a user relay step.

3. **Stop only at a real gate.**
   - Stop before claiming when ChatGPT/user planning refresh is required, a
     subjective human decision is pending, dispatch is explicitly user-held, or a
     technical/safety blocker makes the named successor ineligible.
   - For a planning refresh, return the exact Authoring Chat URL, copyable
     Workstream ID, and persistent summary path.
   - `Refresh owner: execution-agent` is an autonomous bounded refresh unless it
     exposes a genuinely new human-owned decision.
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
   - Read `authoring_chat`, `visual_review`, `visual_review_root`, and
     `visual_review_retention` from the receipt. These are the autonomous route to
     the authoring conversation and Dropbox review lane when presentation review
     is required.
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
- `HUMAN REVIEW REQUIRED <workstream>` plus exact Authoring chat and Dropbox manifest when the active workstream is waiting on subjective review;
- `BLOCKED <reason>` when a named continuation cannot proceed;
- `NO ELIGIBLE AUTO TASK` when the global dispatcher has no eligible work.