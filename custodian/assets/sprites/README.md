# CUSTODIAN — Sprite Assets Overview

**Created:** 2026-03-19

---

## Quick Links

| Topic | Document |
|-------|----------|
| **Animation System** | `weapons/ANIMATION_SYSTEM.md` |
| **Migration Guide** | `design/ANIMATION_SYSTEM_MIGRATION.md` |
| **Sizing Rules** | `design/SIZING_STRATEGY.md` |
| **Drone Assets Needed** | `design/DRONE_ASSETS_NEEDED.md` |

---

## Directory Structure

```
custodian/assets/sprites/
├── weapons/                    # Weapon-owned animation system
│   ├── README.md               # Weapons documentation
│   ├── ANIMATION_SYSTEM.md    # Full animation system
│   ├── fallen_star_katana/    # Melee weapon
│   ├── carbine_rifle/          # Ranged weapon
│   └── carbine_rifle_mk1/      # (Legacy - migrate)
│
├── operator/                   # Player sprites (Legacy - migrate)
│   └── runtime/
│       ├── body/
│       │   ├── melee_fast/     # → weapons/fallen_star_katana/
│       │   └── ranged_2h/      # → weapons/carbine_rifle/
│       └── idle/               # → weapons/<weapon>/animations/
│
├── enemies/                    # Enemy sprites
│   └── drone/
│       └── (See DRONE_ASSETS_NEEDED.md)
│
├── effects/                     # VFX
│   ├── runtime/
│   │   ├── muzzle_flash/      # 64x64, 4 frames
│   │   ├── hit_spark/         # 64x64, 4 frames
│   │   └── block_spark/        # 128x128, 4 frames
│   └── source/                 # Original files
│
└── additional-charsets/        # Third-party assets
```

---

## Sprite Sizes

| Element | Size | Tiles | Notes |
|---------|------|-------|-------|
| **Tiles** | 32x32 | 1x1 | Base unit |
| **Player** | 96x96 | 3x3 | Standard character |
| **Weapons** | 96x96 | 3x3 | At character scale |
| **Enemies (Std)** | 96x96 | 3x3 | Match player |
| **Enemies (Heavy)** | 128x128 | 4x4 | Elite/Boss tier |

**See:** `design/SIZING_STRATEGY.md`

---

## Current Assets Status

### Weapons

| Weapon | Type | Status |
|--------|------|--------|
| fallen_star_katana | Melee 2H | Legacy - migrate to weapon-owned |
| carbine_rifle | Ranged 2H | Legacy - migrate to weapon-owned |
| carbine_rifle_mk1 | Ranged 2H | Needs setup |

### Enemies

| Enemy | Animations | Status |
|-------|-----------|--------|
| drone | idle, firing, missiles | **New assets needed** |

**See:** `design/DRONE_ASSETS_NEEDED.md`

### Effects

| Effect | Frames | Size | Status |
|--------|--------|------|--------|
| muzzle_flash | 4 | 64x64 | ✓ Working |
| hit_spark | 4 | 64x64 | ✓ Working |
| block_spark | 4 | 128x128 | ✓ Working |
| melee_swing | - | - | ✓ Created |

---

## Animation Naming Convention

### Sprite Files

```
<weapon_id>__<category>__<variant>.png
```

**Examples:**
```
fallen_star_katana__melee_2h__fast.png
carbine_rifle__ranged__fire.png
```

### Godot Animations

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

## Workflow

### Adding New Weapon

1. Create `weapons/<weapon_id>/animations/`
2. Create `weapons/<weapon_id>/weapon_definition.json`
3. Add sprites following naming convention
4. Update `weapon_definition.json` with animation mappings
5. Test in Godot

### Adding New Enemy Animation

1. Create new sprite sheet (96x96 frames for standard)
2. Name following convention
3. Update `enemy.tres` with new frames
4. Test animation playback

### Fixing Drone Animations

1. **TODO:** Acquire new drone sprite sheets
2. Resize to 96x96
3. Clean up irregular frame regions
4. Update `enemy.tres`

**See:** `design/DRONE_ASSETS_NEEDED.md`

---

## Import Settings

For pixel art sprites:

```
Filter:        Disabled
Mipmaps:       Disabled
Compression:   Lossless
Repeat:        Disabled
```

---

## TODO

### High Priority
- [ ] Acquire drone animation assets
- [ ] Resize operator sprites (100px → 96px)
- [ ] Migrate weapon sprites to weapon-owned structure

### Medium Priority
- [ ] Create weapon_definition.json for each weapon
- [ ] Implement WeaponAnimationLoader
- [ ] Fix drone_missiles animation

### Low Priority
- [ ] Cleanup legacy .tres files
- [ ] Remove old sprite directories
- [ ] Update all imports

---

## Related Documentation

### In This Project
- `design/ANIMATION_SYSTEM_MIGRATION.md` — Migration guide
- `design/SIZING_STRATEGY.md` — Sprite sizing rules
- `design/DRONE_ASSETS_NEEDED.md` — Enemy requirements
- `weapons/ANIMATION_SYSTEM.md` — Full animation system docs

### External
- Godot SpriteFrames documentation
- Pixel art best practices
