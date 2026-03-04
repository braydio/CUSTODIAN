
## Implementation Status (2026-02-25)

- Phase 1 (deterministic grid substrate + structure instances) is implemented in code.
- Snapshot compatibility and migration are live (`snapshot_version=3`).
- `BUILD <TYPE> <X> <Y>` is implemented with deterministic IDs and invariants.
- Perimeter generation logic is integrated into `FORTIFY <SECTOR> <0-4>` using `PERIMETER`-tagged wall instances.
- `FORTIFY` layout updates are deterministic, do not overwrite occupied non-perimeter cells, and preserve manual/non-perimeter walls.
- Assault pressure now incorporates deterministic perimeter topology signals (coverage + continuity) to model weak-point exposure without tile-by-tile combat simulation.
- Operator-facing telemetry now surfaces perimeter topology in `STATUS FULL` for fortified sectors.
- High-pressure assault degradation now deterministically erodes perimeter-wall instances, allowing grid topology to evolve across repeated assaults.
- Topology scoring now includes weakest-edge integrity (`WEAK`) for stronger breach-vector modeling and operator visibility.
- Repair drone stock now routes deterministic weakest-segment perimeter restoration during repair ticks.
- Operator policy control now governs drone perimeter routing (`POLICY DRONE_REPAIR <AUTO|OFF>`) with explicit status drilldown telemetry.

This is the process documents to add:

> A deterministic grid-based spatial layer.

That is a **data structure problem**, not an engine problem.

You only need to leave Python when you want:

* Real-time rendering
* Animation
* Player input handling
* Physics

You can build the entire grid-based base-building system inside your existing Python simulation cleanly.

---

# 🎯 Important Reframe

You are not adding Minecraft.

You are adding:

> A constrained spatial substrate for systemic structures.

That is entirely compatible with:

* Tick-based deterministic simulation
* Snapshot architecture
* Assault routing
* Power load
* Logistics pressure

Python is perfectly fine for that.

---

# 🧱 The Correct Way to Add a Clean Grid Layer

We must avoid turning this into:

* Infinite voxel chaos
* Pathfinding nightmare
* Unbounded spatial simulation

We design this intentionally small.

---

# 📐 Recommended Grid Model

Per sector:

```plaintext
Sector
  └── Grid (e.g. 12 x 12 or 16 x 16)
```

Not 100x100.
Not infinite.
Small and strategic.

Example:

```plaintext
12 x 12 grid
= 144 cells
```

That’s enough for:

* Defensive walls
* Power nodes
* Turrets
* Drones paths
* Creative layout decisions

Without becoming Factorio-scale madness.

---

# 🧠 Data Model (In Python)

Inside `state.py`:

```python
class SectorGrid:
    width: int
    height: int
    cells: dict[(x, y), GridCell]

class GridCell:
    structure_id: Optional[str]
    terrain_type: str
    blocked: bool
```

Then:

```python
state.sector_grids[sector_name] = SectorGrid(...)
```

That’s it.

No engine required.

---

# 🏗 Structure Instance Model

Instead of abstract structure counts:

```python
StructureInstance:
    id
    type
    hp
    max_hp
    position (x, y)
    power_required
    logistics_cost
```

Stored in:

```python
state.structure_instances[sector]
```

Now fortification becomes:

> Placed walls on grid cells.

---

# 🧩 What This Unlocks

Now you can:

* Make assault routing hit actual walls
* Make breach points meaningful
* Have drones repair specific coordinates
* Have power flow adjacency matter
* Have spatial weak points
* Allow creative base shapes

All still deterministic.

---

# ⚠️ The Critical Constraint

To avoid blowing up scope:

You must enforce:

* Fixed grid size
* Limited structure types
* Deterministic path routing
* No continuous physics
* No freeform terrain sculpting

This is a *board game grid*, not Minecraft terrain.

---

# 🧠 Where the Engine Eventually Fits

When you move to Godot or Unity:

The engine will:

* Render the grid
* Render structure instances
* Move player sprite
* Animate drones
* Play sounds

But the grid simulation logic?

