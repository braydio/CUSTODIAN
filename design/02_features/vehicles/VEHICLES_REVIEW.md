# Vehicle Registry + Pilotable Vehicle System — Persistent Design Doc

**Status:** persistent / canonical design document  
**Implementation tracked in:** `design/20_features/in_progress/VEHICLE_REGISTRY_AND_PILOTING_SYSTEM.md`  
**Last Updated:** 2026-05-27

This is the authoritative, persistent design specification for the Vehicle Registry and Pilotable Vehicle system. Implementation progress, code references, and runtime tracking live in the `20_features/in_progress/` companion document.

---

You’re right: with **one pilotable vehicle already moving into production**, the original classification registry should not be treated as “future scope.” It should become the backbone now. The correction is not “make it smaller”; it is **make it production-safe around the first pilotable vehicle while keeping the taxonomy expandable**.

Below is a Codex-ready implementation design.

---

# Codex Implementation Design: Vehicle Registry + Pilotable Vehicle Integration

## Target Files

Create:

```text
design/20_features/in_progress/VEHICLE_REGISTRY_AND_PILOTING_SYSTEM.md
```

Optional implementation proposal file, to satisfy the older implementation-doc convention:

```text
design/features/implementation/VEHICLE_REGISTRY_AND_PILOTING_SYSTEM_CODE.md
```

Documentation drift note: `AGENTS.md` currently says new Godot implementation specs live under `design/20_features/in_progress/`, but later says required feature implementation docs should live under `design/features/implementation/`. To avoid conflict, create the main design spec in `design/20_features/in_progress/` and put exact copy-paste implementation notes in `design/features/implementation/`. Later, update `AGENTS.md` to clarify whether `design/features/implementation/` is still required for Codex or only for non-Codex agents.

---

# 1. Purpose

Implement a scalable **Vehicle Registry System** for CUSTODIAN that supports:

```text
Faction -> Domain -> Chassis -> Role -> Variant -> Loadout
```

while also shipping the first **production pilotable vehicle** without turning the game into a one-off vehicle controller mess.

The registry must support:

```text
CIVILIAN.GROUND.TRUCK.HAULER.MK2
MILITARY.AIR.ROTOR.GUNSHIP.HEAVY
SALVAGER.SEA.BARGE.RECOVERY.LIGHT
RAIDER.GROUND.BUGGY.SCOUT.LIGHT
CUSTODIAN.GROUND.WALKER.SIEGE.RELIC
```

The system should not kneecap the taxonomy. It should preserve broad domains, chassis, role tags, quality tags, mobility tags, and loadouts, but implement runtime behavior only for the domains currently supported by the game.

The first production requirement is:

> A pilotable vehicle must be definable through data, spawnable in Godot, enterable/exitable by the Operator, controllable through existing player input routing, and able to participate in map traversal without hardcoding its identity into the player controller.

---

# 2. Existing Context / Constraints

Active runtime is Godot 4.x under `custodian/`. Godot-native implementation specs are expected under `./design/`. Runtime architecture changes should also update `custodian/docs/ai_context/CURRENT_STATE.md`, and preferably `CONTEXT.md` / `FILE_INDEX.md` if file ownership changes.

There is already terrain/procgen support that distinguishes vehicle movement from operator movement via `actor_kind == "vehicle"` in road movement multiplier logic, so the vehicle system should plug into that instead of inventing a separate road-speed layer.

Keep fixed-step/deterministic gameplay separation intact: simulation logic should not live inside rendering/UI, and data validation should be explicit.

---

# 3. Design Principle

Do **not** register vehicles by unique hand-authored names.

Bad:

```text
heavy_tank_mk2_fast
desert_hammer_x92
player_car_blue
```

Good:

