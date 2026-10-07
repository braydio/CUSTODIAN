# Custodian Field Scout Buggy Mk I

**Status:** runtime class implemented; compatibility presentation pending Asset V2
**Parent authority:** `design/02_features/vehicles/VEHICLES.md`  
**Implementation series:** lifecycle hardening -> wreck restoration -> diagnosis/knowledge -> component fabrication -> class recovery -> Asset V2 vehicle-family foundation  
**Reviewed main:** `5020df4b88a2`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Purpose

Promote the existing first pilotable vehicle from a registry/hover-buggy compatibility scaffold into the first concrete production vehicle class: **Custodian Field Scout Buggy Mk I**.

This is a gameplay class, not a gratuitous GDScript subclass. Shared vehicle lifecycle and movement remain owned by `PilotableVehicle`; class identity is expressed through registry classification, profiles, scene composition, hardpoints, durability, footprint, and presentation. Add a focused subclass/component later only if this class gains stateful behavior that cannot cleanly live in data or an existing authority.

## Class lock

| Field | Contract |
| --- | --- |
| Registry ID | `custodian_ground_buggy_scout_light` |
| Display name | Custodian Field Scout Buggy Mk I |
| Faction | CUSTODIAN |
| Domain | GROUND |
| Chassis | BUGGY |
| Role | SCOUT |
| Tier | LIGHT |
| Variant | MK1 |
| Interaction | PILOTABLE after restoration |
| Initial world state | WRECKAGE |
| Restoration profile | `field_scout_recovery_light` |
| Recovery grade | R1 SERVICE |
| Restoration requirements | field drive coupler Mk I + Custodian control relay Mk I + structural brace kit Mk I |
| Raw-resource direct repair | forbidden for this class |
| Restoration hold | 4.0 s |
| Restored health | 40 / 100 HP |
| Mobility | WHEELED |
| Seats | 1 driver, 0 passenger |
| Entry radius | 64 px |
| Footprint | 2x1 cells, bottom-center |
| Hardpoints | front light + rear utility |
| Initial loadout | none |
| Intended utility loadout | `scout_sensor_light` only after `light_scanner` has a real runtime consumer |
| Weapons | none baked into the chassis |
| Terrain contract | existing `actor_kind = "vehicle"` surface multiplier |
| Collision damage | disabled for V1 |
| Repair/fuel | wreck restoration + existing field repair / fuel deferred |

The existing registry ID is preserved to avoid identity churn. The production scene should become semantically named for this class. Compatibility aliases may exist only while a live consumer still needs them.

## Recovery loop

The Scout is **found, diagnosed, rebuilt, and recommissioned**.

1. Spawn as `WRECKAGE`: 0 HP, disabled, immobile, not enterable.
2. Diagnose the chassis. The Scout reports three failed standard service assemblies:
   - `field_drive_coupler_mk1`
   - `custodian_control_relay_mk1`
   - `structural_brace_kit_mk1`
3. These three R1 service patterns are starter-known. The first Scout teaches fabrication/install flow without demanding a research grind.
4. Fabricate each part through the existing Field Fabricator. `ResourceLedger` materials are recipe inputs only; the wreck never consumes raw scrap/alloy/power directly.
5. `InventoryManager` receives the completed replacement assemblies.
6. Return to the wreck. The restoration interaction shows which required assemblies are present/missing.
7. Hold the installation/bootstrap interaction for 4.0 seconds. Release, target loss, range exit, death/impact, portal transitions, or open UI cancel for free.
8. On successful completion, consume the three assemblies exactly once and restore the same Scout at 40/100 HP.
9. Existing field repair can then improve HP. Later lethal damage returns the Scout to recoverable wreckage.

Advanced R2+ wrecks use the same flow, but some missing assemblies are recipe-locked until scanning enough compatible vehicles/parts supplies the required mechanical-domain knowledge and pattern evidence.

See `VEHICLE_RECOVERY_REVERSE_ENGINEERING.md` for R0-R4 progression and authority boundaries.

## Movement and durability

V1 preserves the already-tuned first-vehicle movement values so the class migration does not disguise a handling rebalance:

