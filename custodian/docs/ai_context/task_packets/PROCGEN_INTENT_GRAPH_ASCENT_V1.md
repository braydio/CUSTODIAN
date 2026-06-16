# Procgen Intent Graph + Ascent V1

## Status

- Status: complete
- Owner: Codex
- Created: 2026-06-16
- Last updated: 2026-06-16

## Problem

Current procgen world progression has mostly been metadata layered over the existing BSP/corridor/cellular-automaton generator. The generated map still behaves like rooms/caves with later overlays rather than a deliberate route-first ascent with faction/story setpieces.

## Goal

Introduce a deterministic route-first worldgen intent graph that becomes the upstream shape authority for main route beats, ascent spine, branch pockets, faction site reservations, story room reservations, vista/reveal beats, terrain/elevation requests, and future encounter insertion.

The existing generator remains available as filler/detail generation, not the primary topology authority.

## Non-goals

- Do not delete the current procgen generator.
- Do not rewrite all pathfinding.
- Do not implement full stacked elevation.
- Do not create new production art.
- Do not convert every story room to final authored art in this pass.

## Branch Audit

- Work started from `main` at `7de91c34`, then branch `procgen-intent-graph-ascent-v1` was created as requested.
- `git fetch --all --prune` completed.
- No branch contained existing runtime `WorldgenIntent`, `IntentGraph`, or `AscentSpine` files to cherry-pick.
- Worldgen-relevant branch search found only older design references to `sector_graph_builder`, `maintenance_complex_generator`, `room_placer`, and `corridor_router` in `STARTER_MAP_PROCGEN.md`.
- Working tree was dirty before this task; unrelated operator/enemy/camera/docs changes were left untouched.

## Implementation Discovery

- `_fill_tilemaps()` location: `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- terrain-builder call location: `_apply_terrain_builder(map_size)`.
- road/parking enforcement order: road carving, wall visuals, ingress protection, road enforcement/pruning/visual refresh, then terrain and post-terrain road repair.
- foliage/prop placement order: after world progression, faction sites, story rooms, and streaming/runtime collision preparation.
- faction site placement order: `_place_faction_ambient_sites(map_size)` after world progression samples.
- story room placement order: `_place_story_rooms(map_size)` after faction activity sites.
- `get_level_data()` export location: `proc_gen_tilemap.gd`.
- `get_player_spawn()` exists? yes; used directly.
- `_ensure_world_progress_profile()` exists? yes; used directly.
- `claim_procgen_floor_rect_for_authored_scene_tiles()` exists? yes; used for V1 story/faction geometry reservations.
- `_generated_floor_cells` value shape: dictionary entries with source/atlas/alternative metadata; new worldgen writes preserve dictionary shape.
- TerrainTileIds preload name: `TerrainTileIdsScript`.
- ElevationMap traversal API names: `can_traverse`, `can_move_between`, `get_cell_data`, `is_valid_spawn_cell`.
- available validation scripts: `procgen_placeholder_roads_smoke.gd`, `procgen_ascent_style_smoke.gd`, `faction_story_sites_smoke.gd`, `procgen_authored_scene_authority_smoke.gd`, `terrain_builder_smoke.gd`, and `elevation_map_smoke.gd`.

## Implemented Slice

- Added route-first intent data models and deterministic ascent spine builder under `game/world/procgen/intent/`.
- Added `world_shape_mode` with default `ASCENT_FIELD`; `LEGACY_CAVE` keeps the old ProcGen cave substrate available without deleting it.
- Added `AscentFieldBuilder`, which turns the intent graph into the base exterior floor/wall authority instead of carving over the legacy BSP/corridor/cellular cave output.
- Added region footprint reservation from intent graph edges/nodes into floor cells and reserved region rects.
- Integrated `ProcGenTilemap` to branch substrate generation: `LEGACY_CAVE` runs the old ProcGen mask path, while `ASCENT_FIELD` clears base state, builds the graph, builds broad exterior ascent floor mass, places sparse exterior blockers, and then runs existing terrain/road/prop/faction/story passes.
- Carved ascent-field floor cells using the existing `_generated_floor_cells` dictionary shape and shared procgen wall-authority cleanup.
- Fed intent required cells and reserved regions into TerrainBuilder.
- Added guarded reserved-region elevation stamping in TerrainBuilder using runtime heights `0..1`.
- Added V1 story-room and faction-site geometry stampers that call the existing authored-scene floor-claim API.
- Added query-only actor elevation traversal/cost APIs on `ProcGenTilemap`; full navigation/pathing enforcement is deferred.
- Exported `world_shape_mode`, `worldgen_intent_graph`, `ascent_field_summary`, `main_route_cells`, `vista_cells`, and `worldgen_reserved_regions` through `get_level_data()`.

## Required Validation

- Existing procgen still loads.
- Existing terrain/elevation smokes still pass.
- New intent graph smoke passes.
- Same seed produces same intent graph.
- Main route is connected.
- Story/faction reservations do not block required route.
- Existing road smoke still passes.
- Default generated maps should read as outdoor ruined ascent fields, not roguelike cave masks.

## Completion Notes

- Implemented and validated on 2026-06-16.
- `ASCENT_FIELD` is now the default base shape mode and does not use the legacy cave mask as map substrate.
- `LEGACY_CAVE` remains available for old ProcGen-driven cave maps.
- Random foliage placement now rejects authored-scene, story-room, faction-site, Ash-Bell, and Forlorn-Ritualant reservation metadata; `procgen_authored_scene_authority_smoke.gd` asserts claimed authored footprints cannot accept future foliage placement.
- Road stamping/enforcement now refuses impassable ascent-field blockers, terrain blocked/drop/ledge cells, mountain-wall authority, and compound connector wall rails instead of clearing them; `procgen_placeholder_roads_smoke.gd` asserts road cells do not overlap this blocker authority.
- Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.
- `procgen_ascent_style_smoke.gd` exports a debug image to `user://procgen_ascent_field_debug.png`.
- `terrain_builder_smoke.gd` exits 0 and prints its ok summary, but still logs the existing TileSet source id 32 assertion/error during its source audit.
- Headless Godot checks still report existing object/resource leak warnings at process exit.
- Full headless boot exits 0; current contract generation logs a fallback-to-best-available procgen map warning after candidate attempts.

Validation run:

- `godot --headless --script res://tools/validation/procgen_intent_graph_smoke.gd` — PASS.
- `godot --headless --script res://tools/validation/procgen_worldgen_shape_smoke.gd` — PASS.
- `godot --headless --script res://tools/validation/procgen_ascent_style_smoke.gd` — PASS; summary included average main-route width `13.57`, wall/floor ratio `0.145`, eight terraces, two side pockets.
- `godot --headless --script res://tools/validation/procgen_placeholder_roads_smoke.gd` — PASS after late road-component repair and impassable-overlap assertion.
- `godot --headless --script res://tools/validation/faction_story_sites_smoke.gd` — PASS.
- `godot --headless --script res://tools/validation/procgen_authored_scene_authority_smoke.gd` — PASS with authored-footprint foliage rejection assertion.
- `godot --headless --script res://tools/validation/terrain_builder_smoke.gd` — exits 0 with ok summary; logs existing TileSet source id audit error.
- `godot --headless --script res://tools/validation/elevation_map_smoke.gd` — PASS.
- `godot --headless --path . --quit` — PASS with existing warnings.
