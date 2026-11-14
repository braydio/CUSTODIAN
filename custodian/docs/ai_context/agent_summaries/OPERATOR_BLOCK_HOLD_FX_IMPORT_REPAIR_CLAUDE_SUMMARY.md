# Operator Block Hold FX Import Repair

Regenerated the East and West `block_hold_01` FX texture import sidecars. Both now contain valid Godot remap paths and `dest_files` entries. The PNG assets were not changed in the task worktree.

The canonical SpriteFrames import smoke had stopped discovering textures because its ext-resource regex required `path` to immediately follow `type`; the current resource includes a `uid` field before `path`. Updated the parser to accept attributes in between, restoring coverage of all 588 texture imports.

## Validation

- `python3 custodian/tools/validation/run_validation.py --changed --json` — PASS; complete coverage, 1 selected check, all 588 imports valid.
- `git diff --check` — PASS.
- `godot --headless --path custodian --editor --import --quit` regenerated the two target sidecars, but the project-wide import reported unrelated sparse-worktree failures (placeholder LFS resources and an invalid LimboAI addon binary). That scan rewrote 9,464 unrelated `.import` sidecars; they were restored immediately. No unrelated files remain changed.
- `operator_modular_layers_smoke.gd` could not complete in this sparse worktree because unrelated assets and addon resources are unavailable/corrupt there. The missing East/West FX import metadata is repaired; the full actor smoke remains unverified here.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: The full Godot editor import touched 9,464 unrelated sidecars and failed on unrelated unmaterialized/corrupt dependencies.
- Root cause / contributing factors: The editor's project import is global, while this worktree has pointer-only LFS content and an invalid addon binary.
- Prevention / pipeline improvement: Reverted all incidental sidecar churn; use changed-file validation for the import contract and avoid project-wide reimport in sparse/pointer-only checkouts when possible.
- Tooling / docs drift discovered: The canonical resource's ext-resource entries include `uid` before `path`, which the existing smoke parser did not handle.
- Follow-up: fixed-in-scope
- What worked: The targeted two-frame import repair and 588-resource contract check passed.
