# Operator Runtime Import LFS Preflight

The Operator preloader is not selectively suppressing block-hold VFX. `operator.gd` preloads the canonical `operator_runtime_frames.tres`; Godot cannot load that resource when its external texture sidecars say `valid=false`.

The invalid sidecars were reintroduced in commit `1dc10bed` (“testing addons and add block vfx”), which changed both East and West block-hold FX import records from valid remap paths back to `valid=false`. The regression is consistent with a project import run while Git LFS assets were still pointer text. Project-wide import entry points did not check that condition before invoking Godot.

Added `godot_import_preflight.py`. It checks Git LFS paths present inside the Godot project and stops the import if any still contain pointer text; sparse-omitted paths are ignored. Wired it into Operator ingest, Workbench publication, modular alignment repair, runtime asset imports, the shared Godot import adapter, sprite ingest post-processing, the validation runner, and the world-simulation import recipe. The preflight smoke covers pointer detection, materialized and sparse-omitted inputs, and standalone projects without Git metadata. Updated the file index and validation recipe.

## Validation

- `python3 custodian/tools/validation/run_validation.py --test godot_import_lfs_preflight --json` — PASS.
- `python3 custodian/tools/validation/run_validation.py --test asset_pipeline_v2 --json` — PASS.
- `python3 -m py_compile` for the edited Python modules — PASS.
- `bash -n custodian/tools/operator/operator_ingest.sh` — PASS.
- `git diff --check` — PASS.
- The preflight correctly blocks this worktree's project import and lists the checked-out LFS pointers. A `needs_import` validation request now exits with `import_preflight` before launching Godot.
- Full `--changed` validation is limited by this worktree's unavailable LFS payloads; existing Operator Workbench and ingest-wrapper checks cannot read their source images here. No project-wide import was run in this workstream.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: A later asset commit restored invalid `.import` sidecars, and existing project-wide import wrappers had no LFS-pointer guard.
- Root cause / contributing factors: Godot's project import can persist `valid=false` metadata when a checked-out LFS path is still a pointer; the import command itself does not distinguish that input state.
- Prevention / pipeline improvement: Added a shared preflight before repository import entry points and documented the required materialization check.
- Tooling / docs drift discovered: The prior import smoke catches invalid sidecars after the fact, but could not prevent an import from writing them.
- Follow-up: fixed-in-scope
- What worked: Preflight blocks the known pointer-only state before starting Godot and preserves the existing sidecar contents.
