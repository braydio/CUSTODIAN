# Persistent Checkout Sync Agent Guidance Summary

Updated repository agent instructions so routine root-checkout synchronization
does not require user approval and never sacrifices local work to reach
`origin/main`.

## Changes

- Root `AGENTS.md` now requires a safe post-land sync attempt, limited to a clean
  `main` checkout that is strictly behind `origin/main`.
- `custodian/AGENTS.md` repeats the operational rule for active Godot work and
  directs agents to the root instructions for the exact command.
- Dirty, untracked, ahead, diverged, wrong-branch, and other unsafe states must
  remain untouched. Agents report the concrete blocker, leave sync pending, and
  continue closeout without asking for routine approval; they retry once safe.

## Scope and Verification

This was the requested agent-guidance update only. The shared synchronization
helper and Operator-art integration described by the existing
`persistent-checkout-sync-hardening` packet remain that packet's work.

`git diff --check` passed. No runtime or automated test suite was run for this
documentation-only change.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: the generic isolated worktree was initially reported dirty by its setup status; a focused status check confirmed only the two intended agent files were modified.
- Root cause / contributing factors: worktree setup output was noisy and obscured the scoped state.
- Prevention / pipeline improvement: inspect scoped paths and summarized status before interpreting broad worktree output.
- Tooling / docs drift discovered: none
- Follow-up: persistent-checkout-sync-hardening
- What worked: narrow edits to both repository-level agent instruction files.

## Next Handoff
- Next workstream: persistent-checkout-sync-hardening
- Next packet state: ready
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: claim the existing packet to implement shared safe synchronization for the persistent root and Operator-art checkout.
- Blockers or open questions: none