Still lives in Python (until ported to C# later).

---

# 💡 The Real Question

You do not need to leave Python.

You need to decide:

### How detailed should assault routing become?

Option A:

* Assault still abstract
* Grid affects damage distribution only

Option B:

* Assault units path across grid deterministically
* Walls block
* Turrets fire based on Manhattan distance

Option C:

* Full tile-based combat simulation (dangerous)

For your current architecture?

**Option A or B only.**
C explodes complexity.

---

# 🎯 My Strong Recommendation

Implement:

> Grid-based structure placement
> Abstract assault resolution influenced by grid topology

Do not simulate enemy units per tile.

Let grid shape:

* Breach likelihood
* Threat multiplier
* Damage concentration
* Structural cascade

That keeps it elegant.

---

# 📊 Complexity Reality

Grid layer adds:

* +1 state dimension
* +1 routing calculation
* +1 snapshot dimension
* +new tests

But not:

* Real-time complexity
* Rendering complexity
* Engine dependency

You are still building a simulation.

---

# 🚀 Next Step

If you want, I can:

* Design a minimal viable grid system spec that fits your current codebase
* Or design the structure instance system refactor plan
* Or show you how fortification becomes wall placement instead of numeric levels

What depth do you want:

1. Conceptual architecture
2. Concrete file-by-file refactor plan
3. Minimal viable implementation spec
4. Long-term engine-compatible spatial design

Pick one.
You are building **Phase 1: Grid Substrate + Structure Instances**, with:

* Deterministic state mutation
* Snapshot safety
* No combat integration yet
* Fortification migration path defined

Below is:

1. **Implementation Roadmap (file-by-file)**
2. **Structure Type Registry Design**
3. **Fortification → Wall Migration Plan**

This is precise and aligned with your current architecture.

---

# PART 1 — IMPLEMENTATION ROADMAP

## Phase 1: Deterministic Sector Grid + Structure Instances

---

# 🎯 End State

After this phase:

* Each sector has a fixed grid (e.g., 12x12)
* Structures are placed instances
* BUILD command works
* Snapshot includes grid
* No combat changes yet
* Fortification numeric levels still exist (temporary)

---

# STEP 0 — Add Constants

## File: `core/config.py`

Add:

```python
GRID_WIDTH = 12
GRID_HEIGHT = 12
```

No dynamic resizing.

---

# STEP 1 — Add Grid Data Structures

## File: `core/state.py`

### 1.1 Add GridCell

```python
class GridCell:
    def __init__(self):
        self.structure_id: str | None = None
        self.blocked: bool = False
```

---

### 1.2 Add SectorGrid

```python
class SectorGrid:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.cells = {
            (x, y): GridCell()
            for x in range(width)
            for y in range(height)
        }
```

---

### 1.3 Add to World State

In state initialization:

```python
self.sector_grids: dict[str, SectorGrid] = {}
```

After sectors are created:

```python
for sector_name in self.sectors:
    self.sector_grids[sector_name] = SectorGrid(GRID_WIDTH, GRID_HEIGHT)
```

---

# STEP 2 — Structure Instance Layer

Still in `core/state.py`.

### 2.1 Add StructureInstance

```python
class StructureInstance:
    def __init__(self, id, type, sector, position):
        self.id = id
        self.type = type
        self.sector = sector
        self.position = position
        self.hp = 100
        self.max_hp = 100
```

---

### 2.2 Add Storage

In state init:

```python
self.structure_instances: dict[str, StructureInstance] = {}
self.next_structure_id = 1
```

ID must be deterministic.

---

# STEP 3 — Snapshot Integration

## File: `core/snapshot_migration.py`

You must serialize:

* Grid dimensions
* Cell structure IDs
* StructureInstances
* next_structure_id

Serialize only primitives.

Example grid serialization:

```python
{
  sector: {
    "width": grid.width,
    "height": grid.height,
    "cells": {
      "x,y": structure_id
    }
  }
}
```

On load:

* Reconstruct SectorGrid
* Restore structure_id
* Set blocked accordingly

---

# STEP 4 — Structure Type Registry

## File: `core/structures.py`

Create a registry:

```python
STRUCTURE_TYPES = {
    "WALL": {
        "cost": 5,
        "max_hp": 150,
        "blocks": True,
        "power": 0,
    },
    "TURRET": {
        "cost": 20,
        "max_hp": 100,
        "blocks": True,
        "power": 5,
    },
    "GENERATOR": {
        "cost": 30,
        "max_hp": 120,
        "blocks": True,
        "power": -10,  # produces power
    },
}
```

No logic here.
Pure data.

---

# STEP 5 — BUILD Command

## File: `terminal/commands/build.py` (new)

Add command:

```plaintext
BUILD <TYPE> <X> <Y>
```

Flow:

1. Validate sector context
2. Validate structure type
3. Validate bounds
4. Validate empty cell
5. Validate materials
6. Deduct cost
7. Create StructureInstance
8. Assign ID:

   ```python
   id = f"S{state.next_structure_id}"
   state.next_structure_id += 1
   ```
9. Mark grid cell
10. Set blocked if type blocks

Return success message.

---

## Register Command

Update:

```plaintext
terminal/commands/__init__.py
```

Add build to command registry.

Update help.

---

# STEP 6 — Invariants

## File: `core/invariants.py`

Add:

* No two structures occupy same cell
* structure_instances positions match grid
* next_structure_id monotonically increasing

---

# STEP 7 — Tests

Create:

```plaintext
world_state/tests/test_grid_building.py
```

Required tests:

1. Grid created per sector
2. BUILD succeeds in empty cell
3. Cannot build out of bounds
4. Cannot build on occupied
5. Materials deducted
6. Snapshot reload preserves grid
7. Deterministic ID generation

---

# STOP

Combat untouched.
Fortification untouched (for now).

---

# PART 2 — STRUCTURE TYPE REGISTRY DESIGN

We keep registry simple and declarative.

---

# 🎯 Design Rules

Registry must:

* Be pure data
* Have no side effects
* Be engine-agnostic
* Support future extension
* Allow deterministic balancing

---

# Required Fields

Each type must define:

```python
{
    "cost": int,
    "max_hp": int,
    "blocks": bool,
    "power": int,  # + = consumption, - = generation
    "logistics": int,
}
```

Optional future:

* range
* damage
* repair_rate
* adjacency_bonus

But do NOT add yet.

---

# Why This Matters

This registry becomes:

* Engine bridge
* Combat integration source
* UI reference
* Save schema backbone

Keep it stable.

---

# PART 3 — FORTIFICATION → WALL MIGRATION PLAN

Currently:

```python
state.sector_fort_levels[sector]
```

Numeric 0–4.

We migrate to:

> Placed WALL instances forming perimeter.

---

# 🎯 Migration Strategy

DO NOT delete fortification immediately.

We do staged migration.

---

# PHASE A — Parallel State

Keep numeric fortification.

Add walls manually via BUILD.

Combat still reads numeric fortification.

---

# PHASE B — Auto-Translate

When fort level changes:

Instead of storing number:

1. Clear existing perimeter walls.
2. Calculate perimeter ring thickness based on level.
3. Place WALL instances around edge.

Example:

Level 1:

* Single perimeter ring.

Level 2:

* Two thick walls on edges.

Level 3:

* Perimeter + corner reinforcements.

Level 4:

* Full perimeter double layer.

---

# Deterministic Placement Pattern

Define function:

```python
generate_perimeter_positions(level, grid_width, grid_height)
```

Pure function.
No randomness.

---

# PHASE C — Remove Numeric Fortification

After combat reads grid:

* Delete `sector_fort_levels`
* Interception strength computed by:

  * Count of intact perimeter walls
  * Wall cluster continuity

But that is later.

---

# Why This Is Clean

* No sudden breaking change
* Fortification maps naturally to spatial defense
* Allows creative design later
* Preserves deterministic math

---

# Final Architecture After This Phase

You now have:

```plaintext
Sector
  ├── Grid
  ├── StructureInstances
  ├── Numeric Fortification (temporary)
  └── Abstract Assault Logic
```

Next phase will:

* Let assault read grid topology
* Replace numeric fortification fully

---

# What You Have Achieved

You are no longer abstract-only.

You now have:

> A deterministic spatial substrate ready for RTS hybrid integration.

Still Python.
Still engine-agnostic.
Still testable.

---

# Next Logical Step After This

Once grid is stable:

We design:

* Grid influence on assault pressure
* Wall integrity influence on breach
* Turret Manhattan range
* Drone repair routing

1. **Codex Execution Instructions (exact, authoritative, step-ordered)**
2. **Precise Fortification → Perimeter Auto-Generation Logic**

This is written so Codex can implement without ambiguity.

---

# 🔧 PART 1 — CODEX EXECUTION INSTRUCTIONS

## Phase 1: Deterministic Grid + Structure Instances

Codex has read access to full repository contents.
Codex must preserve determinism, snapshot compatibility, and existing test coverage.

---

# 🎯 OBJECTIVE

Introduce a fixed-size deterministic grid per sector and support structure placement, without modifying combat logic yet.

Combat must remain abstract.

No changes to assault routing in this phase.

---

# STEP 1 — Add Grid Constants

### File: `game/simulations/world_state/core/config.py`

Add:

```python
GRID_WIDTH = 12
GRID_HEIGHT = 12
```

Do not allow runtime resizing.

---

# STEP 2 — Add Grid Data Model

### File: `core/state.py`

Codex must:

### 2.1 Add GridCell class

```python
class GridCell:
    __slots__ = ("structure_id", "blocked")

    def __init__(self):
        self.structure_id = None
        self.blocked = False
```

Use `__slots__` to reduce snapshot bloat.

---

### 2.2 Add SectorGrid class

```python
class SectorGrid:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.cells = {
            (x, y): GridCell()
            for x in range(width)
            for y in range(height)
        }
```

No dynamic resizing.

---

### 2.3 Add to World State

In state initialization:

```python
self.sector_grids = {}
```

After sectors are initialized:

```python
from .config import GRID_WIDTH, GRID_HEIGHT

for sector_name in self.sectors:
    self.sector_grids[sector_name] = SectorGrid(GRID_WIDTH, GRID_HEIGHT)
```

Codex must confirm `self.sectors` exists and adjust accordingly.

---

# STEP 3 — Add Structure Instance Layer

### In `core/state.py`

Add:

```python
class StructureInstance:
    __slots__ = ("id", "type", "sector", "position", "hp", "max_hp")

    def __init__(self, id, type, sector, position, max_hp):
        self.id = id
        self.type = type
        self.sector = sector
        self.position = position
        self.hp = max_hp
        self.max_hp = max_hp
```

Add to state:

```python
self.structure_instances = {}
self.next_structure_id = 1
```

ID must be strictly incremental and deterministic.

---

# STEP 4 — Snapshot Integration

### File: `snapshot_migration.py`

Codex must:

Serialize:

* `sector_grids`
* `structure_instances`
* `next_structure_id`

Grid must serialize as primitive dict:

```python
{
  sector: {
    "width": grid.width,
    "height": grid.height,
    "cells": {
        "x,y": structure_id
    }
  }
}
```

On load:

* Reconstruct SectorGrid
* Reassign structure_id
* Set blocked flag from structure type registry

Codex must add backward-compatibility fallback:

If `sector_grids` not in snapshot:
→ initialize fresh grids.

---

# STEP 5 — Create Structure Type Registry

### File: `core/structures.py`

Add:

```python
STRUCTURE_TYPES = {
    "WALL": {
        "cost": 5,
        "max_hp": 150,
        "blocks": True,
        "power": 0,
        "logistics": 0,
    },
    "TURRET": {
        "cost": 20,
        "max_hp": 100,
        "blocks": True,
        "power": 5,
        "logistics": 1,
    },
    "GENERATOR": {
        "cost": 30,
        "max_hp": 120,
        "blocks": True,
        "power": -10,
        "logistics": 1,
    },
}
```

No logic in registry.

---

# STEP 6 — Add BUILD Command

### New File: `terminal/commands/build.py`

Command syntax:

```
BUILD <TYPE> <X> <Y>
```

Codex must implement:

1. Validate sector context
2. Validate type exists in STRUCTURE_TYPES
3. Validate bounds
4. Validate cell empty
5. Validate materials
6. Deduct cost
7. Create StructureInstance
8. Assign ID:

   ```python
   sid = f"S{state.next_structure_id}"
   state.next_structure_id += 1
   ```
9. Register instance
10. Mark grid cell
11. Set blocked flag from registry

Return concise success message.

---

# STEP 7 — Register Command

Update:

* `terminal/commands/__init__.py`
* `help.py`

Add:

```
BUILD <TYPE> <X> <Y>
```

---

# STEP 8 — Add Invariants

### File: `core/invariants.py`

Add checks:

* No duplicate positions
* Grid cell structure_id matches structure_instances
* next_structure_id monotonic

---

# STEP 9 — Tests

Create:

```
test_grid_building.py
```

Must include:

1. Grid exists for each sector
2. Successful BUILD
3. Out-of-bounds rejected
4. Duplicate placement rejected
5. Snapshot reload equality
6. Deterministic ID increment

Combat must remain unaffected.

---

# END CONDITION

Phase 1 complete when:

* Grid fully functional
* Snapshot stable
* Tests pass
* No changes to assaults.py

---

---

# 🧱 PART 2 — FORTIFICATION AUTO-GENERATION LOGIC

Now we design **precise perimeter wall generation**.

This replaces numeric fortification later.

Not implemented yet — design only.

---

# 🎯 Design Goal

Numeric fortification level (0–4) must map to a deterministic wall layout on the grid perimeter.

Constraints:

* Pure function
* No randomness
* No dependence on current grid contents
* Idempotent (same level → same layout)

---

# GRID ASSUMPTIONS

Let:

```
W = GRID_WIDTH
H = GRID_HEIGHT
```

Coordinates:

```
(0,0) → bottom-left
(W-1, H-1) → top-right
```

---

# LEVEL DEFINITIONS

## Level 0

No walls.

Return empty set.

---

## Level 1 — Single Perimeter Ring

All cells where:

```
x == 0
or x == W-1
or y == 0
or y == H-1
```

Return full outer ring.

---

## Level 2 — Double Perimeter

All cells where:

```
x in {0,1,W-2,W-1}
or y in {0,1,H-2,H-1}
```

Two layers thick.

---

## Level 3 — Reinforced Corners

Level 2 +
Corner reinforcement blocks:

Add 2x2 interior corner blocks:

Top-left:

```
(1, H-2), (2, H-2), (1, H-3), (2, H-3)
```

Repeat mirrored at all four corners.

---

## Level 4 — Full Double Ring + Cross Braces

Level 2 +
Internal brace lines:

Vertical center:

```
x = W//2
for y in 2 to H-3
```

Horizontal center:

```
y = H//2
for x in 2 to W-3
```

Creates internal defensive cross.

---

# FUNCTION SPECIFICATION

Codex must implement:

```python
def generate_perimeter_positions(level, width, height) -> set[tuple[int, int]]:
```

Rules:

* Level clamped 0–4
* Must not generate duplicates
* Must never exceed grid bounds
* Must be deterministic

---

# MIGRATION STRATEGY

When converting from numeric fortification:

1. Clear all perimeter WALL instances
2. Generate positions
3. Place WALL instances
4. Mark cells blocked
5. Update structure_instances

Important:

This must:

* Not touch interior non-wall structures
* Not override manually placed interior walls

Perimeter walls must be tagged:

```
structure.subtype = "PERIMETER"
```

So they can be removed cleanly later.

---

# WHY THIS IS CLEAN

* Deterministic mapping
* Scales with grid size
* Spatial meaning
* Future assault routing can use wall continuity
* Supports gradual numeric phase-out

---

# NEXT PHASE AFTER THIS

Once grid stable and perimeter logic ready:

We will:

* Replace interception mitigation math
* Compute “breach vector” from wall continuity
* Let assault pressure read weakest wall segment

But not yet.

---

You are now officially transitioning from abstract colony sim to spatial strategy engine — without breaking determinism.

Next topics for focus (update relevant docs now):

* I can design how assault reads grid topology.
* Or design drone pathing layer.
* Or design player WASD control integration model.
