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
	procgen.seed = 120931
	procgen.map_size = Vector2i(128, 104)

	tilemap.enable_streaming_reveal = true
	tilemap.build_runtime_wall_collision = true
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.generate()
	for _frame in range(360):
		if not tilemap.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame
	assert(not tilemap.debug_get_generated_floor_cells().is_empty(), "ProcGenTilemap did not generate floor state.")

	var protected: Array[Vector2i] = tilemap.debug_get_protected_passable_road_cells()
	assert(not protected.is_empty(), "Expected protected road/passable cells.")

	for tile in protected:
		assert(not tilemap.debug_has_wall_visual_at(tile), "Protected road cell has wall visual: %s region=%s" % [str(tile), tilemap.get_region_type_at_tile(tile)])
		assert(not tilemap.debug_has_wall_authority_at(tile), "Protected road cell has wall authority: %s region=%s" % [str(tile), tilemap.get_region_type_at_tile(tile)])

	var revealed := 0
	for tile in protected:
		tilemap._reveal_tile(tile)
		assert(not tilemap.debug_has_wall_visual_at(tile), "Reveal restored wall visual on protected road cell: %s" % str(tile))
		assert(not tilemap.debug_has_wall_authority_at(tile), "Reveal restored wall authority on protected road cell: %s" % str(tile))
		revealed += 1
		if revealed >= 96:
			break

	print("[CompoundRoadWallSmoke] ok protected=%d revealed=%d" % [protected.size(), revealed])
	quit(0)
