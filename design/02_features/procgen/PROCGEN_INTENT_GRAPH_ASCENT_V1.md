# Procgen Intent Graph + Ascent V1

## Design Rule

Worldgen must be generated from player-facing route intent first, not from rooms first.

Correct order:

1. World profile and distance bands
2. Intent graph
3. Ascent spine
4. Region reservations
5. Terrain/elevation requests
6. Floor/wall carving
7. Faction/story/site stamping
8. Props/actors/ambient anchors
9. Debug export and validation

Incorrect order:

1. BSP rooms
2. Corridors
3. Cellular automaton
4. Metadata overlay

## V1 Runtime Contract

`ProcGenTilemap` now exposes `world_shape_mode`, defaulting to `ASCENT_FIELD`.

`ASCENT_FIELD` builds a deterministic `WorldgenIntentGraph` and uses that graph as the base shape authority. The legacy BSP/corridor/cellular ProcGen output is not used as the map substrate in this mode. Instead, `AscentFieldBuilder` produces a broad exterior playable floor mass, main ascent route, switchback terraces, side pockets, sparse cliff/ruin/border blockers, landmark/vista cells, and story/faction reservations.

`LEGACY_CAVE` keeps the old generator available for cave/roguelike use without deleting it.

Intent graph cells become floor authority, procgen wall authority is cleared through the shared wall cleanup helper, and reserved regions are passed to TerrainBuilder for metadata-first height/traversal pressure.

Story and faction site geometry is still V1 reservation geometry, not final authored setpiece art. The stampers call `claim_procgen_floor_rect_for_authored_scene_tiles(...)` so reservation cleanup stays centralized.

Road and foliage detail passes must respect those authority claims. Random foliage placement rejects authored-scene, story-room, faction-site, Ash-Bell, and Forlorn-Ritualant reservation metadata, including streaming reveal placement. Road stamping/enforcement may clear ordinary road-blocking procgen walls, but must not clear or overlap impassable ascent-field blockers, terrain blocked/drop/ledge cells, mountain-wall authority, or compound connector wall rails.

Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.

## Files

- `custodian/game/world/procgen/intent/worldgen_intent_node.gd`
- `custodian/game/world/procgen/intent/worldgen_intent_edge.gd`
- `custodian/game/world/procgen/intent/worldgen_intent_graph.gd`
- `custodian/game/world/procgen/intent/ascent_spine_builder.gd`
- `custodian/game/world/procgen/intent/ascent_field_builder.gd`
- `custodian/game/world/procgen/intent/region_footprint_reserver.gd`
- `custodian/game/world/procgen/intent/worldgen_intent_debug_overlay.gd`
- `custodian/game/world/procgen/story/story_room_geometry_stamper.gd`
- `custodian/game/world/procgen/factions/faction_site_geometry_stamper.gd`
- `custodian/game/world/procgen/proc_gen_tilemap.gd`
- `custodian/game/world/procgen/terrain/terrain_builder.gd`

## Next Agent Slice

Goal: turn V1 reservations into actual setpiece geometry.

Files:

- `custodian/game/world/procgen/story/`
- `custodian/game/world/procgen/factions/`
- `custodian/game/world/procgen/proc_gen_tilemap.gd`
- `custodian/content/procgen/`

Constraints:

- Keep the intent graph as upstream shape authority.
- Keep `ASCENT_FIELD` free of legacy cave-mask substrate reads.
- Use shared procgen authority claim APIs for any authored/setpiece footprint.
- Keep random foliage and roads subordinate to authored/reserved region and impassable terrain authority.
- Do not move final tile art into simulation authority.
- Do not claim elevation affects actor pathfinding until NavigationSystem consumes the query APIs.

Acceptance checks:

- Story/faction reservations produce visible, connected floor geometry on or near terraces/side pockets.
- Ambient anchors are placed inside their claimed regions.
- Required route remains connected.
- Average main route width remains at least 9 tiles.
- Wall/floor ratio remains low enough to avoid cave-density reads.
- `procgen_intent_graph_smoke.gd`, `procgen_worldgen_shape_smoke.gd`, terrain/elevation smokes, and road smoke pass.
