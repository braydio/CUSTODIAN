extends Node2D
class_name KenneyIsometricBlockoutFeasibility

const PRESENTATION := preload("res://scenes/debug/kenney_isometric_blockout_presentation.gd")

enum PresentationMode { NATIVE, KENNEY }

const CELL_SIZE := PRESENTATION.CELL_SIZE
const VIEW_SIZE := Vector2i(1280, 720)
const ANCHORS := PRESENTATION.ANCHORS
const SAMPLE_REGIONS := PRESENTATION.SAMPLE_REGIONS
const CAPTURE_POS := Vector2(0, -2000)
const CAPTURE_ZOOM := Vector2(0.30, 0.30)
const SETTLE_FRAMES := 30
const SAMPLE_FRAMES := 120
const REPORT_DIR := "res://docs/ai_context/reports/kenney_presentation"
const KENNEY_DOMAIN := PRESENTATION.KENNEY_DOMAIN
const PROTOTYPE_STATES := PRESENTATION.PROTOTYPE_STATES
const BASE_STATES := PRESENTATION.BASE_STATES

@onready var shared_sample: Node2D = %SharedSpatialSample
@onready var anchor_markers: Node2D = %AnchorMarkers
@onready var native_root: Node2D = %NativePresentation
@onready var kenney_root: Node2D = %KenneyPresentation
@onready var camera: Camera2D = %Camera2D
@onready var comparison_viewport: SubViewport = %ComparisonViewport

var _kenney_textures: Dictionary = {}


func _ready() -> void:
	camera.position = CAPTURE_POS
	camera.zoom = CAPTURE_ZOOM
	_kenney_textures = PRESENTATION.load_kenney_textures()
	PRESENTATION.build(shared_sample, anchor_markers, native_root, kenney_root, _kenney_textures)
	set_presentation_mode(PresentationMode.NATIVE)
	if OS.get_cmdline_user_args().has("--capture"):
		call_deferred("_run_experiment")


func set_presentation_mode(mode: PresentationMode) -> void:
	native_root.visible = mode == PresentationMode.NATIVE
	kenney_root.visible = mode == PresentationMode.KENNEY


func parity_snapshot() -> Dictionary:
	return {
		"cell_size": CELL_SIZE,
		"anchors": ANCHORS.duplicate(true),
		"regions": SAMPLE_REGIONS.duplicate(true),
		"viewport": VIEW_SIZE,
		"camera_position": camera.position,
		"camera_zoom": camera.zoom,
	}


func selected_runtime_asset_count() -> int:
	return _kenney_textures.size()


func selected_textures_valid() -> bool:
	return PRESENTATION.selected_textures_valid(_kenney_textures)


func _run_experiment() -> void:
	var native_metrics := await _measure_presentation(PresentationMode.NATIVE)
	set_presentation_mode(PresentationMode.NATIVE)
	await get_tree().process_frame
	var native_path := _capture("k3d1_native.png")

	var kenney_metrics := await _measure_presentation(PresentationMode.KENNEY)
	set_presentation_mode(PresentationMode.KENNEY)
	await get_tree().process_frame
	var kenney_path := _capture("k3d1_kenney.png")
	if native_path.is_empty() or kenney_path.is_empty():
		push_error("K3D-1 capture failed")
		get_tree().quit(1)
		return
	if not _compose_comparison(native_path, kenney_path):
		get_tree().quit(1)
		return
	var metrics := {
		"schema": "custodian.kenney_k3d1_metrics.v1",
		"sample_frames": SAMPLE_FRAMES,
		"settle_frames": SETTLE_FRAMES,
		"viewport": {"width": VIEW_SIZE.x, "height": VIEW_SIZE.y},
		"presentation_modes": {"native": native_metrics, "kenney": kenney_metrics},
		"capture_paths": [
			"custodian/docs/ai_context/reports/kenney_presentation/k3d1_native.png",
			"custodian/docs/ai_context/reports/kenney_presentation/k3d1_kenney.png",
			"custodian/docs/ai_context/reports/kenney_presentation/k3d1_ab_compare.png",
		],
	}
	_write_json("k3d1_metrics.json", metrics)
	print("kenney_isometric_blockout_feasibility: captures and metrics written")
	get_tree().quit(0)


func _measure_presentation(mode: PresentationMode) -> Dictionary:
	set_presentation_mode(mode)
	for _frame in SETTLE_FRAMES:
		await get_tree().process_frame
	var samples: Array[float] = []
	for _frame in SAMPLE_FRAMES:
		var start_usec := Time.get_ticks_usec()
		await get_tree().process_frame
		samples.append(float(Time.get_ticks_usec() - start_usec) / 1000.0)
	samples.sort()
	var root := native_root if mode == PresentationMode.NATIVE else kenney_root
	var renderer_available := DisplayServer.get_name() != "headless"
	return {
		"frame_ms_p50": _percentile(samples, 0.50),
		"frame_ms_p95": _percentile(samples, 0.95),
		"OBJECT_NODE_COUNT": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"RENDER_TOTAL_OBJECTS_IN_FRAME": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)) if renderer_available else null,
		"RENDER_TOTAL_DRAW_CALLS_IN_FRAME": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) if renderer_available else null,
		"presentation_node_count": _count_nodes(root),
		"selected_runtime_asset_count": selected_runtime_asset_count(),
		"instance_count": _count_sprites(root),
		"renderer_available": renderer_available,
	}


func _percentile(sorted_values: Array[float], fraction: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index := clampi(int(ceil(fraction * float(sorted_values.size()))) - 1, 0, sorted_values.size() - 1)
	return snappedf(sorted_values[index], 0.001)


func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


func _count_sprites(node: Node) -> int:
	var count := 1 if node is Sprite2D else 0
	for child in node.get_children():
		count += _count_sprites(child)
	return count


func _capture(filename: String) -> String:
	RenderingServer.force_draw(false)
	var image := comparison_viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != VIEW_SIZE:
		push_error("Capture must be a non-empty %dx%d image, got %s" % [VIEW_SIZE.x, VIEW_SIZE.y, str(image.get_size()) if image != null else "null"])
		return ""
	var path := "%s/%s" % [REPORT_DIR, filename]
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if image.save_png(absolute) != OK:
		push_error("Could not save capture: %s" % absolute)
		return ""
	return absolute


func _compose_comparison(native_path: String, kenney_path: String) -> bool:
	var native_image := Image.load_from_file(native_path)
	var kenney_image := Image.load_from_file(kenney_path)
	if native_image == null or kenney_image == null:
		push_error("Could not reload A/B captures for composition")
		return false
	if native_image.get_size() != VIEW_SIZE or kenney_image.get_size() != VIEW_SIZE:
		push_error("A/B capture dimensions drifted before composition")
		return false
	native_image.convert(Image.FORMAT_RGBA8)
	kenney_image.convert(Image.FORMAT_RGBA8)
	var composite := Image.create(VIEW_SIZE.x * 2, VIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	composite.blit_rect(native_image, Rect2i(Vector2i.ZERO, VIEW_SIZE), Vector2i.ZERO)
	composite.blit_rect(kenney_image, Rect2i(Vector2i.ZERO, VIEW_SIZE), Vector2i(VIEW_SIZE.x, 0))
	var absolute := ProjectSettings.globalize_path("%s/k3d1_ab_compare.png" % REPORT_DIR)
	return composite.save_png(absolute) == OK


func _write_json(filename: String, value: Dictionary) -> void:
	var path := "%s/%s" % [REPORT_DIR, filename]
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	assert(file != null, "Could not write metrics report")
	file.store_string(JSON.stringify(value, "\t") + "\n")
	file.close()
