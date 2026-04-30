# CUSTODIAN Documentation Drift Report

**Generated:** 2026-04-21
**Purpose:** Identify discrepancies between design docs and actual implementations

---

## Executive Summary

This report identifies significant drift between the documented design and implemented code across multiple systems. Some features are partially implemented, others are completely missing, and some undocumented features exist in code.

---

## Finding #1: SHADOW SYSTEM — Architecture Mismatch

### Design Doc: `design/02_features/implementation/SHADOW_SYSTEM_IMPLEMENTATION.md`

### What the Design Specifies
- TileMap-based shadows with dedicated `shadow_tilemap` layer
- Navigation system integration for walkability checks
- 6 public methods: `set_shadow_offset()`, `set_shadow_alpha()`, `get_shadow_count()`, etc.
- `initialize()` takes 4 parameters (floor, wall, shadow_tilemap, navigation_system)

### What the Code Actually Does
- Uses Node2D procedural drawing via `draw_rect()` instead of TileMap
- No shadow_tilemap reference exists
- No navigation system integration
- `initialize()` only takes 2 parameters (floor_tilemap, walls_tilemap)

### Discrepancies

| Aspect | Design Doc | Implementation |
|--------|-----------|---------------|
| Approach | TileMap-based shadows | Node2D procedural drawing |
| Shadow tilemap | Required reference | NOT implemented |
| Navigation integration | Used for walkability | NOT implemented |
| Public methods | 6 specified | Only 3 implemented |

### Documented but NOT Implemented
- `set_shadow_offset()`, `set_shadow_alpha()`, `get_shadow_count()`
- `_is_walkable()` utility

### Implemented but NOT Documented
- `_edge_cells` / `_corner_cells` caching (design used `_floor_cells` / `_wall_cells`)
- Export parameters for runtime tuning

### Action Required
- [ ] Update design doc to reflect Node2D procedural approach, OR
- [ ] Implement TileMap-based shadow layer if that's the desired approach

---

## Finding #2: WEAPON DATA SYSTEM — Incomplete Factory

### Design Docs: 
- `design/features/implementation/WEAPON_DATA_INTEGRATION.md`
- `design/features/implementation/WEAPON_DATA_INTEGRATION_CODE.md`

### What the Design Specifies
- Simple two-section JSON: `stats` (10 fields) + `ammo`
- Files in `res://assets/weapons/data/`

### What the Code Actually Does
- JSON schema has 20+ fields across multiple sections
- Factory reads only 10 core stats, ignores everything else
- Files in `res://content/weapons/data/`

### Discrepancies

| Finding | Status |
|---------|--------|
| Path mismatch | `assets/weapons/` → `content/weapons/` |
| Magazine size | Inconsistent naming (`stats.magazine_size` vs `ammo.capacity`) |
| Extended stats | Factory ignores `crit_chance`, `crit_multiplier`, `stagger`, `pellets` |
| Full schema ignored | Handling, animation, projectile, sounds, VFX, mod slots, AI config NOT read |

### Critical Gap
The design doc specifies a simple 10-field structure, but the actual JSON schema has 20+ fields. The factory only reads 10 stats, leaving significant data unused.

### Action Required
- [ ] Align magazine size field naming (decide which is authoritative)
- [ ] Add crit/stagger stats to factory, OR simplify the JSON schema
- [ ] Update design doc to reflect full schema scope

---

## Finding #3: PROCGen — Fundamental Mismatch

### Design Docs:
- `design/03_architecture/REGION_GENERATION_SYSTEM.md`
- `design/00_meta/PROCGEN_PIPELINE_CORRECTION.md`

### What the Design Specifies
- Graph-first, template-based generation
- Authored room templates with metadata (Edgar/Tiled)
- CampaignScenario input
- Biome/Threat system that affects structure
- Objectives/Hazards as first-class generation outputs
- 10-step pipeline

### What the Code Actually Does
- Classic BSP + Cellular Automaton dungeon generation
- Random procedural rectangles, not authored templates
- Just seed + parameters (no scenario input)
- Not implemented: biome, threat, objectives, hazards

### Discrepancies

| Document Says | Code Does |
|---------------|------------|
| Graph-first, template-based generation | BSP + Cellular Automaton |
| Authored room templates with metadata | Random procedural rectangles |
| CampaignScenario input | Just seed + parameters |
| Biome/Threat affects structure | Not implemented |
| Objectives/Hazards as outputs | Not implemented |
| 10-step pipeline | Simple raw array output |

### What's Implemented (foundation only)
- Basic BSP room partitioning
- Room adjacency detection via edge overlap
- Corridor routing
- Cellular automaton terrain smoothing

### Missing Components
- RegionGraph / RegionNode / RegionEdge classes
- CampaignScenario → RegionSpec conversion
- Biome system, threat profiles, difficulty conditioning
- Template taxonomy, room metadata

