# OPUI Canvas Resize Shortcut Summary

## Change

- Replaced the separate Shift+R and Ctrl+R bindings with one priority Ctrl+R
  dispatcher. Workbench routes to the existing `action_resize_canvas()` flow;
  Motion routes to `action_motion_reset()`; other modes do nothing.
- Textual `Input` and `TextArea` focus consumes Ctrl+R before mode routing.
- Updated the ContextKeyBar and the active Workbench spec/current-state docs.
- Expanded the real Textual pilot to cover Workbench resize with AnimationTree
  focus, MotionLabState reset, Timeline no-op, search focus suppression, and no
  Shift+R hint.

## Validation

- `PYTHONPATH=/tmp/custodian-opui-deps python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — PASS, including real Textual pilot.
- `python3 -m py_compile custodian/tools/operator/ui/app.py custodian/tools/operator/ui/widgets/context_key_bar.py custodian/tools/validation/operator_workbench_ui_smoke.py` — PASS.
- `git diff --check` — PASS.
- UI requirements were installed to `/tmp/custodian-opui-deps` so the optional
  real pilot could run without changing repository or global Python packages.

## Notes

- Both keyboard routes use the existing canvas resize action and its existing
  preview/apply backend flow; no resize backend was added.
- The initial smoke invocation skipped the optional Textual pilot because its
  dependencies were absent. The rerun with the temporary dependency target
  exercised and passed the real pilot.
- No relevant negative controls failed; the explicit Timeline and focused
  search cases confirmed the required no-op behavior.
