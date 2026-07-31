extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const ROAD_SURFACE_ROOT := "res://content/tiles/roads_paths/runtime/roads/surface/"
const PATH_ROOT := "res://content/tiles/roads_paths/runtime/placeholders/paths/"
const SURFACE_MANIFEST := "res://content/tiles/roads_paths/runtime/roads/surface/road_surface_piece_manifest.game32.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)
	var tilemap := map as ProcGenTilemap
	assert(tilemap != null)

	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame

	var procgen := map.get_node("ProcGen2") as ProcGen
	assert(procgen != null)
	procgen.generate_seed = false
	procgen.seed = 420777
	procgen.map_size = Vector2i(128, 104)

	tilemap.enable_streaming_reveal = false
	tilemap.build_runtime_wall_collision = true
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.generate()
	for _frame in range(360):
		if not tilemap.debug_get_generated_floor_cells().is_empty() \
				and tilemap.debug_get_road_piece_decal_count() > 0:
			break
		await process_frame

	var road_tiles := tilemap.get_main_road_tiles()
	var parking_tiles := tilemap.get_parking_zone_tiles()
	var component_descriptions := _road_component_descriptions(road_tiles)
	assert(road_tiles.size() >= 100, "Expected a substantial generated road network, got %d tiles." % road_tiles.size())
	assert(not parking_tiles.is_empty(), "Expected generated parking/staging road tiles.")
	assert(component_descriptions.size() == 1, "Generated road network is disconnected: components=%s" % str(component_descriptions))

	var role_map: Dictionary = {}
	for tile in road_tiles:
		assert(not tilemap.debug_has_wall_visual_at(tile), "Road tile has wall visual: %s" % str(tile))
		assert(not tilemap.debug_has_wall_authority_at(tile), "Road tile has wall authority: %s" % str(tile))
		assert(not tilemap.debug_is_road_blocked_by_impassable_authority(tile), "Road tile overlaps impassable authority: %s" % str(tile))
		var expected_role := tilemap.debug_classify_road_surface_role(tile)
		var actual_role := tilemap.debug_get_road_surface_role_at(tile)
		assert(not expected_role.is_empty(), "Road tile has no classified surface role: %s" % str(tile))
		assert(
			actual_role == expected_role,
			"Road role mismatch at %s: expected=%s actual=%s"
			% [str(tile), expected_role, actual_role]
		)
		assert(tilemap.debug_has_road_surface_decal_at(tile), "Road tile lacks its base decal: %s" % str(tile))
		role_map[tile] = actual_role

	var decal_paths := tilemap.debug_get_road_piece_decal_texture_paths()
	var road_decal_count := 0
	var path_decal_count := 0
	for path in decal_paths:
		if path.begins_with(ROAD_SURFACE_ROOT):
			road_decal_count += 1
		elif path.begins_with(PATH_ROOT):
			path_decal_count += 1
	assert(road_decal_count == road_tiles.size(), "Expected exactly one road decal per road tile: decals=%d tiles=%d" % [road_decal_count, road_tiles.size()])
	assert(
		str(tilemap.path_piece_manifest_path).begins_with(
			"res://content/tiles/roads_paths/runtime/placeholders/paths/"
		),
		"Footpaths no longer use their separate path manifest."
	)
	assert(
		not (tilemap.get("_path_piece_defs_by_mask") as Dictionary).is_empty(),
		"Footpath connection-mask definitions did not load."
	)

	var role_counts := tilemap.debug_get_road_piece_decal_surface_role_counts()
	assert(int(role_counts.get("center", 0)) > 0, "Expected center road pieces.")
	assert(
		int(role_counts.get("edge_n", 0))
			+ int(role_counts.get("edge_e", 0))
			+ int(role_counts.get("edge_s", 0))
			+ int(role_counts.get("edge_w", 0)) > 0,
		"Expected exterior edge road pieces."
	)
	assert(
		int(role_counts.get("outer_corner_nw", 0))
			+ int(role_counts.get("outer_corner_ne", 0))
			+ int(role_counts.get("outer_corner_sw", 0))
			+ int(role_counts.get("outer_corner_se", 0)) > 0,
		"Expected exterior corner road pieces."
	)
	_assert_manifest_contract()

	var sample_tile: Vector2i = road_tiles[road_tiles.size() / 2]
	var sample_role := tilemap.debug_get_road_surface_role_at(sample_tile)
	tilemap.call("_remove_road_piece_decal", sample_tile)
	assert(not tilemap.debug_has_road_surface_decal_at(sample_tile), "Road decal did not unload.")
	tilemap.call("_reveal_road_piece_decal", sample_tile)
	assert(tilemap.debug_get_road_surface_role_at(sample_tile) == sample_role, "Streaming reveal reconstructed a different role.")
	assert(role_map[sample_tile] == sample_role, "Fixed-seed role map changed during streaming reconstruction.")

	print(
		"[ProcgenRoadSurfaceRolesSmoke] ok roads=%d parking=%d road_decals=%d path_decals=%d roles=%s"
		% [road_tiles.size(), parking_tiles.size(), road_decal_count, path_decal_count, str(role_counts)]
	)
	quit(0)


func _assert_manifest_contract() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SURFACE_MANIFEST))
	assert(parsed is Dictionary, "Road surface manifest is invalid.")
	var manifest := parsed as Dictionary
	var pieces := manifest.get("pieces", []) as Array
	assert(pieces.size() == 15, "Road surface manifest must contain the 15-piece minimum pack.")
	var roles: Dictionary = {}
	for piece_variant: Variant in pieces:
		var piece := piece_variant as Dictionary
		var role := str(piece.get("surface_role", ""))
		var path := ROAD_SURFACE_ROOT + str(piece.get("file", ""))
		assert(not role.is_empty(), "Road surface piece is missing surface_role.")
		assert(ResourceLoader.exists(path), "Road surface piece is missing: %s" % path)
		roles[role] = true
	for required_role in [
		"center",
		"edge_n", "edge_e", "edge_s", "edge_w",
		"outer_corner_nw", "outer_corner_ne", "outer_corner_sw", "outer_corner_se",
		"inner_corner_nw", "inner_corner_ne", "inner_corner_sw", "inner_corner_se",
	]:
		assert(roles.has(required_role), "Road surface manifest lacks role: %s" % required_role)


func _road_component_descriptions(road_tiles: Array[Vector2i]) -> Array[String]:
	if road_tiles.is_empty():
		return []
	var road_set := {}
	for tile in road_tiles:
		road_set[tile] = true
	var descriptions: Array[String] = []
	while not road_set.is_empty():
		descriptions.append(_pop_connected_road_component_description(road_set, road_set.keys()[0] as Vector2i))
	descriptions.sort()
	descriptions.reverse()
	return descriptions


func _pop_connected_road_component_description(road_set: Dictionary, start: Vector2i) -> String:
	var size := 0
	var min_tile := start
	var max_tile := start
	var visited := {}
	var frontier: Array[Vector2i] = [start]
	visited[start] = true
	road_set.erase(start)
	while not frontier.is_empty():
		var tile: Vector2i = frontier.pop_front()
		size += 1
		min_tile = Vector2i(mini(min_tile.x, tile.x), mini(min_tile.y, tile.y))
		max_tile = Vector2i(maxi(max_tile.x, tile.x), maxi(max_tile.y, tile.y))
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = tile + direction
			if visited.has(next) or not road_set.has(next):
				continue
			visited[next] = true
			road_set.erase(next)
			frontier.append(next)
	return "size=%d bounds=%s..%s" % [size, str(min_tile), str(max_tile)]