### Action Required
- [ ] Decide if graph-first architecture is the target, OR simplify docs to match current BSP implementation

---

## Finding #4: COMPOUND TILE SYSTEM — Not Implemented (SIMPLIFIED APPROACH ADOPTED)

### Design Doc: `design/03_architecture/COMPOUND_TILE_SYSTEM.md`

### What the Original Design Specifies
- 15 structural tile types (Wall_Standard, Wall_Reinforced, Door_Secure, Turret_Mount, etc.)
- CompoundTileState resource with HP/damage/power/repair semantics
- TileRegistry keyed by Vector2i
- Power conduit graph routing
- Full damage state machine (intact → damaged → critical → destroyed)
- Signals for damage, destruction, repair, power changes
- Marked as "completed" in progress tracker (INCORRECT)

### What the Code Actually Does
- **THIS SYSTEM DOES NOT EXIST**

### Reality Check
- `chunk/chunk/` directory contains **Aseprite file format parsers** (sprite tool format), NOT compound tile code
- Actual `compound/rooms/` has room template assembly (room_loader.gd, room_graph.gd, layout_assembler.gd)
- No CompoundTileState, no CompoundTileType enum, no damage system, no power routing

### Decision Made: SIMPLIFIED IMPLEMENTATION
After reviewing the complexity vs. benefit, we are implementing a **bounded, simpler version**:

**What's NOT being built:**
- 15 structural tile types with individual HP tracking
- Full damage state machine per tile
- Tile registry keyed by Vector2i

**What's WILL be implemented:**
- Add `power_conduit` marker type to room templates (like existing `turret_mount`)
- Spawn PowerNode actors at marker positions when room layout is assembled
- Connect PowerNodes to existing power.gd distribution system
- Reuse existing marker → world offset pattern from layout_assembler.gd

**See new spec:** `design/03_architecture/SIMPLIFIED_POWER_IN_ROOMS.md`

### Action Required
- [x] Decide on simplified approach (DONE)
- [ ] Implement simpler power-in-rooms system

---

## Finding #5: ENEMY DIRECTOR — Tuned Different from Design

### Design Doc: `design/02_features/enemy_director/implementation.md`

### What the Design Specifies
- Budget formula: `threat * 1.5`
- Conditional objective selection: "If power is damaged, target power 60%"

### What the Code Actually Does
- Budget formula: `threat * 0.65` (tuned ~57% lower)
- Weighted random objective selection (always considers all objectives)

### Discrepancies

| Aspect | Design Spec | Implementation |
|--------|-------------|----------------|
| Budget multiplier | `threat * 1.5` | `threat * 0.65` |
| Objective selection | Damaged-power conditional | Weighted random |
| AttackPlan class | Used | NOT used |

### Note
The implementation was tuned for pacing (0.65 scale) as noted in implementation date of 2026-03-30.

### Action Required
- [ ] Update design doc to reflect actual budget formula, OR
- [ ] Restore design formula if that's the intended behavior

---

## Finding #6: POWER SYSTEM — Minor Value Differences

### Design Doc: `design/02_features/power/POWER_SYSTEMS_GODOT.md`

### What the Design Specifies
- Damaged state efficiency: 0.75
- Power node max_output: 100

### What the Code Actually Does
- Damaged state efficiency: 0.6 (NOT 0.75)
- Added "critical" state at 0.3 (NOT in design)
- Power node max_output: 120 (default)

### Discrepancies

| Aspect | Design | Code |
|--------|--------|------|
| Damaged efficiency | 0.75 | 0.6 |
| Critical state | Not defined | 0.3 (added) |
| Max output | 100 | 120 |

### Action Required
- [ ] Update design doc to reflect actual values, OR fix the code to match design

---

## Consolidated Action Items

| # | System | Priority | Action |
|---|--------|----------|--------|
| 1 | Compound Tile | HIGH | Decide: implement full system or update docs to room assembly |
| 2 | ProcGen | HIGH | Decide: target graph-first arch or simplify docs |
| 3 | Shadow System | MEDIUM | Update docs to reflect Node2D approach |
| 4 | Enemy Director | MEDIUM | Update budget formula in docs |
| 5 | Weapon Data | LOW | Fix magazine size naming, add crit stats |
| 6 | Power | LOW | Update values in docs |

---

## Recommendations Summary

1. **Critical:** The Compound Tile System and ProcGen architecture docs describe significantly more ambitious systems than what's implemented. Either invest in completing them or align the docs with reality.

2. **Shadow System:** Was designed as TileMap-based but implemented as Node2D procedural. Update either the design or the code.

3. **Weapon Data:** The JSON schema has 20+ fields but factory only reads 10. Either expand the factory or simplify the schema.

4. **Enemy Director:** Was tuned from 1.5 to 0.65 budget multiplier. Either update docs or restore original formula.

---

*End of Report*