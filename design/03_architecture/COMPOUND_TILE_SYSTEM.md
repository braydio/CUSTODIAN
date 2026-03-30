# `design/20_features/in_progress/COMPOUND_TILE_SYSTEM.md`

# Compound Tile System

**Project:** CUSTODIAN
**Status:** Required After Runtime Stabilization; Can Progress in Parallel with Campaign Systems Once Compound Runtime Authority Is Stable
**Priority:** High
**Depends On:** Runtime World & Camera Stabilization
**Supports:** Campaign Flow, World Transition, Repair Gameplay, Sector Damage, Turret Placement, Power Routing, Defensive Readability
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-03-27

---

## 1. Purpose

Define the authoritative system for representing the compound as a tile-governed structural runtime rather than a loose visual shell. The Compound Tile System exists to make the base physically legible, mechanically destructible, strategically meaningful, and compatible with all future systems that need to reason about the compound as a structure.

This system is not just “better walls.” It is the structural substrate for:

- compound buildings
- wall integrity
- breach formation
- door and gate semantics
- power conduit routing
- turret mount rules
- cover and lane shaping
- repair gameplay
- sector damage propagation
- prep-phase fortification
- assault pressure against actual built space

The compound is the home-state world context. If it remains a mostly decorative or loosely inferred arrangement, every system built on top of it becomes vague. This file defines how the compound becomes a real runtime object.

---

## 2. Why This System Exists

The project already has:

- a Godot-native runtime
- operator traversal and combat
- wave spawning
- turret runtime
- procgen map loading/promotion
- world/Hub/campaign direction
- sector and damage systems in partial or in-progress form

What it does not yet have is a fully authoritative structural model of the compound as an interactable, destructible, routable built environment.

Right now, the compound risks existing in an awkward in-between state:

- visually tile-based, but not mechanically authoritative
- sector-shaped, but not structurally granular
- damageable in concept, but not expressed through real wall segments, conduits, doors, or mounts
- navigable, but not fully reasoned about as a defensive construction layer

This system fixes that by establishing the compound as:

> a tile-authored structural world whose runtime semantics are derived from tile truth, not invented later by scene guesswork.

---

## 3. Design Intent

The Compound Tile System should satisfy six major design goals.

### 3.1 One Structural Truth

The compound must have one authoritative structural representation. Every later system must be able to ask:

- what exists here?
- is it solid?
- is it powered?
- is it damaged?
- is it blocking?
- is it routable?
- is it repairable?
- can something mount here?

and receive a consistent answer.

### 3.2 Preserve TileMap Efficiency

Do not replace Godot TileMap with an unnecessarily heavy entity-per-brick simulation across the entire compound. The system must use tilemap authority intelligently and only promote tile cells into richer runtime state where needed.

### 3.3 Be Mechanical, Not Merely Visual

A wall is not just art. A tile may carry:

- collision
- health
- repair semantics
- power function
- door behavior
- breach potential
- mount compatibility
- damage state transitions

### 3.4 Support Tactical Readability

The player should be able to read:

- where the perimeter is weak
- where breach points exist
- where doors/gates provide access
- where power travels
- where turrets can be placed
- where defensive lines can form

### 3.5 Allow Controlled Granularity

The system should be more granular than “whole sector healthy / damaged,” but it does not need to simulate arbitrary voxel destruction. Granularity should exist where it produces meaningful tactical consequences.

### 3.6 Remain Compatible with Procgen and Hybrid Layouts

This system must work whether the compound is:

- statically authored
- procgen-generated
- assembled from room templates
- partially rebuilt between campaigns
- modified during prep

---

## 4. Non-Goals

This file does **not** define:

- biome region generation outside the compound
- Hub scenario generation
- mission transition flow
- full save schema for all systems
- combat balance details
- animation implementation
- complete power system design beyond tile-conduit implications
- general-purpose construction game tooling with infinite free-form building

It defines the structural tile substrate for the compound only.

