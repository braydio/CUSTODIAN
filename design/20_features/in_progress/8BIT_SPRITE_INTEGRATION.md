# 8-BIT SPRITE INTEGRATION GUIDE

**Created:** 2026-03-12
**Status:** Reference Document

---

## Production Spec (Locked)

| Property | Value |
|----------|-------|
| Body sprite | 32x64 pixels |
| Frame size | 96x96 pixels (draw/export) |
| Draw scale | 128x256 (4x for detail) |
| Scale in-engine | ~1.0-1.05 (uniform) |

---

## Pipeline: Sprite → Playable Unit

### 1. Export Sprite Sheet

Combine frames into a single sprite sheet:

```
96x96 frames

+----+----+----+----+
| f1 | f2 | f3 | f4 |
+----+----+----+----+
```

Export as:
- PNG
- Transparent background
- No scaling
- Nearest neighbor

Example: `custodian_alert_ranged_2h.png`

---

### 2. Import Into Godot

Drag to: `assets/sprites/operator/`

Ensure import settings:
```
Filter: OFF
Repeat: OFF
```

Pixel art requires **filter off**.

---

### 3. Create AnimatedSprite2D

In your unit scene (`operator.tscn`):

```
Operator (CharacterBody2D)
 ├ CollisionShape2D
 ├ BodySprite (AnimatedSprite2D)
 ├ WeaponSprite (AnimatedSprite2D)
 └ MuzzleMarker (Marker2D)
```

**Key:** Weapon should be separate from body.

---

### 4. Create SpriteFrames

Select `AnimatedSprite2D` → New `SpriteFrames`

Add animation:
```
name: idle_right
frame size: 32 x 64
frames: 4
FPS: 6-8
loop: on
```

---

### 5. Weapon System (Critical)

**Guns should NOT be baked into body sprite.**

Structure:
```
Operator
 ├ BodySprite
 └ WeaponSprite
```

Load weapon dynamically:

```gdscript
@onready var weapon_sprite = $WeaponSprite

func equip_weapon(texture: Texture2D):
    weapon_sprite.texture = texture
```

---

### 6. Align Weapon

Tweak position until it lines up with hands:

```gdscript
weapon_sprite.position = Vector2(6, -10)  # Adjust as needed
```

Or use marker nodes:

```
Operator
 ├ BodySprite
 ├ WeaponSocket (Marker2D)
 │   └ WeaponSprite
```

---

### 7. Sync Animations

Play body and weapon together:

```gdscript
body_sprite.play("alert_ranged_2h")
weapon_sprite.play("alert_ranged_2h")
```

Current runtime wiring:

- Operator firing body animation resolves through `custodian/assets/sprites/operator/runtime/body/ranged_2h/operator_body_ranged_2h_fire_loop.png`; refresh that runtime asset from new exports to preserve the existing Godot import path
- Runtime muzzle flash resolves through `custodian/entities/effects/muzzle_flash_frames.tres`, which points at `custodian/assets/sprites/effects/runtime/muzzle_flash_yellow.png`

---

### 8. Add Muzzle Flash

```
Operator
 ├ BodySprite
 ├ WeaponSprite
 └ MuzzleFlash (Sprite2D/AnimatedSprite2D)
```

Spawn on fire:

```gdscript
func _spawn_muzzle_flash():
    muzzle_flash.show()
    await get_tree().create_timer(0.05).timeout
    muzzle_flash.hide()
```

---

### 9. Direction System

Create animations for each direction:
```
idle_right
idle_left
idle_up
idle_down
walk_right
walk_left
...
```

Switch based on facing:

```gdscript
func _update_animation():
    var suffix = _get_direction_suffix(aim_direction)
    body_sprite.play("idle_" + suffix)
```

---

### 10. Shooting Logic

```gdscript
func _fire_bullet():
    var bullet = BULLET_SCENE.instantiate()
    bullet.global_position = muzzle_marker.global_position
    bullet.direction = aim_direction
    get_tree().current_scene.add_child(bullet)
```

---

## Recommended Folder Structure

```
assets/
  sprites/
    operator/
      body/
        idle/
        walk/
        attack/
      guns/
        runtime/
          pistol.png
          rifle.png
          ...
        source/

entities/
  operator/
    operator.gd
    operator.tscn
```

---

## Animation Naming Convention

```
{idle|walk|attack}_{direction}
idle_right
idle_left
idle_up
idle_down
walk_right
attack_right
...
```

---

## Game Feel: Hit Stop & Shake

Settings in `operator.gd`:

```gdscript
@export var melee_hit_stop_scale: float = 0.8     # 0.8 = subtle 80% speed
@export var melee_hit_stop_duration: float = 0.02 # Very short
@export var melee_camera_shake_power: float = 1.0  # Very weak
```

**Philosophy:** Subtle is better. Test with 8-bit sprites - overkill feels bad at low res.

---

## Optimization: Fake 8 Directions

RTS games (Starcraft, Into The Breach) use only **4-5 directions** and flip horizontally:

| Animation | Used For |
|-----------|----------|
| idle_right | right, down_right, down |
| idle_up | up, up_right, up_left |
| (flip horizontally for left side) |

This reduces animation workload by ~40-50%.

---

## Next Steps

1. Build `idle` animation (4 directions)
2. Build `walk` animation 
3. Build `attack` animation
4. Wire weapon sprite to existing firing code
5. Tune hit stop / shake values

---

## Reference

- Existing code: `entities/operator/operator.gd`
- Turret patterns: `entities/defense/turret.gd`
- Sprite setup: `entities/operator/operator.tscn`
