# CUSTODIAN Initial Vehicle Fleet Asset Program V1

**Status:** active production-art planning authority  
**Scope:** first reusable five-vehicle runtime fleet + shared recovery/salvage presentation  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b  
**Inspected main:** `ad846c21ef7f3d41cb437a9042555e907c3a2a63`

This document is the authoritative **generation order and Asset Pipeline V2 asset
map** for the initial CUSTODIAN vehicle fleet. It complements
`VEHICLE_INTEGRATION_SYSTEM_V1.md`, which owns reusable source-to-runtime
architecture, and `VEHICLE_RECOVERY_ART_MANIFEST.md`, which remains the detailed
Scout/recovery-family contract.

The production goal is not to draw every possible vehicle state. Author only
persistent physical structure, derive exact state projections, use procedural
presentation for temporary body motion, and reuse shared FX across the fleet.

## Global rules

- Asset Pipeline V2 owns canonical runtime filenames. Paths below define family
  contract targets, source-work roots, inbox roots, runtime domains and owners;
  never hand-author final runtime filenames.
- Vehicle body families use 8dir presentation: authored `n/ne/e/se/s`, mirrored
  `nw/w/sw`.
- Every directional body family locks one family-level root, ground contact,
  envelope and scale from the approved drive/turnaround authority. Disabled,
  destroy, restore and socket overlays do not independently maximize alpha bounds.
- `parked_01` is derived from an approved neutral `drive_01` frame.
- `wreck_01` is derived from the settled final `destroy_01` frame and must be
  pixel-identical to that endpoint.
- Engine-start, engine-idle, ordinary brake and ordinary impact are procedural
  presentation states. Do **not** commission separate full-body raster families
  for those actions.
- Directional destruction body art and directional destruction FX are separate
  families. The paired source sheets share one source registration per heading.
- Socket overlays describe visible failed/missing assemblies but do not create a
  second mechanical component authority. Current R1 recovery still consumes the
  reviewed required-component set atomically; future staged per-socket installation
  may consume these same art states without reauthoring them.
- Build-time skins handle paint/decals/weathering. Runtime attachment families are
  reserved for silhouette-changing independently controlled modules.
- New source art enters `asset_drop/source_work`, then normalized
  `asset_drop/inbox/<family>`, then Asset V2 publication. Runtime never reads
  Dropbox, source_work or inbox.

## Initial runtime fleet

| Phase | Vehicle | Registry ID | Chassis / role | Grade | Runtime body cell |
|---|---|---|---|---|---:|
| 1 | Custodian Field Scout Buggy Mk I | `custodian_ground_buggy_scout_light` | BUGGY / SCOUT / LIGHT | R1 SERVICE | 156x156 |
| 2 | Custodian Utility Hauler Mk I | `custodian_ground_truck_utility_medium_mk1` | TRUCK / HAULER / MEDIUM | R1 SERVICE | 192x192 |
| 3 | Custodian Industrial Crawler Mk I | `custodian_ground_crawler_industrial_medium_mk1` | CRAWLER / INDUSTRIAL / MEDIUM | R2 TECHNICAL | 224x224 |
| 4 | Custodian Recovery Rig Mk I | `custodian_ground_rig_recovery_heavy_mk1` | RIG / RECOVERY / HEAVY | R2 TECHNICAL | 256x256 |
| 5 | Custodian Restricted APC Mk I | `custodian_ground_apc_restricted_medium_mk1` | APC / SECURITY / MEDIUM | R3 RESTRICTED | 224x224 |

The registry IDs for phases 2-5 are introduced by this program as stable planned
identities. They are not claims that those classes are already registered.

# Phase 0 — shared fleet presentation vocabulary

Phase 0 is complete when the shared families below are registered, source-complete,
normalized and consumable by the reusable presentation rig. The same assets are
reused by all later vehicle phases.

## 0A — Vehicle recovery FX

**Family:** `vehicle_recovery_fx_common`  
**Kind:** `effect`  
**Family contract target:** `custodian/content/metadata/assets/families/vehicle_recovery_fx_common.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/vehicle_recovery_fx_common/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_recovery_fx_common/`  
**Runtime domain:** `sprites/effects/vehicles/recovery`  
**Runtime owner:** `vehicle_recovery_fx_common`  
**Cell:** 256x256 RGBA, omni

