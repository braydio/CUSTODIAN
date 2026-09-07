# Task Packet — Awakening Asset Pipeline V2 Family Registration

## Goal

Register the production Asset Pipeline V2 families for **Awakening / The First Return sections 01–10** exactly as defined in:

- `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`
- `design/04_architecture/ASSET_PIPELINE_V2.md`

This is a **family-contract registration and tracker-alignment pass only**. Do not create or ingest production art.

## Runtime context

Awakening is already live as `res://scenes/awakening_first_return.tscn`, with `game/world/awakening/awakening_layout.gd` as spatial authority. The Road of Witnesses South Reach remains the existing live map asset. The P-9 locker continues using the existing `field_retention_locker` art/runtime.

## Primary owner

`custodian/content/metadata/assets/families/`

## Implement

### 1. Create every family contract in the manifest

Create V2 family JSON files for all families listed in `AWAKENING_ASSET_MANIFEST.md`:

**Backdrop families**
- `awakening_creche_environment`
- `awakening_ambulatory_environment`
- `awakening_attestation_environment`
- `awakening_locker_reliquary_environment`
- `awakening_dust_lung_environment`
- `awakening_undergate_environment`
- `awakening_gate_plaza_environment`
- `awakening_custodian_approach_environment`
- `awakening_late_service_environment`

**Hero / interactable world props**
- `awakening_creche_recovery_alcove`
- `awakening_creche_console`
- `awakening_dust_lung_lift`
- `gate_of_dust`
- `awakening_late_service_relay_lamp`

**Zone fixture families**
- `awakening_creche_fixtures`
- `awakening_ambulatory_fixtures`
- `awakening_attestation_fixtures`
- `awakening_reliquary_fixtures`
- `awakening_dust_lung_structures`
- `awakening_undergate_machinery`
- `awakening_approach_fixtures`
- `awakening_late_service_fixtures`

**Tile/decal families**
- `awakening_authority_inlay`
- `awakening_ruin_decal`
- `awakening_institutional_decal`

**Effect families**
- `awakening_creche_console_activation_fx`
- `awakening_dust_motes`
- `awakening_falling_ash`
- `awakening_gate_wind_dust`
- `awakening_relay_static`
- `awakening_water_shimmer`

There should be **31 new family contracts** total.

### 2. Follow existing V2 schema patterns

Use `schema: custodian.asset_family.v2`.

Use the existing kind schemas rather than adding pipeline branches:
- `backdrop`
- `world_prop`
- `tile`
- `effect`

Relevant examples/authorities include:
- `custodian/content/metadata/assets/families/drowned_basilica_underlay.asset.json`
- `custodian/content/metadata/assets/families/field_fabricator_mk1.asset.json`
- `custodian/content/metadata/assets/schemas/{backdrop,world_prop,tile,effect}.json`

Do **not** change Asset Pipeline V2 merely to accommodate these families. If a contract does not validate, first fix the contract to match the existing supported schema.

### 3. Exact environment routing

Backdrop outputs must land directly under the existing intended zone folders, not under an extra owner subfolder.

Use this pattern:

```json
"runtime": {
  "domain": "levels/awakening/01_creche",
  "owner": "awakening_creche",
  "template": "{domain}/{filename}",
  "filename_policy": "template",
  "filename_template": "{owner}_{variant}_{frame_size}.png"
}
```

Each environment family has required `underlay` and `foreground` copy states at the exact canvas in the manifest.

### 4. Exact prop routing

All Awakening `world_prop` families should route under:

```text
sprites/environment/props/awakening
```

Use the existing world-prop canonical filename/routing behavior unless a family requires the manifest's explicit per-state frame override.

### 5. Gate family is future-stable

`gate_of_dust` must include the current required structural states plus the optional/deferred continuity states in the same family.

Current required:
- `body_idle_sealed`
- `west_pylon`
- `east_pylon`
- `sealed_aperture`
- `rest_threshold`

Deferred optional states:
- `authority_wake` — 8f, 768×512, 8 FPS
- `route_acquire` — 8f, 768×512, 8 FPS
- `aperture_resolve` — 12f, 768×512, 8 FPS
- `continuity_stable` — 8f, 768×512, 8 FPS
- `shutdown` — 8f, 768×512, 8 FPS

Do not mark deferred states required or wire them into runtime.

### 6. Consumer declarations