```text
movement profile: ground_wheeled_light
max speed:        175 px/s
acceleration:     420 px/s^2
deceleration:     520 px/s^2
turn response:    10.0
reverse:          0.45x
offroad:          0.78x
road multiplier:  enabled
```

Durability becomes data-owned rather than an untracked scene/script default:

```text
durability profile: light_scout_utility
max health:         100
destroyed at:       0
```

No armor/resistance/fuel model is introduced in V1.

## Runtime scene contract

Target production scene:

```text
custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn
```

The scene uses `PilotableVehicle` as the shared runtime authority and retains one `VehicleSeat` driver seat, authoritative collision geometry, an exit marker used as the first safe-exit candidate, `Hardpoints/FrontLight`, `Hardpoints/RearUtility`, and one presentation node consuming the selected visual kit.

The old `light_buggy.tscn` scene has been removed after moving its live consumers to `field_scout_buggy_mk1.tscn`; no scene compatibility alias remains. Current hover SpriteFrames are explicitly named compatibility presentation until the Asset V2 vehicle-family slice replaces them.

A stale constant in-world health bar is not acceptable. Bind it to authoritative vehicle health through an existing presentation seam if one exists; otherwise remove the orphan presentation rather than creating a second health authority.

## Lifecycle invariants

1. The Operator can never remain hidden, collision-disabled, or process-disabled after vehicle ownership ends.
2. `PilotableVehicle` owns pilot occupancy and vehicle lifecycle state. `PlayerController` owns input/camera routing, not duplicate occupancy truth.
3. Disable/destruction while occupied uses the same pilot-release authority as an ordinary exit, with safe placement semantics and a fail-safe fallback that cannot strand the Operator.
4. Vehicle destruction cannot leave PlayerController targeting a dead/disabled vehicle.
5. Nearby discovery returns each vehicle once even if compatibility groups overlap.
6. A zero-health/wrecked vehicle cannot be entered or driven and is not advertised as a live pilotable interaction.
7. Initial wreck spawn does not emit `vehicle_destroyed`; actual lethal damage does.
8. `restore_from_wreck()` is the only transition from zero-health wreckage back to operational state; economy code never mutates lifecycle fields directly.
9. Current safe-exit collision/navigation behavior remains intact.

## Visual identity

The current hover-buggy art is compatibility art, not the final Field Scout visual contract.

Production silhouette:
- low, compact four-wheel field chassis;
- visible wheel contact with the ground, never hover lift;
- narrow forward service nose and exposed/armored wheel wells;
- one enclosed or half-enclosed Operator cockpit;
- rear utility deck with a readable equipment socket;
- military-civic Custodian construction rather than civilian car styling;
- pale neutral/stone-metal body, restrained charcoal mechanicals, amber functional accents;
- no permanent weapon silhouette;
- no giant exhaust flame, float bob, or hover shadow language.

It must read at normal gameplay zoom against hardened civic paving, dirt, grass, and alpine terrain.

## Asset Pipeline V2 family

```text
family id:        custodian_field_scout_buggy_mk1
kind:             vehicle
runtime domain:   sprites/vehicles
runtime owner:    custodian_field_scout_buggy_mk1
canvas:           256x256 per frame
direction policy: 8dir
auto mirror:      true
authored dirs:    n, ne, e, se, s
mirrored dirs:    nw, w, sw
consumer:         res://game/actors/vehicles/field_scout_buggy_mk1.tscn
```

Asset Pipeline V2 generates W/NW/SW from E/NE/SE. Do not hand-author mirrored duplicates unless later asymmetry requires them.

### State manifest

| State | Tier | Frames | Sheet per authored direction | FPS | Loop | Group |
| --- | --- | ---: | --- | ---: | --- | --- |
| `parked_01` | required | 1 | 256x256 | n/a | no | posture |
| `engine_start_01` | recommended | 7 | 1792x256 | 8 | no | transition |
| `engine_idle_01` | recommended | 6 | 1536x256 | 6 | yes | posture |
| `drive_01` | required | 6 | 1536x256 | 8 | yes | locomotion |
| `brake_01` | recommended | 4 | 1024x256 | 10 | no | locomotion |
| `impact_01` | recommended | 4 | 1024x256 | 12 | no | reaction |
| `disabled_01` | required | 1 | 256x256 | n/a | no | reaction |
| `destroy_01` | recommended | 8 | 2048x256 | 10 | no | death |
| `wreck_01` | required | 1 | 256x256 | n/a | no | death |
| `restore_01` | recommended | 8 | 2048x256 | 8 | no | transition |
| `restore_fx_01` | recommended | 8 | 2048x256 | 8 | no | fx |

