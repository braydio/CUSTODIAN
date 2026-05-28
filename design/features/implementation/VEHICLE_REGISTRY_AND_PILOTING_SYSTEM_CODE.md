# Vehicle Registry + Pilotable Vehicle — Implementation Notes

**Source spec:** `design/20_features/in_progress/VEHICLE_REGISTRY_AND_PILOTING_SYSTEM.md`
**Status:** review → complete (update after validation)

---

## Files to Create

### Runtime (`custodian/game/vehicles/`)
- `vehicle_definition.gd` — `class_name VehicleDefinition extends RefCounted`
- `vehicle_registry.gd` — autoload or manager node
- `vehicle_controller.gd` — input routing + state machine
- `pilotable_vehicle.gd` — `class_name PilotableVehicle extends CharacterBody2D`
- `vehicle_seat.gd` — enter/exit logic
- `vehicle_input_adapter.gd` — PlayerController → vehicle intent bridge
- `vehicle_spawn_resolver.gd` — Definition → scene
- `vehicle_debug_overlay.gd`
- `scenes/pilotable_vehicle_base.tscn`

### Content data (`custodian/content/vehicles/`)
- `vehicle_taxonomy.json` — valid enums
- `vehicle_archetypes.json` — definitions
- `vehicle_movement_profiles.json`
- `vehicle_hardpoint_profiles.json`
- `vehicle_loadouts.json`
- `vehicle_visual_kits.json`
- `vehicle_registry_schema.json`

### Tools
- `custodian/tools/validate_vehicle_registry.gd`

---

## VehicleDefinition.gd

```gdscript
class_name VehicleDefinition extends RefCounted

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

static func from_dict(data: Dictionary) -> VehicleDefinition
func validate() -> PackedStringArray       # returns error strings, empty = valid
func get_display_name() -> String           # "{faction} {tier} {role} {chassis}"
func is_pilotable() -> bool
func is_runtime_supported() -> bool
func has_tag(tag: String) -> bool
func has_mobility(mobility_tag: String) -> bool
```

## VehicleRegistry.gd

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

## PilotableVehicle.gd

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

Expected node tree:
```
PilotableVehicle
├── CollisionShape2D
├── Sprite2D or AnimatedSprite2D
├── EntryArea2D
│   └── CollisionShape2D
├── DriverSeat
└── ExitMarker
```

## VehicleSpawnResolver.gd

```gdscript
func spawn_vehicle(vehicle_id: String, parent: Node, global_position: Vector2) -> Node2D
func spawn_definition(definition: VehicleDefinition, parent: Node, global_position: Vector2) -> Node2D
```

Spawn flow:
1. Lookup definition → `validate()` → if errors, push_warning and return null
2. Check `runtime.scene` path — if empty/not loaded, error
3. Instantiate scene
4. If instance has `apply_vehicle_definition`, call it
5. `node.global_position = global_position`
6. `parent.add_child(node)`
7. `node.add_to_group("vehicles")`
8. If `definition.pilotable`, `node.add_to_group("pilotable_vehicles")`

---

## Input Routing

Add to PlayerController:

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

**Rule:** PilotableVehicle must NOT call `Input.is_action_pressed()` directly (except temp debug). It receives normalized intent.

Guard all non-existent actions with `InputMap.has_action()`.

---

## Enter / Exit

### Enter
1. Operator in EntryArea2D, vehicle pilotable, not disabled, no pilot
2. `pilot = operator`, disable pilot collision + hide visible body
3. `PlayerController.controlled_vehicle = self`
4. Camera: `set_follow_target(self)`
5. `control_state = PILOTED`

### Exit
1. Get global position of ExitMarker
2. Validate (not inside wall, not overlapping hazard)
3. Move operator to exit position
4. Re-enable operator collision + visible body
5. `PlayerController.controlled_vehicle = null`
6. Camera: `set_follow_target(operator)`
7. `control_state = UNOCCUPIED`

If exit blocked: search nearby valid tiles. If none found, deny exit + push_warning.

Camera API (add if missing):
```gdscript
func set_follow_target(target: Node2D) -> void
```

---

## Validation Tool

`custodian/tools/validate_vehicle_registry.gd` checks:
- Duplicate IDs
- Missing required fields
- Invalid enum values (domain/chassis/role/tier)
- Spawnable vehicles missing `runtime.scene`
- Pilotable vehicles missing `seat_profile` or `movement_profile`
- Profile references that don't exist in loaded data
- Unsupported domain + spawnable without `allow_placeholder_spawn`

Run:
```bash
cd custodian && godot --headless --path . --script res://tools/validate_vehicle_registry.gd
```

---

## First Production Vehicle

Acceptance:
- [ ] Registry loads without errors
- [ ] Vehicle exists in `vehicle_archetypes.json`
- [ ] Spawnable from registry ID
- [ ] Operator enters/exits with Interact
- [ ] Movement input controls vehicle when piloted, Operator when not
- [ ] Uses `actor_kind = "vehicle"` for terrain multiplier
- [ ] Missing optional InputMap actions don't crash
- [ ] Unsupported domains valid in data, refuse spawn
- [ ] Display name generated from fields
- [ ] Registry queryable by faction/domain/chassis/role/tier

---

## Documentation

Update:
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`

Add:
```
Vehicle registry: res://game/vehicles/vehicle_registry.gd
Pilotable vehicle base: res://game/vehicles/pilotable_vehicle.gd
Spawn resolver: res://game/vehicles/vehicle_spawn_resolver.gd
Registry data: res://content/vehicles/vehicle_archetypes.json
First production scene: <actual path>
```

---

## Implementation Order

| Step | What |
|---|---|
| 1 | JSON data files + schema |
| 2 | `VehicleDefinition.gd` |
| 3 | `VehicleRegistry.gd` |
| 4 | Movement profiles + `PilotableVehicle.gd` movement |
| 5 | `PilotableVehicle.gd` + base scene |
| 6 | PlayerController input routing |
| 7 | Enter/exit (`VehicleSeat.gd`) |
| 8 | Camera follow switching |
| 9 | `VehicleSpawnResolver.gd` |
| 10 | Wire production vehicle in archetypes |
| 11 | Registry validator tool |
| 12 | Doc updates |
