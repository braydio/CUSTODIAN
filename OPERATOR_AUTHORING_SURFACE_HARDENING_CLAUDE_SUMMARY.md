# Operator Authoring Surface Hardening Summary

## Delivered

- Corrected the two active Operator pipeline/how-to docs to current Workbench V5
  authority: `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md` and
  `custodian/content/sprites/_pipeline/README.md` no longer document the retired
  `Shift+R` shortcut, the stale `1`–`4` mode range, or the deleted
  `build_operator_modular_runtime.py` / `update_operator_curated_resources.gd`
  builder route. Both now describe live Workbench modes `1`–`5` (PLAN / WORKBENCH /
  PREVIEW / TIMELINE / MOTION), the live `Ctrl+R` canvas-resize review flow, and the
  live Operator V2 sync path (`operator/source/animations/` →
  `operator/runtime/animations/` via `operator_ingest.sh` / `sync_operator_runtime_assets.py`).
- Added `--profile PROFILE` and `--strict` to `custodian/tools/operator/operator_ingest.sh`,
  forwarded to every `sync_operator_runtime_assets.py` invocation in the script (the
  main sync call and the apply-only superseded-cleanup call). Dry-run-by-default and
  all existing flags (`--apply`, `--skip-inbox`, `--no-import`, `--no-validate`,
  `--no-mirror`) are unchanged; argument parsing moved from a single-token `for`
  loop to a `while`/`shift` loop only to support `--profile`'s value.
- Added two focused regression tests and registered both in `validation_manifest.json`:
  - `operator_authoring_surface_contract_smoke.py` derives the live numbered-mode
    set and the WORKBENCH `Ctrl+R` → canvas-resize binding straight from
    `custodian/tools/operator/ui/app.py` and fails if the two active docs drift from
    it, or reintroduce the retired builder/script names. This makes it a drift
    detector, not a frozen snapshot: it fails automatically the next time a mode is
    added/removed or `Ctrl+R` is rebound and the docs aren't updated.
  - `operator_ingest_wrapper_smoke.py` runs the wrapper twice in dry-run
    (`--skip-inbox`, once with `--profile unarmed --strict`, once with neither),
    and checks from the bash trace that only the scoped run forwards those flags,
    and from the sync tool's own reported count that scoping to `unarmed` actually
    narrows the synchronized set (287 of 586 sheets on the measured baseline)
    rather than merely accepting the flags.

## Validation

- `python3 custodian/tools/validation/operator_authoring_surface_contract_smoke.py`: pass.
- `python3 custodian/tools/validation/operator_ingest_wrapper_smoke.py`: pass (scoped=287, plain=586).
- Regression check: manually reverted the doc fix and the wrapper's forwarding to
  confirm both new tests fail on the exact known regression, then restored and
  reconfirmed both pass.
- `run_validation.py --test operator_authoring_surface_contract --json`: passed.
- `run_validation.py --test operator_ingest_wrapper --json`: passed.
- `run_validation.py --test operator_animation_workbench --json`: passed (unaffected).
- `run_validation.py --test operator_workbench_ui --json`: passed (unaffected; optional Textual pilot skipped, as before).
- `python3 custodian/tools/validation/operator_modular_pipeline_smoke.py`: passed directly (not registered under a matching manifest id; ran as a related-consumer sanity check).
- Closeout: `run_validation.py --changed --base origin/main --json` — 5/5 selected tests passed (`asset_pipeline_v2`, `operator_authoring_surface_contract`, `operator_compatibility_resources`, `operator_ingest_wrapper`, `validation_runner`).
- `bash -n custodian/tools/operator/operator_ingest.sh` and `python3 -c "import json; json.load(...)"` on `validation_manifest.json`: both clean.
- Moment Forge: not run — this slice changes tooling/docs only, no runtime or presentation behavior changed.

## Awkward Parts And Deferred Work

- My first `operator_ingest.sh --dry-run --skip-inbox` smoke run created
  `reports/operator_ingest/operator_ingest_<timestamp>.log`, and I cleaned it up
  with `rm -rf reports/operator_ingest` without checking `git status` first — that
  directory has 44 previously-committed tracked report files, all of which I
  deleted. Caught it on the next `git status` before committing and restored
  everything with `git checkout -- reports/operator_ingest/` (confirmed 0 diff
  afterward). No data was actually lost, but the destructive `rm -rf` should have
  been scoped to only the file I just created, or preceded by a status check.
- `custodian/docs/ai_context/FILE_INDEX.md` and `CURRENT_STATE.md` both contain
  older Operator-pipeline drift unrelated to this task (e.g. `CURRENT_STATE.md`
  still references a separately-deleted `build_operator_runtime.py`, and
  `FILE_INDEX.md`'s one-line description of `operator_ingest.sh` doesn't mention
  `--profile`/`--strict`). Neither statement was made stale by this task's
  implementation — the CURRENT_STATE.md drift predates it and the FILE_INDEX.md
  line remains true, just incomplete — so both were left alone per the task's
  scoping (update those docs only when this task's contract makes their current
  statements stale) and per the general instruction not to edit an otherwise-correct
  document just because it was listed as related.
- The `unarmed/defense/block_hit_01` art conversion and any generic
  workstream-finish/archive hardening remain explicitly out of scope, as stated in
  the task packet.
- No Asset V2, gameplay, or animation-timing behavior was touched.
