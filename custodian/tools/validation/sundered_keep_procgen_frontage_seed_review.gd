extends SceneTree

const PROCGEN_MAP_SCENE := preload(
	"res://game/world/procgen/proc_gen_map.tscn"
)
const PLACEMENT_RESOLVER := preload(
	"res://game/world/levels/world_ingress_placement_resolver.gd"
)
const PRESENTATION_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_procgen_vista_presentation.tscn"
)
const ROUTE_PATH := (
	"res://content/routes/sundered_keep/sundered_keep_route.json"
)
const DEFAULT_OUTPUT_DIR := (
	"res://../reports/sundered_keep_procgen_frontage"
)
const REVIEW_SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
const MAP_SIZE := Vector2i(176, 176)
const VIEWPORT_SIZE := Vector2i(2560, 1440)

var _output_dir := DEFAULT_OUTPUT_DIR
var _seeds: Array[int] = []
var _failures: Array[String] = []
var _manifest: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_output_dir = _parse_output_dir(args)
	_seeds = _parse_seeds(args)
	var absolute_output := ProjectSettings.globalize_path(_output_dir)
	var directory_error := DirAccess.make_dir_recursive_absolute(
		absolute_output
	)
	if directory_error != OK:
		_failures.append(
			"could not create %s: %s"
			% [absolute_output, error_string(directory_error)]
		)
	else:
		for seed_value in _seeds:
			await _capture_seed(seed_value)
		_write_manifest()
	_finish()