| State | Frames | FPS | Final strip | Loop | Status |
|---|---:|---:|---:|---|---|
| `scan_sweep_01` | 8 | 12 | 2048x256 | no | source selected |
| `fault_ping_01` | 4 | 8 | 1024x256 | no | source selected |
| `install_sparks_01` | 6 | 12 | 1536x256 | presentation-controlled during hold | source selected |
| `power_route_01` | 8 | 10 | 2048x256 | no | source selected |
| `bootstrap_01` | 8 | 10 | 2048x256 | no | source selected |
| `restore_success_01` | 6 | 10 | 1536x256 | no | source selected |

Existing immutable source handoff:
`/CUSTODIAN/implementation_inputs/custodian_vehicle_recovery_fx_common_production_source_handoff_v1_20261017.zip`.

## 0B — Shared destruction tail

**Family:** `vehicle_destruction_fx_common`  
**Kind:** `effect`  
**Family contract target:** `custodian/content/metadata/assets/families/vehicle_destruction_fx_common.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/vehicle_destruction_fx_common/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_destruction_fx_common/`  
**Runtime domain:** `sprites/effects/vehicles/destruction`  
**Runtime owner:** `vehicle_destruction_fx_common`  
**Cell:** 256x256 RGBA, omni

Required state:

- `post_destroy_smoke_01`: 8f @ 8 FPS, 2048x256, non-looping.

Existing source handoff:
`/CUSTODIAN/implementation_inputs/custodian_vehicle_post_destroy_smoke_fx_v1_20261017.zip`.

## 0C — Shared motion/combat FX

**Family:** `vehicle_motion_fx_common`  
**Kind:** `effect`  
**Family contract target:** `custodian/content/metadata/assets/families/vehicle_motion_fx_common.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/vehicle_motion_fx_common/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_motion_fx_common/`  
**Runtime domain:** `sprites/effects/vehicles/motion`  
**Runtime owner:** `vehicle_motion_fx_common`  
**Cell:** 256x256 RGBA, omni/fitted

Generate once:

| State | Frames | FPS | Strip | Intended fit |
|---|---:|---:|---:|---|
| `impact_sparks_01` | 4 | 12 | 1024x256 | impact anchor |
| `wheel_dust_01` | 6 | 12 | 1536x256 | wheel/ground anchors |
| `track_dust_01` | 6 | 10 | 1536x256 | track/ground bounds |
| `exhaust_puff_01` | 6 | 8 | 1536x256 | exhaust anchor |
| `brake_dust_01` | 4 | 10 | 1024x256 | rear ground anchors |
| `muzzle_flash_vehicle_01` | 4 | 12 | 1024x256 | weapon muzzle anchor |

No vehicle-specific copies are created.

## 0D — Vehicle component/status icons

**Family:** `vehicle_service_component_icons`  
**Kind:** `ui`  
**Family contract target:** `custodian/content/metadata/assets/families/vehicle_service_component_icons.asset.json`  
**Source:** `custodian/asset_drop/source_work/ui/vehicle_service_component_icons/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_service_component_icons/`  
**Runtime domain:** `ui/vehicles/recovery/components`  
**Runtime owner:** `vehicle_service_component_icons`  
**Cell:** 64x64 RGBA, 1f each

Shared status states:

- `component_missing`
- `component_damaged`
- `component_ready`
- `component_compatible`
- `component_restricted`
- `pattern_unknown`
- `knowledge_insufficient`

Component item icon states required by phases 1-5 are the exact component IDs in
the fleet component inventory below. One icon per unique component ID.

## 0E — Physical salvage component props

**Family:** `vehicle_service_component_props`  
**Kind:** `world_prop`  
**Family contract target:** `custodian/content/metadata/assets/families/vehicle_service_component_props.asset.json`  
**Source:** `custodian/asset_drop/source_work/props/vehicle_service_component_props/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_service_component_props/`  
**Runtime domain:** `sprites/environment/props/vehicles/recovery_components`  
**Runtime owner:** `vehicle_service_component_props`  
**Cell:** 96x96 RGBA, omni/static

