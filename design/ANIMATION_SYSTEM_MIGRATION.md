# CUSTODIAN — Animation System Migration Guide

**Created:** 2026-03-19  
**Status:** Design — Pending Implementation

---

## Overview

This document guides the migration from the current **type-first** animation structure to the new **weapon-centric** system.

> **Key Principle:** A weapon owns its animations — not the attack type.

---

## Why Migrate?

### Current Problems

- Weapons scattered across folders
- Hard to extend with new attacks
- Animation lookup requires folder traversal
- Mixed sprite sizes (96x96, 100x100, 128x128)
- Irregular drone_missiles animation frames

### Benefits of Weapon-Centric

1. **Self-contained** — all data for one weapon in one place
2. **Easy to extend** — add new attacks without folder restructuring
3. **Data-driven** — animations controlled by JSON, not hardcoded paths
4. **Runtime flexibility** — swap weapons without code changes
5. **Clear contracts** — naming convention makes parsing trivial

---

## Target Structure

```
custodian/assets/sprites/
├── weapons/                              # Weapon-owned system
│   ├── fallen_star_katana/
│   │   ├── weapon_definition.json        # Animation mappings
│   │   └── animations/
│   │       ├── fallen_star_katana__idle.png
│   │       ├── fallen_star_katana__melee_2h__fast.png
│   │       └── fallen_star_katana__melee_2h__heavy.png
│   │
│   ├── carbine_rifle/
│   │   ├── weapon_definition.json
│   │   └── animations/
│   │       ├── carbine_rifle__idle.png
│   │       ├── carbine_rifle__ranged__stance.png
│   │       └── carbine_rifle__ranged__fire.png
│   │
│   └── ANIMATION_SYSTEM.md              # Full documentation
│
├── enemies/
│   └── drone/
│       └── (Pending new assets - see DRONE_ASSETS_NEEDED.md)
│
└── effects/
    └── runtime/
```

---

## Naming Convention

### Sprite Files

```
<weapon_id>__<category>__<variant>.png
```

**Examples:**
```
fallen_star_katana__melee_2h__fast.png
carbine_rifle__ranged__fire.png
```

### Animation Names (Godot)

```
<category>_<variant>
```

**Examples:**
```
idle
melee_fast
melee_heavy
ranged_stance
ranged_fire
```

---

## Sprite Sizes

| Element | Size | Tiles | Notes |
|---------|------|-------|-------|
| Player | 96x96 | 3x3 | Standard character |
| Weapons | 96x96 | 3x3 | Match character scale |
| Enemies | 96x96 | 3x3 | Standard |
| Heavy Enemies | 128x128 | 4x4 | Elite tier |
| Tiles | 32x32 | 1x1 | Base unit |

**See:** `design/SIZING_STRATEGY.md`

---

## Current → New Mapping

### Player Animations

| Current Location | Animation | New Location | Sprite |
|-----------------|----------|-------------|--------|
| `operator/runtime/body/melee_fast/` | melee_2h_fast_right | `weapons/fallen_star_katana/` | 96x96 |
| `operator/runtime/body/melee_fast/` | melee_2h_fast_weapon | `weapons/fallen_star_katana/` | 96x96 |
| `operator/runtime/body/melee_fast/` | melee_2h_fast_fx | `weapons/fallen_star_katana/` | 96x96 |
| `operator/runtime/body/melee_2h/` | melee_2h_stance | `operator/runtime/body/melee_2h/` | 96x96 |
| `operator/runtime/idle/` | idle | `weapons/fallen_star_katana/` | 96x96 |
| `operator/runtime/body/ranged_2h/` | ranged_stance | `weapons/carbine_rifle/` | 96x96 |

### Enemy Animations

| Current | Animation | Status | Action Needed |
|---------|----------|--------|---------------|
| `enemies/drone/runtime/` | drone_idle | 128x128 | Resize to 96x96 |
| `enemies/drone/runtime/` | drone_firing | 128x128 | Resize to 96x96 |
| `enemies/drone/runtime/` | drone_missiles | Irregular | **New assets needed** |

**See:** `design/DRONE_ASSETS_NEEDED.md`

---

