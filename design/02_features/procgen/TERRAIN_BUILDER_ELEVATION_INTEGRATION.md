# CUSTODIAN Terrain Builder: Elevation, Cliffs, and Impassable Terrain Integration

Status: complete
Target runtime: Godot 4.x
Primary implementation area: `custodian/game/world/procgen/`
Supporting runtime data: `custodian/content/tiles/elevation/`, `custodian/content/tiles/mountain_cliffs/`
Supporting docs: `custodian/docs/ai_context/CURRENT_STATE.md`

## Goal

Implement a dedicated terrain builder layer in the current CUSTODIAN procgen process.

The terrain builder owns baseline terrain metadata, blocked mountain/cliff terrain, a small deterministic industrial elevation structure, and movement validation rules. It keeps tile visuals separate from gameplay metadata so later movement, pathing, and combat systems can consume height/traversal data without depending on art placement.

## Implemented V1 Scope

- Dedicated builder files under `custodian/game/world/procgen/terrain/`.
- Elevation metadata stored through `custodian/game/world/elevation/elevation_map.gd`.
- Terrain generation flow inside `ProcGenTilemap` now calls the builder after base floor/wall capture and before props/spawns.
- Baseline ground fills all current procgen floor cells.
- One deterministic mountain wall region can be stamped as blocked terrain.
- One deterministic industrial raised platform can be stamped with a single ramp/stair access.
- Baseline connectivity is validated and rescued before terrain feature passes run, so reserved-region elevation,
  ascent-route terrain, mountain boundaries, and platforms are only discarded when they newly break an already-normalized
  baseline rather than being blamed for pre-existing disconnected floor islands.
- Connectivity validation prevents terrain features from isolating spawn/objective cells. Required cells are semantic
  anchors: spawn, early room centers, interior thresholds, compound ingress, intent graph required cells, and
  deterministic road/parking samples rather than every road or parking tile. If the final feature stack still
  disconnects required cells, the rescue pass force-carves deterministic walkable corridors from the start cell to
  every missing required cell before fallback is allowed.
- Spawn/prop candidate helpers reject blocked/drop/ledge cells.
- Debug logging reports terrain seed, generation mode, map size, required/missing cell counts, total and baseline
  rescue-carved cell counts, blocked/elevated/ramp counts, region counts, and fallback state. Candidate-evaluation
  rollback warnings are retained in the TerrainBuilder result but are not pushed as immediate warnings unless
  fallback/fatal conditions occur.

## Non-Goals

This pass intentionally does not implement jumping, climbing, falling, vertical collision motion, projectile arcs, height-based combat bonuses, or a full TileSet rewrite. Actor traversal enforcement remains deferred. Elevation metadata currently supports procgen validation, spawn/prop filtering, visual stamping, and level-data export, but it does not yet block operator, vehicle, or enemy movement.

## Runtime Files

- `custodian/game/world/procgen/terrain/terrain_builder.gd`
- `custodian/game/world/procgen/terrain/terrain_region.gd`
- `custodian/game/world/procgen/terrain/terrain_tile_ids.gd`
- `custodian/game/world/procgen/terrain/terrain_debug_overlay.gd`
- `custodian/game/world/elevation/elevation_map.gd`
- `custodian/game/world/procgen/proc_gen_tilemap.gd`
- `custodian/tools/validation/terrain_builder_smoke.gd`

## Terrain Metadata

Height convention:

- `-1`: drop/chasm/void
- `0`: normal ground
- `1`: elevated platform/plateau
- `2`: reserved for later

Traversal convention:

- `walkable`
- `blocked`
- `ledge`
- `ramp`
- `stair`
- `drop`

Movement may cross equal-height adjacent cells. Height changes of one level are allowed through stairs or through directional ramps when approach direction matches the ramp metadata. Blocked, ledge, and drop cells are not spawn-valid.

## Visual Mapping

The builder returns symbolic tile IDs from `TerrainTileIds` rather than hardcoded atlas coordinates.

The active procgen TileSet now has registered terrain sources for industrial elevation and mountain/cliff art. `ProcGenTilemap` resolves `TerrainTileIds` symbols through `TERRAIN_TILESET_SOURCES`, currently mapped to source IDs `32..59` in `res://content/tiles/tilesets/procgen_world_tileset.tres`.

Baseline terrain metadata must not repaint ordinary procgen floor/wall cells by default. Baseline floor and existing blocked/wall cells use an empty tile ID as a visual no-op.

Only explicit terrain features should write visual tiles:

- industrial elevated floors
- industrial ledges
- ramps/stairs
- mountain walls
- cliff/drop tiles

If a tile source is missing, terrain metadata should remain valid and the visual pass should fail safely without corrupting baseline floor/wall art.

## Validation

The smoke validation script checks deterministic output, connectivity, ramp access, spawn validity, and missing tile mapping tolerance:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_terrain_required_cells_smoke.gd
```

## Current Runtime Notes

- The rescue pass updates the same metadata consumed by validation: `blocked_cells`, `height_by_cell`,
  `traversal_by_cell`, and `ramp_dir_by_cell`.
- `ProcGenTilemap.get_level_data()` exports TerrainBuilder fallback/connectivity/rescue status so contract candidate
  scoring can reject terrain fallback maps and excessive rescue-carve maps before final visual generation.
