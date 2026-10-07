# Vehicle Recovery Art Manifest

**Status:** active production-art contract  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

All vehicle recovery art uses Asset Pipeline V2. New/unprocessed files are saved under the exact `asset_drop/source_work/...` or normalized `asset_drop/inbox/<family>/...` paths below. Runtime paths are outputs, never authoring destinations.

## Family A — Custodian Field Scout Buggy Mk I

- schema: `custodian.asset_family.v2`
- kind: `vehicle`
- family id: `custodian_field_scout_buggy_mk1`
- metadata: `custodian/content/metadata/assets/families/custodian_field_scout_buggy_mk1.asset.json`
- source work: `custodian/asset_drop/source_work/vehicles/custodian_field_scout_buggy_mk1/`
- normalized inbox: `custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1/`
- runtime domain: `custodian/content/sprites/vehicles/custodian_field_scout_buggy_mk1/`
- consumer: `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`
- canvas: 256×256 RGBA per frame
- direction policy: 8dir, authored n/ne/e/se/s, mirrored nw/w/sw
- registration: stable bottom-center; wheel/ground contact may not bob
- true alpha; no baked floor shadow

| State | Tier | Frames | FPS | Per-direction sheet |
|---|---|---:|---:|---:|
| `parked_01` | required | 1 | n/a | 256×256 |
| `drive_01` | required | 6 | 8 | 1536×256 |
| `disabled_01` | required | 1 | n/a | 256×256 |
| `wreck_01` | required | 1 | n/a | 256×256 |
| `engine_start_01` | recommended | 7 | 8 | 1792×256 |
| `engine_idle_01` | recommended | 6 | 6 | 1536×256 |
| `brake_01` | recommended | 4 | 10 | 1024×256 |
| `impact_01` | recommended | 4 | 12 | 1024×256 |
| `destroy_01` | recommended | 8 | 10 | 2048×256 |
| `restore_01` | strongly recommended | 8 | 8 | 2048×256 |

Normalized example: `custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1/wreck_01__e.png`.

## Family B — Shared Vehicle Recovery FX

- schema: `custodian.asset_family.v2`
- kind: `effect`
- family id: `vehicle_recovery_fx_common`
- metadata: `custodian/content/metadata/assets/families/vehicle_recovery_fx_common.asset.json`
- source work: `custodian/asset_drop/source_work/effects/vehicle_recovery_fx_common/`
- normalized inbox: `custodian/asset_drop/inbox/vehicle_recovery_fx_common/`
- runtime domain: `custodian/content/sprites/effects/vehicles/recovery/`
- canvas: 256×256 RGBA
- direction: omni
- registration: center/bottom-center aligned to vehicle origin depending on state; family metadata must define one stable convention
- true alpha

| State | Tier | Frames | FPS | Sheet |
|---|---|---:|---:|---:|
| `scan_sweep_01` | required | 8 | 12 | 2048×256 |
| `fault_ping_01` | required | 4 | 8 | 1024×256 |
| `install_sparks_01` | required | 6 | 12 | 1536×256 |
| `power_route_01` | required | 8 | 10 | 2048×256 |
| `bootstrap_01` | required | 8 | 10 | 2048×256 |
| `restore_success_01` | required | 6 | 10 | 1536×256 |
| `restore_failure_01` | optional | 4 | 8 | 1024×256 |

The FX should be restrained technical/industrial feedback: diagnostic lines, amber/white functional indicators, localized sparks and system wake-up. Avoid giant magical bloom, loot-rarity colors, or an explosion-sized resurrection effect.

Normalized example: `custodian/asset_drop/inbox/vehicle_recovery_fx_common/scan_sweep_01__omni.png`.

## Family C — Vehicle Service Component Icons

- schema: `custodian.asset_family.v2`
- kind: `ui`
- family id: `vehicle_service_component_icons`
- metadata: `custodian/content/metadata/assets/families/vehicle_service_component_icons.asset.json`
- source work: `custodian/asset_drop/source_work/ui/vehicle_service_component_icons/`
- normalized inbox: `custodian/asset_drop/inbox/vehicle_service_component_icons/`
- runtime domain: `custodian/content/ui/vehicles/recovery/components/`
- canvas: 64×64 RGBA
- omni/static, 1 frame each

Required states:
- `field_drive_coupler_mk1`
- `custodian_control_relay_mk1`
- `structural_brace_kit_mk1`
- `component_missing`
- `pattern_unknown`
- `knowledge_insufficient`
- `component_ready`

Icons must read at terminal-list scale and should describe mechanical function before decorative detail.

## Family D — Vehicle Service Component World Props

- schema: `custodian.asset_family.v2`
- kind: `world_prop`
- family id: `vehicle_service_component_props`
- metadata: `custodian/content/metadata/assets/families/vehicle_service_component_props.asset.json`
- source work: `custodian/asset_drop/source_work/props/vehicle_service_component_props/`
- normalized inbox: `custodian/asset_drop/inbox/vehicle_service_component_props/`
- runtime domain: `custodian/content/sprites/props/vehicles/recovery_components/`
- canvas: 96×96 RGBA
- omni/static, 1 frame
- V1 tier: recommended/optional because fabricated parts are inventory items, not loose physics actors yet

States:
- `field_drive_coupler_mk1`
- `custodian_control_relay_mk1`
- `structural_brace_kit_mk1`

These become useful for future donor-part finds, physical staging, or authored salvage without changing the InventoryManager authority.

## Naming rule

Source-master example:
```text
custodian/asset_drop/source_work/effects/vehicle_recovery_fx_common/scan_sweep_01__omni_source.png
```

Normalized intake:
```text
custodian/asset_drop/inbox/vehicle_recovery_fx_common/scan_sweep_01__omni.png
```

Do not invent runtime filenames manually. After family registration, `asset request <family-id>` is the source of truth for the exact requested input names.

## Visual progression contract

- WRECKAGE: dark, inert, physically broken or incomplete; no magical glow.
- DIAGNOSIS: technical scan/fault isolation, subsystem-specific highlights.
- MISSING PART: empty socket/failed assembly read where class art supports it; UI icon always provides fallback truth.
- INSTALLATION: localized tool/spark action, not a generic health beam.
- BOOTSTRAP: power routing and indicator wake-up, followed by engine/system turnover.
- OPERATIONAL: vehicle comes online damaged; restoration is not a pristine repair.

R2+ classes may add class-specific missing-assembly silhouettes, but shared FX/icon vocabulary remains reusable.
