extends SceneTree

const PROCGEN_MAP_SCENE := preload(
	"res://game/world/procgen/proc_gen_map.tscn"
)
const PLACEMENT_RESOLVER_SCRIPT := preload(
	"res://game/world/levels/world_ingress_placement_resolver.gd"
)
const VISTA_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_world_vista.tscn"
)
const ROUTE_PATH := (
	"res://content/routes/sundered_keep/sundered_keep_route.json"
)
const DEFAULT_OUTPUT_DIR := (
	"res://../reports/sundered_keep_world_vista"
)
const REVIEW_SEEDS := [
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
]
const REVIEW_MAP_SIZE := Vector2i(176, 176)
const REVIEW_VIEWPORT_SIZE := Vector2i(1920, 1080)
const CINEMATIC_ZOOM := Vector2(0.78, 0.78)
const CINEMATIC_OFFSET := Vector2(0.0, -120.0)

var _placement: Dictionary = {}
var _output_dir := DEFAULT_OUTPUT_DIR
var _review_seeds: Array[int] = []
var _failures: Array[String] = []
var _manifest_entries: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_output_dir = _parse_output_dir(args)
	_review_seeds = _parse_review_seeds(args)
	_placement = _load_vista_placement()
	if _placement.is_empty():
		_finish()
		return

	var absolute_output := ProjectSettings.globalize_path(_output_dir)
	var make_dir_error := DirAccess.make_dir_recursive_absolute(
		absolute_output
	)
	if make_dir_error != OK:
		_failures.append(
			"could not create output directory %s: %s"
			% [absolute_output, error_string(make_dir_error)]
		)
		_finish()
		return

	for seed_value: int in _review_seeds:
		await _capture_seed(seed_value)
	_write_manifest()
	_finish()


func _capture_seed(seed_value: int) -> void:
	var viewport := SubViewport.new()
	viewport.name = "VistaSeedReviewViewport_%04d" % seed_value
	viewport.size = REVIEW_VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	viewport.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var procgen_runtime := Node2D.new()
	procgen_runtime.name = "ProcGenRuntime"
	world.add_child(procgen_runtime)
	var map := await _generate_map(seed_value, procgen_runtime)
	if map == null:
		_manifest_entries.append({
			"seed": seed_value,
			"ok": false,
			"reason": "procgen map generation failed",
		})
		viewport.queue_free()
		await process_frame
		return

	var level_data := map.get_level_data()
	var resolver: RefCounted = PLACEMENT_RESOLVER_SCRIPT.new()
	var placement_result := resolver.call(
		"resolve",
		_placement,
		level_data,
		map,
		[] as Array[Vector2i]
	) as Dictionary
	if not bool(placement_result.get("ok", false)):
		var reason := str(
			placement_result.get("reason", "placement failed")
		)
		_failures.append("seed %04d: %s" % [seed_value, reason])
		_manifest_entries.append({
			"seed": seed_value,
			"ok": false,
			"reason": reason,
		})
		viewport.queue_free()
		await process_frame
		return
	if not bool(
		placement_result.get(
			"requires_authored_pocket",
			false
		)
	):
		var reason := "north-edge Vista did not claim its authored pocket"
		_failures.append("seed %04d: %s" % [seed_value, reason])
		_manifest_entries.append({
			"seed": seed_value,
			"ok": false,
			"reason": reason,
		})
		viewport.queue_free()
		await process_frame
		return
	var pocket := map.call(
		"claim_world_overlook_pocket",
		placement_result.get(
			"pocket_center_tile"
		) as Vector2i,
		placement_result.get(
			"pocket_size_tiles"
		) as Vector2i
	) as Rect2i
	if pocket.size == Vector2i.ZERO:
		var reason := "authored overlook pocket could not be claimed"
		_failures.append("seed %04d: %s" % [seed_value, reason])
		_manifest_entries.append({
			"seed": seed_value,
			"ok": false,
			"reason": reason,
		})
		viewport.queue_free()
		await process_frame
		return

	var ingress_tile := placement_result.get("tile") as Vector2i
	var ingress := Area2D.new()
	ingress.name = "SunderedKeepIngressSite"
	ingress.global_position = _tile_to_world(map, ingress_tile)
	ingress.set_meta(
		"world_ingress_outward_direction",
		placement_result.get(
			"outward_direction",
			Vector2i.ZERO
		)
	)
	ingress.set_meta(
		"world_ingress_edge_distance_tiles",
		int(placement_result.get("edge_distance_tiles", -1))
	)
	world.add_child(ingress)

	var operator := Node2D.new()
	operator.name = "Operator"
	world.add_child(operator)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	camera.zoom = CINEMATIC_ZOOM
	camera.offset = CINEMATIC_OFFSET
	world.add_child(camera)
	var landmarks := Node2D.new()
	landmarks.name = "WorldLandmarks"
	world.add_child(landmarks)
	var vista := VISTA_SCENE.instantiate() as Node2D
	vista.set("operator_path", NodePath("../../Operator"))
	vista.set("camera_path", NodePath("../../Camera2D"))
	landmarks.add_child(vista)
	vista.call("configure", ingress, map, level_data)
	await process_frame

	var apex := vista.get_node("CameraApex") as Marker2D
	operator.global_position = apex.global_position
	vista.call("_process", 0.0)
	var anchor := vista.get_node(
		"CameraPresentationAnchor"
	) as Marker2D
	camera.global_position = anchor.global_position

	for _frame: int in range(8):
		RenderingServer.force_draw(false)
		await process_frame

	var image := viewport.get_texture().get_image()
	var output_path := _output_dir.path_join(
		"seed_%04d.png" % seed_value
	)
	var save_error := ERR_CANT_CREATE
	if image != null and not image.is_empty():
		save_error = image.save_png(
			ProjectSettings.globalize_path(output_path)
		)
	if save_error != OK:
		_failures.append(
			"seed %04d: could not save apex screenshot: %s"
			% [seed_value, error_string(save_error)]
		)
		_manifest_entries.append({
			"seed": seed_value,
			"ok": false,
			"reason": "screenshot save failed",
		})
	else:
		_manifest_entries.append({
			"seed": seed_value,
			"ok": true,
			"output": output_path,
			"ingress_tile": [
				ingress_tile.x,
				ingress_tile.y,
			],
			"edge_distance_tiles": int(
				placement_result.get(
					"edge_distance_tiles",
					-1
				)
			),
			"authored_pocket": bool(
				placement_result.get(
					"requires_authored_pocket",
					false
				)
			),
		})
		print(
			"[SunderedKeepWorldVistaSeedReview] saved %s"
			% output_path
		)

	viewport.queue_free()
	await process_frame


