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
	var frame_specs := [
		{
			"name": "first_reveal",
			"marker": "FirstRevealApex",
			"zoom": Vector2(0.78, 0.78),
		},
		{
			"name": "frontage_apex",
			"marker": "FrontageApex",
			"zoom": Vector2(0.74, 0.74),
		},
		{
			"name": "gate_approach",
			"marker": "GateThreshold",
			"zoom": Vector2(0.90, 0.90),
		},
	]
	for spec in frame_specs:
		var marker := presentation.get_node(spec["marker"]) as Marker2D
		operator.global_position = marker.global_position
		presentation.call("_process", 0.0)
		var focus := presentation.get_node(
			"CameraPresentationAnchor"
		) as Marker2D
		camera.global_position = (
			focus.global_position
			if spec["name"] != "gate_approach"
			else marker.global_position + Vector2(0.0, -110.0)
		)
		camera.zoom = spec["zoom"]
		outputs[spec["name"]] = await _save_frame(
			viewport,
			seed_value,
			spec["name"]
		)

	var ok := true
	for output in outputs.values():
		if str(output).is_empty():
			ok = false
	_manifest.append({
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
		"rectangular_authored_footprint": false,
		"authored_pocket": false,
	})
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
	var output_path := _output_dir.path_join(
		"seed_%04d_%s.png" % [seed_value, frame_name]
	)
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
