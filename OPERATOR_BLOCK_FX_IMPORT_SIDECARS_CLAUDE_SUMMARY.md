# Operator Block FX Import Sidecars

The Operator preload error persisted because a newer `defense` commit after the prior repair regenerated `operator_runtime_frames.tres` but reintroduced `valid=false` into the East and West block-hold FX `.png.import` sidecars. Those invalid sidecars made the referenced textures unavailable and caused Godot to reject the entire SpriteFrames resource.

Removed only those two invalid sidecars and regenerated them with Godot from the current checked-in PNG sources. Both now have valid `.godot/imported/*.ctex` remap paths. Hardened the canonical SpriteFrames import smoke to accept Godot's current ext_resource ordering, where `uid` precedes `path`.

## Validation

- `python3 custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py` — PASS, all 588 referenced texture imports valid.
- `python3 custodian/tools/validation/operator_compatibility_resources_smoke.py` — PASS.
- `godot --headless --path custodian --script res://tools/validation/operator_melee_posture_smoke.gd` — PASS; this loads the canonical resource through the Operator scene.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — PASS, complete coverage, 1 selected check, 0 failures.
- `git diff --check` — PASS.

The fresh isolated import also completed (9,426 import steps); Godot logged one unrelated TLS handshake error from an editor plugin at shutdown but returned exit 0. No PNG source or generated SpriteFrames file was changed in this slice. The project-root checkout had user-local PNG edits, so they were left untouched.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: A later runtime-frame publication reintroduced the two invalid import sidecars after the previous preload fix landed.
- Root cause / contributing factors: The publication commit included failed-import `.import` metadata alongside its newly generated runtime resource; the smoke initially assumed ext_resource `path` preceded `uid` and therefore failed against the newer generated format.
- Prevention / pipeline improvement: The earlier canonical import smoke is now format-tolerant and routes changes to all canonical runtime texture sidecars through changed-file validation; this correction restores valid metadata for both affected textures.
- Tooling / docs drift discovered: The first smoke parser did not tolerate UID-first Godot resource attributes; corrected in-scope.
- Follow-up: fixed-in-scope
- What worked: Local cached LFS objects and a one-time isolated project import allowed exact two-file reimport and focused reproduction without touching the user's PNG edits.
