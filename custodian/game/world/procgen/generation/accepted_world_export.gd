extends RefCounted
class_name ProcgenAcceptedWorldExport

## Owns accepted-world generated-state capture and export: the TileMap-to-cell
## capture, the externally consumed level-data schema and its copy/serialize
## rules, the terrain-builder level-data summary, and the runtime authoring
## fingerprint.
##
## `ProcGenTilemap` remains the live runtime host. It owns the mutable
## `_generated_floor_cells` / `_generated_wall_cells` stores (runtime terrain
## commits and connector dry-runs mutate them) and hands this owner raw source
## values; every export returns detached copies, so a caller can never mutate
## runtime state through exported data. Candidate semantic snapshots stay with
## `candidate_semantic_adapter.gd`; this owner is not a second snapshot
## authority and defines no acceptance policy.

const LEVEL_DATA_MODE_PASS := &"pass"
const LEVEL_DATA_MODE_DEEP := &"deep"
const LEVEL_DATA_MODE_SHALLOW := &"shallow"
const LEVEL_DATA_MODE_CELLS := &"cells"

## Ordered level-data schema: [output key, mode]. `pass` forwards the source
## value, `deep`/`shallow` forward a detached copy, `cells` converts a
## Vector2i-keyed Dictionary into an Array[Vector2i]. Keys not listed here are
## derived in `build_level_data`. Changing this table changes the externally
## consumed level-data contract (ContractWorldLoader, minimap, debug tools).
const LEVEL_DATA_SCHEMA := [
	["generation_id", LEVEL_DATA_MODE_PASS],
	["map_size", LEVEL_DATA_MODE_PASS],
	["tile_size", LEVEL_DATA_MODE_PASS],
	["player_spawn", LEVEL_DATA_MODE_PASS],
	["rooms", LEVEL_DATA_MODE_PASS],
	["rooms_by_distance", LEVEL_DATA_MODE_PASS],
	["corridor_spawns", LEVEL_DATA_MODE_PASS],
	["random_floor_tiles", LEVEL_DATA_MODE_PASS],
	["compound_rect", LEVEL_DATA_MODE_PASS],
	["compound_ingress", LEVEL_DATA_MODE_PASS],
	["compound_buildings", LEVEL_DATA_MODE_PASS],
	["compound_layout_version", LEVEL_DATA_MODE_PASS], # derived
	["compound_rooms", LEVEL_DATA_MODE_DEEP],
	["compound_connections", LEVEL_DATA_MODE_DEEP],
	["compound_corridor_cells", LEVEL_DATA_MODE_SHALLOW],
	["compound_courtyard_cells", LEVEL_DATA_MODE_SHALLOW],
	["compound_primary_anchor", LEVEL_DATA_MODE_PASS],
	["compound_terminal_anchor", LEVEL_DATA_MODE_PASS],
	["compound_fabricator_anchor", LEVEL_DATA_MODE_PASS],
	["compound_construction_zone_anchor", LEVEL_DATA_MODE_PASS],
	["compound_diagnostics", LEVEL_DATA_MODE_DEEP],
	["main_road_tiles", LEVEL_DATA_MODE_PASS],
	["ruined_road_tiles", LEVEL_DATA_MODE_PASS],
	["service_hardstand_tiles", LEVEL_DATA_MODE_PASS],
	["parking_zone_tiles", LEVEL_DATA_MODE_PASS],
	["road_semantics", LEVEL_DATA_MODE_PASS],
	["road_walk_speed_multiplier", LEVEL_DATA_MODE_PASS],
	["road_vehicle_speed_multiplier", LEVEL_DATA_MODE_PASS],
	["interior_region_rect", LEVEL_DATA_MODE_PASS],
	["interior_rooms", LEVEL_DATA_MODE_PASS],
	["interior_thresholds", LEVEL_DATA_MODE_PASS],
	["region_tiles", LEVEL_DATA_MODE_DEEP],
	["elevation_cells", LEVEL_DATA_MODE_PASS],
	["pre_terrain_connectivity", LEVEL_DATA_MODE_DEEP],
	["terrain_builder", LEVEL_DATA_MODE_PASS], # derived
	["biome_id_by_cell", LEVEL_DATA_MODE_DEEP],
	["biome_summary", LEVEL_DATA_MODE_DEEP],
	["surface_material_by_cell", LEVEL_DATA_MODE_DEEP],
	["surface_materials", LEVEL_DATA_MODE_DEEP],
	["macro_presentation", LEVEL_DATA_MODE_DEEP],
	["dressing_clusters", LEVEL_DATA_MODE_DEEP],
	["floor_cells", LEVEL_DATA_MODE_CELLS],
	["wall_cells", LEVEL_DATA_MODE_CELLS],
	["ocean_cells", LEVEL_DATA_MODE_CELLS],
	["chasm_cells", LEVEL_DATA_MODE_CELLS],
	["region_frame", LEVEL_DATA_MODE_PASS],
	["nonwalkable_surface_summary", LEVEL_DATA_MODE_DEEP],
	["runtime_prop_blocker_cells", LEVEL_DATA_MODE_CELLS],
	["runtime_prop_blocker_source_count", LEVEL_DATA_MODE_PASS], # derived
	["world_profile", LEVEL_DATA_MODE_PASS],
	["world_shape_mode", LEVEL_DATA_MODE_PASS],
	["world_progression_enabled", LEVEL_DATA_MODE_PASS],
	["world_progress_profile_id", LEVEL_DATA_MODE_PASS], # derived
	["world_progress_samples", LEVEL_DATA_MODE_DEEP],
	["worldgen_intent_enabled", LEVEL_DATA_MODE_PASS],
	["worldgen_intent_graph", LEVEL_DATA_MODE_PASS], # derived
	["ascent_field_summary", LEVEL_DATA_MODE_DEEP],
	["main_route_cells", LEVEL_DATA_MODE_SHALLOW],
	["main_route_centerline_cells", LEVEL_DATA_MODE_SHALLOW],
	["route_playability", LEVEL_DATA_MODE_DEEP],
	["route_playability_audit", LEVEL_DATA_MODE_DEEP],
	["encounter_plan", LEVEL_DATA_MODE_DEEP],
	["vista_cells", LEVEL_DATA_MODE_SHALLOW],
	["sundered_keep_frontage", LEVEL_DATA_MODE_DEEP],
	["worldgen_reserved_regions", LEVEL_DATA_MODE_DEEP],
	["faction_activity_sites", LEVEL_DATA_MODE_DEEP],
	["story_room_sites", LEVEL_DATA_MODE_DEEP],
	["special_room_sites", LEVEL_DATA_MODE_DEEP],
	["intent_zones_enabled", LEVEL_DATA_MODE_PASS], # derived
]


