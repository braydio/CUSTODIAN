# Vehicle Registry + Pilotable Vehicle System — Implementation Tracking

**Status:** in_progress  
**Priority:** high — first pilotable vehicle moving into production  
**Persistent design doc:** `design/VEHICLES_REVIEW.md`  
**Requires:** Godot 4.x, existing player controller, existing terrain surface multiplier for `actor_kind == "vehicle"`

---

## 1. Purpose

Scalable **Vehicle Registry System** supporting `Faction -> Domain -> Chassis -> Role -> Variant -> Loadout`, shipping the first production pilotable vehicle without one-off controller hacks.

### Acceptance Criteria

- Registry loads without errors
- First production vehicle exists in `vehicle_archetypes.json`
- Vehicle spawnable from registry ID
- Operator can enter/exit with Interact
- While piloted, movement input controls vehicle; while unpiloted, controls Operator
- Vehicle uses `actor_kind = "vehicle"` for terrain movement multiplier
- Missing optional InputMap actions don't crash
- Unsupported domains valid in data but refuse spawn unless `allow_placeholder_spawn == true`
- Display name generated from classification fields
- Registry queryable by faction/domain/chassis/role/tier

---

## 2. Principle

Register by classification, not hand-authored name.

**Bad:** `heavy_tank_mk2_fast`, `player_car_blue`

**Good:**
```json
{
  "id": "raider_ground_buggy_scout_light",
  "faction": "RAIDER", "domain": "GROUND", "chassis": "BUGGY",
  "role": "SCOUT", "tier": "LIGHT", "variant": "MK1",
  "loadout": "UTILITY_LIGHT", "mobility": ["WHEELED"],
  "traits": ["FAST", "JURYRIGGED", "SALVAGED"]
}
```
Display name generated: `"Raider Light Scout Buggy"`
Behavior resolved from: `domain + mobility + chassis + role + loadout + traits`

---

## 3. Taxonomy

### Domains

| Domain | Runtime Support |
|---|---|
| `GROUND` | ✅ supported now |
| `HOVER` | ✅ allowed in data, basic support if already present |
| `STATIC` | ✅ non-pilotable platform |
| `AIR`, `SEA`, `SPACE`, `SUBTERRANEAN`, `AMPHIBIOUS`, `ORBITAL` | 📝 registry-valid, `VehicleSpawnResolver` refuses spawn unless `allow_placeholder_spawn == true` |

### Chassis
```
BUGGY, BIKE, TRIKE, QUAD, SEDAN, VAN, TRUCK, TRACTOR, CRAWLER, TANK, APC,
MECH, WALKER, HAULER, RIG, TRAIN, DRONE, ROTOR, JET, GLIDER, BOMBER, LIFTER,
TRANSPORT, INTERCEPTOR, GUNSHIP, SKIFF, BOAT, CUTTER, BARGE, SUB, DESTROYER,
CARRIER, DREDGER, SHUTTLE, FREIGHTER, CORVETTE, FRIGATE, CRUISER, BATTLESHIP,
MINER, SCOUT, WRECK, TURRET_BASE
```

### Roles
```
SCOUT, PATROL, RECON, TRANSPORT, HAULER, MINER, SALVAGER, REPAIR, SUPPORT,
COMMAND, ASSAULT, SIEGE, DEFENSE, ARTILLERY, BREACHER, INTERCEPTOR, ESCORT,
COLONIZER, EXPLORER, HARVESTER, RECOVERY, CONSTRUCTION, SURVEYOR, MEDICAL,
FUEL, COVER, HAZARD, OBJECTIVE
```

### Tiers
```
MICRO, LIGHT, MEDIUM, HEAVY, SUPERHEAVY, MASSIVE, RELIC
```

### Mobility Tags
```
TRACKED, WHEELED, LEGGED, HOVER, VTOL, JET, SAIL, SUBMERSIBLE, MAGLEV, WARP
```

