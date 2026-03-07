# Turret System — Implementation Plan

**Created:** 2026-03-05
**Status:** Implemented (Defense Module Runtime Slice)
**Depends On:** Sector Damage System

---

## 1. Overview

Turrets are automated defense structures that shoot at enemies. They connect to the power grid, can be damaged, and provide automated defense during waves.

Confirmed implementation decisions:
- Destroyed turrets remain as wrecks in-world (not `queue_free()`).
- Turrets remain preplaced for the current gameplay slice.
- Power dependency remains sector-based for now.

---

## 2. Turret Types

| Turret Type | Damage | Fire Rate | Range | Special |
|-------------|--------|-----------|-------|---------|
| **Gunner** | Medium | Medium | Medium | Balanced |
| **Blaster** | High | Slow | Short | High single-target damage |
| **Repeater** | Low | Fast | Medium | Spray and pray |
| **Sniper** | Very High | Very Slow | Very Long | Single target, piercing |

---

## 3. Core Turret Script

### `turret.gd`

```gdscript
extends Damageable
class_name Turret

@export var turret_name: String = "Turret"
@export var turret_type: String = "gunner"  # gunner, blaster, repeater, sniper
@export var range: float = 250.0
@export var fire_rate: float = 1.0  # Shots per second
@export var damage: float = 15.0
@export var bullet_scene: PackedScene
@export var muzzle_offset: float = 20.0

# Turret stats by type
const TURRET_STATS := {
    "gunner": {"damage": 15.0, "fire_rate": 1.0, "range": 250.0, "spread": 2.0},
    "blaster": {"damage": 35.0, "fire_rate": 0.5, "range": 180.0, "spread": 0.0},
    "repeater": {"damage": 8.0, "fire_rate": 4.0, "range": 220.0, "spread": 8.0},
    "sniper": {"damage": 60.0, "fire_rate": 0.3, "range": 500.0, "spread": 0.0},
}

var fire_timer: float = 0.0
var target: Node2D = null
var barrel_angle: float = 0.0
var turret_state: String = "idle"  # idle, targeting, firing, disabled, destroyed

@onready var barrel = $Barrel if has_node("Barrel") else null
@onready var base_visual = $Base if has_node("Base") else null

func _ready():
    super._ready()
    _apply_turret_type()
    add_to_group("turret")
    add_to_group("structure")

func _apply_turret_type():
    var stats = TURRET_STATS.get(turret_type, TURRET_STATS["gunner"])
    damage = stats["damage"]
    fire_rate = stats["fire_rate"]
    range = stats["range"]
    var spread = stats["spread"]

func _physics_process(delta):
    if state == "destroyed":
        return
    
    if not _has_power():
        return
    
    fire_timer += delta
    
    target = _find_target()
    
    if target:
        _aim_at_target(target)
        
        if fire_timer >= (1.0 / fire_rate):
            _fire()
            fire_timer = 0.0

func _has_power() -> bool:
    # Check power grid connection
    var power_system = get_node_or_null("/root/GameRoot/Power")
    if power_system and power_system.has_method("has_power"):
        return power_system.has_power()
    return true  # Default to powered if no system

func _find_target() -> Node2D:
    var enemies = get_tree().get_nodes_in_group("enemies")
    var nearest: Node2D = null
    var nearest_dist := range
    
    for enemy in enemies:
        if enemy is Node2D:
            var dist = global_position.distance_to(enemy.global_position)
            if dist < nearest_dist:
                nearest_dist = dist
                nearest = enemy
    
    return nearest

func _aim_at_target(target: Node2D):
    if target == null:
        return
    
    var direction = (target.global_position - global_position).normalized()
    barrel_angle = direction.angle()
    
    if barrel:
        barrel.rotation = barrel_angle

func _fire():
    if target == null or bullet_scene == null:
        return
    
    var bullet = bullet_scene.instantiate()
    if bullet == null:
        return
    
    var direction = (target.global_position - global_position).normalized()
    bullet.global_position = global_position + direction * muzzle_offset
    
    if bullet.has_method("set_direction"):
        bullet.set_direction(direction)
    
    bullet.damage = damage
    bullet.team = "defense"  # Distinguish from player bullets
    
    var container = get_node_or_null("/root/GameRoot/World/Projectiles")
    if container:
        container.add_child(bullet)

func get_efficiency() -> float:
    if state == "destroyed":
        return 0.0
    if not _has_power():
        return 0.0
    return super.get_efficiency()

func _update_state():
    super._update_state()
    
    # Visual feedback for state
    match state:
        "operational":
            _set_barrel_color(Color(0.2, 0.8, 0.2))  # Green
        "damaged":
            _set_barrel_color(Color(0.8, 0.6, 0.2))  # Orange
        "critical":
            _set_barrel_color(Color(0.8, 0.2, 0.2))  # Red
        "destroyed":
            _set_barrel_color(Color(0.3, 0.3, 0.3))  # Gray

func _set_barrel_color(color: Color):
    if barrel and barrel.has_node("Sprite"):
        barrel.get_node("Sprite").modulate = color
```

