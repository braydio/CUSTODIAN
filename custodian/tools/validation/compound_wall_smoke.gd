extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")


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
	procgen.seed = 91573
	procgen.map_size = Vector2i(112, 96)

	tilemap.enable_streaming_reveal = true
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.generate()
	for _frame in range(300):
		if not tilemap.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame
	assert(not tilemap.debug_get_generated_floor_cells().is_empty(), "ProcGenTilemap did not generate floor state.")

	var walls: Dictionary = tilemap.debug_get_generated_wall_cells()
	var floors: Dictionary = tilemap.debug_get_generated_floor_cells()
	var protected_tiles := {}

	for tile in tilemap.get_main_road_tiles():
		protected_tiles[tile] = true
		assert(not walls.has(tile), "Main road tile should not be generated wall: %s" % str(tile))

	for tile in tilemap.get_parking_zone_tiles():
		protected_tiles[tile] = true
		assert(not walls.has(tile), "Parking tile should not be generated wall: %s" % str(tile))

	for tile in tilemap.debug_get_compound_ingress_footprints():
		protected_tiles[tile] = true
		assert(not walls.has(tile), "Compound ingress footprint should not be generated wall: %s" % str(tile))

	for tile_variant in floors.keys():
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		var region := tilemap.get_region_type_at_tile(tile)
		if region == "compound_connector_road" or region == "destroyed_wall_floor":
			protected_tiles[tile] = true
			assert(not walls.has(tile), "Protected region should not be generated wall: %s %s" % [region, str(tile)])
		if walls.has(tile) and _is_protected_region(region):
			assert(false, "Protected floor/wall dual membership: %s %s" % [region, str(tile)])

	var revealed_count := 0
	for tile in protected_tiles.keys():
		if not (tile is Vector2i):
			continue
		if not floors.has(tile):
			continue
		tilemap._reveal_tile(tile)
		assert(not tilemap.debug_runtime_wall_body_exists(tile), "Streaming reveal recreated runtime wall body on protected tile: %s" % str(tile))
		revealed_count += 1
		if revealed_count >= 64:
			break

	print("[CompoundWallSmoke] ok protected=%d revealed=%d" % [protected_tiles.size(), revealed_count])
	quit(0)


func _is_protected_region(region: String) -> bool:
	match region:
		"main_road", "parking_zone", "compound_connector_road", "compound_ingress", "compound_approach", "interior_threshold", "destroyed_wall_floor", "terrain_elevation_access", "compound_connector_ramp", "compound_connector_elevated_road":
			return true
		_:
			return false
