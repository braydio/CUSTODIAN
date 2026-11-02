extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const SUNDERED_KEEP_MAP_SCENE := preload(
	"res://game/world/sundered_keep/sundered_keep_map.tscn"
)
const VIEWPORT_SIZE := Vector2i(2560, 1440)
const DEFAULT_OUTPUT_DIR := (
	"res://../reports/sundered_keep_route_correction"
)

var _output_dir := DEFAULT_OUTPUT_DIR
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_output_dir = _parse_output_dir(OS.get_cmdline_user_args())
	var absolute_output := ProjectSettings.globalize_path(_output_dir)
	var directory_error := DirAccess.make_dir_recursive_absolute(
		absolute_output
	)
	if directory_error != OK:
		push_error(
			"[SunderedKeepRouteCorrectionReview] Could not create %s: %s"
			% [absolute_output, error_string(directory_error)]
		)
		quit(1)
		return
	await _capture_approach()
	await _capture_front_gate()
	if _failures.is_empty():
		print("[SunderedKeepRouteCorrectionReview] PASS")
		quit()
		return
	for failure in _failures:
		push_error("[SunderedKeepRouteCorrectionReview] %s" % failure)
	quit(1)


func _capture_approach() -> void:
	var viewport := _make_viewport("ApproachReview")
	var approach := APPROACH_SCENE.instantiate() as Node2D
	viewport.add_child(approach)
	await process_frame
	for _frame in range(8):
		RenderingServer.force_draw(false)
		await process_frame
	if approach.has_method("is_visual_ready") \
			and not bool(approach.call("is_visual_ready")):
		_failures.append("approach did not reach visual readiness")
		viewport.queue_free()
		await process_frame
		return
	var debug_probe := approach.get_node_or_null("VistaDebugProbe")
	if debug_probe != null:
		debug_probe.visible = false
	var camera := Camera2D.new()
	camera.name = "ReviewCamera"
	camera.enabled = true
	camera.zoom = Vector2(1.0, 1.0)
	viewport.add_child(camera)
	var frame_specs := [
		{
			"name": "parish_arrival_northbound",
			"marker": "EntrySpawn",
			"offset": Vector2(120.0, -220.0),
		},
		{
			"name": "parish_close_detail_reveal",
			"marker": "SecondVistaFull",
			"offset": Vector2(260.0, -180.0),
		},
		{
			"name": "parish_long_east_traverse",
			"marker": "TraverseEnd",
			"offset": Vector2(-260.0, -80.0),
		},
	]
	for spec in frame_specs:
		var marker := approach.get_node_or_null(
			"Markers/%s" % spec["marker"]
		) as Marker2D
		if marker == null:
			_failures.append("approach marker missing: %s" % spec["marker"])
			continue
		camera.global_position = marker.global_position + spec["offset"]
		await _save_frame(viewport, spec["name"])
	viewport.queue_free()
	await process_frame


func _capture_front_gate() -> void:
	var viewport := _make_viewport("FrontGateReview")
	var map := SUNDERED_KEEP_MAP_SCENE.instantiate() as Node2D
	map.name = "SunderedKeepMap"
	viewport.add_child(map)
	await process_frame
	for _frame in range(8):
		RenderingServer.force_draw(false)
		await process_frame
	var hud := map.get_node_or_null("SunderedKeepCustodianHUD")
	if hud != null:
		hud.visible = false
	var spawn := map.find_child("EntrySpawn", true, false) as Node2D
	if spawn == null:
		_failures.append("Front Gate EntrySpawn missing")
	else:
		var camera := Camera2D.new()
		camera.name = "ReviewCamera"
		camera.enabled = true
		camera.zoom = Vector2(1.0, 1.0)
		camera.global_position = spawn.global_position + Vector2(0.0, -180.0)
		viewport.add_child(camera)
		await _save_frame(viewport, "front_gate_arrival_clear")
	viewport.queue_free()
	await process_frame


func _make_viewport(viewport_name: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = viewport_name
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	return viewport


func _save_frame(viewport: SubViewport, frame_name: String) -> void:
	for _frame in range(4):
		RenderingServer.force_draw(false)
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("empty capture: %s" % frame_name)
		return
	var output_path := _output_dir.path_join("%s.png" % frame_name)
	var save_error := image.save_png(
		ProjectSettings.globalize_path(output_path)
	)
	if save_error != OK:
		_failures.append(
			"could not save %s: %s"
			% [output_path, error_string(save_error)]
		)
		return
	print(
		"[SunderedKeepRouteCorrectionReview] saved %s"
		% output_path
	)


func _parse_output_dir(args: PackedStringArray) -> String:
	for index in range(args.size()):
		if args[index] == "--output-dir" and index + 1 < args.size():
			return args[index + 1]
	return DEFAULT_OUTPUT_DIR