func _capture_seed(seed_value: int) -> void:
	var viewport := SubViewport.new()
	viewport.name = "SunderedKeepFrontageReview_%04d" % seed_value
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var world := Node2D.new()
	world.name = "World"
	viewport.add_child(world)
	var procgen_runtime := Node2D.new()
	procgen_runtime.name = "ProcGenRuntime"
	world.add_child(procgen_runtime)
	var map := await _generate_map(seed_value, procgen_runtime)
	if map == null:
		_record_failure(seed_value, "procgen generation failed")
		viewport.queue_free()
		await process_frame
		return

	var level_data: Dictionary = map.get_level_data()
	var frontage: Dictionary = level_data.get(
		"sundered_keep_frontage",
		{}
	)
	if frontage.is_empty():
		_record_failure(seed_value, "level data omitted frontage")
		viewport.queue_free()
		await process_frame
		return
	var placement := _load_placement()
	var resolved: Dictionary = PLACEMENT_RESOLVER.new().call(
		"resolve",
		placement,
		level_data,
		map,
		[] as Array[Vector2i]
	)
	if not bool(resolved.get("ok", false)) \
			or bool(resolved.get("requires_authored_pocket", true)):
		_record_failure(
			seed_value,
			"generated terminal ingress did not resolve cleanly"
		)
		viewport.queue_free()
		await process_frame
		return

	var ingress := Area2D.new()
	ingress.name = "SunderedKeepIngressSite"
	ingress.global_position = _tile_to_world(
		map,
		resolved.get("tile") as Vector2i
	)
	world.add_child(ingress)
	var operator := Node2D.new()
	operator.name = "Operator"
	world.add_child(operator)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	world.add_child(camera)
	var presentation := PRESENTATION_SCENE.instantiate() as Node2D
	presentation.set(
		"operator_path",
		NodePath("../../Operator")
	)
	presentation.set(
		"camera_path",
		NodePath("../../Camera2D")
	)
	var landmarks := Node2D.new()
	landmarks.name = "WorldLandmarks"
	world.add_child(landmarks)
	landmarks.add_child(presentation)
	presentation.call("configure", ingress, map, level_data)
	await process_frame

	var outputs := {}
	var overview_reveal := presentation.get_node(
		"FirstRevealApex"
	) as Marker2D
	operator.global_position = overview_reveal.global_position
	presentation.call("_process", 0.0)
	var overview_bounds := _frontage_world_bounds(map, frontage)
	camera.global_position = overview_bounds.get_center()
	camera.zoom = _fit_zoom(overview_bounds.size)
	outputs["world_overview"] = await _save_frame(
		viewport,
		seed_value,
		"world_overview"
	)
	var distance_frames: Array[Dictionary] = []
	for requested_s in [0.0, 4.0, 8.0, 12.0, 16.0, 20.0, 24.0, 28.0, 32.0, 36.0, 44.0, 52.0]:
		var cell := _centerline_cell_at_s(frontage, requested_s)
		operator.global_position = _tile_to_world(map, cell)
		presentation.call("_process", 0.0)
		var focus := presentation.get_node(
			"CameraPresentationAnchor"
		) as Marker2D
		var state := presentation.call("get_world_vista_debug_state") as Dictionary
		camera.global_position = focus.global_position if requested_s < 36.0 else operator.global_position
		camera.zoom = Vector2.ONE * float(state.get("camera_zoom_target", 0.9))
		var ruins := presentation.get_node("VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/OceanRuinsPresentation") as Node2D
		var keep := presentation.get_node("VistaPresentationRoot/ExteriorVistaClip/FortressPresentation") as Node2D
		var frame_name := "s%02d" % int(requested_s)
		outputs[frame_name] = await _save_frame(
			viewport,
			seed_value,
			frame_name
		)
		distance_frames.append({
			"requested_s": requested_s,
			"actual_s": float(state.get("route_s_cells", 0.0)),
			"camera_weight": float(state.get("camera_weight", 0.0)),
			"zoom": float(state.get("camera_zoom_target", 0.9)),
			"camera_offset": _vector2_json(state.get("camera_offset_target", Vector2.ZERO)),
			"camera_operator_distance": float(state.get("camera_operator_distance", 0.0)),
			"ruins_alpha": float(state.get("ruins_alpha", 0.0)),
			"keep_alpha": float(state.get("keep_alpha", 0.0)),
			"foreground_cliff_alpha": float(state.get("foreground_cliff_alpha", 0.0)),
			"ruins_screen_center": _vector2_json(_world_to_screen(ruins.global_position, camera)),
			"keep_screen_center": _vector2_json(_world_to_screen(keep.global_position, camera)),
			"ruins_apparent_screen_bounds": _rect2_json(_node_screen_bounds(ruins, camera)),
			"keep_apparent_screen_bounds": _rect2_json(_node_screen_bounds(keep, camera)),
		})
	var outside_cell := _centerline_cell_before_influence(frontage, 8)
	operator.global_position = _tile_to_world(map, outside_cell)
	presentation.call("_process", 0.0)
	camera.global_position = operator.global_position
	camera.zoom = Vector2(0.9, 0.9)
	outputs["ordinary_outside_cinematic"] = await _save_frame(viewport, seed_value, "ordinary_outside_cinematic")
	var coastline := map.get_node_or_null(
		"NavigationRegion2D/NonWalkableSurfaceOverlay/SunderedKeepCoastlinePresentation"
	) as Node2D
	if coastline != null and coastline.get_child_count() > 0:
		var coast_subject: Node2D = null
		for child in coastline.get_children():
			if child is Node2D and str(child.name).begins_with("CliffEdge_"):
				coast_subject = child as Node2D
				break
		if coast_subject == null:
			coast_subject = coastline.get_child(0) as Node2D
		presentation.call("_apply_visual_state", 0.0)
		var fortress := presentation.get_node_or_null(
			"VistaPresentationRoot/ExteriorVistaClip/HorizonPresentation/FortressPresentation"
		) as CanvasItem
		if fortress != null:
			fortress.visible = false
		camera.global_position = coast_subject.global_position + Vector2(0.0, 18.0)
		camera.zoom = Vector2(2.1, 2.1)
		outputs["coastline_closeup"] = await _save_frame(viewport, seed_value, "coastline_closeup")

	var ok := true
	for output in outputs.values():
		if str(output).is_empty():
			ok = false
	var seed_summary := {
		"seed": seed_value,
		"ok": ok,
		"viewport": [VIEWPORT_SIZE.x, VIEWPORT_SIZE.y],
		"grammar_id": str(frontage.get("grammar_id", "")),
		"gate_anchor": _vector2i_json(
			frontage.get("gate_anchor", Vector2i.ZERO)
		),
		"overlook_anchor": _vector2i_json(
			frontage.get("overlook_anchor", Vector2i.ZERO)
		),
		"outputs": outputs,
		"distance_frames": distance_frames,
		"floor_source_counts_after": ((frontage.get("debug_summary", {}) as Dictionary).get("floor_source_counts", {}) as Dictionary).duplicate(true),
		"floor_source_counts_before": _legacy_floor_source_counts(map, frontage),
		"macro_cliff_sprite_count": int(coastline.get_meta("macro_cliff_count", 0)) if coastline != null else 0,
		"macro_cliff_before_count": _legacy_macro_cliff_count(map, frontage),
		"macro_cliff_average_run_stride": float(coastline.get_meta("macro_cliff_stride", 0.0)) if coastline != null else 0.0,
		"depth_backdrop_mode": map.depth_backdrop.call("get_debug_mode") if map.depth_backdrop != null else "missing",
		"rectangular_authored_footprint": false,
		"authored_pocket": false,
	}
	_manifest.append(seed_summary)
	_write_seed_summary(seed_value, seed_summary)
	if not ok:
		_failures.append("seed %04d failed one or more captures" % seed_value)
	viewport.queue_free()
	await process_frame


