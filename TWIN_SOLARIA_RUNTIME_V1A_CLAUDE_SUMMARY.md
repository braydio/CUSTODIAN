# Twin Solaria Runtime V1-A Summary

## Delivered

- Moved `Twin_Solaria_Runtime_Crop_Pack_v1.zip` from `~/Downloads` to the repository root.
- Registered `twin_solaria_v1_environment` and ingested its eight plate crops into the canonical Asset V2 runtime domain.
- Added a separate native-scale visual assembly at `custodian/scenes/twin_solaria_v1.tscn`, with the untouched 2048×1536 master underlay and plate positions from `PLACEMENT_MANIFEST.json`.
- Added the V1-A focused smoke and updated the Twin Solaria entries in `CURRENT_STATE.md` and `FILE_INDEX.md`.

## Measurements and controls

- All eight source crops matched `MASTER_TRACKER.csv` dimensions and SHA-256 values. No crop dimensions differed.
- All eight runtime PNGs are byte-identical to their source crops; the scene positions match the placement manifest and use default scale `(1,1)`. After the existing Godot editor processed their imports, Asset V2 status reported all eight imports and runtime bindings ready.
- Asset V2 plan and dry run passed with eight creates, zero replacements, and no warnings. Ingest without the Godot importer flag completed; status reports 6/6 required and 2/2 recommended states ready, with an empty family inbox.
- `asset.py doctor --json` still reports the pre-existing unregistered `operator` inbox warning.

## Problems encountered

- The first plan saw `_source` files copied into the inbox and rejected those names. The inbox was corrected to contain only the eight manifest-named plate files; the subsequent plan and dry run passed.
- `asset ingest --godot-import` timed out at 300 seconds and rolled back its managed outputs while a Godot editor process was already open. The assets were then ingested without that importer flag; the already-open editor subsequently processed them. No existing Godot process was stopped or modified.
- The first smoke draft also asserted the packet's stated 3500×3000 preview size and exposed the live 4000×3000 mismatch. That assertion was corrected to check that the untouched preview's camera bounds follow its currently loaded texture; the controller and preview were not changed.
- Live inspection found the old development preview loads a 4000×3000 texture, while its controller and smoke still expect 3500×3000. The old preview files were left untouched; the discrepancy is recorded in `CURRENT_STATE.md`.

## Deferred

- V1-B collision, Operator/camera integration, POIs, and V1-C dormant interactions remain outside this V1-A packet.

## Validation run

- `python3 custodian/tools/assets/asset.py plan twin_solaria_v1_environment --json` — pass after inbox correction.
- `python3 custodian/tools/assets/asset.py ingest twin_solaria_v1_environment --dry-run` — pass.
- `python3 custodian/tools/assets/asset.py ingest twin_solaria_v1_environment --yes` — pass.
- `python3 custodian/tools/assets/asset.py status twin_solaria_v1_environment --verbose` — pass, 8/8 ready with Godot import and runtime binding verified.
- `python3 custodian/tools/assets/asset.py doctor --json` — one unrelated unregistered Operator inbox warning.
- `timeout 60s godot --headless --path custodian --script res://tools/validation/twin_solaria_v1_smoke.gd` — pass. The old preview emits its documented size warning; smoke verifies it remains the development preview and checks bounds against its loaded texture.
- `python3 custodian/tools/validation/run_validation.py --changed --list` — selects 174 validations across unrelated dirty work in the shared checkout. The sweep was not run to avoid executing another task's broad validation set; the focused Twin Solaria smoke was run instead.
