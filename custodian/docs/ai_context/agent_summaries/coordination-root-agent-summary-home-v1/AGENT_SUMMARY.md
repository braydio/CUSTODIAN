# CUSTODIAN Coordination Root and Agent Summary Home

Workstream: coordination-root-agent-summary-home-v1
Agent: ChatGPT
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef81ab-23fc-83ea-8010-74334c76fb3a

## Goal

Keep `~/Projects/CUSTODIAN` on `main` as a shared coordination checkout,
give every agent an isolated V2 worktree, and stop closeout summaries cluttering
repository root.

## Changes

- Added a Claude Bash PreToolUse guard and SessionStart root-branch check.
- Documented coordination-root and 2:1 safe-worktree-retirement policies.
- Created permanent `custodian/docs/ai_context/agent_summaries/`.
- Migrated historical root task summaries byte-for-byte to that home.
- Standardized future per-workstream `AGENT_SUMMARY.md` naming with explicit agent attribution.
- Updated active workstream and process-feedback summary readers for the new home
  while retaining bounded historical path compatibility.

## Validation and limits

Code regression tests: the focused new guard/summary discovery tests are added.
CI and repository-host validation must be checked before claiming an accepted
landing. The Claude pre-tool hook protects Bash tool calls, not all possible
third-party file-writers. Root ownership must also be enforced by standing
instructions and the V2 dispatcher.

## Next Handoff

Verify CI/PR status, merge through GitHub protection, and sync the coordination
root only if `main` is clean and fast-forward eligible. Do not forcibly
repair a diverged coordination checkout or delete protected worktrees.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What worked: Existing V2 worktrees and GitHub content-addressed blob history.
- What went wrong: Root task checkout and hundreds of root-level summary files.
- Prevention: Root mutation guard and canonical summary home.
- Follow-up: `none`
