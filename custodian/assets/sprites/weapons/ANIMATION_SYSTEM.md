# CUSTODIAN — Weapon Animation System

**Created:** 2026-03-19  
**Status:** Design — Pending Full Implementation

---

## Overview

Custodian uses a **weapon-centric animation system** where each weapon owns its animations. This provides:

- Self-contained weapon data
- Easy extensibility
- Data-driven animation selection
- Clean runtime integration

---

## Directory Structure

```
weapons/
├── README.md                  # This file
├── fallen_star_katana/
│   ├── weapon_definition.json # Animation mappings
│   └── animations/
│       ├── fallen_star_katana__idle.png
│       ├── fallen_star_katana__melee_2h__fast.png
│       ├── fallen_star_katana__melee_2h__heavy.png
│       └── fallen_star_katana__melee_2h__combo.png
│
├── carbine_rifle/
│   ├── weapon_definition.json
│   └── animations/
│       ├── carbine_rifle__idle.png
│       ├── carbine_rifle__ranged__stance.png
│       ├── carbine_rifle__ranged__fire.png
│       └── carbine_rifle__ranged__reload.png
│
└── carbine_rifle_mk1/
    └── ...
```

---

## Naming Convention

### Sprite Files

```
<weapon_id>__<category>__<variant>.png
```

**Segments:**
- `<weapon_id>` — Unique weapon identifier (snake_case)
- `<category>` — Animation category (idle, melee, ranged, ability)
- `<variant>` — Specific variant (fast, heavy, stance, fire)

**Examples:**
```
fallen_star_katana__melee_2h__fast.png
carbine_rifle__ranged__fire.png
sword_night_flame__ability__dash.png
```

---

## Weapon Definition JSON

Each weapon directory contains a `weapon_definition.json` that maps game actions to animation files:

```json
{
  "weapon_id": "fallen_star_katana",
  "weapon_type": "melee_2h",
  "sprite_size": 96,
  "animations": {
    "idle": {
      "file": "animations/fallen_star_katana__idle.png",
      "frames": 3,
      "speed": 7.0,
      "loop": true
    },
    "melee_fast": {
      "file": "animations/fallen_star_katana__melee_2h__fast.png",
      "frames": 12,
      "speed": 14.0,
      "loop": false,
      "hit_frame_start": 3,
      "hit_frame_end": 6
    },
    "melee_heavy": {
      "file": "animations/fallen_star_katana__melee_2h__heavy.png",
      "frames": 8,
      "speed": 11.0,
      "loop": false,
      "hit_frame_start": 4,
      "hit_frame_end": 7
    }
  },
  "sockets": {
    "right_hand": [10, -8],
    "left_hand": [2, -4],
    "muzzle": [24, 0]
  }
}
```

---

## Animation Categories

| Category | Description | Examples |
|---------|-------------|---------|
| `idle` | Neutral stance | idle, idle_alternative |
| `melee` | Close combat attacks | melee_fast, melee_heavy, melee_combo |
| `ranged` | Distance attacks | ranged_stance, ranged_fire, ranged_reload |
| `ability` | Special moves | dash_strike, overcharge_slash |
| `block` | Defensive poses | block_activate, block_hold, block_break |
| `move` | Movement variants | walk, run, sprint |

---

## Frame Sheet Layout

### Standard Layout (Horizontal Strip)

```
┌────────┬────────┬────────┬────────┐
│ Frame  │ Frame  │ Frame  │ Frame  │
│   0    │   1    │   2    │   3    │
│ 96x96  │ 96x96  │ 96x96  │ 96x96  │
└────────┴────────┴────────┴────────┘
```

### Specs

| Property | Value |
|----------|-------|
| Frame Width | 96px (matches player scale) |
| Frame Height | 96px |
| Layout | Horizontal strip |
| Background | Transparent |

---

## Animation → Action Mapping

### Input Actions

| Input | Action |
|-------|--------|
| Attack (F/M1) | `melee_fast` |
| Shift + Attack | `melee_heavy` |
| Block (RMB) | `block_hold` |
| Q | Weapon ability |

### Godot Constants

