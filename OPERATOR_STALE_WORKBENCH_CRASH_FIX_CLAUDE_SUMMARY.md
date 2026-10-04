# operator stale workbench warning recovery

User clarified that Aseprite never opens and the Workbench terminal appears frozen after a stale warning in preview (mode 3). Reproduced the concrete interaction defect: ErrorDialog stayed modal after Escape, with no keyboard dismissal binding. A headless stale edit did not crash Python or launch Aseprite, so no independent event-loop deadlock or editor crash was established.

Error dialogs now focus Close, accept Escape/Enter/Close, stop button event bubbling, and render backend error text literally. Preview/motion ticks pause while an error dialog is open and reset their last-tick timestamps to avoid catch-up playback. Stale edit protection remains authoritative and does not refresh, discard, or overwrite saved animation documents. Updated the owning Workbench design contract and current-state projection.

Added a headless preview-mode regression covering failed stale Edit, focused Close, paused clocks, one dialog on repeated errors, Escape/Enter/mouse dismissal, no editor process, no mutation, and no app exception. The existing UI smoke file initially contained a literal backslash-n syntax error and assumed every real repository checkout was coordination main. Corrected both bounded validation defects, preserving the checkout-specific publication guard. Full operator_workbench_ui_smoke passed in the UI virtual environment; git diff --check passed.

The actual art checkout has unrelated local music import metadata; it must remain preserved when fast-forwarding the UI fix. Restart OPUI after deployment. Escape now closes a stale warning; stale sessions still require explicit refresh/reconciliation before editing. No animation pixels or frame contracts were changed by this slice.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: modal had no Escape/Enter dismissal; validation fixture had a syntax error and coordination-only checkout expectation
- Root cause / contributing factors: warning recovery relied on a mouse button; invalid fixture concealed coverage and did not follow isolated worktree lifecycle
- Prevention / pipeline improvement: keyboard/mouse modal recovery regression and checkout-aware real-repository assertion
- Tooling / docs drift discovered: broken UI smoke syntax and outdated checkout expectation
- Follow-up: fixed-in-scope
- What worked: focused headless reproduction distinguished the modal interaction defect from an Aseprite crash