Only component IDs marked **world prop required** in the fleet component inventory
need physical prop art in this initial program.

# Phase 1 — Field Scout Buggy full-loop proof

## Body family

**Family:** `custodian_field_scout_buggy_mk1`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_field_scout_buggy_mk1.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/custodian_field_scout_buggy_mk1/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1/`  
**Runtime domain:** `sprites/vehicles`  
**Runtime owner:** `custodian_field_scout_buggy_mk1`  
**Asset V2 runtime root:** `custodian/content/sprites/vehicles/custodian_field_scout_buggy_mk1/runtime/`  
**Cell:** 156x156 RGBA  
**Directions:** authored n/ne/e/se/s; mirror nw/w/sw

### Unique authored body states

| State | Frames | FPS | Per-direction strip | Source status |
|---|---:|---:|---:|---|
| `drive_01` | 12 | 12 | 1872x156 | approved 5dir source + normalized strips exist |
| `disabled_01` | 1 | n/a | 156x156 | locked 5-view source exists |
| `destroy_01` | 8 | 10 | 1248x156 | complete 5dir source exists |
| `restore_01` | 8 | 8 | 1248x156 | complete 5dir source coverage exists |

### Derived body states

- `parked_01`: selected neutral frame from `drive_01`.
- `wreck_01`: frame 8 of `destroy_01`, pixel-identical to the destroy endpoint.

### Procedural states, no unique body art

- engine start
- engine idle
- brake
- ordinary impact

### Required Scout socket overlays

These are static 156x156 overlay states in the same registered family envelope,
authored n/ne/e/se/s and mirrored by normal vehicle policy:

- `socket_drive_coupler_failed_01`
- `socket_control_relay_missing_01`
- `socket_chassis_brace_failed_01`

Generate 15 authored socket frames total.

## Scout directional destruction FX

**Family:** `custodian_field_scout_buggy_mk1_destruction_fx`  
**Kind:** `effect`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_field_scout_buggy_mk1_destruction_fx.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/custodian_field_scout_buggy_mk1_destruction_fx/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1_destruction_fx/`  
**Runtime domain:** `sprites/effects/vehicles/destruction`  
**Runtime owner:** `custodian_field_scout_buggy_mk1_destruction_fx`  
**Cell:** 256x256 RGBA, 8dir auto-mirror

- `destroy_fx_01`: 8f @ 10 FPS, 2048x256 per authored heading.
- Body/VFX source pair uses the same source registration per direction; VFX is
  not independently alpha-centered.

Current complete-loop source handoff:
`/CUSTODIAN/implementation_inputs/custodian_field_scout_buggy_full_vehicle_loop_handoff_v1_20261021.zip`  
Dropbox file ID: `id:8NXqdXuW6GUAAAAAAAAEkg`  
Outer SHA256: `2ca1b82b3c83e84d607aed5ac79f55277cb764e3116919053687d644c721b2df`.

## Scout components

| Component ID | Domain | 64px icon | 96px world prop |
|---|---|---|---|
| `field_drive_coupler_mk1` | MOBILITY/POWERTRAIN | required | required |
| `custodian_control_relay_mk1` | CONTROL | required | required |
| `structural_brace_kit_mk1` | CHASSIS | required | required |

Phase 1 is complete when the same Scout instance proves:
wreck spawn -> diagnosis -> required components -> held restoration -> 40/100 HP
operational state -> drive -> lethal destruction -> directional body/VFX ->
shared smoke -> exact wreck endpoint -> repeat recovery. Socket overlays may
initially update at the reviewed aggregate restoration boundary; staged
per-component installation is a separate runtime enhancement.

# Phase 2 — Custodian Utility Hauler Mk I

## Body family