---

## 5. Core Principle

This is the most important rule in the file:

> **TileMap remains the spatial source of truth.**

Do not create a second disconnected grid that competes with the actual tilemap.

The correct architecture is:

```plaintext id="6b3b6w"
Compound TileMap Layers
    -> structural metadata lookup
    -> runtime tile state registry
    -> damage / repair / power / interaction semantics
    -> collision / navigation updates
```

Not:

```plaintext id="g9qmi2"
visual tilemap
    + separate gameplay grid
    + separate wall entity map
    + separate power map
```

That path creates three or four conflicting truths and will rot.

---

## 6. Authoritative Representation Model

The compound should be represented through a layered structural model.

### 6.1 Layer A: Spatial Tile Authority

This is the TileMap / TileMapLayer itself:

- floor cells
- wall cells
- door cells
- conduit cells
- mount cells
- decor cells

### 6.2 Layer B: Structural Tile Registry

A runtime registry maps meaningful cells to structural state objects:

- current HP
- max HP
- type
- powered state
- destroyed state
- repairable state
- connectivity metadata
- damage visual state

### 6.3 Layer C: Derived Systems

Systems derive from the tile + registry pair:

- collision rebuild
- navigation walkability
- power routing
- turret mount eligibility
- breach detection
- cover generation
- repair targets
- sector damage summaries

---

## 7. Compound Scope

This system governs the home-base compound, including:

- outer perimeter walls
- sector building envelopes
- connecting corridors
- doorways and gates
- internal structural chokepoints
- powered conduits in or across walls
- turret mount hardpoints
- sector-adjacent reinforcement surfaces

It should support the canonical compound layout direction you already described elsewhere: sector-shaped built spaces linked by transit/corridor structure, with defense-relevant perimeter logic.

---

## 8. Why TileMap Must Stay Authoritative

There are three reasons this needs to be explicit.

### 8.1 Existing Navigation Already Uses Tile Truth

Your current navigation logic already builds pathability from floor cells and wall occupancy. The Compound Tile System must not break that relationship.

### 8.2 Procgen and Template Systems Already Think in Tiles

The current and planned world systems are already based around tilemap promotion, room templates, and structural layout grids. A non-tile structural model would split the architecture.

### 8.3 Visual, Collision, and Interaction Must Align

If the player sees a wall tile, the game should not secretly think the wall is elsewhere or represented by some detached invisible entity map.

---

## 9. Required System Responsibilities

The Compound Tile System owns the following responsibilities.

### 9.1 Structural Tile Classification

Identify which compound cells are mechanically relevant.

### 9.2 Structural Runtime State

Track current damage/power/repair/mount state for meaningful structural cells.

### 9.3 Destruction and Breach Updates

When a structural tile is damaged or destroyed, update:

- visual tile state
- collision
- navigation
- power continuity
- cover semantics
- mount validity if relevant

### 9.4 Repair Target Surface

Expose damaged tiles and compound structures as repair targets.

### 9.5 Power-Conduit Participation

Provide tile-level participation in conduit routing and structural dependency.

### 9.6 Tactical Feature Encoding

Support doors, gates, mounts, reinforcement classes, and sensor/utility walls.

### 9.7 Sector-Level Aggregation

Roll local tile damage upward into sector-level damage summaries where appropriate.

---

## 10. Structural Tile Taxonomy

The system should support a typed set of structural cells.

```gdscript id="4ok9ln"
enum CompoundTileType {
    NONE,
    WALL_STANDARD,
    WALL_REINFORCED,
    WALL_DESTRUCTIBLE,
    WALL_POWER_CONDUIT,
    WALL_SENSOR,
    DOOR_STANDARD,
    DOOR_SECURE,
    GATE_EXPANSION,
    TURRET_MOUNT,
    STRUCTURAL_COLUMN,
    BARRICADE,
    SECTOR_BOUNDARY,
    MAINTENANCE_PANEL
}
```

