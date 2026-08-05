extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEEDS := [824771, 824772, 824773, 824774, 824775]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for seed in SEEDS:
		var map := MAP_SCENE.instantiate()
		root.add_child(map)
		var tilemap := map as ProcGenTilemap
		assert(
			not tilemap.intent_main_roads_enabled,
			"Production ProcGenMap must keep wide road generation disabled."
		)
		var procgen := map.get_node("ProcGen2") as ProcGen
		procgen.generate_seed = false
		procgen.seed = seed
		procgen.map_size = Vector2i(96, 96)
		tilemap.generation_evaluation_mode = true
		tilemap.enable_streaming_reveal = false
		tilemap.build_runtime_wall_collision = false
		tilemap.enable_final_foliage = false
		tilemap.generate()
		for _frame in 480:
			if not tilemap.debug_get_generated_floor_cells().is_empty():
				break
			await process_frame

		var floors := tilemap.debug_get_generated_floor_cells()
		var walls := tilemap.debug_get_generated_wall_cells()
		var roads := tilemap.get_main_road_tiles()
		var audit := tilemap.debug_run_route_playability_audit()
		var level_data := tilemap.get_level_data()
		var bounds := _bounds(floors.keys())
		var floor_layer := map.get_node("NavigationRegion2D/Floor") as TileMapLayer
		var wall_layer := map.get_node("NavigationRegion2D/Walls") as TileMapLayer
		var cliff_count := _count_layer_sources(floor_layer, 46, 59) + _count_layer_sources(wall_layer, 46, 59)
		var void_count := _count_layer_sources(floor_layer, 100, 114) + _count_layer_sources(wall_layer, 100, 114)
		assert(not floors.is_empty() and bounds.size != Vector2i.ZERO)
		assert(
			roads.is_empty(),
			"Seed %d unexpectedly generated %d wide-road tiles"
			% [seed, roads.size()]
		)
		assert(bool(audit.get("ok", false)), "Seed %d route invalid: %s" % [seed, audit])
		var spawn := level_data.get("player_spawn", Vector2i(-1, -1)) as Vector2i
		assert(spawn != Vector2i(-1, -1) and floors.has(spawn), "Seed %d spawn is not valid floor: %s" % [seed, spawn])
		print("elevated_world_seed seed=%d floor=%d cliff=%d void=%d bounds=%s roads=%d route_ok=%s spawn=%s" % [seed, floors.size(), cliff_count, void_count, bounds, roads.size(), audit.get("ok", false), spawn])
		map.queue_free()
		await process_frame
	print("elevated_world_seed_review: PASS seeds=%s" % str(SEEDS))
	quit(0)


func _count_sources(cells: Dictionary, low: int, high: int) -> int:
	var count := 0
	for value in cells.values():
		if value is Dictionary:
			var source_id := int((value as Dictionary).get("source_id", -1))
			if source_id >= low and source_id <= high:
				count += 1
	return count


func _count_layer_sources(layer: TileMapLayer, low: int, high: int) -> int:
	var count := 0
	for cell in layer.get_used_cells():
		var source_id := layer.get_cell_source_id(cell)
		if source_id >= low and source_id <= high:
			count += 1
	return count


func _bounds(cells: Array) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var minimum := cells[0] as Vector2i
	var maximum := minimum
	for value in cells:
		var cell := value as Vector2i
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