Where useful for future `BOUND` reporting, declare the live Awakening scene as consumer:

```text
res://scenes/awakening_first_return.tscn
```

Do not fake binding evidence. Until the scene references an ingested canonical path, `BOUND` should remain false/not-bound.

### 7. Do not create speculative creature families

Do not register:
- Attestation Sentinel
- Witness Sentinel
- broken Approach Sentinel
- dust-fed scavenger
- route-leech
- pale city bird

Their gameplay/runtime contracts are not locked enough yet.

### 8. Do not replace existing live assets

Do not modify or replace:
- `custodian/content/levels/hub/Road_of_Witnesses_Tilemap.png`
- existing `field_retention_locker` family/art/runtime
- Operator art
- Field Terminal art/runtime

No production PNGs should be generated, copied, ingested, renamed, or bound in this task.

### 9. Align `REQUIRED_ASSETS.md`

The root `REQUIRED_ASSETS.md` remains the sole canonical missing-asset tracker.

Revise its Awakening entries so they refer to the V2 family/state identity and the actual V2-resolved runtime target naming instead of the older manually invented `*_v1.png` paths where those differ.

Do not duplicate the full semantic contract there. Keep it a concise missing-production-art tracker.

Add missing P0/P1 Awakening families from the manifest when the root tracker does not currently represent them.

Do not add deferred creature/enemy families.

### 10. AI context/document index

Update only where useful:
- `custodian/docs/ai_context/FILE_INDEX.md` — add `design/04_architecture/AWAKENING_ASSET_MANIFEST.md` and describe the family-contract location.
- `custodian/docs/ai_context/CURRENT_STATE.md` — one concise sentence that Awakening art production is now registered through 31 Asset V2 families; do not imply art exists.

Do not rewrite unrelated sections.

## Non-goals

- No production art.
- No image processing.
- No runtime scene art binding.
- No Godot visual changes.
- No audio pipeline changes.
- No new Asset V2 kind.
- No `asset watch` work.
- No creature/enemy design.
- No Road of Witnesses migration.
- No P-9 locker replacement.
- No Continuity Port gameplay.

## Validation

Run focused checks first:

```bash
cd ~/Projects/CUSTODIAN

python3 custodian/tools/validation/asset_contract_schema_smoke.py
python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py
python3 custodian/tools/validation/asset_pipeline_v2_smoke.py
```

Then inspect the family registry:

```bash
python3 custodian/tools/assets/asset.py families
python3 custodian/tools/assets/asset.py doctor
```

Spot-check at minimum:

```bash
python3 custodian/tools/assets/asset.py status awakening_creche_environment
python3 custodian/tools/assets/asset.py status awakening_creche_recovery_alcove
python3 custodian/tools/assets/asset.py status awakening_dust_lung_environment
python3 custodian/tools/assets/asset.py status gate_of_dust
python3 custodian/tools/assets/asset.py status awakening_authority_inlay
python3 custodian/tools/assets/asset.py status awakening_gate_wind_dust

python3 custodian/tools/assets/asset.py request awakening_creche_environment
python3 custodian/tools/assets/asset.py request gate_of_dust
```

Expected state before any art is supplied:
- contracts validate;
- families list successfully;
- requests resolve exact canvases/states;
- status reports source/runtime art missing, not contract/routing errors;
- no generated catalog entry should falsely claim production completeness;
- no runtime file should be created.

Finally:

```bash
python3 custodian/tools/validation/run_validation.py --changed --json
```

## Acceptance

- Exactly 31 new Awakening Asset V2 family contracts exist.
- Family IDs, states, canvases, frame counts, priorities, and routing match `AWAKENING_ASSET_MANIFEST.md`.
- Environment families resolve directly into `content/levels/awakening/<zone>/`.
- World props resolve under `content/sprites/environment/props/awakening/...`.
- Tiles and effects use their existing V2 kinds and supported routing.
- Gate future states exist but are optional/deferred.
- Existing Road and P-9 locker assets remain untouched.
- `REQUIRED_ASSETS.md` is aligned with V2 family identities and resolved targets.
- Focused Asset V2 validation passes.

## Completion report

Report only:
- files created/changed;
- count of family contracts by kind;
- any contract/schema adjustment necessary versus the manifest;
- validation commands and results;
- any family that could not be represented cleanly by current V2 without changing the pipeline.