All animations use `layout: horizontal_strip`, `layer: body`, 256x256 cells, true alpha, stable bottom-center registration, consistent wheel-ground contact, and no painted floor shadow.

Suggested aliases:

```text
idle       -> parked_01
idle_start -> engine_start_01
idle_loop  -> engine_idle_01
move       -> drive_01
```

Loop behavior remains runtime/presentation truth because the current Asset V2 family parser does not own a loop field.

## Source-work and inbox contract

New/unprocessed art:

```text
custodian/asset_drop/source_work/vehicles/custodian_field_scout_buggy_mk1/
<state_id>__<direction>_source.png
```

Examples:
```text
parked_01__n_source.png
drive_01__e_source.png
destroy_01__se_source.png
```

Normalized intake:

```text
custodian/asset_drop/inbox/custodian_field_scout_buggy_mk1/
<state_id>__<direction>.png
```

Examples:
```text
parked_01__n.png
drive_01__e.png
destroy_01__se.png
```

Required authored directions for every directional state are `n, ne, e, se, s`. Generate the exact request from the registered family with `asset request custodian_field_scout_buggy_mk1`; never invent canonical runtime filenames.

## Current compatibility art

Current `hover_buggy_idle_frames.tres` proves these legacy cadences:
- `idle`: 1 frame;
- `idle_start`: 7 frames at 8 FPS;
- `idle_loop`: 6 authored frames expanded into a ping-pong loop at 5.5 FPS;
- `move`: the legacy resource currently plays five sliced frames at 8 FPS even though the modern inbox grammar describes a six-frame strip.

This is migration evidence, not the wheeled class art contract.

## Known live defects and deferred presentation work

Lifecycle V1 closes the occupied-disable/destruction/teardown stranding path, centralizes the production damage-to-zero transition in `PilotableVehicle`, consolidates PlayerController ownership and group discovery, and removes the unused parallel `VehicleBase` behavior. The class recovery now supplies semantic Scout identity, data-owned durability, and wreck-first world spawning. Remaining presentation/pipeline work is deferred to the Asset V2 vehicle-family slice:

- The Field Scout scene still consumes explicitly named compatibility hover-buggy art.
- `update_vehicle_runtime_resources.gd` is hard-coded to `hover_buggy`.
- Required-assets entries still target nonexistent `light_buggy/runtime` paths while compatibility art is under `hover_buggy/runtime`.
- Older vehicle docs contain superseded paths/claims.

## Implementation series

1. `vehicle-runtime-lifecycle-hardening-v1` - complete/reviewed shared lifecycle correctness and legacy-path disposition.
2. `vehicle-wreck-restoration-foundation-v1` + correction/re-review - generic world-spawn wreckage and held restoration lifecycle.
3. `vehicle-diagnosis-knowledge-v1` - vehicle scanning, domain knowledge, and pattern evidence.
4. `vehicle-part-fabrication-recovery-v1` - R0 direct-material exception plus R1+ fabricated assembly recovery.
5. `vehicle-field-scout-buggy-class-v1-recovery-1` - semantic Scout class is landed/reviewed; review R0-01 requires the existing component-recovery correction after slice 4 review.
6. `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1` - migrate the landed Scout profile/smoke to reviewed R1 component recovery.
7. `vehicle-field-scout-buggy-asset-v2` - Asset V2 family plus wreck/restoration presentation and family-driven vehicle post-processing.
8. `vehicle-recovery-presentation-manifests-v1` - shared diagnostic/install FX and replacement-component UI/prop family contracts.

Each implementation slice receives paired fresh-context review before its successor is eligible.

## Deferred

Actual `light_scanner` gameplay, weapons, passengers, cargo, fuel, broader repair economy/balance, collision damage, boost, multiplayer authority, save/load persistence across world reconstruction, production PNG creation, human art-direction approval, and additional chassis classes.
