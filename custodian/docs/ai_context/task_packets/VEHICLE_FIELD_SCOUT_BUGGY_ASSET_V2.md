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
- Reviewed main: `4cbc6a67d1156fe7e87262203279835cffe1548f`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Give the Field Scout Buggy a real Asset Pipeline V2 family and replace hover-buggy-specific vehicle post-processing with an owner/family-driven seam that supports future vehicle classes without another hard-coded importer.
- Completion boundary: Done when `custodian_field_scout_buggy_mk1.asset.json` is registered against the live vehicle kind schema, Asset V2 request/plan/status exposes the exact 256 px directional state contract, vehicle runtime resource rebuilding no longer assumes `hover_buggy` as the only owner, the Scout class can bind canonical family outputs when present while safely retaining compatibility art when absent, and required-assets/docs point at family truth rather than nonexistent paths.
- Source-art availability: The full five authored `drive_01` directions are now present on the user's workstation at `/home/braydenchaffee/CUSTODIAN-DROPBOX-UPLOADS/Custodian-Buggy`. This local handoff supersedes the earlier three-direction Dropbox package for drive coverage. Treat these files as approved production source candidates, not runtime-complete assets, until this packet stages, normalizes, ingests, validates, and binds them through Asset Pipeline V2.
- Current measured state: The semantic `field_scout_buggy_mk1.tscn` class is landed, and its parent review found one blocking R1 restoration defect now owned by the dependency-gated correction/re-review pair. Asset kind `vehicle` exists with domain `sprites/vehicles`, default 8dir/auto-mirror/body/locomotion and `vehicle_runtime_import`. No production Scout vehicle family contract exists yet. Legacy inbox grammar recognizes hover-buggy names and `update_vehicle_runtime_resources.gd` remains hover-specific. Live compatibility art is still under `content/sprites/vehicles/hover_buggy/`. `CURRENT_STATE.md` also retains one stale older paragraph claiming the production ID uses the LightBuggy scene; live runtime no longer does.
- Evidence: `custodian/content/metadata/assets/schemas/vehicle.json`; `custodian/tools/assets/asset_contract.py`; `asset.py`; `custodian/tools/pipelines/generate_inbox_manifests.py`; `update_vehicle_runtime_resources.gd`; `custodian/content/sprites/_pipeline/README.md`; `custodian/content/metadata/assets/required_assets.registry.json`; `custodian/game/actors/vehicles/hover_buggy_idle_frames.tres`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Task-specific authority: `design/04_architecture/ASSET_PIPELINE_V2.md`; live `vehicle.json` kind schema and Asset V2 CLI/contract code; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Work surface: User handoff `/home/braydenchaffee/CUSTODIAN-DROPBOX-UPLOADS/Custodian-Buggy/`; `custodian/asset_drop/source_work/vehicles/custodian_field_scout_buggy_mk1/`; `custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1/`; new family contract `custodian/content/metadata/assets/families/custodian_field_scout_buggy_mk1.asset.json`; vehicle post-process/runtime-resource tooling; visual-kit binding; required-assets registry/generated view; focused Asset V2/vehicle validation.
- Change: Stage the approved five-direction drive handoff from the exact local directory below, preserving original high-resolution masters and 156px reference strips in source_work; normalize the high-resolution masters frame-by-frame to canonical 12×256×256 horizontal inbox strips; ingest and bind them through Asset Pipeline V2. Register family `custodian_field_scout_buggy_mk1` as kind `vehicle`, runtime domain `sprites/vehicles`, owner `custodian_field_scout_buggy_mk1`, 256x256 canvas, 8dir, auto-mirror true, authored required directions `n, ne, e, se, s`. Encode required `parked_01` 1f, `drive_01` 12f at 12 FPS, `disabled_01` 1f, `wreck_01` 1f; recommended `engine_start_01` 7f at 8 FPS, `engine_idle_01` 6f at 6 FPS, `brake_01` 4f at 10 FPS, `impact_01` 4f at 12 FPS, `destroy_01` 8f at 10 FPS, `restore_01` 8f at 8 FPS on the body transition layer, and `restore_fx_01` 8f at 8 FPS on the FX transition layer. Use horizontal strips for animations and aliases `idle -> parked_01`, `idle_start -> engine_start_01`, `idle_loop -> engine_idle_01`, `move -> drive_01`. Generalize vehicle post-processing so owner/family identity comes from contract/catalog/consumer rather than per-class constants. Preserve old hover resource only as compatibility source until canonical Scout states exist. Make Scout presentation resolve authoritative facing direction when canonical directional clips exist. Replace stale firing/damage/destruction requirements with family/state-backed needs reflecting the unarmed class: no required firing body state; track impact/destroy/wreck according to the family. Regenerate REQUIRED_ASSETS. Reconcile the stale Vehicle Registry paragraph in `custodian/docs/ai_context/CURRENT_STATE.md` so it names the semantic Field Scout scene and labels hover-buggy frames as compatibility presentation only; this closes parent-review R0-02.
- Preserve: Asset V2 canonical routing/naming; non-vehicle ingest; hover compatibility art; stable class runtime behavior; no direct runtime references to asset_drop; immutable source masters.
- Non-goals: Do not regenerate or artistically modify the supplied drive PNGs; do not fabricate missing non-drive states; do not add weapons; do not redesign Asset V2 globally; do not remove hover compatibility while a live fallback needs it; do not change handling.
- Acceptance: All ten supplied local handoff PNGs are preserved under source_work with deterministic provenance names; the five canonical `drive_01__{n,ne,e,se,s}.png` inbox strips are 3072×256 RGBA, 12 frames of 256×256, generated from the high-resolution masters without per-frame crop/recenter or artistic edits; `asset request custodian_field_scout_buggy_mk1` requests `<state>__<direction>.png` for five authored directions with exact geometry; ingest/plan/status parse family cleanly; doctor has no new errors; runtime publication exposes N/NE/E/SE/S and the configured NW/W/SW mirrors; post-processing targets Scout owner without a duplicated Scout-specific script and still rebuilds hover compatibility; the live Scout consumer plays canonical `drive_01` for movement with correct facing and 12 FPS timing; required-assets no longer targets nonexistent `light_buggy/runtime` or requires firing art; validation proves frame count, 256px registration, mirrored coverage, and consumer binding.
- Validation: Inspect `python3 custodian/tools/assets/asset.py --help`. Run `python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py`, `python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py`, `res://tools/validation/validate_vehicle_registry.gd`, then current request/plan/status commands for `custodian_field_scout_buggy_mk1`, `python3 custodian/tools/assets/asset.py doctor`, and `python3 custodian/tools/assets/asset.py needs --check`. Add a focused implementation-created vehicle-family/post-process smoke using temporary fixture strips, record its exact path/validation ownership, then changed-file closeout.
- Task overrides: `none`
- Deferred: Non-drive Scout production states (`parked_01`, `disabled_01`, `wreck_01`, recommended transitions/FX), additional vehicle families, and any later human polish pass to the already-approved drive source masters.