**Family:** `custodian_utility_hauler_mk1`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_utility_hauler_mk1.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/custodian_utility_hauler_mk1/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_utility_hauler_mk1/`  
**Runtime domain:** `sprites/vehicles`  
**Runtime owner:** `custodian_utility_hauler_mk1`  
**Asset V2 runtime root:** `custodian/content/sprites/vehicles/custodian_utility_hauler_mk1/runtime/`  
**Cell:** 192x192 RGBA  
**Directions:** authored n/ne/e/se/s; mirror nw/w/sw  
**Recommended footprint:** 3x2

Generate in order:

1. five-view operational turnaround, source authority only;
2. `drive_01`: 12f @ 10 FPS, 2304x192 per authored direction;
3. `disabled_01`: 1f, 192x192;
4. `destroy_01`: 8f @ 10 FPS, 1536x192;
5. derive `wreck_01`;
6. `restore_01`: 8f @ 8 FPS, 1536x192;
7. socket overlays;
8. cargo attachment;
9. component icons/major props.

Derived `parked_01` and `wreck_01`; procedural start/idle/brake/impact.

Required socket overlays, 1f x 5 authored headings = 35 authored frames:

- `socket_front_drive_axle_failed_01`
- `socket_rear_drive_axle_failed_01`
- `socket_powerpack_failed_01`
- `socket_control_relay_missing_01`
- `socket_structural_crossmember_failed_01`
- `socket_cargo_actuator_failed_01`
- `socket_utility_power_junction_failed_01`

## Hauler cargo attachment

**Family:** `custodian_utility_hauler_mk1_cargo_module`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_utility_hauler_mk1_cargo_module.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/attachments/custodian_utility_hauler_mk1_cargo_module/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_utility_hauler_mk1_cargo_module/`  
**Runtime domain:** `sprites/vehicles/attachments`  
**Runtime owner:** `custodian_utility_hauler_mk1_cargo_module`  
**Cell:** 192x192 RGBA, 8dir auto-mirror

Unique authored state:

- `cargo_access_01`: 6f @ 8 FPS, 1152x192 per authored heading.

Derived:

- `cargo_closed_01`: first frame.
- `cargo_open_01`: final frame.

## Hauler destruction FX

**Family:** `custodian_utility_hauler_mk1_destruction_fx`  
**Kind:** `effect`  
**Source:** `custodian/asset_drop/source_work/effects/custodian_utility_hauler_mk1_destruction_fx/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_utility_hauler_mk1_destruction_fx/`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_utility_hauler_mk1_destruction_fx.asset.json`  
**Runtime domain:** `sprites/effects/vehicles/destruction`  
**Runtime owner:** `custodian_utility_hauler_mk1_destruction_fx`

- `destroy_fx_01`: 8f @ 10 FPS, 256x256 cells, 2048x256 per authored heading.

## Hauler components

- `medium_front_drive_axle_mk1` — MOBILITY — icon + world prop required.
- `medium_rear_drive_axle_mk1` — MOBILITY — icon + world prop required.
- `hauler_powerpack_mk1` — POWERTRAIN — icon + world prop required.
- `custodian_control_relay_mk1` — CONTROL — reuse Scout icon/prop.
- `structural_crossmember_kit_mk1` — CHASSIS — icon required.
- `cargo_actuator_mk1` — SPECIALTY — icon + world prop required.
- `utility_power_junction_mk1` — SPECIALTY/POWERTRAIN — icon required.

Phase 2 is complete when a medium wheeled cargo vehicle uses the same integrator,
shared FX and recovery machinery without a new vehicle controller.

# Phase 3 — Custodian Industrial Crawler Mk I

## Body family

**Family:** `custodian_industrial_crawler_mk1`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_industrial_crawler_mk1.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/custodian_industrial_crawler_mk1/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_industrial_crawler_mk1/`  
**Runtime domain:** `sprites/vehicles`  
**Runtime owner:** `custodian_industrial_crawler_mk1`  
**Asset V2 runtime root:** `custodian/content/sprites/vehicles/custodian_industrial_crawler_mk1/runtime/`  
**Cell:** 224x224 RGBA  
**Directions:** authored n/ne/e/se/s; mirror nw/w/sw  
**Recommended footprint:** 3x2

Unique authored:

- `drive_01`: 12f @ 8 FPS, 2688x224.
- `disabled_01`: 1f, 224x224.
- `destroy_01`: 8f @ 10 FPS, 1792x224.
- `restore_01`: 8f @ 8 FPS, 1792x224.

Derived parked/wreck; procedural start/idle/brake/impact.

Socket overlays, 35 authored static frames:

