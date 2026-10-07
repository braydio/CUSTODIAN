# VEHICLE FIELD SCOUT BUGGY ASSET V2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-field-scout-buggy-asset-v2`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`
- Locks: `asset-pipeline-vehicle, vehicle-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, runtime`
- Paired review workstream: `review-vehicle-field-scout-buggy-asset-v2`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `production Asset V2 contract and vehicle post-process authority migration`
- Reviewed main: `ff5fc4056217e004901ea342f0de4422b8162775`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Give the Field Scout Buggy a real Asset Pipeline V2 family and replace hover-buggy-specific vehicle post-processing with an owner/family-driven seam that supports future vehicle classes without another hard-coded importer.
- Completion boundary: Done when `custodian_field_scout_buggy_mk1.asset.json` is registered against the live vehicle kind schema, Asset V2 request/plan/status exposes the exact 256 px directional state contract, vehicle runtime resource rebuilding no longer assumes `hover_buggy` as the only owner, the Scout class can bind canonical family outputs when present while safely retaining compatibility art when absent, and required-assets/docs point at family truth rather than nonexistent paths.
- Current measured state: The semantic `field_scout_buggy_mk1.tscn` class is landed, and its parent review found one blocking R1 restoration defect now owned by the dependency-gated correction/re-review pair. Asset kind `vehicle` exists with domain `sprites/vehicles`, default 8dir/auto-mirror/body/locomotion and `vehicle_runtime_import`. No production Scout vehicle family contract exists yet. Legacy inbox grammar recognizes hover-buggy names and `update_vehicle_runtime_resources.gd` remains hover-specific. Live compatibility art is still under `content/sprites/vehicles/hover_buggy/`. `CURRENT_STATE.md` also retains one stale older paragraph claiming the production ID uses the LightBuggy scene; live runtime no longer does.
- Evidence: `custodian/content/metadata/assets/schemas/vehicle.json`; `custodian/tools/assets/asset_contract.py`; `asset.py`; `custodian/tools/pipelines/generate_inbox_manifests.py`; `update_vehicle_runtime_resources.gd`; `custodian/content/sprites/_pipeline/README.md`; `custodian/content/metadata/assets/required_assets.registry.json`; `custodian/game/actors/vehicles/hover_buggy_idle_frames.tres`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Task-specific authority: `design/04_architecture/ASSET_PIPELINE_V2.md`; live `vehicle.json` kind schema and Asset V2 CLI/contract code; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Work surface: New family contract `custodian/content/metadata/assets/families/custodian_field_scout_buggy_mk1.asset.json`; vehicle post-process/runtime-resource tooling; visual-kit binding; required-assets registry/generated view; focused Asset V2/vehicle validation.
- Change: Register family `custodian_field_scout_buggy_mk1` as kind `vehicle`, runtime domain `sprites/vehicles`, owner `custodian_field_scout_buggy_mk1`, 256x256 canvas, 8dir, auto-mirror true, authored required directions `n, ne, e, se, s`. Encode required `parked_01` 1f, `drive_01` 6f at 8 FPS, `disabled_01` 1f, `wreck_01` 1f; recommended `engine_start_01` 7f at 8 FPS, `engine_idle_01` 6f at 6 FPS, `brake_01` 4f at 10 FPS, `impact_01` 4f at 12 FPS, `destroy_01` 8f at 10 FPS, `restore_01` 8f at 8 FPS on the body transition layer, and `restore_fx_01` 8f at 8 FPS on the FX transition layer. Use horizontal strips for animations and aliases `idle -> parked_01`, `idle_start -> engine_start_01`, `idle_loop -> engine_idle_01`, `move -> drive_01`. Generalize vehicle post-processing so owner/family identity comes from contract/catalog/consumer rather than per-class constants. Preserve old hover resource only as compatibility source until canonical Scout states exist. Make Scout presentation resolve authoritative facing direction when canonical directional clips exist. Replace stale firing/damage/destruction requirements with family/state-backed needs reflecting the unarmed class: no required firing body state; track impact/destroy/wreck according to the family. Regenerate REQUIRED_ASSETS. Reconcile the stale Vehicle Registry paragraph in `custodian/docs/ai_context/CURRENT_STATE.md` so it names the semantic Field Scout scene and labels hover-buggy frames as compatibility presentation only; this closes parent-review R0-02.
- Preserve: Asset V2 canonical routing/naming; non-vehicle ingest; hover compatibility art; stable class runtime behavior; no direct runtime references to asset_drop; immutable source masters.
- Non-goals: Do not generate production PNGs; do not declare missing art verified; do not add weapons; do not redesign Asset V2 globally; do not remove hover compatibility while a live fallback needs it; do not change handling.
- Acceptance: `asset request custodian_field_scout_buggy_mk1` requests `<state>__<direction>.png` for five authored directions with exact geometry; plan/status parse family cleanly; doctor has no new errors; post-processing targets Scout owner without a duplicated Scout-specific script and still rebuilds hover compatibility; presentation selects canonical directional parked/drive/wreck/restore states with fixture art and falls back safely when absent; required-assets no longer targets nonexistent `light_buggy/runtime` or requires firing art; `CURRENT_STATE.md` no longer claims a LightBuggy production scene; validation proves frame count/256 px registration and consumer binding.
- Validation: Inspect `python3 custodian/tools/assets/asset.py --help`. Run `python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py`, `python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py`, `res://tools/validation/validate_vehicle_registry.gd`, then current request/plan/status commands for `custodian_field_scout_buggy_mk1`, `python3 custodian/tools/assets/asset.py doctor`, and `python3 custodian/tools/assets/asset.py needs --check`. Add a focused implementation-created vehicle-family/post-process smoke using temporary fixture strips, record its exact path/validation ownership, then changed-file closeout.
- Task overrides: `none`
- Deferred: Human production PNG creation under `asset_drop/source_work/vehicles/custodian_field_scout_buggy_mk1/`, normalization/ingest of future files, human art-direction approval, additional vehicle families.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Re-read reviewed Scout scene/visual-kit identity and current Asset V2 vehicle schema/tooling at claim. Reconcile landed names mechanically; escalate only if visual identity, canvas scale, or direction contract materially changed.

## Handoff

- Next workstream: `review-vehicle-field-scout-buggy-asset-v2`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Finish normally and hand family/tooling result to paired review.
- Blockers or open questions: `none`
