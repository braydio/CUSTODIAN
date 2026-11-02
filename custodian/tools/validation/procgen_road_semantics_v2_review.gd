extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const REVIEW_SEED := 824790
const MAP_SIZE := Vector2i(128, 104)
const VIEWPORT_SIZE := Vector2i(1600, 900)
const OUTPUT_DIR := "res://../reports/procgen_road_semantics_v2"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var world := Node2D.new()
	viewport.add_child(world)
	var map := MAP_SCENE.instantiate() as ProcGenTilemap
	world.add_child(map)
	if not map.is_node_ready():
		await map.ready
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var procgen := map.get_node("ProcGen2") as ProcGen
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = REVIEW_SEED
	procgen.map_size = MAP_SIZE
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	var expected_generation := map._debug_generation_id + 1
	map.generate()
	if not await _wait_for_generation(map, expected_generation):
		push_error("Road semantics review seed did not finish generation")
		quit(1)
		return
	for _frame in range(4):
		await process_frame
	var camera := Camera2D.new()
	camera.enabled = true
	world.add_child(camera)
	camera.position = Vector2(MAP_SIZE) * 16.0
	var fit := minf(float(VIEWPORT_SIZE.x) / (MAP_SIZE.x * 32.0), float(VIEWPORT_SIZE.y) / (MAP_SIZE.y * 32.0)) * 0.94
	camera.zoom = Vector2.ONE * fit
	for _frame in range(6):
		RenderingServer.force_draw(false)
		await process_frame
	var viewport_texture := viewport.get_texture()
	if viewport_texture == null:
		push_error("Road Semantics capture requires a rendering backend; headless dummy rendering exposes no viewport texture")
		viewport.queue_free()
		await process_frame
		quit(2)
		return
	var image := viewport_texture.get_image()
	var capture_path := OUTPUT_DIR.path_join("seed_%d_overview.png" % REVIEW_SEED)
	var save_error := image.save_png(ProjectSettings.globalize_path(capture_path))
	var summary := map.debug_get_road_semantics_summary()
	var review_route_audit := map.debug_run_route_playability_audit()
	var ruined_road_cell_count := map.get_ruined_road_tiles().size()
	var ruined_road_fragment_count := int(summary.get("ruined_road_fragment_count", 0))
	var service_hardstand_cell_count := map.get_service_hardstand_tiles().size()
	var parking_cell_count := map.get_parking_zone_tiles().size()
	var ruined_road_decal_count := map.debug_get_surface_piece_decal_count("ruined_road")
	var ruined_road_surface_role_counts := map.debug_get_surface_piece_role_counts("ruined_road")
	var road_closeup_path := ""
	var largest_fragment := _largest_road_fragment(map.get_ruined_road_tiles())
	if not largest_fragment.is_empty():
		var bounds := _cell_bounds(largest_fragment).grow(4)
		camera.position = Vector2(bounds.position) * 32.0 + Vector2(bounds.size) * 16.0
		var closeup_fit := minf(float(VIEWPORT_SIZE.x) / (bounds.size.x * 32.0), float(VIEWPORT_SIZE.y) / (bounds.size.y * 32.0)) * 0.92
		camera.zoom = Vector2.ONE * clampf(closeup_fit, 0.5, 2.0)
		for _frame in range(6):
			RenderingServer.force_draw(false)
			await process_frame
		var closeup_texture := viewport.get_texture()
		if closeup_texture != null:
			road_closeup_path = OUTPUT_DIR.path_join("seed_%d_road_fragment_detail.png" % REVIEW_SEED)
			save_error = closeup_texture.get_image().save_png(ProjectSettings.globalize_path(road_closeup_path))
	var bounded_apron_check := await _check_service_apron_sample(map, procgen)
	var report := {
		"seed": REVIEW_SEED,
		"production_wide_roads_enabled": map.intent_main_roads_enabled,
		"road_semantics": summary,
		"ruined_road_cell_count": ruined_road_cell_count,
		"ruined_road_fragment_count": ruined_road_fragment_count,
		"ruined_road_decal_count": ruined_road_decal_count,
		"ruined_road_surface_role_counts": ruined_road_surface_role_counts,
		"service_hardstand_cell_count": service_hardstand_cell_count,
		"parking_cell_count": parking_cell_count,
		"bounded_service_apron_check": bounded_apron_check,
		"route_audit": review_route_audit,
		"capture": capture_path,
		"road_fragment_detail_capture": road_closeup_path,
	}
	var file := FileAccess.open(OUTPUT_DIR.path_join("review_manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ") + "\n")
	viewport.queue_free()
	await process_frame
	if save_error != OK:
		push_error("Road semantics visual capture failed: " + error_string(save_error))
		quit(1)
		return
	print("procgen_road_semantics_v2_review: capture=%s road_detail=%s fragments=%d roads=%d decals=%d roles=%s apron=%d parking=%d apron_sample=%s" % [capture_path, road_closeup_path, ruined_road_fragment_count, ruined_road_cell_count, ruined_road_decal_count, str(ruined_road_surface_role_counts), service_hardstand_cell_count, parking_cell_count, str(bounded_apron_check)])
	quit(0)


