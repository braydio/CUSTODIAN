# Enemy Behavior Director — Implementation Plan

**Created:** 2026-03-05
**Status:** In Progress (Runtime Slice + Telemetry Implemented)
**Depends On:** Wave Spawning System

---

## 1. Overview

The Enemy Behavior Director sits above the WaveManager and Enemy AI, acting as the strategic brain that decides:
- What enemies spawn
- Where they attack (which lane)
- What their objectives are

This mirrors the legacy Python assault orchestration layer, which modeled lanes, objectives, and escalation. The Godot implementation borrows these core patterns but is adapted for native architecture.

### Runtime Slice Delivered (2026-03-08 to 2026-03-10)

- Added `res://core/systems/enemy_director.gd` and attached it in `res://scenes/game.tscn` as `EnemyDirector`.
- Added `res://core/systems/threat_model.gd`.
- Added `res://core/systems/assault_lane.gd`.
- Added `res://core/systems/enemy_factory.gd`.
- Extended `res://core/systems/wave_manager.gd` with `set_external_wave_plan(composition, lane, objective)`.
- WaveManager now accepts director-forced lane and objective per wave while retaining existing spawn execution.
- Enemy objective string is now respected by `res://entities/enemies/enemy.gd` target-priority ordering.
- Added `EnemyDirector.get_director_status()` runtime telemetry.
- Added lane outcome metrics (`total_attacks`, `successful_attacks`, `success_ratio`) in `AssaultLane`.
- Added HUD line + terminal fallback telemetry rendering in `res://scenes/ui.gd` (`DIRECTOR`, `THREAT`, `ASSAULT`, `WAVE/BUDGET`).

---

## 2. Architecture

```
custodian/
 └─ core/
     └─ systems/
         ├─ wave_manager.gd        # Existing - executes spawns
         ├─ enemy_director.gd      # NEW - strategic brain
         ├─ threat_model.gd       # NEW - difficulty calculation
         ├─ assault_lane.gd        # NEW - lane definitions
         └─ enemy_factory.gd       # NEW - composition generation
```

---

## 3. Threat Model

### Concept
Threat scales with time, destruction, and wave number. Higher threat = harder attacks.

### Implementation: `threat_model.gd`

```gdscript
extends Node
class_name ThreatModel

signal threat_updated(new_threat: float)

@export var base_threat: float = 5.0
@export var threat_per_wave: float = 3.0
@export var threat_per_destroyed_structure: float = 10.0
@export var threat_per_minute: float = 1.0

var elapsed_minutes: float = 0.0

func _process(delta):
    elapsed_minutes += delta / 60.0

func calculate_threat(wave_number: int, destroyed_structures: int) -> float:
    var threat := base_threat
    threat += wave_number * threat_per_wave
    threat += destroyed_structures * threat_per_destroyed_structure
    threat += elapsed_minutes * threat_per_minute
    threat_updated.emit(threat)
    return threat

func reset():
    elapsed_minutes = 0.0
```

---

## 4. Assault Lanes

### Concept
Lanes represent entry routes into the base. Each lane has spawn nodes and a strategic value.

### Implementation: `assault_lane.gd`

```gdscript
extends Node
class_name AssaultLane

@export var lane_name: String = "default"
@export var display_name: String = "Default Route"
@export var weight: float = 1.0
@export var active: bool = true

var spawn_nodes: Array[SpawnNode] = []
var recent_attacks: int = 0
var failed_attacks: int = 0

func _ready():
    add_to_group("assault_lanes")

func register_spawn_node(node: SpawnNode):
    if node.active:
        spawn_nodes.append(node)

func get_spawn_node() -> SpawnNode:
    if spawn_nodes.is_empty():
        return null
    return spawn_nodes.pick_random()

func get_attack_score() -> float:
    var score := weight
    
    # Prefer lanes that haven't been attacked recently
    score -= recent_attacks * 2.0
    
    # Slightly prefer previously failed lanes
    score += failed_attacks * 0.5
    
    # Add some randomness
    score += randf_range(-2.0, 2.0)
    
    return max(0.1, score)

func record_attack(success: bool):
    recent_attacks += 1
    if not success:
        failed_attacks += 1

func decay():
    recent_attacks = max(0, recent_attacks - 1)
```