## Weapon Definition JSON

### Example: fallen_star_katana

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

### Example: carbine_rifle

```json
{
  "weapon_id": "carbine_rifle",
  "weapon_type": "ranged_2h",
  "sprite_size": 96,
  
  "animations": {
    "idle": {
      "file": "animations/carbine_rifle__idle.png",
      "frames": 3,
      "speed": 7.0,
      "loop": true
    },
    "ranged_stance": {
      "file": "animations/carbine_rifle__ranged__stance.png",
      "frames": 3,
      "speed": 7.0,
      "loop": true
    },
    "ranged_fire": {
      "file": "animations/carbine_rifle__ranged__fire.png",
      "frames": 2,
      "speed": 12.0,
      "loop": true
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

## Runtime Integration

### Loading Animations

```gdscript
class_name WeaponAnimationLoader

static func load_weapon_animations(weapon_id: String) -> Dictionary:
    var def_path := "res://assets/sprites/weapons/%s/weapon_definition.json" % weapon_id
    var def_file := FileAccess.open(def_path, FileAccess.READ)
    var def := JSON.parse_string(def_file.get_as_text())
    
    var animations := {}
    for anim_name in def.animations:
        var anim_data: Dictionary = def.animations[anim_name]
        var full_path := "res://assets/sprites/weapons/%s/%s" % [weapon_id, anim_data.file]
        animations[anim_name] = {
            "frames": load_framesheet(full_path, anim_data.frames),
            "speed": anim_data.speed,
            "loop": anim_data.loop,
            "hit_window": [
                anim_data.get("hit_frame_start", -1),
                anim_data.get("hit_frame_end", -1)
            ]
        }
    
    return animations
```

### Playing Animations

```gdscript
# OLD (brittle)
animated_sprite.play("melee_2h_fast_right")

# NEW (data-driven)
var weapon_anims = load_weapon_animations(current_weapon_id)
animated_sprite.play(weapon_anims["melee_fast"].frames)
```

---

## Migration Phases

### Phase 1: Create Structure
1. Create `weapons/<weapon_id>/animations/` directories
2. Create `weapon_definition.json` for each weapon
3. Create `weapons/ANIMATION_SYSTEM.md`

### Phase 2: Migrate Sprites
1. Copy sprites to new locations
2. Rename to follow convention
3. Resize any mis-sized sprites (100px → 96px)
4. Update drone_missiles after new assets arrive

### Phase 3: Update Runtime
1. Implement `WeaponAnimationLoader` class
2. Update `OperatorWeaponDefinition.gd`
3. Update animation playback in `operator.gd`
4. Update melee overlay system

### Phase 4: Cleanup
1. Remove legacy `.tres` files
2. Remove old sprite directories
3. Update imports
4. Test all animations

---

## Files to Update

| File | Changes |
|------|---------|
| `operator.gd` | Animation loading, playback logic |
| `operator_weapon_definition.gd` | JSON loading, animation dictionary |
| `operator.tscn` | Remove old sprite references |
| `operator_runtime_frames.tres` | Migrate to weapon directories |
| `operator_weapon_frames.tres` | Migrate to weapon directories |
| `operator_melee_overlay_frames.tres` | Migrate to weapon directories |
| `enemy.tres` | Fix drone_missiles, resize to 96px |
| `carbine_rifle_mk1_definition.tres` | Point to new structure |
| `fallen_star_katana_definition.tres` | Point to new structure |

---

## Implementation Order

1. **Acquire drone assets** (see DRONE_ASSETS_NEEDED.md)
2. **Resize operator sprites** (100px → 96px)
3. **Create weapon directories**
4. **Write weapon_definition.json**
5. **Implement WeaponAnimationLoader**
6. **Update operator.gd**
7. **Test melee ↔ ranged swap**
8. **Cleanup legacy files**

---

## Related Docs

- `custodian/assets/sprites/weapons/ANIMATION_SYSTEM.md` — Full system docs
- `design/SIZING_STRATEGY.md` — Sprite sizing rules
- `design/DRONE_ASSETS_NEEDED.md` — Enemy sprite requirements
- `custodian/assets/sprites/README.md` — Sprite overview
