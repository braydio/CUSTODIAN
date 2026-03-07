# CUSTODIAN — Wave Spawning System Implementation Plan

**Created:** 2026-03-05
**Status:** ✅ IMPLEMENTED
**Godot-Native:** Yes
**Files:** `custodian/core/systems/wave_manager.gd`, `spawn_node.gd`

---

## 1. System Overview

The wave spawning system creates periodic enemy waves that escalate in difficulty. It is Godot-native and designed for later integration with the strategic Python simulation.

### Architecture

```
custodian/
 └─ core/
     └─ systems/
         ├─ wave_manager.gd      # Main wave orchestration
         ├─ spawn_node.gd         # Individual spawn point
         └─ enemy_factory.gd     # Enemy creation (optional, can be in wave_manager)
```

---

## 2. Spawn Nodes

### Purpose
Designated positions on the map where enemies spawn. Placed on map edges to create predictable assault lanes.

### Implementation: `spawn_node.gd`

**File:** `res://core/systems/spawn_node.gd`

```gdscript
extends Node2D
class_name SpawnNode

@export var lane: String = "default"
@export var spawn_weight: float = 1.0
@export var active: bool = true

func _ready():
    add_to_group("enemy_spawn")
    add_to_group("spawn_node_" + lane)
```

### Scene Setup

Create spawn node scenes:
- `res://core/systems/spawn_node.tscn` (instantiate for each spawn point)

### Lane Groups

Spawn nodes automatically join groups:
- `spawn_node_north`
- `spawn_node_east`  
- `spawn_node_south`
- `spawn_node_west`

---

## 3. Wave Manager

### Purpose
Controls wave timing, composition, and difficulty scaling.

### Implementation: `wave_manager.gd`

**File:** `res://core/systems/wave_manager.gd`

```gdscript
extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

# Configuration
@export var wave_interval: float = 30.0
@export var base_points: int = 5
@export var growth_per_wave: int = 3
@export var max_wave: int = 20
@export var initial_delay: float = 5.0

# Enemy Scene References (assign in inspector)
@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene

# Runtime State
var wave_number: int = 0
var timer: Timer = null
var spawn_nodes: Array = []
var active: bool = true

# Enemy Cost Table
var enemy_cost := {
    "drone": 1,
    "fast": 2,
    "heavy": 4
}

# Enemy Stats Modifiers (for scaling)
var hp_modifier: float = 1.0
var damage_modifier: float = 1.0

func _ready():
    _setup_timer()
    _collect_spawn_nodes()
    print("[WaveManager] Initialized with ", spawn_nodes.size(), " spawn nodes")
    
    # Start first wave after initial delay
    await get_tree().create_timer(initial_delay).timeout
    if active:
        start_next_wave()

func _setup_timer():
    timer = Timer.new()
    timer.wait_time = wave_interval
    timer.autostart = false
    timer.timeout.connect(_on_wave_timer)
    add_child(timer)

func _collect_spawn_nodes():
    spawn_nodes = get_tree().get_nodes_in_group("enemy_spawn")
    # Sort by lane for predictable spawning
    spawn_nodes.sort_custom(func(a, b): 
        return a.lane < b.lane
    )

func _on_wave_timer():
    start_next_wave()

func start_next_wave():
    if wave_number >= max_wave:
        print("[WaveManager] Max wave reached: ", max_wave)
        all_waves_completed.emit()
        return
    
    wave_number += 1
    
    var points = _calculate_points()
    var difficulty = _calculate_difficulty()
    
    print("[WaveManager] Starting Wave ", wave_number, " | Points: ", points, " | Difficulty: ", difficulty)
    
    wave_started.emit(wave_number)
    _spawn_wave(points, difficulty)
    
    wave_completed.emit(wave_number)

func _calculate_points() -> int:
    return base_points + wave_number * growth_per_wave

func _calculate_difficulty() -> float:
    return 1.0 + (wave_number * 0.25)

func _spawn_wave(points: int, difficulty: float):
    var remaining_points = points
    
    while remaining_points > 0:
        var enemy_type = _choose_enemy(remaining_points)
        
        if enemy_type.is_empty():
            break
        
        _spawn_enemy(enemy_type, difficulty)
        remaining_points -= enemy_cost[enemy_type]

func _choose_enemy(available_points: int) -> String:
    var options: Array[String] = []
    
    # Always available
    if available_points >= enemy_cost["drone"]:
        options.append("drone")
    
    # Unlocks at wave 3
    if available_points >= enemy_cost["fast"] and wave_number >= 3:
        options.append("fast")
    
    # Unlocks at wave 6
    if available_points >= enemy_cost["heavy"] and wave_number >= 6:
        options.append("heavy")
    
    if options.is_empty():
        return ""
    
    return options.pick_random()

func _spawn_enemy(enemy_type: String, difficulty: float):
    if spawn_nodes.is_empty():
        push_warning("[WaveManager] No spawn nodes available!")
        return
    
    # Pick random spawn node
    var spawn_node = spawn_nodes.pick_random()
    
    var scene: PackedScene
    match enemy_type:
        "drone":
            scene = drone_scene
        "fast":
            scene = fast_drone_scene
        "heavy":
            scene = heavy_drone_scene
    
    if scene == null:
        push_warning("[WaveManager] Enemy scene not set: " + enemy_type)
        return
    
    var enemy = scene.instantiate()
    
    # Apply difficulty modifiers
    if enemy.has_method("apply_difficulty_modifiers"):
        enemy.apply_difficulty_modifiers(difficulty, difficulty)
    
    # Position at spawn node
    enemy.global_position = spawn_node.global_position
    
    # Add to world
    var world = get_node_or_null("/root/GameRoot/World")
    if world:
        var enemies_container = world.find_child("Enemies", true, false)
        if enemies_container:
            enemies_container.add_child(enemy)
            return
    
    # Fallback
    get_tree().current_scene.add_child(enemy)

# Control Functions
func start_waves():
    active = true
    if timer and not timer.is_started():
        timer.start()

func stop_waves():
    active = false
    if timer:
        timer.stop()

func skip_wave():
    start_next_wave()

func reset():
    wave_number = 0
    stop_waves()
    # Clear existing enemies
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.queue_free()
```

