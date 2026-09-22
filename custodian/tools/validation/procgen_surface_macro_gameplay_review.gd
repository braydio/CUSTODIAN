extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEEDS: Array[int] = [824790]
const MAP_SIZE := Vector2i(96, 96)
const VIEWPORT_SIZE := Vector2i(1920, 1080)
const OUTPUT_DIR := "res://../reports/procgen_surface_macro_rocky_upland/gameplay"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for seed_value: int in SEEDS:
		var result := await _generate_and_capture(seed_value)
		if bool(result.get("accepted", false)):
			_write_manifest(result)
			print("procgen_surface_macro_gameplay_review: PASS seed=%d output=%s" % [seed_value, OUTPUT_DIR])
			quit(0)
			return
	push_error("No fixed review seed realized CHASM, cliff/corner, and shelf/ground macro placements")
	quit(1)


func _generate_and_capture(seed_value: int) -> Dictionary:
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
	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame
	var procgen := map.get_node("ProcGen2") as ProcGen
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = seed_value
	procgen.map_size = MAP_SIZE
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = true
	map.generate()
	for _frame: int in 480:
		if not map.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame
	for _frame: int in 4:
		await process_frame

	var plan := map.debug_get_macro_presentation_plan()
	var surface: Array[Dictionary] = []
	var chasm_count := 0
	var has_cliff := false
	var has_ground := false
	for placement: Dictionary in plan.get("placements", []):
		if int(placement.get("placement_domain", TerrainStampProfile.PlacementDomain.SURFACE)) == TerrainStampProfile.PlacementDomain.CHASM:
			chasm_count += 1
			continue
		if String(placement.get("family_id", "")) != "procgen_surface_rocky_upland":
			continue
		surface.append(placement)
		var stamp_id := String(placement.get("stamp_id", ""))
		has_cliff = has_cliff or stamp_id.contains("cliff") or stamp_id.contains("corner")
		has_ground = has_ground or stamp_id.contains("shelf") or stamp_id.contains("scree")
	var accepted := chasm_count > 0 and has_cliff and has_ground
	if not accepted:
		var rejected_ids: Array[String] = []
		for placement: Dictionary in surface:
			rejected_ids.append(String(placement.get("stamp_id", "")))
		print("surface_review reject seed=%d chasm=%d surface=%s" % [seed_value, chasm_count, str(rejected_ids)])
		for region: Dictionary in plan.get("regions", []):
			if String(region.get("kind_name", "")) in ["mountain_wall", "rocky_upland_floor"]:
				print("surface_review region kind=%s biome=%s cells=%d" % [String(region.get("kind_name", "")), String(region.get("biome_id", "")), (region.get("cells", []) as Array).size()])
		viewport.queue_free()
		await process_frame
		return {"accepted": false, "seed": seed_value, "chasm_count": chasm_count, "surface_count": surface.size()}

	var camera := Camera2D.new()
	camera.enabled = true
	world.add_child(camera)
	var bounds := _placement_bounds(plan.get("placements", []))
	camera.position = bounds.get_center()
	camera.zoom = _fit_zoom(bounds.size)
	for _frame: int in 5:
		RenderingServer.force_draw(false)
		await process_frame
	var image := viewport.get_texture().get_image()
	var output_path := OUTPUT_DIR.path_join("seed_%d_overview.png" % seed_value)
	var save_error := image.save_png(ProjectSettings.globalize_path(output_path))
	if save_error != OK:
		viewport.queue_free()
		return {"accepted": false, "seed": seed_value, "save_error": error_string(save_error)}
	var stamp_ids: Array[String] = []
	for placement: Dictionary in surface:
		stamp_ids.append(String(placement.get("stamp_id", "")))
	var result := {
		"accepted": true,
		"seed": seed_value,
		"capture": output_path,
		"chasm_count": chasm_count,
		"surface_count": surface.size(),
		"surface_stamp_ids": stamp_ids,
		"route_audit": map.debug_run_route_playability_audit(),
		"fingerprint": String(plan.get("fingerprint", "")),
	}
	viewport.queue_free()
	await process_frame
	return result


func _placement_bounds(placements: Array) -> Rect2:
	var bounds := Rect2()
	var initialized := false
	for placement: Dictionary in placements:
		var footprint: Rect2i = placement.get("visual_footprint", Rect2i())
		var rect := Rect2(Vector2(footprint.position) * 32.0, Vector2(footprint.size) * 32.0)
		if not initialized:
			bounds = rect
			initialized = true
		else:
			bounds = bounds.merge(rect)
	return bounds.grow(192.0)


func _fit_zoom(world_size: Vector2) -> Vector2:
	var scale := minf(float(VIEWPORT_SIZE.x) / world_size.x, float(VIEWPORT_SIZE.y) / world_size.y) * 0.88
	return Vector2.ONE * clampf(scale, 0.20, 1.0)


func _write_manifest(result: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_DIR.path_join("review_manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "  ") + "\n")