- `socket_left_track_missing_01`
- `socket_right_track_missing_01`
- `socket_final_drive_failed_01`
- `socket_power_unit_failed_01`
- `socket_control_core_missing_01`
- `socket_frame_tensioner_failed_01`
- `socket_aux_generator_failed_01`

## Crawler destruction FX

**Family:** `custodian_industrial_crawler_mk1_destruction_fx`  
**Kind:** `effect`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_industrial_crawler_mk1_destruction_fx.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/custodian_industrial_crawler_mk1_destruction_fx/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_industrial_crawler_mk1_destruction_fx/`  
**Runtime domain:** `sprites/effects/vehicles/destruction`  
**Runtime owner:** `custodian_industrial_crawler_mk1_destruction_fx`

- `destroy_fx_01`: 8f @ 10 FPS, 256x256 cells.

## Crawler components

- `crawler_left_track_cassette_mk1` — MOBILITY — icon + world prop.
- `crawler_right_track_cassette_mk1` — MOBILITY — icon + world prop.
- `crawler_final_drive_mk1` — MOBILITY/POWERTRAIN — icon + world prop.
- `crawler_power_unit_mk1` — POWERTRAIN — icon + world prop.
- `custodian_vehicle_control_core_mk1` — CONTROL — icon + world prop.
- `crawler_frame_tensioner_kit_mk1` — CHASSIS — icon.
- `auxiliary_generator_mk1` — SPECIALTY/POWERTRAIN — icon + world prop.

Phase 3 is the first R2 expedition-recovery proof: remote wreck, repeated logistics,
donor-part/fabrication support, visible broken assemblies and eventual extraction.

# Phase 4 — Custodian Recovery Rig Mk I

## Body family

**Family:** `custodian_recovery_rig_mk1`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_recovery_rig_mk1.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/custodian_recovery_rig_mk1/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_recovery_rig_mk1/`  
**Runtime domain:** `sprites/vehicles`  
**Runtime owner:** `custodian_recovery_rig_mk1`  
**Asset V2 runtime root:** `custodian/content/sprites/vehicles/custodian_recovery_rig_mk1/runtime/`  
**Cell:** 256x256 RGBA  
**Directions:** authored n/ne/e/se/s; mirror nw/w/sw  
**Recommended footprint:** 4x2

Unique authored:

- `drive_01`: 12f @ 8 FPS, 3072x256.
- `disabled_01`: 1f, 256x256.
- `destroy_01`: 8f @ 10 FPS, 2048x256.
- `restore_01`: 8f @ 8 FPS, 2048x256.

Socket overlays, 45 authored static frames:

- `socket_front_axle_failed_01`
- `socket_rear_axle_failed_01`
- `socket_powerpack_failed_01`
- `socket_control_core_missing_01`
- `socket_frame_brace_failed_01`
- `socket_winch_missing_01`
- `socket_boom_hydraulics_failed_01`
- `socket_service_power_bus_failed_01`
- `socket_tow_coupler_missing_01`

## Recovery Rig service attachment

**Family:** `custodian_recovery_rig_mk1_service_module`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_recovery_rig_mk1_service_module.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/attachments/custodian_recovery_rig_mk1_service_module/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_recovery_rig_mk1_service_module/`  
**Runtime domain:** `sprites/vehicles/attachments`  
**Runtime owner:** `custodian_recovery_rig_mk1_service_module`  
**Cell:** 256x256 RGBA, 8dir auto-mirror

- `service_deploy_01`: 8f @ 8 FPS, 2048x256 per authored direction.
- `service_stowed_01`: derive first frame.
- `service_deployed_01`: derive last frame.
- Stow uses reverse playback of `service_deploy_01`; do not author another full sequence.
- Tow cable is procedural geometry, not a raster animation family.

A separate winch-drum animation is not required for the initial slice. Add one
later only if static-module + procedural cable fails visual review.

## Recovery Rig destruction FX

**Family:** `custodian_recovery_rig_mk1_destruction_fx`  
**Kind:** `effect`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_recovery_rig_mk1_destruction_fx.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/custodian_recovery_rig_mk1_destruction_fx/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_recovery_rig_mk1_destruction_fx/`  
**Runtime domain:** `sprites/effects/vehicles/destruction`  
**Runtime owner:** `custodian_recovery_rig_mk1_destruction_fx`

