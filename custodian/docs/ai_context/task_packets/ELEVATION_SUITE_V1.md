# Elevation Suite V1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-20
- Created: 2026-05-20
- Last updated: 2026-05-20

## Task

Begin implementation of the contained elevation suite from `design/ELEVATION.md`, then audit `custodian/content/tiles/` for existing elevation/cliff assets before tracking any missing production art.

## Outcome

- Script-owned elevation metadata exists independently from visual tiles.
- Procgen can stamp a deterministic first elevation/platform metadata slice without requiring final art.
- Runtime consumers can query cell height, traversal type, and cardinal traversal permission.
- Asset audit found the industrial elevation runtime kit under `custodian/content/tiles/elevation/industrial/`, the source Aseprite file at `custodian/content/tiles/elevated_industrial.aseprite`, and the mountain cliff runtime kit under `custodian/content/tiles/mountain_cliffs/`.
- Incorrect missing-elevation-art tracker entries were removed from both required asset tracker copies.
- `procgen_world_tileset.tres` now registers the elevation/cliff PNGs as source IDs `32..59`, and `ProcGenTilemap` maps terrain-builder symbolic tile IDs to those sources during terrain visual application.
- The false 100x100 startup fallback warning was removed by disabling `ProcGen2` auto-generation in `proc_gen_map.tscn`; contract generation now drives the real profiled generation pass.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/ELEVATION.md`
- Active runtime/docs files: `custodian/game/world/elevation/`, `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/docs/ai_context/*`
- Historical reference only: older procgen/elevation-like portal platform notes

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/elevation/`
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/procgen.gd`
  - `custodian/game/world/procgen/proc_gen_map.tscn`
  - `custodian/content/tiles/tilesets/procgen_world_tileset.tres`
  - `custodian/tools/validation/terrain_builder_smoke.gd`
  - `REQUIRED_ASSETS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/tiles/`
  - `custodian/game/world/procgen/`
- Out-of-scope areas:
  - new generated production art
  - full pathfinding rewrite

## Constraints

- Determinism concerns: elevation stamps must be derived from existing procgen seed/hash behavior.
- Simulation/UI boundary concerns: art remains presentation; traversal metadata is authoritative.
- Asset requirements: clean elevation and mountain-cliff PNGs exist; do not re-add them to `REQUIRED_ASSETS.md` unless a specific missing tile is discovered.
- Compatibility or migration concerns: existing procgen navigation and floor/wall generation must keep working.
- Clarifying questions or assumptions: the first visual slice uses the existing Floor/Walls TileMapLayer split instead of adding separate `ElevationTileMap` / `ShadowTileMap` layers; metadata remains authoritative for traversal.

## Implementation Plan

1. Add `ElevationMap` with height/traversal metadata, platform stamping helpers, and traversal checks.
2. Wire `ProcGenTilemap` to own/query an `ElevationMap` and stamp a deterministic first raised slab metadata zone.
3. Update asset trackers and active docs; validate changed scripts and full headless load.

## Acceptance

- Runtime behavior:
  - `ProcGenTilemap` exposes elevation data and traversal checks.
  - A deterministic first elevated platform metadata zone can be generated and rendered with the existing industrial elevation tiles.
  - Terrain-builder blockers render through registered mountain/elevation wall sources instead of generic placeholder walls.
  - Existing procgen generation still loads.
- Documentation:
  - Current state and file index mention elevation V1.
- Path/reference validation:
  - New script path loads under Godot.
- Manual validation:
  - Existing industrial elevation and mountain cliff art paths are verified under `custodian/content/tiles/`.
  - Required asset trackers do not list incorrect elevation PNG requests.
  - Full headless boot does not emit the false pre-profile 100x100 terrain-builder fallback warning.
- Automated/headless validation:
  - Godot check-only for changed scripts and full headless load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No; `design/ELEVATION.md` is the active request source.

## Completion Notes

- Implemented: `ElevationMap` metadata/traversal core, procgen elevation-map ownership/query helpers, deterministic raised-platform metadata stamping, `elevation_cells` level-data export, elevation smoke validation script, TileSet source registration for elevation/cliff PNGs, terrain-builder symbolic tile visual mapping, and startup auto-generation gating for the contract map scene.
- Asset audit: existing elevation art was found under `custodian/content/tiles/elevation/industrial/` and `custodian/content/tiles/mountain_cliffs/`; incorrect required-asset entries for those PNGs were removed from both tracker copies.
- Validated: Godot check-only passed for `elevation_map.gd`, `proc_gen_tilemap.gd`, `procgen.gd`, `terrain_builder.gd`, and `custodian_contract_map.gd`; `elevation_map_smoke.gd` and `terrain_builder_smoke.gd` passed; full headless `res://scenes/game.tscn` load completed successfully with accepted terrain-builder passes reporting `fallback=false`.
- Deferred: dedicated visual layer split, navigation-cost enforcement, and full movement/pathing integration through elevation traversal are deferred; production elevation PNG delivery is not currently blocked.

## Next Steps

- Next action: add the dedicated `ElevationTileMap` / `ShadowTileMap` split if visual debugging requires it, then route movement/pathing through `can_traverse_elevation()`.
- Best starting files: `custodian/game/world/elevation/elevation_map.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: `design/ELEVATION.md`, existing procgen region metadata.
- Validation to run: Godot check-only and full headless load.
- Blockers or open questions: no missing elevation PNG blocker found; active blocker is movement/pathing integration beyond spawn/prop filtering and contract-map scoring.