## Captures visible structural TileMap cells into the generated floor/wall
## stores, mutating the supplied dictionaries in place. Streaming reveal keeps
## undiscovered authoritative cells unpainted, so that mode merges instead of
## clearing first.
static func capture_tile_state(
	floor_tilemap: TileMapLayer,
	walls_tilemap: TileMapLayer,
	map_size: Vector2i,
	floor_cells: Dictionary,
	wall_cells: Dictionary,
	merge_into_existing: bool
) -> void:
	if not merge_into_existing:
		floor_cells.clear()
		wall_cells.clear()
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)
			var floor_source := floor_tilemap.get_cell_source_id(pos)
			if floor_source >= 0:
				floor_cells[pos] = {
					"source_id": floor_source,
					"atlas": floor_tilemap.get_cell_atlas_coords(pos),
					"alternative": floor_tilemap.get_cell_alternative_tile(pos),
				}
				wall_cells.erase(pos)
			var wall_source := walls_tilemap.get_cell_source_id(pos)
			if wall_source >= 0:
				wall_cells[pos] = {
					"source_id": wall_source,
					"atlas": walls_tilemap.get_cell_atlas_coords(pos),
					"alternative": walls_tilemap.get_cell_alternative_tile(pos),
				}
				floor_cells.erase(pos)