- `destroy_fx_01`: 8f @ 10 FPS, 256x256 cells.

## Recovery Rig components

- `heavy_front_axle_module_mk1` — MOBILITY — icon + world prop.
- `heavy_rear_axle_module_mk1` — MOBILITY — icon + world prop.
- `recovery_powerpack_mk1` — POWERTRAIN — icon + world prop.
- `custodian_vehicle_control_core_mk1` — CONTROL — reuse.
- `heavy_frame_brace_kit_mk1` — CHASSIS — icon.
- `winch_drum_assembly_mk1` — SPECIALTY — icon + world prop.
- `boom_hydraulic_pack_mk1` — SPECIALTY — icon + world prop.
- `utility_power_junction_mk1` — SPECIALTY/POWERTRAIN — reuse.
- `heavy_tow_coupler_mk1` — SPECIALTY — icon + world prop.

Phase 4 is complete when service deployment/towing/recovery support changes which
remote wrecks the player can practically extract without duplicating recovery logic.

# Phase 5 — Custodian Restricted APC Mk I

## Body family

**Family:** `custodian_restricted_apc_mk1`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_restricted_apc_mk1.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/custodian_restricted_apc_mk1/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_restricted_apc_mk1/`  
**Runtime domain:** `sprites/vehicles`  
**Runtime owner:** `custodian_restricted_apc_mk1`  
**Asset V2 runtime root:** `custodian/content/sprites/vehicles/custodian_restricted_apc_mk1/runtime/`  
**Cell:** 224x224 RGBA  
**Directions:** authored n/ne/e/se/s; mirror nw/w/sw  
**Recommended footprint:** 3x2  
**Mobility:** 6x6 wheeled for the first APC; tracked mobility is already proven by Phase 3.

Unique authored:

- `drive_01`: 12f @ 10 FPS, 2688x224.
- `disabled_01`: 1f, 224x224.
- `destroy_01`: 8f @ 10 FPS, 1792x224.
- `restore_01`: 8f @ 8 FPS, 1792x224.

Socket overlays, 45 authored static frames:

- `socket_front_axle_failed_01`
- `socket_rear_bogie_failed_01`
- `socket_powerpack_failed_01`
- `socket_control_core_missing_01`
- `socket_hull_brace_failed_01`
- `socket_steering_actuator_failed_01`
- `socket_turret_ring_failed_01`
- `socket_weapon_power_bus_failed_01`
- `socket_crew_door_actuator_failed_01`

## APC turret attachment

**Family:** `custodian_restricted_apc_mk1_turret`  
**Kind:** `vehicle`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_restricted_apc_mk1_turret.asset.json`  
**Source:** `custodian/asset_drop/source_work/vehicles/attachments/custodian_restricted_apc_mk1_turret/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_restricted_apc_mk1_turret/`  
**Runtime domain:** `sprites/vehicles/attachments`  
**Runtime owner:** `custodian_restricted_apc_mk1_turret`  
**Cell:** 224x224 RGBA, independent 8dir aim presentation

Required:

- `turret_idle_01`: 1f per authored n/ne/e/se/s heading, mirrored where valid.
- Firing uses shared `muzzle_flash_vehicle_01`; no full-body fire animation.

Recommended/deferred:

- `crew_hatch_open_01`: 6f @ 8 FPS only if hatch interaction is in the first APC gameplay slice.

## APC destruction FX

**Family:** `custodian_restricted_apc_mk1_destruction_fx`  
**Kind:** `effect`  
**Family contract:** `custodian/content/metadata/assets/families/custodian_restricted_apc_mk1_destruction_fx.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/custodian_restricted_apc_mk1_destruction_fx/`  
**Inbox:** `custodian/asset_drop/inbox/custodian_restricted_apc_mk1_destruction_fx/`  
**Runtime domain:** `sprites/effects/vehicles/destruction`  
**Runtime owner:** `custodian_restricted_apc_mk1_destruction_fx`

- `destroy_fx_01`: 8f @ 10 FPS, 256x256 cells.