---

## 5. Enemy Factory

### Concept
Generates enemy compositions based on point budgets and unlocks.

### Implementation: `enemy_factory.gd`

```gdscript
extends Node
class_name EnemyFactory

@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene
@export var siege_drone_scene: PackedScene

const ENEMY_COST := {
    "drone": 1,
    "fast": 2,
    "heavy": 4,
    "siege": 6,
}

const UNLOCK_WAVE := {
    "drone": 0,
    "fast": 3,
    "heavy": 6,
    "siege": 10,
}

func generate_composition(budget: int, wave_number: int) -> Array[String]:
    var enemies: Array[String] = []
    var remaining := budget
    
    while remaining > 0:
        var enemy_type := _choose_enemy(remaining, wave_number)
        if enemy_type.is_empty():
            break
        enemies.append(enemy_type)
        remaining -= ENEMY_COST[enemy_type]
    
    return enemies

func _choose_enemy(budget: int, wave: int) -> String:
    var options: Array[String] = []
    
    for type in ["drone", "fast", "heavy", "siege"]:
        if budget >= ENEMY_COST[type] and wave >= UNLOCK_WAVE[type]:
            options.append(type)
    
    if options.is_empty():
        return ""
    
    return options.pick_random()

func get_scene_for_type(enemy_type: String) -> PackedScene:
    match enemy_type:
        "drone": return drone_scene
        "fast": return fast_drone_scene
        "heavy": return heavy_drone_scene
        "siege": return siege_drone_scene
    return drone_scene
```

---

## 6. Objectives

### Concept
Different attack objectives prioritize different targets.

### Objective Types

| Objective | Target Priority |
|-----------|----------------|
| `harass_player` | Player |
| `destroy_power` | Power Nodes → Turrets → Command |
| `destroy_turrets` | Turrets → Power → Command |
| `breach_command` | Command → Turrets → Power |

### Implementation: `objective.gd`

```gdscript
class_name AttackObjective

enum Type {
    HARASS_PLAYER,
    DESTROY_POWER,
    DESTROY_TURRETS,
    BREACH_COMMAND,
}

static func get_priority_list(objective: Type) -> Array[String]:
    match objective:
        Type.HARASS_PLAYER:
            return ["player", "turret", "power_node", "command_post"]
        Type.DESTROY_POWER:
            return ["power_node", "turret", "command_post", "player"]
        Type.DESTROY_TURRETS:
            return ["turret", "power_node", "command_post", "player"]
        Type.BREACH_COMMAND:
            return ["command_post", "turret", "power_node", "player"]
        _:
            return ["player", "command_post"]
```

---

## 7. Enemy Director

### Concept
The Director runs each wave, making strategic decisions.

### Implementation: `enemy_director.gd`