```gdscript
# Animation name constants
const ANIM_IDLE := "idle"
const ANIM_MELEE_FAST := "melee_fast"
const ANIM_MELEE_HEAVY := "melee_heavy"
const ANIM_RANGED_STANCE := "ranged_stance"
const ANIM_RANGED_FIRE := "ranged_fire"

# Action → Animation mapping
const ACTION_ANIMATIONS := {
    "primary": "melee_fast",
    "heavy": "melee_heavy",
    "ranged": "ranged_fire",
    "ability": "special_attack"
}
```

---

## Runtime Integration

### Loading

```gdscript
class_name WeaponAnimationLoader

static func load_weapon_animations(weapon_id: String) -> Dictionary:
    var def_path := "res://assets/sprites/weapons/%s/weapon_definition.json" % weapon_id
    var def_file := FileAccess.open(def_path, FileAccess.READ)
    var def := JSON.parse_string(def_file.get_as_text())
    
    var animations := {}
    for anim_name in def.animations:
        var anim_data := def.animations[anim_name]
        var full_path := "res://assets/sprites/weapons/%s/%s" % [weapon_id, anim_data.file]
        animations[anim_name] = {
            "frames": load_framesheet(full_path, anim_data.frames),
            "speed": anim_data.speed,
            "loop": anim_data.loop,
            "hit_window": [anim_data.get("hit_frame_start", -1), anim_data.get("hit_frame_end", -1)]
        }
    
    return animations
```

### Playback

```gdscript
func play_weapon_animation(anim_name: String) -> void:
    var anim_data = weapon_animations.get(anim_name)
    if anim_data:
        animated_sprite.play(anim_name)
        animated_sprite.speed = anim_data.speed
```

---

## Hit Frame Windows

Specify which frames during an animation can register hits:

```json
"melee_fast": {
    "frames": 12,
    "hit_frame_start": 3,
    "hit_frame_end": 6
}
```

**Usage:**
```gdscript
func _process_melee_hitbox():
    var current_frame = animated_sprite.frame
    var hit_window = current_animation.hit_window
    
    if current_frame >= hit_window[0] and current_frame <= hit_window[1]:
        # Check for hits
```

---

## Socket Positions

Relative positions for hand and muzzle sockets:

```json
"sockets": {
    "right_hand": [10, -8],
    "left_hand": [2, -4],
    "muzzle": [24, 0]
}
```

**Usage:**
```gdscript
right_hand_socket.position = weapon_def.sockets.right_hand
left_hand_socket.position = weapon_def.sockets.left_hand
muzzle_socket.position = weapon_def.sockets.muzzle
```

---

## Migration from Legacy

### Current → New Structure

| Legacy Location | New Location |
|----------------|-------------|
| `operator/runtime/body/melee_fast/` | `weapons/fallen_star_katana/animations/` |
| `operator/runtime/idle/` | `weapons/fallen_star_katana/animations/` |
| `weapons/ranged/carbine_rifle/` | `weapons/carbine_rifle/animations/` |
| `operator_melee_overlay_frames.tres` | Weapon-owned per-animation |

**See:** `design/ANIMATION_SYSTEM_MIGRATION.md`

---

## Implementation Checklist

### Phase 1: Structure
- [ ] Create weapon directories
- [ ] Create animations/ subdirectory
- [ ] Create weapon_definition.json

### Phase 2: Sprites
- [ ] Rename sprites to convention
- [ ] Move to weapon directories
- [ ] Verify frame sizes

### Phase 3: Runtime
- [ ] Implement WeaponAnimationLoader
- [ ] Update OperatorWeaponDefinition.gd
- [ ] Update animation playback

### Phase 4: Cleanup
- [ ] Remove legacy .tres files
- [ ] Remove old sprite locations
- [ ] Test all animations

---

## Related Docs

- `design/ANIMATION_SYSTEM_MIGRATION.md` — Full migration guide
- `design/SIZING_STRATEGY.md` — Sprite sizing rules
- `design/DRONE_ASSETS_NEEDED.md` — Enemy requirements
- `custodian/assets/sprites/README.md` — Sprite overview