### 10.1 Notes on Scope

Not every type must ship immediately, but the taxonomy should be declared now so data shape does not drift.

---

## 11. Tile Type Intent

### 11.1 `WALL_STANDARD`

Baseline structural wall.

Use for:

- common interior walls
- common perimeter segments
- corridor definitions

Properties:

- destructible
- repairable
- blocks movement
- may provide cover
- medium HP

### 11.2 `WALL_REINFORCED`

High-integrity structural wall.

Use for:

- command core shell
- critical sector boundaries
- stronger perimeter nodes
- optional hub fortification upgrades later

Properties:

- high HP
- slower or impossible to breach depending on design phase
- repairable if damaged
- often higher power resilience

### 11.3 `WALL_DESTRUCTIBLE`

Explicitly weak wall designed to fail or be sacrificed.

Use for:

- old compromised sectors
- unstable partitions
- destructible tactical shortcuts
- salvage-prone weak barriers

Properties:

- low HP
- intended breach candidate
- may drop resources or debris
- repair possible but not always efficient

### 11.4 `WALL_POWER_CONDUIT`

Structural wall tile that is also part of a power route.

Use for:

- powered corridors
- sector feed lines
- relay chain boundaries
- defense-grid linking walls

Properties:

- blocks movement
- carries routing identity
- destruction can sever downstream systems
- damage state should be visually distinct

### 11.5 `WALL_SENSOR`

Utility wall carrying sensor or detection semantics.

Use for:

- defense-grid lines
- surveillance sections
- alert chokepoints

Properties:

- moderate HP
- utility loss on destruction
- potential recon/detection bonus
- should not be overused

### 11.6 `DOOR_STANDARD`

Normal open/close passage.

Properties:

- may open or remain closed by state
- blocks movement when closed
- supports damage and repair
- may participate in local access logic

### 11.7 `DOOR_SECURE`

High-integrity or privileged door.

Properties:

- higher HP
- stronger blockage semantics
- optional auth or mission-phase requirements
- can shape compound lockdown events later

### 11.8 `GATE_EXPANSION`

Larger passage tile or segment used for:

- hangar-scale movement
- large ingress/egress
- compound perimeter breach points
- future vehicle or cargo access

### 11.9 `TURRET_MOUNT`

A structural tile that explicitly supports turret placement.

Properties:

- usually not walkable
- high integrity
- can be powered
- can invalidate a turret if destroyed
- should anchor defense planning

### 11.10 `STRUCTURAL_COLUMN`

Non-wall support element.

Properties:

- blocks movement
- not necessarily a wall edge
- provides cover
- can help make interiors tactically interesting

### 11.11 `BARRICADE`

Lighter defensive obstruction.

Properties:

- destructible
- may provide partial cover
- lower HP than standard wall
- can be temporary or prep-built later

### 11.12 `SECTOR_BOUNDARY`

Special tile class representing a meaningful boundary between sector spaces.

Properties:

- may aggregate into sector integrity logic
- should not necessarily differ visually from a reinforced wall unless needed
- useful for reporting and propagation rules

### 11.13 `MAINTENANCE_PANEL`

Utility/interact tile embedded in structural surfaces.

Properties:

- not primary wall body
- may be repair interaction anchor
- can expose localized system fixes without demolishing structural clarity

---

## 12. Structural Tile State Model

Each structural cell needs a runtime state object.

```gdscript id="7ia8n2"
class_name CompoundTileState
extends Resource

var cell: Vector2i
var tile_type: int = 0

var max_hp: float = 100.0
var current_hp: float = 100.0

var is_destructible: bool = true
var is_repairable: bool = true
var is_destroyed: bool = false
var is_powered: bool = false
var is_open: bool = false               # for doors/gates
var damage_state: String = "intact"     # intact / damaged / critical / destroyed

var sector_id: String = ""
var conduit_group_id: String = ""
var mount_id: String = ""
var tags: Array[String] = []
```

