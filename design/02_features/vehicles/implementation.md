# Vehicles Implementation Plan

**Project:** CUSTODIAN  
**Created:** 2026-04-05  
**Status:** draft (Phase 1 implemented)  
**Author:** PAI-OpenCode

**Roadmap:** v1.1 - Vehicle System  
**Status:** design (pending implementation)  
**Depends on:** Combat system, Repair mechanics, Free-roam (v0.5.0)

---

## Overview

This document defines the implementation plan for the Vehicle System — enabling the player to operate light hover vehicles (buggies) as a first vehicle archetype. Vehicles provide tactical mobility options while maintaining the game's core pillars: static sectorized base defense, knowledge-over-power progression, and doctrine-based enemy adaptation.

The implementation introduces a shared `ControllableActor` interface that unifies player and vehicle control, enabling seamless enter/exit mechanics and future AI control compatibility.

---

## Goals

- Implement `ControllableActor` interface for unified control
- Enable enter/exit vehicle gameplay (E key interaction)
- Create Light Hover Buggy as first vehicle archetype
- Integrate vehicle weapons with existing weapon system
- Implement vehicle health and destruction mechanics
- Prepare architecture for future vehicle types (tank, mech, drone, transport)

## Non-Goals

- Physics-based vehicle movement (acceleration, drift, friction) — deferred to v2
- Multi-passenger vehicles — deferred to Transport archetype
- Flying vehicles/drones — deferred to Drone archetype
- Vehicle deployment as deployable units — deferred to Defense Grid integration
- Complex turning radius mechanics — deferred to Tank archetype

---

## User Experience

### User Story

As a player in the field during free-roam or post-assault, I want to enter a light hover buggy so that I can quickly traverse the compound, respond to threats across multiple sectors, and provide mobile fire support.

### Interaction Flow

```
1. Player approaches vehicle → Interaction prompt appears ("Press E to enter")
2. Player presses E → Player avatar hides, vehicle becomes controlled
3. Player moves/aims/fires → Vehicle responds with same input as operator
4. Player presses E → Player exits at vehicle position, vehicle becomes idle
```

### Controls

| Action | Input | Result |
|--------|-------|--------|
| Enter vehicle | E (near vehicle) | Enter and take control |
| Exit vehicle | E (while in vehicle) | Exit at current position |
| Move | WASD/Arrow keys | Vehicle moves in input direction |
| Aim | Mouse | Aim weapon (forward-only for v1) |
| Fire | LMB | Fire forward weapon |

### UI/UX

- Interaction prompt appears when within range of vehicle
- Vehicle health displayed in HUD when controlling
- Exit places operator at vehicle position, facing same direction

---

## Technical Design

### Architecture

#### ControllableActor Interface

```gdscript
# controllable_actor.gd
class_name ControllableActor
extends CharacterBody2D

## Shared interface for player operator and vehicles
## Enables unified control handoff system

func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool) -> void:
    """Process movement, aiming, and firing input"""
    pass

func get_velocity() -> Vector2:
    """Return current velocity for camera tracking"""
    return Vector2.ZERO

func get_health() -> float:
    """Return current health"""
    return 0.0
```

#### VehicleBase Class

```gdscript
# vehicle_base.gd
class_name VehicleBase
extends ControllableActor

@export var max_speed: float = 300.0
@export var health: float = 100.0
@export var max_health: float = 100.0

var weapon: WeaponBase
var is_occupied: bool = false
var occupant: Operator = null

func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool) -> void:
    velocity = input_vector * max_speed
    move_and_slide()
    if is_firing and weapon:
        fire_weapon(aim_vector)

func fire_weapon(aim_direction: Vector2) -> void:
    weapon.fire(global_position, aim_direction)

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0:
        destroy()

func destroy() -> void:
    spawn_destruction_effects()
    if is_occupied and occupant:
        # Player controller will handle exit
        pass
    queue_free()
```

#### PlayerController Router

```gdscript
# player_controller.gd
var current_actor: ControllableActor
var operator: Operator
var is_in_vehicle: bool = false

func _process(delta: float) -> void:
    var input_vector = get_movement_input()
    var aim_vector = get_aim_vector()
    var firing = Input.is_action_pressed("fire")
    
    current_actor.process_input(input_vector, aim_vector, firing)

func enter_vehicle(vehicle: VehicleBase) -> void:
    current_actor = vehicle
    vehicle.is_occupied = true
    vehicle.occupant = operator
    operator.visible = false
    is_in_vehicle = true

func exit_vehicle() -> void:
    var vehicle = current_actor as VehicleBase
    operator.global_position = vehicle.global_position
    operator.visible = true
    vehicle.is_occupied = false
    vehicle.occupant = null
    current_actor = operator
    is_in_vehicle = false
```

### Data Structures

```gdscript
# vehicle_data.gd (resource)
@export var vehicle_name: String
@export var max_speed: float
@export var max_health: float
@export var weapon_scene: PackedScene
@export var sprite_frames: SpriteFrames

# Vehicle registry for spawn management
var vehicle_registry = {
    "light_buggy": preload("res://entities/vehicles/light_buggy.tscn")
}
```

### Asset Requirements

```
custodian/assets/sprites/vehicles/hover_buggy/
├── buggy_idle.png          # 64x64 or 96x96, 2.5D perspective
├── buggy_move.png          # Animation frames
└── buggy_destroy.png       # Destruction sequence (optional)
```

