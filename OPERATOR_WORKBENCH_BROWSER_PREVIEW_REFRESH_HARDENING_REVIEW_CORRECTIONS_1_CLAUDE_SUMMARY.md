# Operator Workbench Browser / Preview Refresh Hardening — Correction Cycle 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

Closed all four findings from the paired post-land review.

- **R0-01:** Browser-owned `_load_session()` now checks its captured browser generation after session and watch-signature projection, before state or widget mutation. Direct user selection remains guarded by the independent session generation.
- **R0-02:** `_reload_browser()` resolves identity and fallback against the staged candidate. It applies the session projection first, then commits the accepted snapshot and tree in the same event-loop turn. A failed fallback leaves the previous snapshot/tree/selection/session in place and emits no deletion event. A successful stable deletion emits one event and performs one fallback projection.
- **R0-03:** Live Bridge export generation, semantic identity, and source are recorded against the server command sequence before the command is sent. Result events carry that issue-time context; `_apply_live_preview()` rejects results without matching current ownership. Document, revision, and output-path checks remain active.
- **R0-04:** Added deterministic coverage for stale browser sessions, failed/successful deletion, direct selection ordering, transient Fast 02/03 disappearance, hidden-selection F5, one session projection, old/current Live Bridge result application, stale comparison and transition results, empty/replacing/stale/out-of-range tick states, PUBLISH refresh coalescing, and reachability parsing/status precedence.

The pinned UI smoke passed, including the expanded Textual Pilot cases. Changed-file validation passed 17/17 with complete coverage; `py_compile` and `git diff --check` passed. The first runner attempt exposed a 20-second timeout that could not fit the expanded UI Pilot, so the `operator_workbench_ui` timeout is now 60 seconds; the final changed-file run included the pinned UI environment. The original production crash traceback remains unavailable; this work addresses only the independently reproduced ownership defects and adds no crash-root-cause claim.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first stable-deletion transaction probe caught stale-snapshot lookup left behind during refactoring; corrected before closeout. The expanded pinned Pilot exceeded the old 20-second runner budget, and the system interpreter lacked optional Live Bridge packages.
- Root cause / contributing factors: Session projection lacked browser-request ownership, delayed live results used receiver-time generation, and the validation timeout had not accounted for the longer deterministic Pilot.
- Prevention / pipeline improvement: Added barrier-controlled assertions at browser/session and Live Bridge issue/result seams, plus explicit PUBLISH/tick/selection controls; raised only the UI smoke timeout to 60 seconds and ran the final validator with pinned UI dependencies.
- Tooling / docs drift discovered: System Python lacks the optional Textual and websockets dependencies supplied by the Operator UI environment.
- Follow-up: review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1
- What worked: All reproduced review findings now have focused deterministic regression coverage.

## Next Handoff
- Next workstream: review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Run the paired fresh-context correction review and verify dispositions for R0-01 through R0-04.
- Blockers or open questions: none; historic crash traceback unavailable.