### 12.1 Why This Object Exists

You need a mutable state layer that:

- survives visual tile changes
- supports damage and repair
- supports save/load
- can be queried by other systems
- does not require one full scene node per structural cell

---

## 13. Registry Model

Use a registry keyed by cell coordinate.

```gdscript id="ylh77v"
var compound_tile_registry: Dictionary = {}  # Vector2i -> CompoundTileState
```

### 13.1 Important Rule

Only structurally meaningful cells enter the registry.

Do not populate every decorative floor or moss tile into this system.

### 13.2 Classification Source

The registry should be built from:

- tile source IDs
- atlas coords
- custom tile metadata
- layer membership
- optional authored tags in room/template source

---

## 14. Recommended TileMap Layer Model

The compound should use layered tilemaps with clear intent.

### 14.1 Floor Layer

Walkable ground, paths, sector flooring.

### 14.2 Structure Layer

Walls, columns, doors, gates, mounts.

### 14.3 Utility Layer

Conduits, sensors, maintenance panels, overlays.

### 14.4 Damage/Overlay Layer

Cracks, scorch, breach marks, warning decals, shadow overlays.

### 14.5 Collision/Navigation Implication

Collision and walkability should derive from structure state, not from decorative overlays.

---

## 15. Tile Metadata Strategy

This is critical.

Use TileSet custom data or a structured lookup table so each structural tile can advertise:

- `compound_tile_type`
- `base_hp`
- `destructible`
- `repairable`
- `blocks_movement`
- `supports_power`
- `supports_mount`
- `sector_boundary`
- `open_variant`
- `damaged_variant`
- `critical_variant`
- `destroyed_variant`

### 15.1 Why This Matters

The TileSet then becomes a declarative structural catalog rather than “just art.”

---

## 16. Source of Truth Rule

Lock this now:

> Tile coordinates and type come from the TileMap.
> Mutable status comes from `CompoundTileState`.
> Runtime world behavior is derived from the combination.

Not from scene node guesses.

---

## 17. Compound Build Pipeline

The compound tile system should construct its runtime state in a fixed sequence.

### Step 1 — Read Structural Tile Layers

Scan the compound structure layer(s).

### Step 2 — Classify Relevant Cells

Identify all structural cells and their types.

### Step 3 — Create Registry Entries

Create `CompoundTileState` per relevant cell.

### Step 4 — Build Derived Maps

Build:

- walkability blockers
- conduit groups
- mount points
- sector-boundary aggregations

### Step 5 — Bind to Systems

Expose registry to:

- repair system
- sector damage system
- power system
- turret placement system
- navigation/collision updater

### Step 6 — Validate Compound Structure

Check:

- doors exist where intended
- no impossible sealed sectors unless deliberate
- mounts valid
- sector IDs coherent
- outer boundary intact where required

---

## 18. Compound Tile Runtime Manager

Create a dedicated system owner.

```plaintext id="i3jzab"
custodian/core/systems/compound/compound_tile_system.gd
```

### 18.1 Responsibilities

- scan tilemaps
- build and own registry
- answer tile queries
- process damage and repair requests
- emit structural change signals
- trigger collision/nav rebuilds when needed
- provide aggregated sector summaries

### 18.2 Signals

Recommended signals:

```gdscript id="d990z4"
signal compound_tile_damaged(cell: Vector2i, state: CompoundTileState)
signal compound_tile_destroyed(cell: Vector2i, state: CompoundTileState)
signal compound_tile_repaired(cell: Vector2i, state: CompoundTileState)
signal compound_tile_power_changed(cell: Vector2i, state: CompoundTileState)
signal compound_structure_changed()
signal sector_integrity_changed(sector_id: String, integrity_ratio: float)
```

---

## 19. Damage Model

Damage must operate at tile granularity, but in a controlled way.

### 19.1 Damage Request API

