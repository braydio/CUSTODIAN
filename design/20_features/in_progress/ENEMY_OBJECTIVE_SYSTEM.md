# CUSTODIAN — Enemy Objective System Implementation Plan

**Created:** 2026-03-05
**Status:** Ready for Implementation
**Depends On:** Wave Spawning System

---

## 1. Overview

Enemies currently just chase the player. This system gives them **objectives** — they target structures (power nodes, turrets, command post) instead of solely chasing the player.

This creates the core defense gameplay: enemies attack your base, not just you.

---

## 2. Design

### Target Priority

Each enemy evaluates nearby targets in priority order:

```
1. Command Post (highest priority)
2. Power Nodes
3. Turrets
4. Player (lowest priority)
```

### Why This Order

- Command Post = game over if destroyed
- Power = affects all defenses
- Turrets = immediate threat to enemies
- Player = fallback when nothing else nearby

---

## 3. Implementation

### Step 1: Add Structure Groups

Modify your existing structure scenes to add them to groups:

**Command Post:** Add to group `"command_post"`
**Power Nodes:** Add to group `"power_node"`
**Turrets:** Add to group `"turret"`

### Step 2: Modify Enemy Script

**File:** `res://entities/enemies/enemy.gd`

Add target priority logic:

```gdscript
extends CharacterBody2D
class_name Enemy

@export var enemy_name: String = "DRONE"
@export var speed: float = 80.0
@export var health: float = 50.0
@export var max_health: float = 50.0
@export var damage: float = 10.0

# NEW: Attack range for structures
@export var structure_attack_range: float = 60.0

var target: Node2D = null
var dead := false
var damage_timer := 0.0
var damage_interval := 1.0

# Target priority (lower = higher priority)
var target_priority := {
    "command_post": 1,
    "power_node": 2,
    "turret": 3,
    "player": 4,
}

@onready var health_bar = $HealthBar
@onready var visual = $Visual

func _ready():
    add_to_group("enemies")
    find_initial_target()

func find_initial_target():
    # Find operator as initial target
    var world = get_node("/root/GameRoot/World")
    if world:
        var operators = world.find_children("Operator", "CharacterBody2D")
        if operators.size() > 0:
            target = operators[0]

func _physics_process(_delta):
    if dead:
        return
    
    # Update target based on priority
    _update_target()
    
    if target:
        var direction = (target.global_position - global_position).normalized()
        
        # Check if in attack range
        var dist = global_position.distance_to(target.global_position)
        var attack_range = _get_attack_range()
        
        if dist > attack_range:
            # Move toward target
            velocity = direction * speed
            move_and_slide()
        else:
            # Attack target
            velocity = Vector2.ZERO
            _attack_target()

func _update_target():
    if target == null or not is_instance_valid(target):
        target = _find_best_target()
        return
    
    # Check if there's a higher priority target nearby
    var better_target = _find_better_target()
    if better_target:
        target = better_target

func _find_best_target() -> Node2D:
    var best_target: Node2D = null
    var best_priority := 999
    
    # Get all potential targets
    var world = get_node("/root/GameRoot/World")
    if not world:
        return null
    
    # Check each target type in priority order
    for target_type in ["command_post", "power_node", "turret"]:
        var targets = world.find_children("*", target_type, true, false)
        
        for t in targets:
            if t is Node2D:
                var priority = target_priority.get(target_type, 999)
                var dist = global_position.distance_to(t.global_position)
                
                # Within detection range?
                if dist < 400:  # Detection range
                    if priority < best_priority:
                        best_priority = priority
                        best_target = t
    
    # Fallback to player if no structure found
    if best_target == null:
        var operators = world.find_children("Operator", "CharacterBody2D")
        if operators.size() > 0:
            best_target = operators[0]
    
    return best_target

func _find_better_target() -> Node2D:
    if target == null:
        return null
    
    var current_priority = 999
    var current_type = ""
    
    # Determine current target type
    if target.is_in_group("command_post"):
        current_type = "command_post"
    elif target.is_in_group("power_node"):
        current_type = "power_node"
    elif target.is_in_group("turret"):
        current_type = "turret"
    else:
        current_type = "player"
    
    current_priority = target_priority.get(current_type, 4)
    
    # Look for higher priority targets
    var world = get_node("/root/GameRoot/World")
    if not world:
        return null
    
    for target_type in ["command_post", "power_node", "turret"]:
        var priority = target_priority.get(target_type, 999)
        
        if priority < current_priority:
            var targets = world.find_children("*", target_type, true, false)
            for t in targets:
                if t is Node2D:
                    var dist = global_position.distance_to(t.global_position)
                    if dist < 400:  # Detection range
                        return t
    
    return null

func _get_attack_range() -> float:
    if target == null:
        return 60.0
    
    if target.is_in_group("player"):
        return 40.0  # Closer range for player
    
    return structure_attack_range

func _attack_target():
    damage_timer += get_process_delta_time()
    if damage_timer >= damage_interval:
        damage_timer = 0
        if target and target.has_method("take_damage"):
            target.take_damage(damage)
            print("Enemy ", enemy_name, " attacked ", target.name, " for ", damage)

func take_damage(amount: float):
    if dead:
        return
    
    health -= amount
    update_visuals()
    
    if visual:
        visual.modulate = Color(1, 1, 1)
        await get_tree().create_timer(0.1).timeout
        update_visuals()
    
    if health <= 0:
        die()

func update_visuals():
    if health_bar:
        health_bar.value = (health / max_health) * 100.0
    
    if visual:
        var health_pct = health / max_health
        if health_pct > 0.5:
            visual.modulate = Color(0.8, 0.2, 0.2)
        elif health_pct > 0.2:
            visual.modulate = Color(0.8, 0.5, 0.2)
        else:
            visual.modulate = Color(0.8, 0.1, 0.1)

func die():
    dead = true
    print("ENEMY DESTROYED: ", enemy_name)
    queue_free()
```

---

## 4. Making Structures Damageable

### Add to Your Structure Scripts

Each structure needs a `take_damage` method:

```gdscript
# Example for PowerNode, Turret, CommandPost

func take_damage(amount: float):
    hp -= amount
    _update_state()
    
    if hp <= 0:
        _on_destroyed()

func _update_state():
    # Visual updates based on HP
    if hp < max_hp * 0.3:
        state = "critical"
    elif hp < max_hp * 0.6:
        state = "damaged"
    else:
        state = "operational"

func _on_destroyed():
    # Disable functionality, play destruction animation
    queue_free()
```

---

## 5. Testing Checklist

- [ ] Command Post in group "command_post"
- [ ] Power Nodes in group "power_node"
- [ ] Turrets in group "turret"
- [ ] Enemies prioritize Command Post over Player
- [ ] Enemies switch targets when higher priority appears
- [ ] Structures take damage from enemies
- [ ] Destroyed structures affect gameplay (power off, etc.)

---

## 6. Integration with Wave System

The Wave Spawning System and Enemy Objective System work together:

```
Wave Spawning → spawns enemies
                    ↓
Enemy Objective → enemies choose targets
                    ↓
Sector Damage → structures take damage
```

This creates the core gameplay loop.
