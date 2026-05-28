# CUSTODIAN — Sizing Strategy

> **Note:** This is a recommendation document. The 96x96 target size has not been fully audited against runtime sprites. See `PROJECT_STATUS.md` for current sprite status and `_ACTIVE.md` (deprecated) for tracking. This doc should be reviewed for implementation status.

**Created:** 2026-03-19

---

## Current State

| Element | Current Size | Notes |
|---------|--------------|-------|
| **Tiles** | 32x32 | Grid-based terrain |
| **Operator** | 96x96 / 100x100 | Mixed (inconsistent) |
| **Katana Overlay** | 96x96 | Overlays operator |
| **Enemies (Drones)** | 128x128 | Larger than operator |
| **Weapons (Carbine)** | Varies | Assorted ranged assets |

---

## The Problem

Mixed sprite sizes create:
- Inconsistent visual scale
- Complex offset calculations
- Difficulty adding new content
- Collision mismatches

---

## Recommended Strategy

### Option A: Tile-Centric (Recommended for Isometric Feel)

Scale everything relative to tiles:

| Element | Size | Rationale |
|---------|------|------------|
| **Tiles** | 32x32 | Base unit |
| **Characters** | 96x96 (3x3 tiles) | Humanoid scale |
| **Large Enemies** | 128x128 (4x4 tiles) | Boss/elite tier |
| **Weapons** | Match character | Drawn at character scale |

**Pros:** Clean 3x multiplier, visually readable  
**Cons:** May need sprite scaling in editor

### Option B: Pixel-Perfect (For Crisp Pixel Art)

Maintain original pixel art sizes:

| Element | Size | Notes |
|---------|------|-------|
| **Tiles** | 32x32 | Base unit |
| **Small Characters** | 32x32 | Tile-filling |
| **Medium Characters** | 64x64 | 2x2 tiles |
| **Large Characters** | 96x96 | 3x3 tiles |
| **Bosses** | 128x128 | 4x4 tiles |

**Pros:** Native pixel art, no scaling artifacts  
**Cons:** Size variety requires careful offset management

### Option C: Unified 64px (Balanced)

Standardize on 64px base:

| Element | Size | Notes |
|---------|------|-------|
| **Tiles** | 32x32 | 0.5x base |
| **Small Characters** | 32x32 | 0.5x base |
| **Medium Characters** | 64x64 | 1x base |
| **Large Characters** | 96x96 | 1.5x base |
| **Bosses** | 128x128 | 2x base |

**Pros:** Scales well, divisible  
**Cons:** Requires sprite scaling

---

## Recommended Approach for Custodian

### Target Sizes

```
Character (Operator):     96x96   (3 tiles wide, fits combat area)
Melee Weapon:           96x96   (at character scale)
Ranged Weapon:           96x96   (at character scale)
Standard Enemy:          96x96   (same as player)
Heavy Enemy:            128x128   (larger threat)
Boss/Elite:             128x128   (directional variant)
```

### Tile Relationship

```
96px ÷ 32px = 3 tiles
128px ÷ 32px = 4 tiles
```

Characters occupy **3x3 tiles** (standard) or **4x4 tiles** (heavy).

---

## Migration Steps

### 1. Audit Current Sprites

| Sprite | Current | Target | Action |
|--------|---------|--------|--------|
| Operator idle | 96x96 / 100x100 | 96x96 | Crop/pad to 96 |
| Operator attack | 96x96 | 96x96 | Keep |
| Operator melee | 96x96 | 96x96 | Keep |
| Drone enemies | 128x128 | 96x96 or 128x128 | Decide tier |
| Katana overlay | 96x96 | 96x96 | Keep |
| Carbine sprite | TBD | 96x96 | Scale/crop |

### 2. Update Offset Calculations

```gdscript
# Character positioning
const SPRITE_SIZE := 96.0
const TILE_SIZE := 32.0
const SPRITE_TILES := SPRITE_SIZE / TILE_SIZE  # 3.0

# Offset to center sprite on tile
var sprite_offset := Vector2(SPRITE_SIZE / 2, SPRITE_SIZE / 2)
```

### 3. Collision Alignment

```gdscript
# Character body should be ~60% of sprite height
const BODY_RADIUS := SPRITE_SIZE * 0.3  # ~29px for 96px sprite
const BODY_HEIGHT := SPRITE_SIZE * 0.6    # ~58px for 96px sprite
```

---

## Scale Tiers

| Tier | Size | Sprite Scale | Use Case |
|------|------|-------------|----------|
| **Small** | 32x32 | 0.33x | Drones, rats, small hazards |
| **Standard** | 96x96 | 1.0x | Player, standard enemies, NPCs |
| **Large** | 128x128 | 1.33x | Heavy enemies, turrets, structures |
| **Boss** | 160x160+ | 1.66x+ | Boss encounters |

---

## Visual Guidelines

### Character Placement
- Character bottom aligns with tile bottom
- Sprite center vertically ~70% from top
- Weapon extends above character head

### Enemy Sizing
- **Scout/Swarm:** 32x32 or 64x64
- **Standard:** 96x96 (match player)
- **Heavy/Tank:** 128x128
- **Boss:** 160x160 or larger

### Weapon Sizing
- Melee: Extended beyond character bounds (reach)
- Ranged: Proportional to character
- Held at ~chest height when idle

---

## Sprite Sheet Layout

### Standard Character (96x96)

```
Frame layout: 96x96 per frame
Sheet: H frames × 1 row (horizontal strip)
```

### Animation Grid

| Animation | Frames | Total Width |
|-----------|--------|-------------|
| Idle (4 dirs) | 3 each | 96 × 12 |
| Walk (4 dirs) | 4 each | 96 × 16 |
| Attack (4 dirs) | 6 each | 96 × 24 |
| Death | 4 | 96 × 4 |

---

## Implementation Checklist

- [ ] Define target sprite size (recommend 96x96)
- [ ] Audit all character sprites
- [ ] Update sprite sheet regions
- [ ] Recalculate collision shapes
- [ ] Adjust weapon socket positions
- [ ] Update melee hitbox radii
- [ ] Verify visual alignment in-game

---

## Quick Reference

| What | Current | Target |
|------|---------|--------|
| Operator | 96/100px | 96px |
| Katana | 96px | 96px |
| Drone | 128px | 96px or 128px |
| Tiles | 32px | 32px |
| Character collision | ~22px radius | ~29px radius (30% of 96) |

---

## Next Steps

1. **Decide target size** — 96x96 seems right for your art style
2. **Batch resize** any mis-sized sprites
3. **Update collision** to match new sprite size
4. **Test in-game** for visual consistency
5. **Document** final sizes in weapon definitions