```gdscript id="24c60j"
func apply_damage_to_cell(cell: Vector2i, amount: float, source_tags: Array[String] = []) -> bool
```

### 19.2 Damage Rules

- ignore if cell not structural
- ignore if non-destructible and not damageable
- subtract HP
- update `damage_state`
- if HP <= 0 and destructible, destroy tile
- emit signals
- trigger derived-system refresh if topology changed

### 19.3 Damage State Thresholds

Recommended initial thresholds:

- `intact`: > 66%
- `damaged`: 33%–66%
- `critical`: 1%–33%
- `destroyed`: 0%

### 19.4 Why Threshold States Matter

They support:

- readable visuals
- repair prioritization
- tactical threat awareness
- sector integrity summaries
- future fire/sparking/leak effects

---

## 20. Destruction and Breach Semantics

Destroying a wall tile is not only an HP event. It changes the compound.

### 20.1 On Destruction

The system must:

- mark state destroyed
- swap/remove structure tile
- update collision
- update navigation
- update power continuity if conduit
- update sector integrity if boundary
- invalidate mount if mount cell
- optionally place debris overlay or breach decal

### 20.2 Breach Semantics

A destroyed structural tile may create:

- new enemy ingress route
- new player shortcut
- new line-of-sight lane
- power failure downstream
- compromised sector boundary state

This is why tile destruction matters strategically.

### 20.3 Debris Rule

Do not immediately remove all evidence of destruction. Even if the tile becomes walkable, the breach should remain visually and tactically legible.

---

## 21. Repair Model

Repair must be able to target tile-level structure.

### 21.1 Repair Request API

```gdscript id="u53blg"
func apply_repair_to_cell(cell: Vector2i, amount: float) -> bool
```

### 21.2 Repair Rules

- only for registered structural cells
- only if repairable
- only if damaged or destroyed and rebuild policy allows it
- clamp to max HP
- update damage state
- if rebuilt from destroyed state, restore structure/collision/nav/power as needed

### 21.3 Destroyed-Tile Rebuild Policy

You need to decide early whether destroyed tiles can:

- be fully rebuilt in combat
- only be patched after combat
- be temporarily sealed by barricade substitute
- require materials

Recommended early policy:

- damaged tiles repair normally
- fully destroyed core walls require explicit rebuild interaction or materials later
- first implementation can allow simple full repair if that is faster, but the API should not assume that forever

---

## 22. Door and Gate System Semantics

Doors and gates require special handling because they are structural but stateful.

### 22.1 Door State Fields

- open / closed
- powered / unpowered if relevant
- locked / unlocked if relevant
- damaged / destroyed

### 22.2 Rules

- open door: no movement block
- closed door: movement blocked
- destroyed door: usually open breach
- power loss may default some secure doors to different behavior depending on doctrine later

### 22.3 Important Rule

A door is still a structural tile, not a detached gameplay exception unless animation or interaction nodes wrap it.

---

## 23. Power Conduit Semantics

Conduit walls are one of the most strategically important tile classes.

### 23.1 Conduit Participation

A conduit tile can be part of a connected structural power network.

### 23.2 Destruction Consequences

Destroying a conduit tile may:

- sever downstream powered defenses
- disable mounts
- disable doors
- reduce sector functionality
- alter terminal/system availability

### 23.3 Required System Integration

The compound tile system should not own full power simulation, but it must expose:

- conduit tile locations
- conduit continuity graph
- tile destruction/rebuild events

So the power system can recompute.

---

## 24. Turret Mount Semantics

A mount tile is a structural hardpoint.

### 24.1 Mount Rules

- must be structurally valid
- may require power
- may require adjacency or sector support rules
- if destroyed, mounted turret becomes:
  - disabled
  - detached
  - destroyed
  - or invalid until rebuilt

### 24.2 Why Mount Tiles Matter

They make turret placement legible and constrained. This is much better than “turrets can go anywhere on floor.”

---

## 25. Sector Aggregation Model

