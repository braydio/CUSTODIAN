# ProcGen Tile & Collision Fix Specification

**Status:** 🔴 REQUIRED (Blocking Structural Integrity)
**Date:** 2026-03-31

---

## 1. Problem Summary

Current runtime violates core architectural rules defined in:
- Compound Tile System
- TileMap authority model

### Observed Failures
- Dark cells exist → no tile assigned
- Some walls collide, some don't → partial structural registration
- Navigation / collision / visuals are desynced

---

## 2. Root Cause

**Three competing sources of truth:**

| System       | Source                  |
| ------------ | ----------------------- |
| Visual tiles | TileMap (partial)       |
| Collision    | Generated wall registry |
| Navigation   | TileMap (floor + walls) |

This directly triggers documented failure case:
> "Tilemap says wall, registry says not wall, collision says maybe."

---

## 3. Required Architectural Rule (LOCK THIS)

From spec:
> "Tile coordinates and type come from the TileMap."

### 🔒 Enforced Rule
```
TileMap = SINGLE SOURCE OF TRUTH
```
Everything else must derive from it: collision, navigation, structural registry.

---

## 4. Correct Generation Pipeline (MANDATORY)

### ❌ Current (Broken) Flow
```
generate grid
→ place some walls
→ register some walls
→ maybe place floor
→ build collision separately
```

### ✅ Required Flow
```
STEP 1 — Fill floor (100% coverage)
STEP 2 — Place ALL wall tiles (deterministic)
STEP 3 — Build structural registry FROM tilemap
STEP 4 — Build collision FROM tilemap
STEP 5 — Build navigation FROM tilemap
STEP 6 — Apply overlays (shadows, decals)
```

---

## 5. Implementation Requirements

### 5.1 STEP 1 — Full Floor Fill (CRITICAL)

Eliminate ALL empty cells:

```gdscript
for x in width:
    for y in height:
        floor_tilemap.set_cell(0, Vector2i(x,y), FLOOR_SOURCE, FLOOR_TILE)
```

### 🔴 Failure if skipped:
- dark void tiles
- navigation ambiguity
- visual artifacts

---

### 5.2 STEP 2 — Deterministic Wall Placement

Walls must ALWAYS result in a tile:

```gdscript
if cell_type == WALL:
    wall_tilemap.set_cell(0, pos, WALL_SOURCE, atlas_coords)
```

### 🔴 NEVER DO:
- conditional placement
- "skip if neighbor invalid"
- visual-only placement

---

### 5.3 STEP 3 — Structural Registry FROM TileMap

From spec: "Scan tilemaps → classify relevant cells"

```gdscript
for cell in wall_tilemap.get_used_cells(0):
    registry[cell] = CompoundTileState.new(...)
```

### 🔴 NEVER:
- build registry from generator arrays

---

### 5.4 STEP 4 — Collision FROM TileMap (NOT generator)

Replace this:
```gdscript
for cell in generated_wall_cells:
    create_collision(cell)
```

With:
```gdscript
for cell in wall_tilemap.get_used_cells(0):
    create_collision(cell)
```

### ✅ Guarantees:
- every visible wall collides
- no phantom collisions
- no missing collisions

---

### 5.5 STEP 5 — Navigation Sync

From runtime contract: "Navigation rebuild uses promoted tilemaps as authority"

```gdscript
nav.floor_tilemap = floor_tilemap
nav.walls_tilemap = wall_tilemap
nav.rebuild()
```

---

### 5.6 STEP 6 — Overlays Are Non-Structural

Layer model:
```
Floor → structural
Walls → structural
Shadow → NON-structural
```

### 🔴 Rule:
Shadows MUST NEVER affect: collision, navigation, registry

---

## 6. Validation Checks (ADD THESE)

### 6.1 No Empty Cells
```gdscript
assert(floor_tilemap.get_used_cells(0).size() == width * height)
```

### 6.2 Wall Integrity
```gdscript
for cell in wall_tilemap.get_used_cells(0):
    assert(has_collision(cell))
```

### 6.3 No Ghost Collision
```gdscript
for collider in colliders:
    assert(wall_tilemap.has_cell(collider.cell))
```

### 6.4 Registry Alignment
```gdscript
assert(registry.size() == wall_tilemap.get_used_cells(0).size())
```

---

## 7. Expected Result After Fix

| Before | After |
|--------|-------|
| ❌ dark void tiles | ✅ 100% tile coverage |
| ❌ inconsistent collision | ✅ all walls collide |
| ❌ visual ≠ gameplay | ✅ no phantom space |

Plus: navigation matches visuals, tilemap is authoritative

---

## 8. Anti-Patterns to Eliminate

### ❌ Partial Tile Writes
```gdscript
if random_condition:
    set_cell(...)
```

### ❌ Generator-Based Collision
```gdscript
collision_from(grid_data)
```

### ❌ Multiple Truth Systems
- tilemap says wall
- registry says empty
- collision says maybe

---

## 9. Key Insight

You do NOT have:
- a tileset problem
- a collision bug
- a Godot issue

You have:
> a **broken generation pipeline violating your own architecture**

---

## 10. Priority Order

Fix in this exact order:
1. Floor fill (removes voids)
2. Wall placement (removes inconsistency)
3. Collision derivation (fixes gameplay)
4. Registry rebuild (fixes systems)
5. Navigation rebuild (fixes AI)

---

## 11. Final Rule

> If a tile exists visually, it MUST exist structurally.

No exceptions.