### Quality/Condition Tags
```
DAMAGED, RUSTED, FIELD_REPAIRED, MILITARY_SURPLUS, PRISTINE, MODIFIED,
ARMORED, OVERCLOCKED, JURYRIGGED, SALVAGED, ANCIENT, EXPERIMENTAL, PROTOTYPE
```

### Interaction Modes
```
NONE, COVER_ONLY, HAZARD, OBJECTIVE, ENTERABLE, PILOTABLE, SUMMONED,
DEPLOYABLE, WRECKAGE, ENEMY_PLATFORM
```

First production vehicle uses `interaction_mode: PILOTABLE`.

---

## 4. Files

### Runtime
```
custodian/game/vehicles/
├── vehicle_definition.gd          # Single archetype loader + validator
├── vehicle_registry.gd            # Registry store + queries
├── vehicle_controller.gd          # Input routing + state machine
├── pilotable_vehicle.gd           # PilotableVehicle base (extends CharacterBody2D)
├── vehicle_seat.gd                # Seat/entry/exit logic
├── vehicle_input_adapter.gd       # PlayerController → vehicle intent bridge
├── vehicle_spawn_resolver.gd      # Definition → live scene
├── vehicle_debug_overlay.gd       # Debug display
└── scenes/
    └── pilotable_vehicle_base.tscn
```

### Content data
```
custodian/content/vehicles/
├── vehicle_taxonomy.json          # Valid enum values
├── vehicle_archetypes.json        # Vehicle definitions
├── vehicle_movement_profiles.json # Movement configs
├── vehicle_hardpoint_profiles.json
├── vehicle_loadouts.json
├── vehicle_visual_kits.json
└── vehicle_registry_schema.json
```

### Validation
```
custodian/tools/validate_vehicle_registry.gd
```

---

## 5. Data Schema

### vehicle_archetypes.json

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

Replace `custodian_ground_buggy_scout_light` with the actual production vehicle ID if a scene already exists.

### vehicle_movement_profiles.json

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

### vehicle_hardpoint_profiles.json

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

### vehicle_loadouts.json

```json
{
  "schema_version": 1,
  "loadouts": {
    "none": { "items": [] },
    "scout_sensor_light": {
      "items": [{"hardpoint": "rear_utility", "equipment": "light_scanner"}]
    }
  }
}
```

Hardpoints exist in data now. Mounted equipment can be no-op placeholders. Do not bake weapons into vehicle identity.

---

## 6. Core Classes

### VehicleDefinition.gd

```gdscript
class_name VehicleDefinition extends RefCounted

var id, faction, domain, chassis, role, tier, variant: String
var interaction_mode: String
var mobility: Array[String]
var tags: Array[String]
var movement_profile, hardpoint_profile, loadout, visual_kit: String
var runtime_scene: String
var spawnable, pilotable: bool
var footprint, seat_profile: Dictionary

static func from_dict(data: Dictionary) -> VehicleDefinition
func validate() -> PackedStringArray
func get_display_name() -> String
func is_pilotable() -> bool
func is_runtime_supported() -> bool
func has_tag(tag: String) -> bool
func has_mobility(mobility_tag: String) -> bool
```

### VehicleRegistry.gd

Autoload or manager node attached to active gameplay scene (consistent with project patterns).

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

### VehicleSpawnResolver.gd

```gdscript
func spawn_vehicle(vehicle_id: String, parent: Node, global_position: Vector2) -> Node2D
func spawn_definition(definition: VehicleDefinition, parent: Node, global_position: Vector2) -> Node2D
```

Spawn rules:
1. Look up definition → validate → check `runtime.scene` → instantiate
2. If scene has `apply_vehicle_definition()`, call it
3. Set position, add to parent
4. Add to groups `vehicles` and (if pilotable) `pilotable_vehicles`

### PilotableVehicle.gd

