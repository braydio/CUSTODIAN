# Procgen Roads

- `procgen_road_authority.gd` owns canonical generated road, path, parking,
  ruined-road, service-hardstand, and road-semantics state. It also owns
  deterministic connected-component traversal, component repair-pair
  selection, required-anchor connectivity decisions, and pruning plans.
- Mutations of the owner's canonical state go through its methods. Queries
  return the same set-equivalent tile results used by the `ProcGenTilemap`
  façade and debug/export consumers.
- `ProcGenTilemap` remains responsible for physical floor/wall/region edits,
  generation orchestration, and all road/path decal and material presentation.
  The authority never receives the tilemap host or mutates terrain, collision,
  navigation, foliage, or presentation nodes.
- `surfaces/road_semantics_resolver.gd` remains the pure Road Semantics V2
  classifier; its results are published into the road authority without
  moving or duplicating the classification algorithm. The surface-material
  resolver remains a separate owner.
- `intent_main_roads_enabled` remains false in production. The archived
  wide-road construction path is retained for its opt-in debug contract.
- Belongs here: generated road/path/parking authority state, graph building,
  connectivity repair/pruning decisions, and road/path metric helpers.
- Does not belong here: physical floor/wall realization, decal/material
  selection, foliage placement, campaign state, actor AI, or UI display.
