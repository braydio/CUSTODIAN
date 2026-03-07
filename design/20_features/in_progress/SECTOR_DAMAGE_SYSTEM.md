# CUSTODIAN — Sector Damage System Implementation Plan

**Created:** 2026-03-05
**Status:** In Progress (Audit Complete, Ready to Build)
**Depends On:** Enemy Objective System

---

## 1. Overview

Structures (Command Post, Power Nodes, Turrets) take persistent damage that affects their functionality. This creates strategic pressure — the player must prioritize repairs.

### Damage States

| HP Percentage | State | Effect |
|---------------|-------|--------|
| 100% - 60% | Operational | Full functionality |
| 59% - 30% | Damaged | Reduced efficiency |
| 29% - 1% | Critical | Severe penalties |
| 0% | Destroyed | Disabled / Game Over (Command Post) |

---

## 2. Base Structure Script

Create a reusable damageable component:

**File:** `res://core/systems/damageable.gd`

```gdscript
extends Node2D
class_name Damageable

signal damaged(amount: float, new_hp: float)
signal destroyed()
signal state_changed(new_state: String)

@export var max_health: float = 100.0
@export var current_health: float = 100.0

var state: String = "operational"

func _ready():
    current_health = max_health
    _update_state()

func take_damage(amount: float):
    if current_health <= 0:
        return
    
    current_health = max(0, current_health - amount)
    damaged.emit(amount, current_health)
    _update_state()
    
    if current_health <= 0:
        _on_destroyed()

func repair(amount: float):
    current_health = min(max_health, current_health + amount)
    _update_state()

func get_efficiency() -> float:
    return current_health / max_health

func get_state() -> String:
    return state

func _update_state():
    var hp_percent = (current_health / max_health) * 100.0
    
    var new_state: String
    if hp_percent >= 60:
        new_state = "operational"
    elif hp_percent >= 30:
        new_state = "damaged"
    elif hp_percent > 0:
        new_state = "critical"
    else:
        new_state = "destroyed"
    
    if new_state != state:
        state = new_state
        state_changed.emit(state)
        _on_state_changed(state)

func _on_state_changed(new_state: String):
    # Override in subclasses for specific behavior
    pass

func _on_destroyed():
    destroyed.emit()
    queue_free()
```

---

## 3. Power Node Implementation

**File:** `res://entities/sector/power_node.gd`

```gdscript
extends Damageable
class_name PowerNode

@export var power_output: float = 100.0
@export var node_name: String = "Power Node"

# Efficiency penalties
var efficiency_by_state := {
    "operational": 1.0,
    "damaged": 0.6,
    "critical": 0.3,
    "destroyed": 0.0,
}

func _ready():
    super._ready()
    add_to_group("power_node")
    add_to_group("structure")

func get_power_output() -> float:
    return power_output * efficiency_by_state.get(state, 0.0)

func _on_state_changed(new_state: String):
    match new_state:
        "operational":
            print("[PowerNode] ", node_name, " operational - 100% output")
        "damaged":
            print("[PowerNode] ", node_name, " damaged - 60% output")
        "critical":
            print("[PowerNode] ", node_name, " critical - 30% output")
        "destroyed":
            print("[PowerNode] ", node_name, " destroyed - offline")

func _on_destroyed():
    super._on_destroyed()
    # Notify power system
    var power_system = get_node_or_null("/root/GameRoot/Power")
    if power_system and power_system.has_method("on_power_node_destroyed"):
        power_system.on_power_node_destroyed(self)
```

---

## 4. Turret Implementation

**File:** `res://entities/sector/turret.gd`

```gdscript
extends Damageable
class_name Turret

@export var turret_name: String = "Turret"
@export var fire_rate: float = 1.0  # Shots per second
@export var damage: float = 10.0
@export var range: float = 300.0

var fire_timer: float = 0.0
var target: Node2D = null

# Efficiency penalties
var efficiency_by_state := {
    "operational": 1.0,
    "damaged": 0.5,
    "critical": 0.2,
    "destroyed": 0.0,
}

func _ready():
    super._ready()
    add_to_group("turret")
    add_to_group("structure")

func _physics_process(delta):
    if state == "destroyed":
        return
    
    fire_timer += delta
    
    # Find target
    target = _find_target()
    
    if target and fire_timer >= (1.0 / fire_rate):
        _fire()
        fire_timer = 0.0

func _find_target() -> Node2D:
    var enemies = get_tree().get_nodes_in_group("enemies")
    var nearest: Node2D = null
    var nearest_dist := range
    
    for enemy in enemies:
        var dist = global_position.distance_to(enemy.global_position)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = enemy
    
    return nearest

func _fire():
    if target == null:
        return
    
    # Create bullet (simplified - reuse bullet system)
    print("[Turret] Firing at ", target.name)

func get_efficiency() -> float:
    return efficiency_by_state.get(state, 0.0)

func _on_state_changed(new_state: String):
    match new_state:
        "operational":
            print("[Turret] ", turret_name, " operational")
        "damaged":
            print("[Turret] ", turret_name, " damaged - 50% fire rate")
        "critical":
            print("[Turret] ", turret_name, " critical - 20% fire rate")
        "destroyed":
            print("[Turret] ", turret_name, " destroyed")
```

---

## 5. Command Post Implementation

**File:** `res://entities/sector/command_post.gd`

```gdscript
extends Damageable
class_name CommandPost

@export var node_name: String = "Command Post"

signal game_over()

func _ready():
    super._ready()
    add_to_group("command_post")
    add_to_group("structure")

func _on_destroyed():
    super._on_destroyed()
    game_over.emit()
    print("[GAME OVER] Command Post destroyed!")
    # Trigger game over state

func _on_state_changed(new_state: String):
    match new_state:
        "operational":
            print("[CommandPost] All systems nominal")
        "damaged":
            print("[CommandPost] Warning: Systems degraded")
        "critical":
            print("[CommandPost] CRITICAL: Command impaired")
        "destroyed":
            print("[CommandPost] OFFLINE")
```

---

## 6. Integration with Power System

The Power system needs to query all Power Nodes:

**File:** `res://core/systems/power.gd` (modify existing)

```gdscript
# Add these functions

func get_total_power() -> float:
    var total := 0.0
    var power_nodes = get_tree().get_nodes_in_group("power_node")
    for node in power_nodes:
        if node.has_method("get_power_output"):
            total += node.get_power_output()
    return total

func on_power_node_destroyed(node: PowerNode):
    print("[Power] Node destroyed: ", node.node_name)
    # Recalculate total power
    _update_power_display()
```

---

## 7. Testing Checklist

- [ ] Damageable component created
- [ ] Power Node takes damage, efficiency scales
- [ ] Turret takes damage, fire rate scales
- [ ] Command Post destruction triggers game over
- [ ] Power system recalculates on node damage/destruction
- [ ] Visual feedback for damage states (color changes, etc.)

---

## 8. Integration with Enemy Objectives

The full chain:

```
Wave Spawning → Enemy spawns
                      ↓
Enemy Objective → Enemies target structures
                      ↓
Sector Damage → Structures take damage
                      ↓
Efficiency Loss → Turrets fire slower, power decreases
                      ↓
Player Decision → Repair or defend?
```
