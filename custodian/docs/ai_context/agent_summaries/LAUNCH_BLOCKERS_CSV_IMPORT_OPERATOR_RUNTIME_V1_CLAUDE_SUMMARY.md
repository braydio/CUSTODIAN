# Launch blockers: CSV import crash and dangling Operator runtime asset

Workstream: launch-blockers-csv-import-operator-runtime-v1

## Symptoms
A fresh checkout/worktree could not launch the game. Two independent causes:

1. **Fresh import segfaults (exit 139).** Godot 4.7.2 crashes while reimporting
   three tracked asset-index CSVs whose `.import` files used `csv_translation`
   (`roads_paths/source/index.csv`, `gothic_roads/roads_index.csv`,
   `walls/wall_slices_game32/environment__wall__ruined_stone__manifest.csv`). Their
   columns (`x`, `y`, `pixels` ...) are not locales. Existing checkouts never hit it
   because their `.godot` cache was built earlier. With no import, the project fails
   with hundreds of "Could not find type" script errors.
2. **Dangling Operator asset on main.** `45c8d6176` deleted
   `operator__full_body__ranged_2h__posture__relaxed_01__n__5f__128.png` without
   regenerating `operator_runtime_manifest.generated.json` or
   `operator_runtime_frames.tres`. `operator_runtime_frames.tres` then could not
   load, `operator.tscn` could not load, and ~700 `CameraController`
   "Nonexistent 'bool'/'String' constructor" errors followed.

## Changes
- The three CSV `.import` files now set `importer="keep"`.
- New `tools/validation/godot_csv_import_guard_smoke.py` (registered as
  `godot_csv_import_guard`) fails if any Godot-visible CSV (not under a `.gdignore`
  directory) lacks an `importer="keep"` sidecar, so a new CSV cannot reintroduce the crash.
- Runtime regenerated with the sanctioned tools: `sync_operator_runtime_assets.py
  --strict` (manifest loses the 37-line dead `ranged_2h/posture/relaxed_01/n`
  identity), then `build_operator_runtime_frames.gd` (588 animations; ID renumbering
  makes the `.tres` diff large).
- The `operator-runtime` owner (`operator-ranged-domain-extraction`) was not
  contacted or modified; the user authorized taking over the correction locally.

## Validation
- Fresh worktree: `godot --headless --import` exit 0 (1m24s, ~19.7k files), then
  `godot --headless --quit-after 300`: 0 script errors, 0 errors, 0 warnings.
  Before: 722 script errors / 40 errors.
- `godot_csv_import_guard`, `operator_runtime_spriteframes_imports`,
  `operator_runtime_path_audit`, `operator_animation_reachability_audit`,
  `operator_2_5d_review`, `operator_runtime_spine_immutable`: all pass.
- Windowed launch was not run.

## Open items (not fixed here)
- No north-facing `ranged_2h/posture/relaxed_01` art exists in runtime or source
  (`45c8d6176` says it was "replaced by 96 modular lower/upper n"; no such files are
  present). The identity is simply absent now. Gameplay gap, not a launch blocker.
- `operator_animation_catalog.generated.json` is intentionally broader than the
  manifest (204 catalog-only identities) and 25 of those reference missing files,
  including `ranged_2h/posture/relaxed_01/n`. The catalog merge in
  `sync_operator_runtime_assets.py` never drops identities. The SpriteFrames builder
  reads only the manifest, so launch is unaffected.
- Whether the CSV crash is a Godot 4.7.2-2 regression (installed 2026-10-09) is untested.

## Propagation
Existing worktrees pick up the fix when they merge `origin/main`; new worktrees get
it from main. No other worktree was modified.