## APC components

- `armored_front_axle_module_mk1` — MOBILITY — icon + world prop.
- `armored_rear_bogie_module_mk1` — MOBILITY — icon + world prop.
- `apc_powerpack_mk1` — POWERTRAIN — icon + world prop.
- `restricted_vehicle_control_core_mk1` — CONTROL — icon + world prop.
- `armored_hull_brace_kit_mk1` — CHASSIS — icon.
- `steering_actuator_mk1` — CONTROL/MOBILITY — icon.
- `turret_ring_drive_mk1` — SPECIALTY — icon + world prop.
- `weapon_power_bus_mk1` — SPECIALTY/POWERTRAIN — icon + world prop.
- `crew_door_actuator_mk1` — SPECIALTY — icon.

Phase 5 is complete when the same architecture handles R3 restricted recovery,
armor, independent weapon presentation and component sockets without a new vehicle
controller or a duplicate recovery system.

# Phase 6 — Recovery expedition kit

## Camp prop family

**Family:** `vehicle_recovery_camp_props`  
**Kind:** `world_prop`  
**Family contract:** `custodian/content/metadata/assets/families/vehicle_recovery_camp_props.asset.json`  
**Source:** `custodian/asset_drop/source_work/props/vehicle_recovery_camp_props/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_recovery_camp_props/`  
**Runtime domain:** `sprites/environment/props/vehicles/recovery_camp`  
**Runtime owner:** `vehicle_recovery_camp_props`  
**Base canvas:** 128x128; state overrides may use 96x96

Required static states:

- `portable_field_generator_idle`: 96x96.
- `service_jack_01`: 96x96.
- `recovery_parts_crate_01`: 96x96.
- `portable_work_light_idle`: 96x96.
- `diagnostic_case_01`: 96x96.
- `field_service_bench_01`: 128x128.
- `recovery_beacon_01`: 96x96.
- `tow_ground_anchor_01`: 96x96.

Required animated states:

- `portable_field_generator_start`: 6f @ 8 FPS, 576x96.
- `portable_work_light_wake`: 4f @ 8 FPS, 384x96.

Reuse an existing CUSTODIAN fabricator if it already satisfies field fabrication;
do not create a duplicate vehicle-only fabricator prop.

## Shared salvage FX

**Family:** `vehicle_salvage_fx_common`  
**Kind:** `effect`  
**Family contract:** `custodian/content/metadata/assets/families/vehicle_salvage_fx_common.asset.json`  
**Source:** `custodian/asset_drop/source_work/effects/vehicle_salvage_fx_common/`  
**Inbox:** `custodian/asset_drop/inbox/vehicle_salvage_fx_common/`  
**Runtime domain:** `sprites/effects/vehicles/salvage`  
**Runtime owner:** `vehicle_salvage_fx_common`  
**Cell:** 256x256 RGBA, fitted/omni

- `compatible_part_ping_01`: 4f @ 8 FPS, 1024x256.
- `part_removed_01`: 4f @ 8 FPS, 1024x256.

No per-vehicle removal animation is required.

# Fleet component inventory

Every unique component below requires a 64x64 state in
`vehicle_service_component_icons`. Only rows marked world-prop yes require a
96x96 state in `vehicle_service_component_props`.