---

## 4. Turret Scene Structure

### `turret.tscn`

```
Turret (StaticBody2D)
├── Base (ColorRect) - Stationary base
├── Barrel (Node2D) - Rotating part
│   └── Sprite (ColorRect)
├── RangeIndicator (Node2D) - Optional: shows range
├── CollisionShape2D
└── TurretGlow (Sprite/ColorRect) - Effect layer
```

---

## 5. Bullet Types

### Defense Bullet (for turrets)

Modify existing `bullet.gd` to support team:

```gdscript
# Add to bullet.gd
@export var team: String = "player"  # "player" or "defense"

func _on_body_entered(body: Node):
    # Don't hit friendly fire
    if body.is_in_group("player") and team == "defense":
        return
    if body.is_in_group("turret") and team == "defense":
        return
    # ... rest of damage logic
```

---

## 6. Placement System

### Turret Placement Rules

| Rule | Description |
|------|-------------|
| **Power Required** | Turrets need power to function |
| **Cost** | Each turret costs resources to build |
| **Spacing** | Minimum distance between turrets |
| **Coverage** | Overlapping ranges should cover blind spots |

### Simple Placement (for now)

```gdscript
# In player controller

func _try_place_turret():
    if Input.is_action_just_pressed("place_turret"):
        var pos = get_mouse_position_in_world()
        _spawn_turret(pos, "gunner")

func _spawn_turret(position: Vector2, turret_type: String):
    var turret_scene = preload("res://entities/sector/turret.tscn")
    var turret = turret_scene.instantiate()
    turret.turret_type = turret_type
    turret.global_position = position
    get_tree().current_scene.add_child(turret)
```

---

## 7. Power Integration

Turrets depend on power:

```gdscript
func _has_power() -> bool:
    # Turrets in powered sectors work
    var sector = get_parent()
    if sector and sector.has_method("has_power"):
        return sector.has_power()
    return false
```

When power is low:
- Fire rate reduced (via efficiency)
- Eventually stop firing entirely

---

## 8. Damage States

| State | HP % | Efficiency | Visual |
|-------|------|------------|-------|
| Operational | 60-100% | 100% | Green indicator |
| Damaged | 30-59% | 50% | Orange indicator |
| Critical | 1-29% | 25% | Red indicator, sparks |
| Destroyed | 0% | 0% | Gray, smoking |

---

## 9. Scene Setup

### Creating Turret Types

1. Create `turret.tscn` as the base
2. Create variants:
   - `turret_gunner.tscn` - Default
   - `turret_blaster.tscn` - High damage
   - `turret_repeater.tscn` - Fast fire
   - `turret_sniper.tscn` - Long range

3. For each variant, set:
   - `turret_type` export
   - Different sprite colors

### Current Runtime Mapping (Godot)

- Implemented defense module:
  - `custodian/entities/defense/turret.gd`
  - `custodian/entities/defense/turret.tscn`
  - `custodian/entities/defense/bullet.gd`
  - `custodian/entities/defense/bullet.tscn`
- Sector turret variants now instantiate the defense base scene:
  - `custodian/entities/sector/turret_gunner.tscn`
  - `custodian/entities/sector/turret_blaster.tscn`
  - `custodian/entities/sector/turret_repeater.tscn`
  - `custodian/entities/sector/turret_sniper.tscn`
- Shared projectile team filtering updated in:
  - `custodian/entities/projectiles/bullet.gd`
- Enemy compatibility updated (`enemy` + `enemies` groups):
  - `custodian/entities/enemies/enemy.gd`
- Initial map placement remains under `World/Sectors/DEFENSE` in `custodian/scenes/game.tscn`

---

## 10. Integration with Enemy AI

Enemies should prioritize turrets:

```gdscript
# In enemy target priority

var target_priority := {
    "command_post": 1,
    "power_node": 2,
    "turret": 3,  # Turrets are high priority
    "player": 4,
}
```

---

## 11. Testing Checklist

- [x] Turret spawns at position
- [x] Turret detects enemies in range
- [x] Turret rotates barrel toward target
- [x] Turret fires bullets
- [x] Bullets damage enemies
- [x] Turret stops working without power
- [x] Turret takes damage from enemies
- [x] Turret destroyed when HP reaches 0
- [x] Different turret types have different stats

---

## 12. Future Upgrades

### Manual Targeting
Player can lock turrets to specific targets or lanes.

### Upgrade System
Turrets can be upgraded (faster fire, more damage, longer range).

### Multi-Target
Some turrets can track multiple enemies.

### Armor Piercing
Special ammo types that ignore enemy armor.

---

## 13. Related Systems

- Sector Damage System (provides damage framework)
- Power System (turrets need power)
- Wave System (turrets defend against waves)
- Enemy Objective System (enemies prioritize turrets)
