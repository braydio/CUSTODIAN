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
custodian/content/sprites/
├── _pipeline/                  # Intake-only manifest-driven ingest area
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
	├── environment/                 # In-world environmental sprites
	│   ├── props/
	│   │   └── terminal/
	│   │       └── runtime/body/   # command_terminal / fabricator_terminal prop sheets
│   ├── foliage/
│   └── ambient_critter/
│
└── additional-charsets/        # Third-party assets
```

`_pipeline/` is not a runtime asset root. It stages source PNG + manifest pairs that are written into the
existing runtime-owned sprite domains.

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

New sprite sheets should use the canonical pipeline naming pattern:

```
<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png
```

Examples:

```
operator__body__locomotion__walk__n__8f__96.png
operator__body__locomotion__sprint__se__8f__96.png
operator__body__locomotion__dodge__w__6f__96.png
operator__body__locomotion__roll__nw__8f__96.png
operator__body__melee__fast_01__n__6f__96.png
operator__weapon__melee__fast_01__n__6f__96.png
operator__fx__melee__fast_01__n__6f__96.png
enemy_grunt__body__reaction__stagger__s__5f__96.png
hit_spark__fx__impact__default__omni__4f__64.png
command_terminal__body__interaction__activate__omni__4f__48.png
```

Legacy files may remain while current scenes and rebuild scripts still reference them. New source and intake work
should use the canonical `command_terminal` or `fabricator_terminal` filename and let pipeline manifests write
compatibility copies when needed.

### Direction Codes

Use fixed direction codes:

```
n, ne, e, se, s, sw, w, nw, omni
```

Use `omni` only for non-directional effects.

### Animation Vocabulary

```
locomotion: idle, walk, sprint, dodge, roll
melee: light_01, light_02, fast_01, fast_02, heavy_01, heavy_charge, heavy_release
defense: block_enter, block_hold, block_hit, block_break, block_exit
ranged: aim, fire, fire_walk, reload, recoil
reaction: hit_light, hit_heavy, stagger, knockdown, recover
death: default, disintegrate
interaction: activate, deactivate, open, close, idle
```

---

## Workflow

### Intake Pipeline

1. Drop a PNG + matching JSON manifest into `content/sprites/_pipeline/inbox/`
2. Run `python custodian/tools/pipelines/ingest.py`
3. Validate the written runtime asset in Godot

The ingest pipeline writes into the existing runtime domains such as `weapons/`, `enemies/`, `operator/`,
`effects/`, `vehicles/`, and `turrets/`. It does not write into a separate `entities/` hierarchy.

For terminal props, prefer the prop-owned runtime body folder:

```text
environment/props/terminal/runtime/body/
```

Use `command_terminal` for the current world prop and reserve `fabricator_terminal` for the future distinct prop sprite.

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
2. Use a manifest in `_pipeline/inbox/` to slice the authored strip into the live runtime file path
3. Clean up irregular frame regions only if the source sheet actually needs it
4. Validate the runtime scene/script that consumes the new strip

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