## Approved five-direction drive handoff

### External source directory

Codex must consume these files from the user's local workstation path:

`/home/braydenchaffee/CUSTODIAN-DROPBOX-UPLOADS/Custodian-Buggy`

Fail closed if this path or any listed file is absent. Do not substitute the older three-direction Dropbox ZIP when this local five-direction set is available.

### Source mapping

| Direction | High-resolution source master | Source geometry | 156px reference | Canonical source-work master | Canonical source-work reference | Canonical inbox output |
|---|---|---:|---|---|---|---|
| E | `buggy_e_12f_512_source_v1.png` | 6144×512 = 12×512² | `buggy_e_12f_156_v1.png` | `drive_01__e_source.png` | `drive_01__e_156_reference.png` | `drive_01__e.png` |
| N | `buggy_n_12f_source_v1.png` | 4344×362 = 12×362² | `buggy_n_12f_156_v1.png` | `drive_01__n_source.png` | `drive_01__n_156_reference.png` | `drive_01__n.png` |
| NE | `buggy_ne_12f_362_source_v1.png` | 4344×362 = 12×362² | `buggy_ne_12f_156_v1.png` | `drive_01__ne_source.png` | `drive_01__ne_156_reference.png` | `drive_01__ne.png` |
| S | `buggy_s_12f_source_v1.png` | 4344×362 = 12×362² | `buggy_s_12f_156_v1.png` | `drive_01__s_source.png` | `drive_01__s_156_reference.png` | `drive_01__s.png` |
| SE | `buggy_se_12f_512_source_v1.png` | 6144×512 = 12×512² | `buggy_se_12f_156_v1.png` | `drive_01__se_source.png` | `drive_01__se_156_reference.png` | `drive_01__se.png` |

