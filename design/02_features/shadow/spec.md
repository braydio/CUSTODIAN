# Shadow System Design

## Overview

Shadows in CUSTODIAN are **gameplay-driven and stylized**, not realistic. The goal is readability and depth—not physically accurate lighting.

> "readability shadows (gameplay-driven, stylized)"

## Current Implementation Scope

First-pass Godot implementation should prioritize what can ship immediately from current runtime data:

- Procedural shadow overlay generated from procgen floor and wall tilemaps
- Blob shadow under the operator using a code-drawn ellipse, not a bespoke sprite sheet
- Regeneration when procgen tiles change, including runtime wall destruction

Deferred until dedicated art support is approved or provided:

- Authored shadow atlas tiles for `ShadowTileMap`
- Shadow-specific animation assets
- More advanced fade-in timing authored per tile reveal

---

## Design Philosophy

### ✅ GOOD
- Soft blobs under walls/objects
- Directional edge shadows
- Consistent fake light direction

### ❌ BAD
- Dynamic lights everywhere
- Per-pixel lighting
- Physically correct shadows

### 🎯 Key Insight

The navigation system already knows where walls/floors are. That same data drives shadow placement.

---

## Shadow Methods

### Method 1: Edge Shadows (Most Important)

**Purpose:** Give walls depth—make them feel raised above the floor

**Logic:**
- Any wall tile that borders a floor tile casts a shadow onto the floor
- Placed on a new `ShadowTileMap` layer (above floor, below entities)

```gdscript
for cell in used_cells:
    if is_wall(cell):
        var below = cell + Vector2i(0, 1)
        if is_floor(below):
            place_shadow(below)
```

**Visual Result:**
```
[WALL]    [WALL]
  ↓        ↓
[SHADOW] [SHADOW]
[FLOOR]   [FLOOR]
```

---

### Method 2: Blob Shadows (Player + Objects)

**Purpose:** Ground characters and props to the floor

**Implementation:**
- Simple sprite under player entity
- Ellipse shape: `scale = Vector2(1.2, 0.6)`
- Alpha: `0.15 – 0.35`

```gdscript
shadow_sprite.scale = Vector2(1.2, 0.6)
shadow_sprite.modulate.a = 0.3
```

**Reactive Enhancement:**
```gdscript
shadow.scale.x = 1.0 + velocity.length() * 0.01
```
- Subtle stretch when moving = movement feel

---

### Method 3: Corner Darkening (Huge Upgrade)

**Purpose:** Make rooms feel enclosed, corridors feel deeper

**Logic:**
- Detect corners where walls meet (L-shapes)
- Place darker shadow at intersection

```gdscript
# Wall to right AND wall below = corner shadow
if is_wall(cell + Vector2i(1,0)) and is_wall(cell + Vector2i(0,1)):
    place_corner_shadow(cell)
```

**Visual Result:**
- Rooms feel bounded
- Corridors gain depth

---

### Method 4: Global Fake Light Direction

**Purpose:** Consistent, intentional look across entire map

**Approach:** Pick ONE light direction → all shadows offset that way

**Recommendation:** Top-left light → shadows go bottom-right

```gdscript
const SHADOW_OFFSET := Vector2(2, 2)  # Slight offset in light direction
```

> This alone makes the game look 10x more intentional

---

### Method 5: Procgen Integration

**Purpose:** Shadows generated at world creation time

**Extend Generation Pipeline:**
```gdscript
generate_chunk(chunk):
    place_floor()
    place_walls()
    generate_shadows()  # ← ADD THIS
    rebuild_navigation()
```

**Why:** Shadows are part of the world, not runtime decorations

---

### Method 6: Fade-In Effect

**Purpose:** Match the "world building" feel—tiles fall into place, shadows settle

**Timing:**
```gdscript
await delay + 0.02  # Slight delay after tile placement
place_shadow(...)
```

**Visual Result:** Shadows "settle" into the world after tiles appear

---

## Implementation Order (Priority)

| Priority | Method | Impact |
|----------|--------|--------|
| 1 | Edge shadows | Massive—walls feel 3D |
| 2 | Blob shadow under player | Grounds character |
| 3 | Global light direction | Cohesive look |
| 4 | Corner darkening | Depth in rooms |

---

## Shadow Style Guide

### Color Palette

| Element | Color | Alpha |
|---------|-------|-------|
| Edge shadows | `#000000` | 0.15 – 0.35 |
| Blob shadows | `#000000` | 0.15 – 0.35 |
| Corner shadows | `#000000` | 0.35 – 0.50 |

### ❌ Avoid
- Pure black (`#000000` at full alpha)
- Hard edges without blur
- Shadows that are too dark (muddy visuals)

### ✅ Preferred
- Slight blur (optional)
- Low alpha for subtlety
- Consistent direction

---

## Technical Implementation

### New TileMap Layer

Create: `ShadowTileMap` (TileMapLayer)
- Z-index: Above Floor, Below Entities
- Atlas: Shadow tiles (edge, corner variants)

Implementation note:

- Until a dedicated atlas exists, a procedural overlay node is an acceptable runtime substitute if it preserves the same layering, readability, and deterministic generation rules.

### Shadow Tile Atlas Layout

```
Row 0: Edge shadows (N, S, E, W, NE, NW, SE, SW)
Row 1: Corner shadows (inner corners)
Row 2: Blob shadows (player, large, small)
```

### System Hook

```
ProcGen → NavigationSystem → ShadowSystem
         ↑                    ↑
         └─ Same tile data ───┘
```

---

## Common Mistakes to Avoid

| Mistake | Why It's Bad |
|---------|--------------|
| Shadows too dark | Muddy visuals, loses depth |
| Shadows everywhere | Visual noise, no focal point |
| Inconsistent direction | Looks wrong instantly |
| Using lighting engine | Overkill for tile logic |

---

## Next Steps

1. **Drop-in `ShadowSystem.gd`** - Hooks into procgen + nav system
2. **Procedural overlay pass** - Unblocked fallback while no dedicated shadow atlas is wired
3. **Shadow tileset + atlas layout** - Plug into TileMap once art direction is locked

---

## Implementation Reference

**Detailed example code available in:** `SHADOW_SYSTEM_IMPLEMENTATION.md`

That document contains:
- Complete `ShadowSystem.gd` class (280+ lines)
- ProcGen integration pattern
- Game.tscn setup code
- Blob shadow implementation for player
- Debug visualization system
- Tilemap layer setup guide
- Complete integration example

---

*Document created: 2026-03-26*
*Related systems: NavigationSystem, ProcGen, TileMap*
