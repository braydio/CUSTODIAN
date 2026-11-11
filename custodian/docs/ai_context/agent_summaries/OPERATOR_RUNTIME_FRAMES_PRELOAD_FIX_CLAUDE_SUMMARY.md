# Operator Runtime Frames Preload Fix

Fixed the Operator preload failure reported in `operator.gd:32` and canonical SpriteFrames consumers. The `.tres` was present and its 588 source texture paths existed, but the two unarmed `block_hold_01` FX texture import sidecars (East and West) were committed with `valid=false`. Godot therefore treated those ext_resources as nonexistent and rejected the entire SpriteFrames resource.

Removed only those two stale invalid sidecars and let Godot regenerate valid import metadata and cache entries. Added `operator_runtime_spriteframes_import_smoke.py`, which checks every source texture referenced by the canonical SpriteFrames has an import sidecar marked valid and a generated imported-resource path. Registered the smoke and the import metadata as owners in `validation_manifest.json` so changed-file validation catches recurrence.

## Validation

- `godot --headless --path . --script res://tools/validation/operator_melee_posture_smoke.gd` — PASS after repair.
- `godot --headless --path . --script res://tools/validation/operator_dodge_fx_canonical_smoke.gd` — PASS.
- `python3 tools/validation/operator_runtime_spriteframes_import_smoke.py` — PASS, 588 texture imports.
- `python3 tools/validation/operator_compatibility_resources_smoke.py` — PASS.
- `python3 tools/validation/operator_runtime_path_audit.py` — PASS. Its non-final report notes existing compatibility-residue debt.
- `python3 tools/validation/run_validation.py --changed --json` — PASS, complete coverage, 2 checks, 0 failures.
- `git diff --check` — PASS.

I also invoked `operator_runtime_path_audit.py --final` as an extra check; it fails because 426 legacy identity references remain, an existing C2b.3 migration gate outside this preload repair. No source art or generated SpriteFrames content changed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Two tracked texture import sidecars with `valid=false` made existing block FX look missing to Godot.
- Root cause / contributing factors: The sidecars were committed in their failed-import state and ordinary reimport did not retry them until the stale sidecars were removed.
- Prevention / pipeline improvement: Added a changed-file-routed smoke that validates every external texture source and import sidecar referenced by the canonical Operator SpriteFrames resource.
- Tooling / docs drift discovered: None.
- Follow-up: fixed-in-scope
- What worked: A minimal worktree-local sidecar regeneration resolved the preload without changing the SpriteFrames asset or source textures.