```gdscript
extends Node
class_name EnemyDirector

signal attack_plan_ready(plan: AttackPlan)
signal objective_changed(objective: String)

@export var wave_manager: WaveManager
@export var threat_model: ThreatModel
@export var enemy_factory: EnemyFactory

var lanes: Array[AssaultLane] = []
var current_objective: AttackObjective.Type = AttackObjective.Type.HARASS_PLAYER

class AttackPlan:
    var lane: AssaultLane
    var objective: AttackObjective.Type
    var enemy_types: Array[String]
    var target_priority: Array[String]

func _ready():
    _collect_lanes()
    
func _collect_lanes():
    lanes.clear()
    for node in get_tree().get_nodes_in_group("assault_lanes"):
        if node is AssaultLane and node.active:
            lanes.append(node)

func plan_next_wave(wave_number: int, destroyed_structures: int) -> AttackPlan:
    # 1. Calculate threat
    var threat := threat_model.calculate_threat(wave_number, destroyed_structures)
    
    # 2. Choose lane
    var lane := _choose_lane()
    
    # 3. Choose objective
    var objective := _choose_objective()
    
    # 4. Generate composition
    var budget := int(threat * 1.5)
    var enemy_types := enemy_factory.generate_composition(budget, wave_number)
    
    # 5. Build plan
    var plan := AttackPlan.new()
    plan.lane = lane
    plan.objective = objective
    plan.enemy_types = enemy_types
    plan.target_priority = AttackObjective.get_priority_list(objective)
    
    attack_plan_ready.emit(plan)
    return plan

func _choose_lane() -> AssaultLane:
    if lanes.is_empty():
        push_warning("[Director] No lanes available!")
        return null
    
    var best_lane: AssaultLane = null
    var best_score := -INF
    
    for lane in lanes:
        var score := lane.get_attack_score()
        if score > best_score:
            best_score = score
            best_lane = lane
    
    return best_lane

func _choose_objective() -> AttackObjective.Type:
    # Simple objective selection based on game state
    var power_nodes = get_tree().get_nodes_in_group("power_node")
    var damaged_power = 0
    for node in power_nodes:
        if node.has_method("get_efficiency"):
            if node.get_efficiency() < 0.5:
                damaged_power += 1
    
    # If power is damaged, target power more often
    if damaged_power > 0 and randf() < 0.6:
        return AttackObjective.Type.DESTROY_POWER
    
    # Default to harassing player
    return AttackObjective.Type.HARASS_PLAYER
```

---

## 8. Integration with WaveManager

### How They Connect

```
Director.plan_next_wave()
         ↓
   Returns AttackPlan
         ↓
WaveManager executes spawns with lane + objective info
         ↓
Enemy AI reads objective and adjusts target priority
```

### Modified WaveManager Integration

```gdscript
# In wave_manager.gd, add:

var enemy_director: EnemyDirector
var current_attack_plan

func start_next_wave() -> void:
    # ... existing code ...
    
    if enemy_director:
        var plan = enemy_director.plan_next_wave(wave_number, _count_destroyed_structures())
        current_attack_plan = plan
        _spawn_with_plan(plan)
    else:
        # Fallback to simple spawning
        start_next_wave_simple()
```

---

## 9. Enemy AI Integration

### Reading the Objective

```gdscript
# In enemy.gd, add:

var target_priority: Array[String] = ["player", "command_post", "power_node", "turret"]

func set_objective_priority(priority_list: Array[String]):
    target_priority = priority_list

func _find_best_target() -> Node2D:
    # Use target_priority instead of fixed priority
    for group in target_priority:
        var candidates = get_tree().get_nodes_in_group(group)
        # Find nearest valid candidate
        # ...
```

---

## 10. Runtime Validation Checklist

- [x] ThreatModel calculates and updates threat over time/wave/destruction.
- [x] Assault lanes register active spawn nodes by lane.
- [x] Lane selection uses lane scores with recency/failure bias.
- [x] EnemyFactory generates wave composition within point budget.
- [x] Director produces lane + objective + composition plan each wave.
- [x] WaveManager executes external director plan.
- [x] Enemies consume objective and adjust target priority.
- [x] Director telemetry exposed to HUD/terminal output.

---

## 11. Future Upgrades

### Coordinated Assaults
Multiple lanes attacked simultaneously.

### Adaptive Difficulty
Director learns from player defense patterns.

### Siege Units
Enemies that attack walls/turrets from range.

### Stealth Infiltrators
Enemies that bypass front-line defenses.

---

## 12. Related Systems

- Wave Spawning System (completed)
- Enemy Objective System (in progress)
- Sector Damage System (planned)
- Repair Gameplay System (planned)