func _generate_map(
	seed_value: int,
	parent: Node2D
) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	if map == null:
		return null
	map.name = "GeneratedMap"
	parent.add_child(map)
	if not map.is_node_ready():
		await map.ready
	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	if procgen == null:
		return null
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = seed_value
	procgen.map_size = MAP_SIZE
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.show_runtime_wall_collision_debug = false
	map.enable_final_foliage = true
	map.generate()
	for _frame in range(4):
		await process_frame
	return map


func _save_frame(
	viewport: SubViewport,
	seed_value: int,
	frame_name: String
) -> String:
	for _frame in range(4):
		RenderingServer.force_draw(false)
		await process_frame
	var image := viewport.get_texture().get_image()
	var seed_dir := _output_dir.path_join("seed_%03d" % seed_value)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(seed_dir))
	var output_path := seed_dir.path_join("%s.png" % frame_name)
	if image == null or image.is_empty():
		return ""
	var error := image.save_png(
		ProjectSettings.globalize_path(output_path)
	)
	if error != OK:
		return ""
	print(
		"[SunderedKeepProcgenFrontageSeedReview] saved %s"
		% output_path
	)
	return output_path


func _frontage_world_bounds(
	map: ProcGenTilemap,
	frontage: Dictionary
) -> Rect2:
	var floor_cells: Dictionary = frontage.get("floor_cells", {})
	var bounds := Rect2()
	var initialized := false
	for cell_variant in floor_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var point := _tile_to_world(map, cell_variant as Vector2i)
		if not initialized:
			bounds = Rect2(point, Vector2.ONE)
			initialized = true
		else:
			bounds = bounds.expand(point)
	return bounds.grow(192.0)


func _fit_zoom(world_size: Vector2) -> Vector2:
	if world_size.x <= 0.0 or world_size.y <= 0.0:
		return Vector2(0.5, 0.5)
	var scale := minf(
		float(VIEWPORT_SIZE.x) / world_size.x,
		float(VIEWPORT_SIZE.y) / world_size.y
	) * 0.86
	scale = clampf(scale, 0.20, 0.86)
	return Vector2(scale, scale)


func _tile_to_world(
	map: ProcGenTilemap,
	tile: Vector2i
) -> Vector2:
	return map.minimap_tile_to_global(tile)


func _centerline_cell_at_s(frontage: Dictionary, requested_s: float) -> Vector2i:
	var centerline: Array = frontage.get("route_centerline", [])
	var indices: Dictionary = frontage.get("camera_semantic_indices", {})
	var start_index := int(indices.get("first_influence_start", 0))
	var cumulative := 0.0
	var best_index := start_index
	var best_delta := absf(requested_s)
	for index in range(start_index + 1, centerline.size()):
		cumulative += Vector2((centerline[index] as Vector2i) - (centerline[index - 1] as Vector2i)).length()
		var delta := absf(cumulative - requested_s)
		if delta < best_delta:
			best_delta = delta
			best_index = index
	return centerline[best_index] as Vector2i


func _centerline_cell_before_influence(frontage: Dictionary, cells_before: int) -> Vector2i:
	var centerline: Array = frontage.get("route_centerline", [])
	var indices: Dictionary = frontage.get("camera_semantic_indices", {})
	var start_index := int(indices.get("first_influence_start", 0))
	return centerline[maxi(0, start_index - cells_before)] as Vector2i


func _legacy_floor_source_counts(map: ProcGenTilemap, frontage: Dictionary) -> Dictionary:
	var counts := {129: 0, 130: 0, 131: 0, 132: 0}
	var gate: Vector2i = frontage.get("gate_anchor", Vector2i.ZERO)
	var apron: Dictionary = frontage.get("terminal_apron_cells", {})
	for cell_variant in (frontage.get("floor_cells", {}) as Dictionary).keys():
		var cell := cell_variant as Vector2i
		var variation := int(map.call("_tile_noise_hash", cell + Vector2i(2861, 1877))) % 11
		var source_id := 129
		if apron.has(cell) or cell.distance_to(gate) <= 5.5:
			source_id = 132
		elif cell.distance_to(gate) <= 18.0:
			source_id = 131 if variation < 8 else 130
		elif variation < 3:
			source_id = 130
		counts[source_id] = int(counts[source_id]) + 1
	return counts


