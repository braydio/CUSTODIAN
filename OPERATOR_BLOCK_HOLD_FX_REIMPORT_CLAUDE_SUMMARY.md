# Operator Block Hold FX Reimport

Commit `1dc10bed` reintroduced `valid=false` in the East and West block-hold FX `.import` sidecars after the earlier targeted repair. With the new LFS import preflight landed, I materialized the 12,649 present Git LFS pointers from the local cache only; no fetch was run. The preflight then passed, allowing Godot to safely regenerate the two import records and their imported texture resources.

## Validation

- `godot --headless --path custodian --import --quit` — completed; captured log contained zero `ERROR`/`SCRIPT ERROR` lines.
- `python3 custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py` — PASS, 588 canonical texture imports.
- `godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd` — exit 0. Godot emitted its existing shutdown warning that 13 resources remained in use.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — PASS.
- `git diff --check` — PASS.

Only the two East/West FX import sidecars were changed by the repair; imported caches remain ignored.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The prior import repair was overwritten by a later asset commit.
- Root cause / contributing factors: A project-wide Godot import had run with checked-out Git LFS pointer files; the new preflight now blocks that state.
- Prevention / pipeline improvement: Added the tracked sidecar regression check to the repair and retained the new pre-import LFS guard.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Cache-only hydration followed by one guarded project import regenerated both remaps cleanly.
