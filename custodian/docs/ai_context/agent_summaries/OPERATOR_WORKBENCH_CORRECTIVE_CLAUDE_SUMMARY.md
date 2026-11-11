# Operator Workbench Corrective Pass — Closeout

Fixed the runtime/catalog contract propagation defect: catalog merging now
copies `frame_size`, and a temporary Fast 02 fixture transforms canonical
6-frame 96×96 strips to staged 128×128 strips, runs the real runtime builder,
and asserts both runtime manifest and generated catalog report 128×128 with
768×128 output sheets. No production artwork was published.

Canvas review now says expansion cannot crop pixels and accurately defers
shrink clipping validation to staging, where the existing per-frame alpha
audit fails closed. Clipboard copy forwards keyword arguments through the
worker helper. Live copy waits for the matching bridge `command.result` and
uses its detached output path/frame/canvas metadata. The Textual UI regression
invokes the real Y action for BODY, FX, and BODY+FX, rejects stale pre-existing
cache contents before the result arrives, and confirms the fresh result is
used. Existing copy/mode confirmation toasts are retained.

Validation:

- `operator_animation_workbench_smoke.py` — passed.
- `operator_modular_pipeline_smoke.py` — passed, including runtime/catalog 128×128 propagation.
- `operator_workbench_ui_smoke.py` — full Textual pilot passed in isolated `/tmp/custodian-opui-corrective-venv`; default system Python skips the optional pilot because Textual is absent there.
- `operator_live_bridge_smoke.py` — passed.
- `operator_workbench_mirror_publish_smoke.py` — passed.
- `run_validation.py --changed --json` — 12 passed, 1 unrelated unit failure, 41 skipped. `operator_animation_timing` cannot find `melee_1h/locomotion/run_01/s` in the dirty generated runtime manifest.
- `git diff --check` — passed.

Not done: no canonical Fast 02 publish; no unrelated generated art/runtime changes or Vaultwing work staged. The shared worktree contains unrelated Operator/art/audio/procgen modifications and separate Vaultwing B.1 WIP, preserved outside this commit. Graph MCP startup remains unavailable due to missing `rich.traceback`; targeted inspection was used.
