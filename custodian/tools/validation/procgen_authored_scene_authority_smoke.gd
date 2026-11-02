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
	procgen.seed = 420888
	procgen.map_size = Vector2i(128, 104)

	tilemap.enable_streaming_reveal = true
	tilemap.build_runtime_wall_collision = true
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.generate()

	for _frame in range(360):
		if not tilemap.debug_get_generated_wall_cells().is_empty():
			break
		await process_frame

	var wall_cells := tilemap.debug_get_generated_wall_cells()
	assert(not wall_cells.is_empty(), "Expected generated wall cells before authored-scene reservation.")
	var target_tile := _pick_safe_visible_wall_cell(tilemap, wall_cells.keys(), procgen.map_size)
	assert(target_tile != Vector2i.ZERO, "Could not find safe visible wall cell for authored-scene reservation test.")
	assert(tilemap.debug_runtime_wall_body_exists(target_tile), "Expected runtime wall collision before authored-scene reservation.")

	var claimed_rect: Rect2i = tilemap.claim_procgen_floor_rect_for_authored_scene_world(
		tilemap.minimap_tile_to_global(target_tile),
		Vector2i(9, 7),
		"test_authored_scene_floor",
		"test_authored_scene",
		1
	)
	assert(claimed_rect.size == Vector2i(9, 7), "Unexpected claimed rect size: %s" % str(claimed_rect))

	var check_rect := claimed_rect.grow(1)
	var report := tilemap.debug_get_authored_scene_authority_report(check_rect)
	assert(int(report.get("wall_visual_count", -1)) == 0, "Authored claim retained wall visuals: %s" % str(report))
	assert(int(report.get("wall_authority_count", -1)) == 0, "Authored claim retained wall authority: %s" % str(report))
	assert(int(report.get("blocked_elevation_count", -1)) == 0, "Authored claim retained blocked elevation: %s" % str(report))

	for x in range(check_rect.position.x, check_rect.end.x):
		for y in range(check_rect.position.y, check_rect.end.y):
			var tile := Vector2i(x, y)
			if tile.x < 0 or tile.y < 0 or tile.x >= procgen.map_size.x or tile.y >= procgen.map_size.y:
				continue
			assert(tilemap.get_region_type_at_tile(tile) == "test_authored_scene_floor", "Authored scene region metadata missing at %s." % str(tile))
			assert(not tilemap.is_road_surface_tile(tile), "Authored scene claim retained road authority at %s." % str(tile))
			assert(not tilemap.debug_can_place_foliage_at(tile), "Authored scene allows random foliage placement at %s." % str(tile))

	print("[ProcgenAuthoredSceneAuthoritySmoke] ok claimed=%s center=%s report=%s" % [str(claimed_rect), str(target_tile), str(report)])
	quit(0)


func _pick_safe_visible_wall_cell(tilemap: ProcGenTilemap, cells: Array, map_size: Vector2i) -> Vector2i:
	for item in cells:
		if not (item is Vector2i):
			continue
		var tile := item as Vector2i
		if tile.x <= 12 or tile.y <= 12 or tile.x >= map_size.x - 12 or tile.y >= map_size.y - 12:
			continue
		if tilemap.debug_has_wall_visual_at(tile) and tilemap.debug_runtime_wall_body_exists(tile):
			return tile
	return Vector2i.ZERO
