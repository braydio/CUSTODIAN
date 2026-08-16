# Operator Alignment Repair V2 Hardening

- Status: `complete`
- Authority: `design/04_architecture/SPRITE_PIPELINE_SYSTEM.md` (Operator V2 section), `custodian/tools/pipelines/operator_asset_schema.py`, `custodian/tools/pipelines/build_operator_runtime.py`
- Goal: Harden the live Operator V2 alignment-repair conveyor (`custodian/tools/operator/modular_alignment_repair.py`) against five live bugs and lock the fixes in with regression smoke tests and doc remediation.
- Files: `custodian/tools/operator/modular_alignment_repair.py`, `custodian/tools/operator/modular_combo_check.py`, `custodian/tools/validation/operator_modular_alignment_repair_smoke.py`, `custodian/tools/validation/validation_manifest.json`, `design/04_architecture/SPRITE_PIPELINE_SYSTEM.md`, `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md`, `custodian/docs/ai_context/FILE_INDEX.md`, `custodian/docs/ai_context/CURRENT_STATE.md`.
- Constraints: No PNG pixel edits; never touch `_pipeline/inbox`; no git add -A; no push; do not rewrite `modular_combo_check.py` pairing semantics globally; no new naming convention; no new runtime tree; legacy historical docs stay in place and are labeled historical.
- Acceptance: Provenance keyed by resolved runtime path (kills `_body_body`); exact V2 profile/group/action/direction pairing with no cross-profile/group fan-out; bounded connector search with `connector_confidence >= 0.35` flag gate; live queue re-drives pending until empty and reopens the just-edited source; builder runs with `--strict`; 8 regression tests pass; validation recipes pass in order; docs drift remediated; task files committed.
- Completed: Code fixes applied to `modular_alignment_repair.py` (runtime-path provenance keys, `find_exact_v2_pair_jobs`, bounded connector helper set, `connector_confidence >= 0.35` gate, live-queue `merge_live_queue`/`refresh_live_queue`/`interactive_loop` rewrite, `--strict` builder). Task packet created. Smoke suite extended to 20 tests (8 new regression tests + the provenance-keying test updated to runtime-path keys) and all pass. `modular_combo_check.py` `FRAME_META_RE` now accepts the V2 `WxH` size token (`128x96`), fixing the `sheet_meta` crash on non-square runtime sheets. `validation_manifest.json` had two invalid `"tier":"smoke"` entries (blocked `run_validation.py` at load) corrected to `integration`, and a new `operator_modular_alignment_repair` unit entry registers the smoke suite as owner of the repair tooling. Docs remediated: `SPRITE_PIPELINE_SYSTEM.md`, `AGENT_TOOLING_BY_ASK.md`, `FILE_INDEX.md`, `CURRENT_STATE.md`. All validation recipe steps run; see Validation.
- Deferred: `run_validation.py --changed` still reports `passed: false` only because 13 other-session `custodian/game/actors/operator/*.tres` files are dirty and uncovered; they are out of scope. Historical docs/packets and legacy asset trees referencing old `build_operator_modular_runtime`/`new_operator/modular` paths remain untouched and are historical reference only.

## Behavior Changes In This Slice

1. **Provenance lookup by runtime path, not semantic ID.** Records are keyed by `runtime_record_key(path)` (absolute resolved path). Editable source resolution no longer fabricates `{part}_body` semantic IDs, so lower/upper runtime sheets can never collide into a phantom `_body_body` source.
2. **Exact V2 pairing only.** Lower and upper sheets pair only when `(loadout, family, action, direction)` match exactly. Frame-count or canvas mismatches produce a missing record; duplicate or one-sided keys produce missing/error records. The conveyor never fans one action across partners or guesses.
3. **Bounded connector region.** `connector_debug` finds the lower connector in the central 25–75% x-band scanning from the top, then searches the upper frame only near the expected seam within the lower connector's neighborhood, ignoring narrow appendages below the waist. Flagging requires `connector_confidence >= 0.35`.
4. **Live queue, not an index walk.** `interactive_loop` repeatedly takes the next `pending` entry until none remain; after each save the runtime is rebuilt with `--strict` and the queue is refreshed (`refresh_live_queue`) so partner corrections collapse immediately and newly appeared suspects join as pending. The just-edited source reopens pending while still active. No "QUEUE COMPLETE" claim; a final drain count of fixed/unresolved/skipped is printed.
5. **Strict rebuild.** `run_builder()` invokes `build_operator_runtime.py --strict --remove-superseded`, and the dry-run printed command reflects it.

## Does Not Change Artwork

No runtime or source pixels change as part of this slice. If a sheet is later opened and saved interactively, only that operator edits its own editable source through the normal backup path.

## Validation

```bash
python3 -m py_compile custodian/tools/operator/modular_alignment_repair.py custodian/tools/operator/modular_combo_check.py custodian/tools/operator/operator_asset_reconciliation.py custodian/tools/validation/operator_modular_alignment_repair_smoke.py
python3 custodian/tools/validation/operator_modular_alignment_repair_smoke.py   # 20/20 pass
cd custodian && python3 tools/pipelines/build_operator_runtime.py --strict --remove-superseded --dry-run && cd ..   # 603 sheets, 0 warnings
python3 custodian/tools/operator/modular_alignment_repair.py --report-only --no-open   # 221 runtime sheets, 103 pairs, 524 frames, 91 flagged pairs
python3 custodian/tools/validation/run_validation.py --changed --json   # operator_modular_alignment_repair, validation_runner, sundered_keep_shoreline_compositor all pass
```

`run_validation.py --changed` reports `passed: false` solely because 13 other-session
`custodian/game/actors/operator/*.tres` files are dirty and uncovered. That is a
coverage-gap signal from unrelated work, not a failure of this slice.

Never launch the interactive Aseprite conveyor as validation.

## Validation Notes

- Report-only metric distribution is sane: flagged frames span connector center deltas
  roughly -20.5..21.5 px (median -5.0), gaps 0..6 px, only 5 frames without a detected
  connector. The 91 flagged pairs reflect genuine current seam misalignment in the art,
  which is what the repair conveyor exists to fix.
- The `sheet_meta` crash (non-square V2 `WxH` size tokens) was found during the
  report-only validation step and fixed via `FRAME_META_RE`; it is a prerequisite for
  the report-only recipe to run at all on the current runtime.
- The validation manifest previously blocked `run_validation.py` at load with
  `camera_presentation_subject_constraint: invalid tier` (`"tier":"smoke"` on two
  entries). Corrected to `integration`.