| Component ID | First phase | Domain | World prop |
|---|---:|---|---|
| `field_drive_coupler_mk1` | 1 | MOBILITY/POWERTRAIN | yes |
| `custodian_control_relay_mk1` | 1 | CONTROL | yes |
| `structural_brace_kit_mk1` | 1 | CHASSIS | yes |
| `medium_front_drive_axle_mk1` | 2 | MOBILITY | yes |
| `medium_rear_drive_axle_mk1` | 2 | MOBILITY | yes |
| `hauler_powerpack_mk1` | 2 | POWERTRAIN | yes |
| `structural_crossmember_kit_mk1` | 2 | CHASSIS | no |
| `cargo_actuator_mk1` | 2 | SPECIALTY | yes |
| `utility_power_junction_mk1` | 2 | SPECIALTY/POWERTRAIN | no |
| `crawler_left_track_cassette_mk1` | 3 | MOBILITY | yes |
| `crawler_right_track_cassette_mk1` | 3 | MOBILITY | yes |
| `crawler_final_drive_mk1` | 3 | MOBILITY/POWERTRAIN | yes |
| `crawler_power_unit_mk1` | 3 | POWERTRAIN | yes |
| `custodian_vehicle_control_core_mk1` | 3 | CONTROL | yes |
| `crawler_frame_tensioner_kit_mk1` | 3 | CHASSIS | no |
| `auxiliary_generator_mk1` | 3 | SPECIALTY/POWERTRAIN | yes |
| `heavy_front_axle_module_mk1` | 4 | MOBILITY | yes |
| `heavy_rear_axle_module_mk1` | 4 | MOBILITY | yes |
| `recovery_powerpack_mk1` | 4 | POWERTRAIN | yes |
| `heavy_frame_brace_kit_mk1` | 4 | CHASSIS | no |
| `winch_drum_assembly_mk1` | 4 | SPECIALTY | yes |
| `boom_hydraulic_pack_mk1` | 4 | SPECIALTY | yes |
| `heavy_tow_coupler_mk1` | 4 | SPECIALTY | yes |
| `armored_front_axle_module_mk1` | 5 | MOBILITY | yes |
| `armored_rear_bogie_module_mk1` | 5 | MOBILITY | yes |
| `apc_powerpack_mk1` | 5 | POWERTRAIN | yes |
| `restricted_vehicle_control_core_mk1` | 5 | CONTROL | yes |
| `armored_hull_brace_kit_mk1` | 5 | CHASSIS | no |
| `steering_actuator_mk1` | 5 | CONTROL/MOBILITY | no |
| `turret_ring_drive_mk1` | 5 | SPECIALTY | yes |
| `weapon_power_bus_mk1` | 5 | SPECIALTY/POWERTRAIN | yes |
| `crew_door_actuator_mk1` | 5 | SPECIALTY | no |

Totals for the initial program:

- 32 unique component item icons.
- 7 shared status icons.
- 26 required physical component world props.

# Generation order within each new vehicle phase

Use this order for phases 2-5:

1. operational five-view turnaround;
2. `drive_01` and family registration lock;
3. `disabled_01`;
4. `destroy_01`;
5. derive `wreck_01`;
6. `restore_01`;
7. socket overlays against locked body registration;
8. class-specific attachment animation;
9. component icons and required world props;
10. directional destruction FX paired to body registration;
11. normalize to exact inbox geometry;
12. Asset V2 ingest/build/wire;
13. standardized runtime visual review.

Do not create socket overlays before the body family registration is locked.

# Standard visual-review sheet

Every vehicle phase ends with one contact/review sheet showing:

- n/ne/e/se/s authored headings;
- nw/w/sw mirror proof;
- operational/drive reference;
- disabled state;
- destruction midpoint;
- settled wreck;
- restoration midpoint;
- every broken/missing socket overlay;
- fully repaired body;
- Operator/world-tile scale reference.

Objective geometry/registration checks happen before subjective review.

# Explicitly not generated

The initial fleet does **not** require unique full-body raster sheets for:

- parked;
- generic engine start;
- generic engine idle;
- ordinary braking;
- ordinary impact;
- generic scan;
- generic installation sparks;
- generic power routing/bootstrap/success;
- generic post-destroy smoke;
- generic wheel/track dust;
- generic muzzle flash.

Those states are derived, procedural or shared.

# Phase completion summary

- **Phase 0:** fleet-wide FX/icon/prop vocabulary is registered and reusable.
- **Phase 1:** Scout proves the complete same-instance wreck/recovery/drive/destroy loop.
- **Phase 2:** Hauler proves medium wheeled cargo + more sockets without new controller code.
- **Phase 3:** Crawler proves R2 tracked expedition recovery and donor-part value.
- **Phase 4:** Recovery Rig changes recovery logistics through service/tow capability.
- **Phase 5:** APC proves R3 restricted recovery and independent weapon attachment presentation.
- **Phase 6:** camp/salvage assets make long-form remote recovery legible and reusable.

No later phase may solve a missing presentation need by cloning the complete body
animation set if the integrator can derive, fit, skin, socket or attach it instead.
