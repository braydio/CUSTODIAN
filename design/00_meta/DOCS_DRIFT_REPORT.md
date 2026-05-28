# CUSTODIAN Documentation Drift Report

**Generated:** 2026-04-21
**Purpose:** Track discrepancies between design documents and actual implementations
**Canonical source:** This is the single authoritative drift report. The superseded `DOCUMENTATION_DRIFT_REPORT.md` has been merged into this document and removed.

---

## Executive Summary

| System | Design Claims | Actual State | Gap Severity |
|--------|--------------|-------------|-------------|
| Shadow System | TileMap-based | Node2D procedural | Medium |
| Weapon Data | 10-field structure | Schema has 20+, factory reads 10 | Medium |
| ProcGen | Graph-first, template-driven | BSP + Automaton Foundation | Low (Phased) |
| Compound Tile | Complete (15 types) | NOT IMPLEMENTED | High |
| Enemy Director | threat × 1.5 | threat × 0.65 (tuned) | Low |
| Power | Damaged = 0.75 | Damaged = 0.6 | Low |

---

## Detailed Findings

### 1. SHADOW SYSTEM — Architecture Mismatch

**Location:** `design/02_features/implementation/SHADOW_SYSTEM_IMPLEMENTATION.md` vs `custodian/game/systems/core/systems/shadow_system.gd`

| Aspect | Design Doc | Implementation |
|--------|-----------|---------------|
| Approach | TileMap-based shadows | Node2D procedural `draw_rect()` |
| Initialize params | 4 (floor, wall, shadow_tilemap, nav) | 2 (floor_tilemap, walls_tilemap) |
| Caches | `_floor_cells`, `_wall_cells` | `_edge_cells`, `_corner_cells` |

**Documented but NOT implemented:**
- `shadow_tilemap` reference
- `navigation_system` integration
- `set_shadow_offset()`, `set_shadow_alpha()`, `get_shadow_count()`

**Recommendation:** Update design doc to reflect Node2D approach. Add note that TileMap path is aspirational.

---

### 2. WEAPON DATA — Schema/Factory Mismatch

**Location:** `design/features/implementation/WEAPON_DATA_INTEGRATION*.md` vs `custodian/game/systems/core/systems/weapon_definition_factory.gd`

| Finding | Status |
|---------|--------|
| Path | `assets/weapons/` → `content/weapons/` (works) |
| Extended stats | Factory ignores: `crit_chance`, `crit_multiplier`, `stagger`, `pellets` |
| Full sections ignored | handling, animation, projectile, sounds, VFX, mod_slots, ai_usage |

**Critical:** JSON schema defines 20+ fields, factory only reads 10.

**Recommendation:** Either (A) add missing stats to factory, OR (B) simplify schema to match current factory.

---

### 3. PROCGen — Phased Implementation

**Location:** `design/03_architecture/REGION_GENERATION_SYSTEM.md` vs `custodian/game/world/procgen/`

**STATUS: This is the correctly tracked system.**

| Phase | Description | Status |
|-------|------------|--------|
| **Phase 1** | BSP room partitioning + Cellular Automaton | ✅ IMPLEMENTED |
| **Phase 2** | Room template metadata + Biome selection | 📋 BACKLOG |
| **Phase 3** | Graph-first mission assembly | 📋 BACKLOG |
| **Phase 4** | Full scenario conditioning | 📋 BACKLOG |

**What's implemented:**
- BSP splitting (bsp.gd)
- Room adjacency via edge overlap
- Cellular automaton smoothing (automaton.gd)
- Corridor routing (router.gd)
- Destructible walls (runtime_wall_segment.gd)

**What's NOT implemented (Target):**
- RegionGraph / RegionNode classes
- CampaignScenario → RegionSpec
- Biome system, threat profiles
- Template taxonomy with metadata

**Recommendation:** Keep design doc, add "Phase 1 Complete" markers. Current implementation IS the foundation.

---

### 4. COMPOUND TILE SYSTEM — NOT IMPLEMENTED

**Location:** `design/03_architecture/COMPOUND_TILE_SYSTEM.md`

| Document Claims | Reality |
|---------------|---------|
| 15 structural tile types | DOES NOT EXIST |
| CompoundTileState resource | DOES NOT EXIST |
| HP/damage/repair semantics | DOES NOT EXIST |
| Marked as "complete" | FALSE |

**NOTE:** The `chunk/` directory contains Aseprite file parsers (cel, layer, palette), NOT compound tiles. Misleading name.

**Current approach:** Room template assembly (room_loader.gd, room_graph.gd, layout_assembler.gd)

**Recommendation:** Either implement full system OR update design doc to reflect room assembly as current approach and mark CompoundTile as aspirational.

---

### 5. ENEMY DIRECTOR — Budget Tuning

**Location:** `design/02_features/enemy_director/implementation.md` vs `custodian/game/systems/core/systems/enemy_director.gd`

| Aspect | Design Spec | Implementation |
|--------|-----------|--------------|
| Budget multiplier | `threat × 1.5` | `threat × 0.65` |
| Objective selection | Conditional (damaged power → target) | Weighted random |

**Note:** Implementation was tuned for pacing. Design formula would spawn ~57% more enemies.

**Recommendation:** Update design to reflect 0.65 as baseline with note that tuning is tunable.

---

### 6. POWER SYSTEM — Value Discrepancies

**Location:** `design/02_features/power/POWER_SYSTEMS_GODOT.md` vs `custodian/game/systems/core/systems/power.gd`

| Finding | Design | Code |
|---------|--------|------|
| Damaged efficiency | 0.75 | 0.6 |
| Critical state | N/A | 0.3 |
| Max output | 100 | 120 |

**Recommendation:** Update design doc to match code values.

---

## Action Items (Priority Order)

| Priority | Item | Approach |
|----------|------|---------|
| **1** | ProcGen | ✅ Already tracked — add "Phase 1 Complete" to design doc |
| **2** | Shadow System | Update design to reflect Node2D approach |
| **3** | Weapon Data | Add crit/stagger to factory OR simplify schema |
| **4** | Power | Update design values to match code |
| **5** | Enemy Director | Update design formula to 0.65 baseline |
| **6** | Compound Tile | Decide: implement OR mark aspirational |