Source-work destination for all ten preserved files:

`custodian/asset_drop/source_work/vehicles/custodian_field_scout_buggy_mk1/`

Inbox destination for the five normalized production strips:

`custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1/`

### Preservation rules

1. Copy the five high-resolution source masters byte-for-byte to their canonical `*_source.png` names before normalization.
2. Copy the five 1872×156 reference strips byte-for-byte to the `*_156_reference.png` names. They are visual/cadence evidence, not ingest inputs.
3. If any destination already exists with different bytes, preserve it under a dated `pre_five_direction_drive_handoff_<YYYYMMDD>/` subdirectory before replacement. Never destroy prior source evidence.
4. Runtime code must never reference either the user's external handoff directory or `asset_drop/source_work` / `asset_drop/inbox`.

### Canonical normalization algorithm

Normalize from the **high-resolution source master**, not from the 156px reference strip.

For each direction:

1. Assert RGBA and real alpha.
2. Assert width is exactly `12 × source_frame_size` and height equals `source_frame_size`:
   - E / SE: 12×512×512;
   - N / NE / S: 12×362×362.
3. Split on the existing exact square frame grid. Do **not** alpha-crop, content-recenter, reorder, interpolate, or synthesize frames.
4. Downsample each complete square cell uniformly to 256×256 with the repository's preferred premultiplied-alpha high-quality resampler (Lanczos where that remains the live convention). Scaling the whole cell preserves the authored registration and suspension motion.
5. Concatenate the 12 resulting cells left-to-right into exactly 3072×256 RGBA.
6. Write only the canonical inbox name `drive_01__<direction>.png`.
7. Compare orientation, frame order, and suspension cadence against the corresponding 1872×156 reference strip. The reference must not replace the high-resolution source as normalization input.
8. Record source and normalized hashes in the closing summary or an implementation-owned manifest so review can prove exact provenance.

### Asset Pipeline V2 ingest and wiring

After source staging/normalization:

1. Inspect `python3 custodian/tools/assets/asset.py --help` and the live vehicle family schema before authoring commands or the family contract.
2. Create/update `custodian/content/metadata/assets/families/custodian_field_scout_buggy_mk1.asset.json` rather than creating a second family.
3. The authoritative `drive_01` contract is **12 frames, 12 FPS, 256×256 cells, 3072×256 per authored direction, looped**, with authored N/NE/E/SE/S and auto-mirrored NW/W/SW.
4. Run the live Asset V2 request/plan/status flow and ingest this family through the current CLI. Do not hand-copy canonical runtime outputs.
5. Generalize/consume the vehicle runtime-resource post-process as already scoped by this packet so the Scout resolves family outputs by owner/family identity, not a Scout-only hard-coded importer.
6. Wire the live Field Scout movement presentation to canonical `drive_01` clips for the authoritative facing direction. Preserve hover compatibility only as fallback for states not yet supplied; do not let hover compatibility override canonical drive clips after ingest.
7. Verify all five authored directions at runtime and the three mirrored directions (NW from NE, W from E, SW from SE).
8. Regenerate/check required-assets truth and applicable docs. Mark drive coverage supplied/ingested only after pipeline status and consumer validation are green. Non-drive states remain open.

### Required focused proof

The implementation-created vehicle-family/post-process smoke must use the actual ingested drive family, not only temporary fixture strips, for at least one end-to-end assertion. It must prove:

- five authored `drive_01` strips resolve;
- each clip has exactly 12 frames at 12 FPS;
- mirror routing resolves NW/W/SW to the correct authored source without orientation inversion bugs;
- Field Scout movement selects `drive_01`, while an idle/wreck state with no canonical art still falls back safely;
- no runtime path contains `CUSTODIAN-DROPBOX-UPLOADS` or `asset_drop`.

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