func _legacy_macro_cliff_count(map: ProcGenTilemap, frontage: Dictionary) -> int:
	var count := 0
	var floor := map.debug_get_generated_floor_cells()
	for cell_variant in (frontage.get("ocean_cells", {}) as Dictionary).keys():
		var ocean_cell := cell_variant as Vector2i
		var floor_direction := Vector2i.ZERO
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if floor.has(ocean_cell + direction):
				if floor_direction != Vector2i.ZERO:
					floor_direction = Vector2i.ZERO
					break
				floor_direction = direction
		if floor_direction == Vector2i.ZERO:
			continue
		var tangent := ocean_cell.y if floor_direction.x != 0 else ocean_cell.x
		if posmod(tangent, 2) == 0:
			count += 1
	return count


func _load_placement() -> Dictionary:
	var source := FileAccess.get_file_as_string(ROUTE_PATH)
	var parsed: Variant = JSON.parse_string(source)
	if not parsed is Dictionary:
		return {}
	var ingress: Dictionary = (parsed as Dictionary).get("ingress", {})
	return (ingress.get("placement", {}) as Dictionary).duplicate(true)


func _write_manifest() -> void:
	var output_path := _output_dir.path_join("manifest.json")
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write manifest")
		return
	file.store_string(JSON.stringify({
		"schema": "custodian.sundered_keep_procgen_frontage_review.v1",
		"viewport": [VIEWPORT_SIZE.x, VIEWPORT_SIZE.y],
		"seeds": _manifest,
	}, "\t"))


func _record_failure(seed_value: int, reason: String) -> void:
	_failures.append("seed %04d: %s" % [seed_value, reason])
	_manifest.append({
		"seed": seed_value,
		"ok": false,
		"reason": reason,
	})


func _parse_output_dir(args: PackedStringArray) -> String:
	for index in range(args.size()):
		if args[index] == "--output-dir" \
				and index + 1 < args.size():
			return args[index + 1]
	return DEFAULT_OUTPUT_DIR


func _parse_seeds(args: PackedStringArray) -> Array[int]:
	for index in range(args.size()):
		if args[index] != "--seeds" or index + 1 >= args.size():
			continue
		var result: Array[int] = []
		for raw_seed in args[index + 1].split(",", false):
			if raw_seed.strip_edges().is_valid_int():
				result.append(int(raw_seed.strip_edges()))
		if not result.is_empty():
			return result
	return REVIEW_SEEDS.duplicate()


func _vector2i_json(value: Variant) -> Array[int]:
	if value is Vector2i:
		return [(value as Vector2i).x, (value as Vector2i).y]
	return [0, 0]


func _vector2_json(value: Variant) -> Array[float]:
	if value is Vector2:
		return [(value as Vector2).x, (value as Vector2).y]
	return [0.0, 0.0]


func _rect2_json(value: Rect2) -> Dictionary:
	return {"x": value.position.x, "y": value.position.y, "width": value.size.x, "height": value.size.y}


func _node_screen_bounds(node: Node2D, camera: Camera2D) -> Rect2:
	var bounds := Rect2()
	var initialized := false
	for child in _all_descendants(node):
		if not child is Sprite2D:
			continue
		var sprite := child as Sprite2D
		if sprite.texture == null:
			continue
		var center := _world_to_screen(sprite.global_position, camera)
		var size := sprite.texture.get_size() * sprite.global_scale.abs() * camera.zoom
		var rect := Rect2(center - size * 0.5, size)
		bounds = rect if not initialized else bounds.merge(rect)
		initialized = true
	return bounds


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		result.append(current)
		for child in current.get_children():
			pending.append(child)
	return result


func _world_to_screen(world_position: Vector2, camera: Camera2D) -> Vector2:
	return Vector2(VIEWPORT_SIZE) * 0.5 + (world_position - camera.global_position) * camera.zoom


func _write_seed_summary(seed_value: int, summary: Dictionary) -> void:
	var seed_dir := _output_dir.path_join("seed_%03d" % seed_value)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(seed_dir))
	var file := FileAccess.open(seed_dir.path_join("summary.json"), FileAccess.WRITE)
	if file == null:
		_failures.append("seed %03d summary could not be written" % seed_value)
		return
	file.store_string(JSON.stringify(summary, "\t"))


func _finish() -> void:
	if _failures.is_empty():
		print(
			"[SunderedKeepProcgenFrontageSeedReview] PASS seeds=%d"
			% _seeds.size()
		)
		quit(0)
		return
	for failure in _failures:
		push_error(
			"[SunderedKeepProcgenFrontageSeedReview] %s"
			% failure
		)
	quit(1)