static func dict_keys_as_vector2i_array(source: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key in source.keys():
		if key is Vector2i:
			result.append(key)
	return result


## Detached deep copy of a generated cell store for debug/fingerprint readers.
static func duplicate_cells(source: Dictionary) -> Dictionary:
	return source.duplicate(true)


## Assembles the externally consumed level-data dictionary from raw host
## sources. Source keys match output keys, plus `generated_floor_cells` /
## `generated_wall_cells` (feed `floor_cells` / `wall_cells`),
## `last_terrain_result`, `last_pre_terrain_connectivity`,
## `runtime_prop_blocker_sources`, `world_progress_profile` and
## `worldgen_intent_graph` (objects/dictionaries the derived keys read).
static func build_level_data(sources: Dictionary) -> Dictionary:
	var data := {}
	for entry in LEVEL_DATA_SCHEMA:
		var key: String = entry[0]
		var mode: StringName = entry[1]
		match key:
			"compound_layout_version":
				var rooms: Variant = sources.get("compound_rooms", [])
				data[key] = 1 if not rooms.is_empty() else 0
			"terrain_builder":
				data[key] = build_terrain_builder_level_data(
					sources.get("last_terrain_result", {}),
					sources.get("last_pre_terrain_connectivity", {})
				)
			"floor_cells":
				data[key] = dict_keys_as_vector2i_array(sources.get("generated_floor_cells", {}))
			"wall_cells":
				data[key] = dict_keys_as_vector2i_array(sources.get("generated_wall_cells", {}))
			"runtime_prop_blocker_source_count":
				data[key] = (sources.get("runtime_prop_blocker_sources", {}) as Dictionary).size()
			"world_progress_profile_id":
				var profile: Variant = sources.get("world_progress_profile")
				data[key] = profile.profile_id if profile != null else ""
			"worldgen_intent_graph":
				var graph: Variant = sources.get("worldgen_intent_graph")
				data[key] = graph.to_dictionary() if graph != null else {}
			"intent_zones_enabled":
				data[key] = true
			_:
				var value: Variant = sources.get(key)
				match mode:
					LEVEL_DATA_MODE_DEEP:
						data[key] = value.duplicate(true)
					LEVEL_DATA_MODE_SHALLOW:
						data[key] = value.duplicate()
					LEVEL_DATA_MODE_CELLS:
						data[key] = dict_keys_as_vector2i_array(value)
					_:
						data[key] = value
	return data


## Terrain-builder summary exported inside level data and consumed by candidate
## evaluation (`candidate_semantic_adapter.gd`) and contract-world loading.
static func build_terrain_builder_level_data(
	last_terrain_result: Dictionary,
	last_pre_terrain_connectivity: Dictionary
) -> Dictionary:
	if last_terrain_result.is_empty():
		return {
			"connectivity_ok": true,
			"fallback_used": false,
			"pre_terrain_connectivity": last_pre_terrain_connectivity.duplicate(true),
		}
	var connectivity: Dictionary = last_terrain_result.get("connectivity", {})
	var summary: Dictionary = last_terrain_result.get("debug_summary", {})
	return {
		"connectivity_ok": bool(connectivity.get("ok", summary.get("connectivity_ok", true))),
		"fallback_used": bool(last_terrain_result.get("fallback_used", summary.get("fallback_used", false))),
		"rescue_carved_cells": int(last_terrain_result.get("rescue_carved_cells", summary.get("rescue_carved_cells", 0))),
		"baseline_rescue_carved_cells": int(last_terrain_result.get("baseline_rescue_carved_cells", summary.get("baseline_rescue_carved_cells", 0))),
		"reachable_count": int(connectivity.get("reachable_count", 0)),
		"missing_required": connectivity.get("missing_required", []).duplicate(),
		"pre_terrain_connectivity": last_pre_terrain_connectivity.duplicate(true),
		"summary": summary.duplicate(true),
	}


## Deterministic runtime authoring fingerprint: detached copies of every store
## whose mutation would change accepted-world authority. `sources` carries the
## already-resolved values keyed by fingerprint key.
static func build_runtime_authoring_fingerprint(sources: Dictionary) -> Dictionary:
	var fingerprint := {}
	for key in [
		"floor", "walls", "regions", "roads", "road_centerline", "ruined_road",
		"service_hardstand", "foliage", "surface", "surface_material", "health",
	]:
		fingerprint[key] = (sources.get(key, {}) as Dictionary).duplicate(true)
	return fingerprint
