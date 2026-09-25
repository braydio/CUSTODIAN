# OPUI Ctrl Shortcut Routing Summary

## Change

- Promoted the mode-specific Ctrl bindings to priority app bindings so a
  focused table or button cannot consume them first.
- Added text-entry routing for Input and TextArea. Ctrl+A and Ctrl+Left/Right
  invoke the focused widget's own Textual edit action; other mode shortcuts are
  consumed without triggering timeline/motion actions while editing.
- Added explicit mode guards to timeline and motion shortcut actions.
- Added an isolated Textual pilot using real Ctrl keypresses for timeline
  DataTable focus, motion Button focus, and Input/TextArea editing focus.

Textual 0.89.1 maps Input Ctrl+A to Home and TextArea Ctrl+A to line start, not
select-all. The tests preserve that native behavior and prove the timeline Add
action is not invoked while text editing.

## Validation

- `.ai/operator-ui-venv/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py`
  — passed, including the optional Textual pilot.
- `git diff --check` — passed.
- Code-review-graph was unavailable (`No module named 'rich.traceback'`); the
  relevant UI and smoke-test files were inspected directly.

No gameplay, design docs, or assets changed. Unrelated shared-worktree changes
were left untouched.