func _wait_for_generation(map: ProcGenTilemap, generation_id: int) -> bool:
	for _frame in range(900):
		var summary := map.debug_get_road_semantics_summary()
		if map._debug_generation_id >= generation_id \
				and not map.debug_get_generated_floor_cells().is_empty() \
				and summary.has("fingerprint") \
				and map.debug_get_surface_material_summary().has("fingerprint") \
				and map.debug_get_surface_piece_decal_count("ruined_road") == map.get_ruined_road_tiles().size():
			return true
		await process_frame
	return false


func _check_service_apron_sample(map: ProcGenTilemap, procgen: ProcGen) -> Dictionary:
	var checked_seeds: Array[int] = []
	for offset in range(8):
		var seed := REVIEW_SEED + offset
		if offset > 0:
			procgen.seed = seed
			var expected_generation := map._debug_generation_id + 1
			map.generate()
			if not await _wait_for_generation(map, expected_generation):
				return {"status": "GENERATION_FAILED", "seed": seed, "checked_seeds": checked_seeds}
		checked_seeds.append(seed)
		var apron := map.get_service_hardstand_tiles()
		if apron.is_empty():
			continue
		var parking: Dictionary = {}
		for cell: Vector2i in map.get_parking_zone_tiles():
			parking[cell] = true
		var apron_cells: Dictionary = {}
		for cell: Vector2i in apron:
			apron_cells[cell] = true
			if map.get_surface_material_at_tile(cell) != &"hardened_industrial":
				return {"status": "INVALID_MATERIAL", "seed": seed, "checked_seeds": checked_seeds}
			if map.surface_material_overlay == null or map.surface_material_overlay.get_cell_source_id(cell) < 0:
				return {"status": "MISSING_HARDSTAND_PRESENTATION", "seed": seed, "checked_seeds": checked_seeds}
		if apron_cells != parking:
			return {"status": "PARKING_MISMATCH", "seed": seed, "checked_seeds": checked_seeds}
		if not bool(map.debug_run_route_playability_audit().get("ok", false)):
			return {"status": "ROUTE_AUDIT_FAILED", "seed": seed, "checked_seeds": checked_seeds}
		return {
			"status": "FOUND",
			"seed": seed,
			"service_hardstand_cell_count": apron.size(),
			"parking_cell_count": parking.size(),
			"hardened_industrial_material": true,
			"meridian_hardstand_presentation": true,
			"route_audit_ok": true,
			"checked_seeds": checked_seeds,
		}
	return {"status": "NO_ELIGIBLE_APRON_IN_BOUNDED_SAMPLE", "checked_seeds": checked_seeds}


func _largest_road_fragment(cells: Array[Vector2i]) -> Array[Vector2i]:
	var remaining: Dictionary = {}
	for cell: Vector2i in cells:
		remaining[cell] = true
	var largest: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if not remaining.has(cell):
			continue
		var component: Array[Vector2i] = []
		var queue: Array[Vector2i] = [cell]
		remaining.erase(cell)
		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			component.append(current)
			for delta: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := current + delta
				if remaining.has(next):
					remaining.erase(next)
					queue.append(next)
		if component.size() > largest.size():
			largest = component
	return largest


func _cell_bounds(cells: Array[Vector2i]) -> Rect2i:
	var min_cell := cells[0]
	var max_cell := cells[0]
	for cell: Vector2i in cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)
