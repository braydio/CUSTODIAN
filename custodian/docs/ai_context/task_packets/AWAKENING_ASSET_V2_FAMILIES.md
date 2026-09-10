# Task Packet — Awakening Asset Pipeline V2 Family Registration

**Status:** complete (2026-09-06) · **Addendum A complete (2026-09-09)** — see [Addendum A](#addendum-a--p0-replace-the-p-9-locker) below.

## Goal

Register the production Asset Pipeline V2 families for **Awakening / The First Return sections 01–10** exactly as defined in:

- `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`
- `design/04_architecture/ASSET_PIPELINE_V2.md`

This is a **family-contract registration and tracker-alignment pass only**. Do not create or ingest production art.

## Runtime context

Awakening is already live as `res://scenes/awakening_first_return.tscn`, with `game/world/awakening/awakening_layout.gd` as spatial authority. The Road of Witnesses South Reach remains the existing live map asset. The P-9 locker continued using the existing `field_retention_locker` art/runtime for the original pass; **Addendum A supersedes that.**

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
- existing `field_retention_locker` family/art/runtime *(superseded by Addendum A for The First Return only; the art itself still stays in the repo)*
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
- No P-9 locker replacement. *(Superseded by Addendum A.)*
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
- Existing Road and P-9 locker assets remain untouched. *(P-9 locker clause superseded by Addendum A.)*
- `REQUIRED_ASSETS.md` is aligned with V2 family identities and resolved targets.
- Focused Asset V2 validation passes.

## Completion report

Report only:
- files created/changed;
- count of family contracts by kind;
- any contract/schema adjustment necessary versus the manifest;
- validation commands and results;
- any family that could not be represented cleanly by current V2 without changing the pipeline.


---

## Addendum A — P0: replace the P-9 locker

**Status:** complete (2026-09-09). Supersedes the original packet's "no P-9 locker replacement" non-goal.

### Problem

The existing P-9 locker reads as generic storage and does not match the Crèche / Locker Reliquary tone. The first weapon pickup
in the game is too important to happen out of a prop we already dislike.

### New direction

A purpose-built **Custodian Designation Locker**: a wall-integrated institutional weapon reliquary keyed to designation authority,
not a loot chest.

- tall, narrow black-stone / ceramic-metal facade
- recessed brass authority line
- Custodian designation seal
- severe vertical silhouette
- closed state nearly flush with the wall
- authorization causes the faceplate to split/retract mechanically
- interior reveals the P-9 held in a dedicated angled retention cradle
- after pickup, empty clamps and retention hardware remain visible
- same gothic-civic-industrial language as the Crèche alcove and the Gate of Dust
- no glowing sci-fi vending-machine look

### A1. Family contract — done

`custodian/content/metadata/assets/families/awakening_designation_locker.asset.json`

Kind `world_prop`, P0, canvas 128×160, domain `sprites/environment/props/awakening`, omni, no mirroring, consumer
`res://scenes/awakening_first_return.tscn`. This brings the Awakening family count to **32**.

| State | Source file | Canvas | Frames | FPS | Layout |
|---|---|---:|---:|---:|---|
| `closed` | `closed.png` | 128×160 | 1 | — | copy |
| `authorize_open` | `authorize_open.png` | 1024×160 | 8 × 128×160 | 10 | horizontal strip, one-shot |
| `open_loaded` | `open_loaded.png` | 128×160 | 1 | — | copy |
| `empty` | `empty.png` | 128×160 | 1 | — | copy |

`authorize_open` must be a proper transformation, not a lid lift:

```text
closed
→ authority line illuminates
→ side locks retract
→ front plate separates
→ inner cradle rotates / slides forward
→ P-9 becomes visible
→ mechanism settles
→ open_loaded
```

Then:

```text
open_loaded
→ player takes P-9
→ empty
```

### A2. Production art — done

Ingested 2026-09-09 from `custodian/asset_drop/source_work/awakening/awakening_designation_locker/` (with `open-loaded.png`
renamed to `open_loaded.png` in the inbox). Asset Pipeline V2 resolved the frame geometry itself — 1024×160 inferred as 8 × 128×160
horizontal strip, the three stills as 1-frame copies — and wrote every state pixel-identical to source with alpha intact, no
resizing or repacking. Canonical runtime outputs:

```text
content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body/
  awakening_designation_locker__body__state__closed__omni__1f__128x160.png
  awakening_designation_locker__body__interaction__authorize_open__omni__8f__128x160.png
  awakening_designation_locker__body__state__open_loaded__omni__1f__128x160.png
  awakening_designation_locker__body__state__empty__omni__1f__128x160.png
```

Archive job `job_20260909T183202Z_c76e4762`. `asset status` reports 4/4 required states ready.

The first ingest shipped a `closed.png` that was byte-identical to `empty.png`, so the locker rendered as already open at rest.
A corrected sealed faceplate (`closed_pixel_128x160.png`) was re-ingested the same day with `--replace` (job
`job_20260909T184605Z_f4161fbd`); no contract or code change was needed. All four states are now visually distinct.

### A3. Runtime migration — done

`custodian/game/world/home/sidearm_locker_interactable.gd` now draws every state from the V2 family. The legacy
`field_retention_locker` constants and the interim fallback branch are gone; each state is its own canonical output, so no still
is sliced out of the animation strip.

The **gameplay contract is unchanged**:

```text
interact
→ authorize
→ opening animation
→ open_loaded
→ grant p9_sidearm
→ empty
```

`_sidearm_granted` guards the grant so re-interaction cannot duplicate the P-9, and the emptied locker leaves the `interactable`
group. Interaction prompts, collision, the authored `(832, -1952)` coordinate, the `sidearm_taken` signal, and the
`p9_recovered` progression flag in `awakening_first_return.gd` are all untouched — no scene or layout edit was needed to wire the
new art.

Covered by `custodian/tools/validation/awakening_designation_locker_presentation_smoke.gd` (registered as
`awakening_designation_locker_presentation`), which asserts the canonical art resolves at the right sizes, the strip carries eight
distinct 128×160 regions at 10 FPS one-shot, the stills are their own plates, nothing draws from the retired locker directory, the
locker rests closed, settles on `open_loaded`, ends on `empty`, and grants the P-9 exactly once.

Remaining art-gated follow-ups:

- Retune the `SidearmLocker` collider in `custodian/game/actors/props/sidearm_locker.tscn` (currently 88×96) and the
  `p9_locker` footprint in `custodian/game/world/awakening/awakening_layout.gd` against the 128×160 silhouette.
- Re-check the flush-to-wall placement in `custodian/scenes/awakening_first_return.tscn` against the finished art.

### A4. Manifest change — done

`design/04_architecture/AWAKENING_ASSET_MANIFEST.md` production rules now read:

> The First Return uses the dedicated `awakening_designation_locker` family for the P-9 release. Existing `field_retention_locker`
> assets remain available for generic storage use but are not canonical Crèche weapon-issuance art.

The family is documented under hero/interactable world-prop families, added to the art generation order, and removed from
"explicitly not registered in this pass". The `awakening_reliquary_fixtures` lockers are now explicitly set dressing only.

### A5. Not in scope

- Deleting `custodian/content/sprites/props/storage/field_retention_locker/`. It stays in the repository for generic storage use;
  no code references it any more.
- Any change to the interact → authorize → grant → empty gameplay contract.
- Any other Awakening family.