### Edge Cases

| Case | Handling |
|------|----------|
| Player enters vehicle while weapon is mid-fire | Cancel fire state, transfer to vehicle |
| Vehicle destroyed while occupied | Auto-exit player, apply damage to player |
| Player enters vehicle, vehicle exits map bounds | Clamp position to world bounds |
| Player tries to enter already-occupied vehicle | Show "Occupied" prompt |
| Player enters vehicle, assault begins | Allow if player in vehicle at assault start |
| Player in vehicle, camera zooms out | Adjust camera to account for vehicle speed |

---

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| Operator movement system | ✅ Ready | Base for ControllableActor interface |
| Weapon system | ✅ Ready | Weapon fire interface exists |
| Combat damage system | ✅ Ready | Damage pipeline available |
| Sector damage integration | ✅ Ready | Destruction callbacks available |
| Interaction prompt system | 🔄 Need review | May need extension for vehicles |
| Camera tracking system | ✅ Ready | Already tracks operator velocity |

### Prerequisites for Implementation

1. Refactor operator to extend `ControllableActor`
2. Verify weapon system interface compatibility
3. Review interaction prompt system for vehicle support

---

## Implementation Phases

### Phase 1: Core Architecture (CRITICAL)

**Task 1.1:** Create `ControllableActor` interface
- File: `custodian/entities/base/controllable_actor.gd`
- Purpose: Shared control contract

**Task 1.2:** Refactor operator to use `ControllableActor`
- Update: `custodian/entities/operator/operator.gd`
- Purpose: Conform to unified interface

**Task 1.3:** Create `VehicleBase` class
- File: `custodian/entities/vehicles/vehicle_base.gd`
- Purpose: Base class for all vehicles

### Phase 2: Control Handoff

**Task 2.1:** Update player controller as router
- Update: `custodian/game/player_controller.gd`
- Purpose: Route input to current actor

**Task 2.2:** Implement enter vehicle logic
- Purpose: Hide operator, take vehicle control

**Task 2.3:** Implement exit vehicle logic
- Purpose: Place operator at vehicle position

**Task 2.4:** Create vehicle interaction trigger
- File: `custodian/entities/vehicles/vehicle_interaction.gd`
- Purpose: Show "Press E to enter" prompt

### Phase 3: First Vehicle (Light Hover Buggy)

**Task 3.1:** Create Light Buggy scene
- File: `custodian/entities/vehicles/light_buggy.tscn`
- Purpose: First vehicle archetype

**Task 3.2:** Implement basic movement (no physics)
- Direct velocity mapping, no acceleration/drift

**Task 3.3:** Integrate weapon system
- Forward-only firing for v1

**Task 3.4:** Add health and destruction
- Implement `take_damage()` and `destroy()`

### Phase 4: Integration

**Task 4.1:** Spawn test vehicle in scene
- Add to test level for verification

**Task 4.2:** Bind E key to enter/exit
- Global input mapping

**Task 4.3:** Test enter/exit flow
- Verify all edge cases

---

## Testing

### Unit Tests
- [ ] ControllableActor interface methods return correct values
- [ ] Vehicle movement maps input to velocity correctly
- [ ] Health damage calculates correctly
- [ ] Destruction triggers at health <= 0

### Integration Tests
- [ ] Player can enter vehicle with E key
- [ ] Player can exit vehicle with E key
- [ ] Movement input routes correctly to vehicle
- [ ] Weapon fires when in vehicle
- [ ] Camera tracks vehicle movement

### Manual Test Cases
- [ ] Scenario: Enter vehicle, move across compound, exit
- [ ] Scenario: Enter vehicle, take damage, exit before destruction
- [ ] Scenario: Enter vehicle during assault wave
- [ ] Scenario: Vehicle destroyed while player inside

---

## Future Vehicle Types (Post-v1)

| Archetype | Key Features | Implementation After |
|-----------|---------------|----------------------|
| Tank | Turning radius, heavy armor, slow | v1.1+ |
| Mech | Slow + heavy, stomp attack, melee | v1.2+ |
| Drone | Flying layer, vertical movement | v2.0+ |
| Transport | Multi-seat, passenger capacity | v2.0+ |

---

## Open Questions

- Should vehicles require power from a sector to function?
- Do vehicles persist between assaults or despawn?
- Should destroyed vehicles leave wreckage for scavenge?
- How do vehicles interact with the Defense Grid (deployable)?

---

## Alignment with Game Pillars

| Pillar | Vehicle Integration |
|--------|---------------------|
| Static sectorized base defense | Vehicles extend defense perimeter coverage |
| Command-vs-field asymmetry | Field operatives get mobility; command stays in terminal |
| Knowledge-over-power | Vehicle acquisition via doctrine/unlock, not raw power |
| Enemy adaptation | Enemies adapt to vehicle usage patterns |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Map-scale collapse (vehicle too fast for world) | Clamp max speed to ~2x operator pace |
| Doorway/collision issues | Design vehicle hitbox to fit standard doorways |
| Dismount exploits (exit to gain invulnerability) | Brief delay before player can act after exit |
| Camera failure at speed | Adjust camera smoothing for vehicle velocity |
| Vehicles become default answer | Balance with operational burden (fuel, maintenance, vulnerability) |

---

*This document aligns with MASTER_ROADMAP.md for milestone tracking. Update status in both documents.*