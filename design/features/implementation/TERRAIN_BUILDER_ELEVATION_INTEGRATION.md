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
- Connectivity validation prevents terrain features from isolating spawn/objective cells.
- Spawn/prop candidate helpers reject blocked/drop/ledge cells.
- Debug logging reports terrain seed, map size, blocked/elevated/ramp counts, region counts, and fallback state.

## Non-Goals

This pass intentionally does not implement jumping, climbing, falling, vertical collision motion, projectile arcs, height-based combat bonuses, or a full TileSet rewrite. Active TileSet mapping still uses safe placeholders unless the new art is explicitly wired into the scene's TileSet later.

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

Movement may cross equal-height adjacent cells. Height changes of one level are allowed only when the source or destination cell is a ramp or stair. Blocked, ledge, and drop cells are not spawn-valid.

## Visual Mapping

The builder returns symbolic tile IDs from `TerrainTileIds` rather than hardcoded atlas coordinates. `ProcGenTilemap` currently resolves those symbols to safe placeholder floor/wall cells using the existing TileMap configuration. The new industrial and mountain PNG assets can be added to the active TileSet later without changing the terrain metadata contract.

## Validation

The smoke validation script checks deterministic output, connectivity, ramp access, spawn validity, and missing tile mapping tolerance:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/terrain_builder_smoke.gd
```