Tile damage should roll up into sector status.

### 25.1 Sector ID Assignment

Each structural tile may optionally carry:

- `sector_id`
- `boundary_weight`
- `criticality_weight`

### 25.2 Sector Integrity Score

Sector integrity can be derived from weighted structural tiles.

Example:

```gdscript id="1tbm0g"
sector_integrity = sum(current_hp * weight) / sum(max_hp * weight)
```

### 25.3 Why This Matters

The Sector Damage System can consume sector aggregates without needing to own every wall tile directly.

---

## 26. Collision and Navigation Updating

This is one of the highest-risk implementation areas.

### 26.1 Required Principle

Structural changes that alter passability must update both:

- collision
- navigation

### 26.2 Minimum Required Reactions

On destroy / rebuild / open / close:

- mark tile collision change
- update or rebuild relevant nav representation
- ensure AI and player agree on passability

### 26.3 Efficiency Strategy

Do not rebuild the entire world every time one tile changes if avoidable. Preferred approaches:

- local collision updates if supported
- batched nav rebuild after burst changes
- event coalescing during explosions or chain damage

---

## 27. Cover and Tactical Semantics

Later systems will want to know more than “is this passable?”

### 27.1 Structural Cover Classes

Tile types can advertise:

- no cover
- half cover
- hard cover
- obscuring structure

### 27.2 Why This Matters

Even if full cover mechanics are deferred, the tile system should preserve the information surface now so you do not need to retrofit it awkwardly later.

---

## 28. Procgen Compatibility

The compound tile system must support compound generation from:

- static scenes
- current procgen map promotion
- future room-template assembly
- partial rebuild flows

### 28.1 Requirement

As long as the promoted/generated world can produce structural layers and tile metadata, the compound tile system should be able to scan and initialize.

### 28.2 Important Rule

This file should not assume the compound is always hand-authored in one fixed scene.

---

## 29. Save / Load Requirements

Structural damage is campaign-critical and must persist.

### 29.1 Save Surface

At minimum, save:

- each registered structural cell ID/coord
- tile type
- current HP
- damage state
- door open/closed state
- power relevant flags
- destroyed/rebuilt status
- mount occupancy if applicable

### 29.2 Recommended Strategy

Do not save the whole tilemap blindly if base art is static. Save structural deltas against the base authored/generated map.

---

## 30. Debug Requirements

You will need strong debug tooling.

### 30.1 Structural Overlay

Show color-coded structural cells by type.

### 30.2 Integrity Overlay

Tint cells by HP state:

- green intact
- yellow damaged
- red critical
- black/empty destroyed

### 30.3 Conduit Overlay

Show powered conduit continuity groups.

### 30.4 Mount Overlay

Show valid/invalid turret mount cells.

### 30.5 Sector Aggregation Overlay

Show per-sector integrity values.

### 30.6 Query Debug

Click cell and print:

- type
- HP
- sector ID
- power state
- collision state
- mount ID
- tags

Without this, tile bugs will be painful.

---

## 31. Recommended Module Structure

```plaintext id="noe16s"
custodian/core/systems/compound/
    compound_tile_system.gd
    compound_tile_state.gd
    compound_tile_registry.gd
    conduit_graph.gd
    sector_integrity_aggregator.gd
```

Optional supporting files:

```plaintext id="ixow4q"
custodian/entities/compound/
    door_runtime.gd
    gate_runtime.gd
    turret_mount_runtime.gd
```

### 31.1 Recommended Responsibilities

#### `compound_tile_system.gd`

Main coordinator, scan/build/query/apply damage/repair.

#### `compound_tile_state.gd`

State object definition.

#### `compound_tile_registry.gd`

Optional helper for storage/query/indexing.

#### `conduit_graph.gd`

Conduit adjacency and continuity helper.

#### `sector_integrity_aggregator.gd`

Roll local structure into sector integrity summaries.

---

## 32. Recommended Query APIs