```json
{
  "id": "raider_ground_buggy_scout_light",
  "faction": "RAIDER",
  "domain": "GROUND",
  "chassis": "BUGGY",
  "role": "SCOUT",
  "tier": "LIGHT",
  "variant": "MK1",
  "loadout": "UTILITY_LIGHT",
  "mobility": ["WHEELED"],
  "traits": ["FAST", "JURYRIGGED", "SALVAGED"]
}
```

The display name is generated:

```text
Raider Light Scout Buggy
```

The gameplay behavior is resolved from data:

```text
domain + mobility_profile + chassis_profile + role_profile + loadout_profile + traits
```

---

# 4. Runtime Architecture

Create this runtime structure:

```text
custodian/game/vehicles/
├── vehicle_definition.gd
├── vehicle_registry.gd
├── vehicle_controller.gd
├── pilotable_vehicle.gd
├── vehicle_seat.gd
├── vehicle_input_adapter.gd
├── vehicle_spawn_resolver.gd
└── vehicle_debug_overlay.gd
```

Create this content structure:

```text
custodian/content/vehicles/
├── vehicle_taxonomy.json
├── vehicle_archetypes.json
├── vehicle_movement_profiles.json
├── vehicle_hardpoint_profiles.json
├── vehicle_loadouts.json
├── vehicle_visual_kits.json
└── vehicle_registry_schema.json
```

Create this first production scene folder:

```text
custodian/game/vehicles/scenes/
└── pilotable_vehicle_base.tscn
```

If the existing production vehicle scene already exists elsewhere, do not move it blindly. Instead, adapt it to use `PilotableVehicle.gd` and document the path in `custodian/docs/ai_context/FILE_INDEX.md`.

---

# 5. Taxonomy

Preserve the broad registry taxonomy.

## Domains

```text
GROUND
AIR
SEA
SPACE
SUBTERRANEAN
AMPHIBIOUS
HOVER
ORBITAL
STATIC
```

Runtime support status:

```text
GROUND        supported now
HOVER         allowed in data, basic support if already present
STATIC        supported as non-pilotable vehicle-like platform
AIR           registry-valid, not fully runtime-supported yet
SEA           registry-valid, not runtime-supported yet
SPACE         registry-valid, not runtime-supported yet
SUBTERRANEAN  registry-valid, not runtime-supported yet
AMPHIBIOUS    registry-valid, not runtime-supported yet
ORBITAL       registry-valid, not runtime-supported yet
```

Important: Unsupported does not mean invalid. The registry can define them, but `VehicleSpawnResolver` must refuse to spawn unsupported runtime domains unless `allow_placeholder_spawn == true`.

## Chassis

Keep broad chassis classes:

```text
BUGGY
BIKE
TRIKE
QUAD
SEDAN
VAN
TRUCK
TRACTOR
CRAWLER
TANK
APC
MECH
WALKER
HAULER
RIG
TRAIN
DRONE
ROTOR
JET
GLIDER
BOMBER
LIFTER
TRANSPORT
INTERCEPTOR
GUNSHIP
SKIFF
BOAT
CUTTER
BARGE
SUB
DESTROYER
CARRIER
DREDGER
SHUTTLE
FREIGHTER
CORVETTE
FRIGATE
CRUISER
BATTLESHIP
MINER
SCOUT
WRECK
TURRET_BASE
```

## Roles

```text
SCOUT
PATROL
RECON
TRANSPORT
HAULER
MINER
SALVAGER
REPAIR
SUPPORT
COMMAND
ASSAULT
SIEGE
DEFENSE
ARTILLERY
BREACHER
INTERCEPTOR
ESCORT
COLONIZER
EXPLORER
HARVESTER
RECOVERY
CONSTRUCTION
SURVEYOR
MEDICAL
FUEL
COVER
HAZARD
OBJECTIVE
```

## Tiers

```text
MICRO
LIGHT
MEDIUM
HEAVY
SUPERHEAVY
MASSIVE
RELIC
```

`RELIC` is CUSTODIAN-flavored, not a replacement for the original tiering.

## Mobility Tags