```gdscript
class_name PilotableVehicle extends CharacterBody2D

enum ControlState { UNOCCUPIED, ENTERING, PILOTED, EXITING, DISABLED }

var vehicle_definition: VehicleDefinition
var control_state := ControlState.UNOCCUPIED
var pilot: Node = null
var movement_profile: Dictionary = {}
var current_speed := 0.0
var facing_direction := Vector2.DOWN

func apply_vehicle_definition(definition: VehicleDefinition) -> void
func can_enter(actor: Node) -> bool
func enter_vehicle(actor: Node) -> bool
func exit_vehicle() -> bool
func route_vehicle_input(input_vector: Vector2, actions: Dictionary, delta: float) -> void
func disable_vehicle(reason: String = "") -> void
func is_piloted() -> bool
```

Expected node layout:
```
PilotableVehicle
├── CollisionShape2D
├── Sprite2D or AnimatedSprite2D
├── EntryArea2D
│   └── CollisionShape2D
├── DriverSeat
└── ExitMarker
```

Behavior:
- Unoccupied: no input consumed
- Entered: Operator visual/control hidden (not deleted), camera follows vehicle
- PlayerController routes input to vehicle
- Exit places Operator at valid nearby ExitMarker; if blocked, search nearby; if none valid, deny exit + warning

---

## 7. Input Routing

**Rule:** `PlayerController` owns input intent. `PilotableVehicle` owns movement response. Vehicle must not call `Input.is_action_pressed()` directly except for temp debugging.

```gdscript
var controlled_vehicle: PilotableVehicle = null

func _physics_process(delta: float) -> void:
    if controlled_vehicle != null:
        _route_vehicle_input(delta)
        return
    _route_operator_input(delta)

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

Guard all non-existent InputMap actions with `InputMap.has_action()`.

---

## 8. Movement Model

- Input vector → desired travel direction
- Accelerate toward target velocity; decelerate when no input
- Facing follows velocity when velocity.length > threshold
- Road tiles use existing terrain surface multiplier for `actor_kind = "vehicle"`
- Off-road penalty from movement profile if no terrain multiplier exists
- No drifting, fuel, suspension, gearboxes, damage, wheel health, or mounted weapons in first pass

---

## 9. Enter / Exit Contract

### Enter
1. Operator within EntryArea2D, vehicle pilotable, not disabled, no existing pilot
2. Store pilot, disable pilot collision + visible body
3. Set `PlayerController.controlled_vehicle`, camera follows vehicle
4. State → `PILOTED`

### Exit
1. Find position from ExitMarker, validate
2. Move Operator to exit position, re-enable collision + visibility
3. Clear `controlled_vehicle`, restore camera to Operator
4. State → `UNOCCUPIED`

Camera API needed (if not present):
```gdscript
func set_follow_target(target: Node2D) -> void
```

---

## 10. Validation

`custodian/tools/validate_vehicle_registry.gd` — checks:
- Duplicate IDs
- Missing required fields
- Invalid domain/chassis/role/tier values
- Missing `runtime.scene` for spawnable vehicles
- Pilotable vehicle without `seat_profile` or `movement_profile`
- Hardpoint/movement profile reference missing
- Unsupported domain marked spawnable without `allow_placeholder_spawn`

```bash
cd custodian && godot --headless --path . --script res://tools/validate_vehicle_registry.gd
```

Create even if headless layout not yet supported; document manual run steps.

---

## 11. Documentation Updates

Update:
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`

Add vehicle registry path, pilotable vehicle path, spawn resolver path, first production vehicle scene path.

Set design doc status to `complete` after validation passes.

---

## 12. Implementation Order

1. Create data JSON files + schema
2. `VehicleDefinition.gd` — loader/validator
3. `VehicleRegistry.gd` — store + queries
4. `vehicle_movement_profiles.json` + movement model in `PilotableVehicle.gd`
5. `PilotableVehicle.gd` + `pilotable_vehicle_base.tscn`
6. PlayerController input routing (`_route_vehicle_input`)
7. Enter/exit (`VehicleSeat.gd` + EntryArea2D)
8. Camera follow target switching
9. `VehicleSpawnResolver.gd`
10. Wire up first production vehicle in archetypes
11. `validate_vehicle_registry.gd`
12. Documentation updates