These should exist early.

```gdscript id="rqjlwm"
func has_structural_tile(cell: Vector2i) -> bool
func get_tile_state(cell: Vector2i) -> CompoundTileState
func get_tile_type(cell: Vector2i) -> int
func is_cell_blocking(cell: Vector2i) -> bool
func is_cell_destroyed(cell: Vector2i) -> bool
func is_cell_repairable(cell: Vector2i) -> bool
func is_cell_powered(cell: Vector2i) -> bool
func is_valid_mount_cell(cell: Vector2i) -> bool
func get_sector_integrity(sector_id: String) -> float
```

### 32.1 Why These Matter

Other systems should depend on query contracts, not directly poke the registry.

---

## 33. Build Order

### Phase 1 — Classification and Registry

- structural tile metadata
- registry build from tilemap
- debug overlay

### Phase 2 — Damage / Repair

- HP model
- damage states
- destruction/rebuild APIs
- visual tile state transitions

### Phase 3 — Collision / Navigation Sync

- wall destruction updates passability
- doors/gates change pathing
- nav refresh on topology change

### Phase 4 — Power and Mount Integration

- conduit continuity exposure
- mount validation
- downstream system hooks

### Phase 5 — Sector Aggregation

- weighted sector integrity summaries
- tie into repair/damage reporting

### Phase 6 — Save / Load and Polish

- persist structural deltas
- breach decals
- better visual damage overlays
- efficient batched updates

---

## 34. Failure Cases to Guard Against

### 34.1 Double Source of Truth

Tilemap says wall, registry says not wall, collision says maybe.

### 34.2 Decorative Damage Only

Walls look damaged but still behave fully intact.

### 34.3 Invisible Breaches

Passability changed but player cannot read it.

### 34.4 Registry Overgrowth

Every irrelevant tile becomes a runtime object and performance tanks.

### 34.5 Door Desync

Door sprite open but still blocking, or closed but passable.

### 34.6 Conduit Fiction

Conduit tiles exist visually but never matter mechanically.

### 34.7 Sector Integrity Meaninglessness

Sector health becomes abstract again because tile weighting is poor or disconnected.

### 34.8 Turret Mount Ambiguity

Players cannot tell where turrets belong or why a mount failed.

---

## 35. Acceptance Criteria

This file is complete when all of the following are true.

### Structural Authority

- [ ] compound structural cells are derived from tilemap truth
- [ ] registry exists only for meaningful structural cells
- [ ] systems query structural state through clear APIs

### Damage / Repair

- [ ] structural tiles can take damage
- [ ] damage changes state in a visible and mechanical way
- [ ] repair can restore damage states
- [ ] destroyed tiles can change topology according to policy

### Runtime Effects

- [ ] destruction/open/close can update collision
- [ ] destruction/open/close can update navigation
- [ ] conduit/mount semantics are queryable
- [ ] sector integrity can be aggregated from tiles

### Tactical Readability

- [ ] breaches are visible
- [ ] mount points are legible
- [ ] conduit lines are identifiable
- [ ] weak vs strong structure is readable

### Architecture

- [ ] TileMap remains the spatial source of truth
- [ ] no second competing structural grid exists
- [ ] save/load can preserve structural state or deltas

---

## 36. Exit Condition

This file is done when you can:

1. load the compound,
2. query structural tiles from the real tilemap,
3. damage a wall segment,
4. see it enter damaged and then destroyed states,
5. have collision/navigation change appropriately,
6. repair or rebuild it according to policy,
7. and have sector/power/defense systems consume the result without guessing.

That is the minimum viable Compound Tile System.

---

# Progress Tracking

## Completed Files

- [1] Runtime World & Camera Stabilization
- [2] Hub System (Meta Progression)
- [3] World Transition System
- [4] Region Generation System
- [5] Compound Tile System

## Still To Go

- [6] Campaign Flow & Game Loop
- [7] Integration Contract (Glue Layer)