```text
TRACKED
WHEELED
LEGGED
HOVER
VTOL
JET
SAIL
SUBMERSIBLE
MAGLEV
WARP
```

## Quality / Condition Tags

```text
DAMAGED
RUSTED
FIELD_REPAIRED
MILITARY_SURPLUS
PRISTINE
MODIFIED
ARMORED
OVERCLOCKED
JURYRIGGED
SALVAGED
ANCIENT
EXPERIMENTAL
PROTOTYPE
```

## Interaction Modes

Add this. It is essential for CUSTODIAN.

```text
NONE
COVER_ONLY
HAZARD
OBJECTIVE
ENTERABLE
PILOTABLE
SUMMONED
DEPLOYABLE
WRECKAGE
ENEMY_PLATFORM
```

The first production vehicle must use:

```text
interaction_mode: PILOTABLE
```

---

# 6. Data Schema

Create `custodian/content/vehicles/vehicle_archetypes.json`:

```json
{
  "schema_version": 1,
  "vehicles": {
    "custodian_ground_buggy_scout_light": {
      "id": "custodian_ground_buggy_scout_light",
      "display_name_template": "{faction} {tier} {role} {chassis}",

      "faction": "CUSTODIAN",
      "domain": "GROUND",
      "chassis": "BUGGY",
      "role": "SCOUT",
      "tier": "LIGHT",
      "variant": "MK1",

      "interaction_mode": "PILOTABLE",

      "mobility": ["WHEELED"],
      "tags": ["INDUSTRIAL", "FIELD_REPAIRED", "MILSPEC"],

      "movement_profile": "ground_wheeled_light",
      "hardpoint_profile": "utility_light",
      "loadout": "none",
      "visual_kit": "custodian_industrial_light",

      "seat_profile": {
        "driver_seats": 1,
        "passenger_seats": 0,
        "entry_radius": 32,
        "entry_anchor": "LEFT_SIDE",
        "exit_anchor": "RIGHT_SIDE"
      },

      "footprint": {
        "cells": [2, 1],
        "anchor": "BOTTOM_CENTER",
        "blocks_movement": true,
        "blocks_projectiles": false,
        "cover_profile": "LIGHT"
      },

      "runtime": {
        "scene": "res://game/vehicles/scenes/pilotable_vehicle_base.tscn",
        "spawnable": true,
        "pilotable": true,
        "requires_runtime_support": ["GROUND", "WHEELED"]
      }
    }
  }
}
```

Codex must replace `custodian_ground_buggy_scout_light` with the real production vehicle ID if the actual scene/data already exists.

---

# 7. Core Classes

## `VehicleDefinition.gd`

Responsibility:

```text
Load one vehicle archetype.
Validate fields.
Expose typed helpers.
Generate display name.
Resolve unsupported runtime capabilities.
```

Required properties:

```gdscript
class_name VehicleDefinition
extends RefCounted

var id: String
var faction: String
var domain: String
var chassis: String
var role: String
var tier: String
var variant: String
var interaction_mode: String
var mobility: Array[String]
var tags: Array[String]
var movement_profile: String
var hardpoint_profile: String
var loadout: String
var visual_kit: String
var runtime_scene: String
var spawnable: bool
var pilotable: bool
var footprint: Dictionary
var seat_profile: Dictionary
```

Required methods:

```gdscript
static func from_dict(data: Dictionary) -> VehicleDefinition
func validate() -> PackedStringArray
func get_display_name() -> String
func is_pilotable() -> bool
func is_runtime_supported() -> bool
func has_tag(tag: String) -> bool
func has_mobility(mobility_tag: String) -> bool
```

## `VehicleRegistry.gd`

Responsibility:

```text
Load all vehicle JSON.
Store definitions by ID.
Provide classification/tag queries.
Prevent duplicate IDs.
```

Make it an autoload only if the project already uses autoloads for registries. Otherwise, attach it to a manager node in the active gameplay scene.

Required methods:

```gdscript
func load_registry(path := "res://content/vehicles/vehicle_archetypes.json") -> void
func get_vehicle(id: String) -> VehicleDefinition
func has_vehicle(id: String) -> bool
func get_all_ids() -> PackedStringArray
func find_by_role(role: String) -> Array[VehicleDefinition]
func find_by_chassis(chassis: String) -> Array[VehicleDefinition]
func find_by_domain(domain: String) -> Array[VehicleDefinition]
func find_pilotable() -> Array[VehicleDefinition]
```

## `VehicleSpawnResolver.gd`

Responsibility:

```text
Turn a VehicleDefinition into a live scene instance.
Reject unsupported runtime domains unless explicitly allowed.
Apply movement profile, hardpoints, seat config, and visual kit.
```

Required methods:

```gdscript
func spawn_vehicle(vehicle_id: String, parent: Node, global_position: Vector2) -> Node2D
func spawn_definition(definition: VehicleDefinition, parent: Node, global_position: Vector2) -> Node2D
```

Spawn rules:

```text
1. Look up definition.
2. Validate definition.
3. Check runtime.scene.
4. Instantiate scene.
5. If scene has `apply_vehicle_definition`, call it.
6. Set global_position.
7. Add to parent.
8. Add to group `vehicles`.
9. If pilotable, add to group `pilotable_vehicles`.
```

---

# 8. Pilotable Vehicle Runtime

## `PilotableVehicle.gd`

Base class:

```gdscript
class_name PilotableVehicle
extends CharacterBody2D
```

Required node expectations:

```text
PilotableVehicle
├── CollisionShape2D
├── Sprite2D or AnimatedSprite2D
├── EntryArea2D
│   └── CollisionShape2D
├── DriverSeat
└── ExitMarker
```

Required state:

```gdscript
enum ControlState {
    UNOCCUPIED,
    ENTERING,
    PILOTED,
    EXITING,
    DISABLED
}

var vehicle_definition: VehicleDefinition
var control_state := ControlState.UNOCCUPIED
var pilot: Node = null
var movement_profile: Dictionary = {}
var current_speed := 0.0
var facing_direction := Vector2.DOWN
```

Required API:

```gdscript
func apply_vehicle_definition(definition: VehicleDefinition) -> void
func can_enter(actor: Node) -> bool
func enter_vehicle(actor: Node) -> bool
func exit_vehicle() -> bool
func route_vehicle_input(input_vector: Vector2, actions: Dictionary, delta: float) -> void
func disable_vehicle(reason: String = "") -> void
func is_piloted() -> bool
```

Behavior:

```text
- When unoccupied, vehicle does not consume player movement input.
- When entered, Operator visual/control should be hidden or disabled, not deleted.
- Camera should follow vehicle while piloted.
- Player controller should route input to the vehicle.
- Exit should place Operator at a valid nearby exit marker.
- If exit location is blocked, search nearby valid positions.
- If no exit location is valid, deny exit and show/log warning.
```

---

# 9. Input Routing

Codex must inspect the existing player controller before editing. There was prior runtime evidence of `_route_vehicle_input` existing in `player_controller.gd`, so Codex should preserve that intent rather than creating parallel input plumbing.

Implementation rule:

```text
PlayerController owns input intent.
PilotableVehicle owns vehicle movement response.
```

Do not let `PilotableVehicle` call `Input.is_action_pressed()` directly except for temporary debugging. It should receive normalized intent from player/controller code.

Add or adapt:

```gdscript
var controlled_vehicle: PilotableVehicle = null
```

Player controller flow:

```gdscript
func _physics_process(delta: float) -> void:
    if controlled_vehicle != null:
        _route_vehicle_input(delta)
        return

    _route_operator_input(delta)
```

Vehicle route shape:

```gdscript
func _route_vehicle_input(delta: float) -> void:
    var input_vector := Vector2.ZERO

    input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    input_vector = input_vector.normalized()

    var actions := {
        "primary": Input.is_action_pressed("primary_attack"),
        "secondary": Input.is_action_pressed("secondary_attack"),
        "interact_pressed": Input.is_action_just_pressed("interact"),
        "brake": Input.is_action_pressed("brake") if InputMap.has_action("brake") else false,
        "exit_pressed": Input.is_action_just_pressed("interact")
    }

    controlled_vehicle.route_vehicle_input(input_vector, actions, delta)
```

Important: do not reference non-existent InputMap actions like `"fire"` unless Codex also adds them to project settings. Prefer existing action names or guard with `InputMap.has_action()`.

---

# 10. Movement Model

Use a simple production-safe movement profile first.

Create `vehicle_movement_profiles.json`:

```json
{
  "schema_version": 1,
  "profiles": {
    "ground_wheeled_light": {
      "domain": "GROUND",
      "mobility": ["WHEELED"],
      "max_speed": 175.0,
      "acceleration": 420.0,
      "deceleration": 520.0,
      "turn_response": 10.0,
      "reverse_multiplier": 0.45,
      "road_speed_multiplier_enabled": true,
      "offroad_speed_multiplier": 0.78,
      "collision_damage_enabled": false
    }
  }
}
```

Movement behavior:

```text
- Input vector controls desired travel direction.
- Vehicle accelerates toward target velocity.
- Vehicle decelerates when no input is held.
- Facing direction follows velocity when velocity length exceeds threshold.
- Road tiles may increase speed using existing terrain surface multiplier for actor_kind `"vehicle"`.
- Off-road penalty comes from movement profile if no terrain multiplier exists.
```

Do not add drifting, fuel, suspension, gearboxes, vehicle damage, wheel health, or mounted weapons in this first production pass unless the current vehicle already has them.

---

# 11. Enter / Exit Contract

Interaction rules:

```text
- Operator must be within vehicle EntryArea2D.
- Vehicle definition must be pilotable.
- Vehicle must not be disabled.
- Vehicle must not already have a pilot.
- Interact enters vehicle.
- Interact while piloting exits vehicle.
```

On enter:

```text
1. Store pilot node.
2. Disable pilot collision and visible body.
3. Parent does not need to change unless existing architecture requires it.
4. Set PlayerController.controlled_vehicle.
5. Set camera follow target to vehicle if camera supports it.
6. Set vehicle state to PILOTED.
```

On exit:

```text
1. Find exit position from ExitMarker.
2. Validate position.
3. Move Operator to exit position.
4. Re-enable Operator collision and visible body.
5. Clear PlayerController.controlled_vehicle.
6. Restore camera follow target to Operator.
7. Set vehicle state to UNOCCUPIED.
```

If camera target switching is not currently supported, Codex should add a small method to the camera controller, not hardcode camera access from the vehicle.

Suggested camera API:

```gdscript
func set_follow_target(target: Node2D) -> void
```

---

# 12. Hardpoints and Loadouts

Implement the data layer now, even if the first production vehicle has no weapon.

Hardpoint profile:

```json
{
  "schema_version": 1,
  "profiles": {
    "utility_light": {
      "hardpoints": [
        {
          "id": "front_light",
          "type": "FRONT_LIGHT",
          "socket_path": "Hardpoints/FrontLight",
          "allowed_families": ["LIGHT", "SCANNER", "UTILITY"]
        },
        {
          "id": "rear_utility",
          "type": "UTILITY",
          "socket_path": "Hardpoints/RearUtility",
          "allowed_families": ["CARGO", "REPAIR", "SCANNER"]
        }
      ]
    }
  }
}
```

Loadout profile:

```json
{
  "schema_version": 1,
  "loadouts": {
    "none": {
      "items": []
    },
    "scout_sensor_light": {
      "items": [
        {
          "hardpoint": "rear_utility",
          "equipment": "light_scanner"
        }
      ]
    }
  }
}
```

Implementation rule:

```text
Hardpoints exist in data now.
Mounted equipment can be no-op placeholders.
Do not bake weapons into vehicle identity.
```

---

# 13. First Production Vehicle Acceptance Criteria

Codex implementation is complete when:

```text
- The vehicle registry loads without errors.
- The first production pilotable vehicle exists in vehicle_archetypes.json.
- The vehicle can spawn from its registry ID.
- The Operator can enter it with interact.
- The Operator can exit it with interact.
- While piloted, movement input controls the vehicle instead of the Operator.
- While unpiloted, movement input controls the Operator.
- Vehicle movement uses `actor_kind = "vehicle"` when querying road/terrain movement multiplier.
- Missing optional InputMap actions do not crash the game.
- Unsupported domains are valid in registry data but cannot spawn unless explicitly allowed.
- Vehicle display name is generated from classification fields.
- The registry can query by faction/domain/chassis/role/tier.
```

---

# 14. Validation

Codex should add a validation script or editor-safe debug command:

```text
custodian/tools/validate_vehicle_registry.gd
```

Validation checks:

```text
- duplicate vehicle IDs
- missing required fields
- invalid domain/chassis/role/tier values
- missing runtime.scene for spawnable vehicles
- pilotable vehicle without seat_profile
- pilotable vehicle without movement_profile
- hardpoint_profile reference missing
- movement_profile reference missing
- unsupported runtime domain marked spawnable without placeholder permission
```

Minimum command:

```bash
cd custodian && godot --headless --path . --script res://tools/validate_vehicle_registry.gd
```

If the project does not currently support this headless script layout, Codex should still create the validator as a normal GDScript and document how to run it manually.

---

# 15. Documentation Updates

Codex must update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
```

Add:

```text
Vehicle registry added.
Pilotable vehicle path:
- registry data: res://content/vehicles/vehicle_archetypes.json
- runtime base: res://game/vehicles/pilotable_vehicle.gd
- spawn resolver: res://game/vehicles/vehicle_spawn_resolver.gd
- first production vehicle scene: <actual path>
```

Also update the design doc status:

```text
status: review
```

After implementation and validation:

```text
status: complete
```

---

# 16. Codex Prompt

Use this with Codex:

```text
Implement the CUSTODIAN Vehicle Registry + Pilotable Vehicle system from:

design/20_features/in_progress/VEHICLE_REGISTRY_AND_PILOTING_SYSTEM.md

Requirements:
- Preserve the scalable classification taxonomy: faction, domain, chassis, role, tier, variant, loadout, mobility, tags.
- Do not reduce the taxonomy to only current runtime domains.
- Implement runtime support for the first production pilotable GROUND vehicle.
- Add registry data under custodian/content/vehicles/.
- Add runtime scripts under custodian/game/vehicles/.
- Integrate with the existing player controller input routing; do not create a second competing player input system.
- Guard all optional InputMap actions with InputMap.has_action().
- Route player intent into PilotableVehicle.route_vehicle_input() instead of reading raw Input directly inside vehicle movement code.
- Use existing terrain/procgen road multiplier logic with actor_kind = "vehicle" where available.
- Add a registry validator.
- Update custodian/docs/ai_context/CURRENT_STATE.md and FILE_INDEX.md.
- Do not silently move existing production vehicle art or scenes. Adapt the existing scene if found; otherwise create pilotable_vehicle_base.tscn as a reusable base.
- Run validation. If Godot cannot run headless, report the exact failure and leave manual validation steps.
```

---

## Bottom line

The original registry review should be treated as **the correct long-term content architecture**. The only adjustment is that CUSTODIAN now needs a real production seam:

```text
classification data -> vehicle definition -> spawn resolver -> pilotable runtime -> player input routing
```

That lets your first pilotable vehicle ship without becoming a special-case object, while still leaving room for trucks, walkers, crawlers, drones, gunships, barges, relic machines, wrecks, and faction variants later.
