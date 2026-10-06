# Custodian Field Scout Buggy Mk I

**Status:** active implementation design  
**Parent authority:** `design/02_features/vehicles/VEHICLES.md`  
**Implementation series:** lifecycle hardening -> class implementation -> Asset V2 vehicle-family foundation  
**Reviewed main:** `ad2868d66a`

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
| Interaction | PILOTABLE |
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
| Repair/fuel | deferred |

The existing registry ID is preserved to avoid identity churn. The production scene should become semantically named for this class. Compatibility aliases may exist only while a live consumer still needs them.

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

`custodian/game/actors/vehicles/light_buggy.tscn` is a migration name, not the permanent class identity. Remove it after live consumers move, or retain it only as an explicit compatibility alias with an exit condition.

A stale constant in-world health bar is not acceptable. Bind it to authoritative vehicle health through an existing presentation seam if one exists; otherwise remove the orphan presentation rather than creating a second health authority.

## Lifecycle invariants

1. The Operator can never remain hidden, collision-disabled, or process-disabled after vehicle ownership ends.
2. `PilotableVehicle` owns pilot occupancy and vehicle lifecycle state. `PlayerController` owns input/camera routing, not duplicate occupancy truth.
3. Disable/destruction while occupied uses the same pilot-release authority as an ordinary exit, with safe placement semantics and a fail-safe fallback that cannot strand the Operator.
4. Vehicle destruction cannot leave PlayerController targeting a dead/disabled vehicle.
5. Nearby discovery returns each vehicle once even if compatibility groups overlap.
6. A zero-health vehicle cannot be entered or driven.
7. Current safe-exit collision/navigation behavior remains intact.

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

## Known live defects this series closes

- `PilotableVehicle.disable_vehicle()` can strand an occupied pilot by switching to DISABLED before pilot restoration.
- The production destruction callback path is not owned end-to-end by `PilotableVehicle`.
- PlayerController keeps duplicate vehicle references and overlapping-group discovery.
- Old `VehicleBase` behavior survives as compatibility/history residue.
- WHEELED/Scout taxonomy points at hover-buggy presentation.
- `update_vehicle_runtime_resources.gd` is hard-coded to `hover_buggy`.
- Required-assets entries target nonexistent `light_buggy/runtime` paths while live compatibility art is under `hover_buggy/runtime`.
- Older vehicle docs contain superseded paths/claims.

## Implementation series

1. `vehicle-runtime-lifecycle-hardening-v1` - shared lifecycle correctness and legacy-path disposition.
2. `vehicle-field-scout-buggy-class-v1` - concrete class data, durability, semantic scene, live integration.
3. `vehicle-field-scout-buggy-asset-v2` - Asset V2 family plus family-driven vehicle post-processing and tracker repair.

Each implementation slice receives paired fresh-context review before its successor is eligible.

## Deferred

Actual `light_scanner` gameplay, weapons, passengers, cargo, fuel, repair economy, collision damage, boost, multiplayer authority, production PNG creation, human art-direction approval, and additional chassis classes.