func _generate_map(
	seed_value: int,
	parent: Node2D
) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	if map == null:
		_failures.append(
			"seed %04d: could not instantiate procgen map"
			% seed_value
		)
		return null
	map.name = "GeneratedMap"
	parent.add_child(map)
	if not map.is_node_ready():
		await map.ready

	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame
	var procgen := map.get_node("ProcGen2") as ProcGen
	if procgen == null:
		_failures.append(
			"seed %04d: procgen generator node was missing"
			% seed_value
		)
		return null
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = seed_value
	procgen.map_size = REVIEW_MAP_SIZE

	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.show_runtime_wall_collision_debug = false
	map.enable_final_foliage = true
	map.generate()
	await process_frame
	return map


func _tile_to_world(
	map: ProcGenTilemap,
	tile: Vector2i
) -> Vector2:
	if map.floor_tilemap != null:
		return map.floor_tilemap.to_global(
			map.floor_tilemap.map_to_local(tile)
		)
	return map.global_position + Vector2(tile) * 32.0


func _load_vista_placement() -> Dictionary:
	var source := FileAccess.get_file_as_string(ROUTE_PATH)
	if source.is_empty():
		_failures.append(
			"could not read Sundered Keep route definition"
		)
		return {}
	var parsed: Variant = JSON.parse_string(source)
	if not (parsed is Dictionary):
		_failures.append(
			"Sundered Keep route definition was not valid JSON"
		)
		return {}
	var ingress: Dictionary = (
		(parsed as Dictionary).get("ingress", {})
	)
	var placement: Dictionary = ingress.get("placement", {})
	if str(placement.get("strategy", "")) != "north_edge_overlook":
		_failures.append(
			"Sundered Keep route does not use north_edge_overlook"
		)
		return {}
	return placement.duplicate(true)


func _parse_output_dir(args: PackedStringArray) -> String:
	for index: int in range(args.size()):
		if args[index] == "--output-dir" and index + 1 < args.size():
			return args[index + 1]
	return DEFAULT_OUTPUT_DIR


func _parse_review_seeds(
	args: PackedStringArray
) -> Array[int]:
	for index: int in range(args.size()):
		if args[index] != "--seeds" or index + 1 >= args.size():
			continue
		var result: Array[int] = []
		for raw_seed: String in args[index + 1].split(
			",",
			false
		):
			if raw_seed.strip_edges().is_valid_int():
				result.append(int(raw_seed.strip_edges()))
		if not result.is_empty():
			return result
	var defaults: Array[int] = []
	for seed_value: int in REVIEW_SEEDS:
		defaults.append(seed_value)
	return defaults


func _write_manifest() -> void:
	var manifest_path := _output_dir.path_join("manifest.json")
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		_failures.append(
			"could not write seed-review manifest: %s"
			% FileAccess.get_open_error()
		)
		return
	file.store_string(
		JSON.stringify(
			{
				"map_size": [
					REVIEW_MAP_SIZE.x,
					REVIEW_MAP_SIZE.y,
				],
				"seeds": _manifest_entries,
			},
			"  "
		)
		+ "\n"
	)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"[SunderedKeepWorldVistaSeedReview] PASS (%d seeds)"
			% _review_seeds.size()
		)
		quit(0)
		return
	for failure: String in _failures:
		push_error(
			"[SunderedKeepWorldVistaSeedReview] %s"
			% failure
		)
	quit(1)