---

## 4. Enemy Difficulty Modifiers

### Add to Existing Enemy Script

Modify `res://entities/enemies/enemy.gd` to support difficulty scaling:

```gdscript
# Add these functions to enemy.gd

func apply_difficulty_modifiers(hp_mult: float, damage_mult: float):
    max_health = max_health * hp_mult
    health = max_health
    damage = damage * damage_mult
    update_visuals()
```

---

## 5. Scene Setup Instructions

### Step 1: Add WaveManager to Scene

1. Open `test_map.tscn`
2. Add new Node → name it `WaveManager`
3. Attach script: `res://core/systems/wave_manager.gd`

### Step 2: Assign Enemy Scenes

In Inspector for WaveManager:
- `Drone Scene`: assign `res://entities/enemies/enemy.tscn`
- `Fast Drone Scene`: (create new scene or duplicate)
- `Heavy Drone Scene`: (create new scene or duplicate)

### Step 3: Place Spawn Nodes

1. Create Node2D instances around map edges
2. Attach `spawn_node.gd`
3. Set `Lane` property (north, east, south, west)
4. Place 3-5 spawn nodes per lane

### Example Scene Tree:

```
GameRoot
 ├── World
 │   ├── Sectors
 │   │   └── TileMap
 │   ├── Enemies
 │   ├── Projectiles
 │   ├── Operator
 │   ├── SpawnNodes
 │   │   ├── SpawnNode_North1 (lane: "north")
 │   │   ├── SpawnNode_North2 (lane: "north")
 │   │   ├── SpawnNode_East1 (lane: "east")
 │   │   └── ...
 │   └── Camera2D
 ├── WaveManager
 │   (assign enemy scenes in inspector)
 ├── Simulation
 ├── Combat
 ├── Power
 ├── UI
 └── PauseUI
```

---

## 6. Wave Configuration Reference

### Default Values

| Parameter | Value | Description |
|-----------|-------|-------------|
| wave_interval | 30.0 | Seconds between waves |
| base_points | 5 | Starting points for wave 1 |
| growth_per_wave | 3 | Points added per wave |
| max_wave | 20 | Final wave |
| initial_delay | 5.0 | Time before first wave |

### Wave Composition Examples

| Wave | Points | Possible Composition |
|------|--------|---------------------|
| 1 | 8 | 8 drones |
| 3 | 14 | 12 drones + fast |
| 5 | 20 | 16 drones + fast + fast |
|  | 208 | 29 drones + fast×4 + heavy |
| 12 | 41 | Mixed with multiple heavy |
| 20 | 65 | Maximum difficulty |

---

## 7. Testing Checklist

- [ ] WaveManager node added to scene
- [ ] Enemy scenes assigned in inspector
- [ ] Spawn nodes placed on map edges
- [ ] Spawn nodes have correct lane groups
- [ ] First wave triggers after initial_delay
- [ ] Enemies spawn at correct positions
- [ ] Wave difficulty increases over time
- [ ] Fast drones unlock at wave 3
- [ ] Heavy drones unlock at wave 6
- [ ] Max wave stops spawning

---

## 8. Future Integration Points

When connecting to Python strategic simulation:

1. **Replace wave timing:**
   ```gdscript
   # Instead of fixed timer
   func request_wave_from_simulation():
       var params = python_bridge.get_wave_parameters()
       _spawn_wave(params.points, params.difficulty)
   ```

2. **Lane-specific spawning:**
   ```gdscript
   # Target specific lanes
   func spawn_on_lane(lane_name: String, count: int):
       var nodes = get_tree().get_nodes_in_group("spawn_node_" + lane_name)
       # spawn at these nodes
   ```

3. **Difficulty from simulation:**
   ```gdscript
   # Use Python threat level
   func set_difficulty_from_threat(threat_level: float):
       hp_modifier = 1.0 + (threat_level * 0.1)
   ```

---

## 9. Related Systems to Implement Next

1. **Enemy Objective System** — Enemies target structures, not just player
2. **Sector Damage System** — Structures take persistent damage
3. **Repair Gameplay** — Player repairs damaged structures

See: `design/ENEMY_OBJECTIVE_SYSTEM.md` and `design/SECTOR_DAMAGE_SYSTEM.md`
