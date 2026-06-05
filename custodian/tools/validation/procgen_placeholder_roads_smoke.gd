extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const PLACEHOLDER_ROAD_ROOT := "res://content/tiles/roads_paths/runtime/placeholders/"


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

	tilemap.enable_streaming_reveal = true
	tilemap.build_runtime_wall_collision = true
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.generate()
	for _frame in range(360):
		if not tilemap.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame

	var road_tiles := tilemap.get_main_road_tiles()
	var parking_tiles := tilemap.get_parking_zone_tiles()
	var component_descriptions := _road_component_descriptions(road_tiles)
	assert(road_tiles.size() >= 100, "Expected a substantial generated road network, got %d tiles." % road_tiles.size())
	assert(not parking_tiles.is_empty(), "Expected generated parking/staging road tiles.")
	assert(component_descriptions.size() == 1, "Generated road network is disconnected: components=%s" % str(component_descriptions))

	for tile in road_tiles:
		assert(not tilemap.debug_has_wall_visual_at(tile), "Road tile has wall visual: %s" % str(tile))
		assert(not tilemap.debug_has_wall_authority_at(tile), "Road tile has wall authority: %s" % str(tile))

	var decal_paths := tilemap.debug_get_road_piece_decal_texture_paths()
	assert(decal_paths.size() >= 8, "Expected placeholder road/path decals to spawn, got %d." % decal_paths.size())
	for path in decal_paths:
		assert(path.begins_with(PLACEHOLDER_ROAD_ROOT), "Road decal did not use placeholder runtime art: %s" % path)
		assert(path.get_file().begins_with("PLACEHOLDER_"), "Road placeholder file is not clearly named: %s" % path)

	var role_counts := tilemap.debug_get_road_piece_decal_role_counts()
	for role in ["center", "left_1", "left_2", "right_1", "right_2"]:
		assert(int(role_counts.get(role, 0)) > 0, "Expected road lane placeholder role '%s' to spawn, got roles=%s" % [role, str(role_counts)])

	print("[ProcgenPlaceholderRoadsSmoke] ok roads=%d parking=%d decals=%d roles=%s" % [road_tiles.size(), parking_tiles.size(), decal_paths.size(), str(role_counts)])
	quit(0)


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
