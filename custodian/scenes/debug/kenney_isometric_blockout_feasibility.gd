extends Node2D
class_name KenneyIsometricBlockoutFeasibility

enum PresentationMode { NATIVE, KENNEY }

const ROAD_SCRIPT := preload("res://game/world/hub/road_of_witnesses_prototype.gd")
const CELL_SIZE := 32
const VIEW_SIZE := Vector2i(1280, 720)
const ANCHORS := {
	&"spawn_south_reach": Vector2(-6, 162),
	&"forum_south": Vector2(0, -2464),
	&"adjudication_dais": Vector2(0, -3136),
}
const SAMPLE_REGIONS := {
	&"north_processional": Rect2(-512, -2400, 1024, 1152),
	&"ashen_forum": Rect2(-1280, -4032, 2560, 1792),
}
const CAPTURE_POS := Vector2(0, -2000)
const CAPTURE_ZOOM := Vector2(0.30, 0.30)
const SETTLE_FRAMES := 30
const SAMPLE_FRAMES := 120
const REPORT_DIR := "res://docs/ai_context/reports/kenney_presentation"
const KENNEY_DOMAIN := "res://content/tiles/experiments/kenney_feasibility"

const PROTOTYPE_STATES := [
	"floor_s", "slab_s", "block_s", "wall_s", "wall_corner_s",
	"stairs_s", "slope_s", "doorway_s", "column_s", "pole_s",
]
const BASE_STATES := [
	"base_grass_flat_s", "base_stone_flat_s", "base_stone_high_s",
	"square_stone_flat_s", "base_dirt_detail_s", "square_dirt_high_s",
]

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
	_load_kenney_textures()
	_build_shared_sample()
	_build_native_presentation()
	_build_kenney_presentation()
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
	if _kenney_textures.size() != PROTOTYPE_STATES.size() + BASE_STATES.size():
		return false
	for texture: Variant in _kenney_textures.values():
		if not texture is Texture2D or texture.get_size() != Vector2(256, 512):
			return false
	return true


func _load_kenney_textures() -> void:
	for state in PROTOTYPE_STATES:
		var path := "%s/kenney_iso_miniature_prototype_ref_%s_256.png" % [KENNEY_DOMAIN, state]
		_kenney_textures["prototype/%s" % state] = load(path) as Texture2D
	for state in BASE_STATES:
		var path := "%s/kenney_iso_miniature_bases_ref_%s_256.png" % [KENNEY_DOMAIN, state]
		_kenney_textures["bases/%s" % state] = load(path) as Texture2D


func _build_shared_sample() -> void:
	var background := Polygon2D.new()
	background.name = "EvaluationBackdrop"
	background.z_index = -100
	background.color = Color("181a20")
	background.polygon = PackedVector2Array([
		Vector2(-2600, -4300), Vector2(2600, -4300),
		Vector2(2600, 350), Vector2(-2600, 350),
	])
	shared_sample.add_child(background)

	var route := Line2D.new()
	route.name = "SharedRouteExtent"
	route.width = CELL_SIZE
	route.default_color = Color(0.83, 0.79, 0.68, 0.18)
	route.begin_cap_mode = Line2D.LINE_CAP_ROUND
	route.end_cap_mode = Line2D.LINE_CAP_ROUND
	route.points = PackedVector2Array([
		ANCHORS[&"spawn_south_reach"], Vector2(0, -862),
		Vector2(0, -1824), Vector2(0, -2400),
		ANCHORS[&"forum_south"], ANCHORS[&"adjudication_dais"],
	])
	anchor_markers.add_child(route)

	_add_region_outline(anchor_markers, SAMPLE_REGIONS[&"north_processional"], Color(0.38, 0.72, 0.82, 0.8), "NorthProcessionalBounds")
	_add_region_outline(anchor_markers, SAMPLE_REGIONS[&"ashen_forum"], Color(0.82, 0.67, 0.36, 0.8), "AshenForumBounds")
	_add_anchor_marker(anchor_markers, &"spawn_south_reach", "SPAWN • SOUTH REACH", Color("9fdbd1"))
	_add_anchor_marker(anchor_markers, &"forum_south", "FORUM SOUTH", Color("f1d18a"))
	_add_anchor_marker(anchor_markers, &"adjudication_dais", "ADJUDICATION DAIS", Color("f7bc64"))


func _build_native_presentation() -> void:
	var regions := Node2D.new()
	regions.name = "NativeSpatialBlockout"
	regions.z_index = -4
	native_root.add_child(regions)
	_add_filled_rect(regions, SAMPLE_REGIONS[&"north_processional"], Color(0.23, 0.30, 0.32, 0.82), "NorthProcessional")
	_add_filled_rect(regions, SAMPLE_REGIONS[&"ashen_forum"], Color(0.31, 0.29, 0.27, 0.76), "AshenForum")
	_add_filled_rect(regions, Rect2(-160, -4032, 320, 1792), Color(0.49, 0.41, 0.31, 0.92), "CeremonialAxis")
	_add_filled_rect(regions, Rect2(-224, -3200, 448, 192), Color(0.71, 0.59, 0.40, 0.96), "Dais")

	for spec: Dictionary in ROAD_SCRIPT.MODULES:
		var module := Node2D.new()
		module.name = String(spec.id).capitalize()
		module.position = spec.position
		module.z_index = -2
		native_root.add_child(module)
		var size: Vector2 = spec.size
		var base := "res://content/levels/hub/road_of_witnesses/%s/road_of_witnesses_%s" % [spec.id, spec.id]
		_add_road_texture(module, "%s_underlay_%dx%d.png" % [base, int(size.x), int(size.y)], "Underlay", 0)
		_add_road_texture(module, "%s_foreground_%dx%d.png" % [base, int(size.x), int(size.y)], "Foreground", 4)


func _build_kenney_presentation() -> void:
	# The route is a visual-only sequence of modular floor pieces. Their overlap
	# is presentation geometry; the shared anchors and extents remain unchanged.
	for row in range(10):
		var y := -1264.0 - float(row) * 128.0
		for column in range(9):
			var x := -512.0 + float(column) * 128.0
			_add_kenney_sprite(kenney_root, "prototype/floor_s", Vector2(x, y), 0.58, -3)

	# The Forum uses bases as civic plinths, then repeats its bounded structural
	# vocabulary at the same threshold and dais anchors used by presentation A.
	_place_base("bases/base_grass_flat_s", Vector2(-896, -3040), 0.90)
	_place_base("bases/base_grass_flat_s", Vector2(896, -3040), 0.90)
	_place_base("bases/base_stone_flat_s", Vector2(-608, -3120), 0.95)
	_place_base("bases/base_stone_flat_s", Vector2(608, -3120), 0.95)
	_place_base("bases/base_stone_high_s", Vector2(0, -3040), 1.25)
	_place_base("bases/square_stone_flat_s", Vector2(-1088, -2992), 0.92)
	_place_base("bases/square_stone_flat_s", Vector2(1088, -2992), 0.92)
	_place_base("bases/base_dirt_detail_s", Vector2(-1280, -3040), 0.88)
	_place_base("bases/square_dirt_high_s", Vector2(1280, -2960), 0.88)

	for x in [-192.0, 0.0, 192.0]:
		_add_kenney_sprite(kenney_root, "prototype/slab_s", Vector2(x, -3008), 0.56, 0)
	_add_kenney_sprite(kenney_root, "prototype/block_s", Vector2(0, -2912), 0.48, 1)
	_add_kenney_sprite(kenney_root, "prototype/doorway_s", Vector2(0, -2500), 0.48, 1)
	_add_kenney_sprite(kenney_root, "prototype/stairs_s", Vector2(0, -2700), 0.54, 1)
	_add_kenney_sprite(kenney_root, "prototype/slope_s", Vector2(-192, -2544), 0.44, 1)
	_add_kenney_sprite(kenney_root, "prototype/slope_s", Vector2(192, -2544), 0.44, 1)

	for x in [-1056.0, 1056.0]:
		_add_kenney_sprite(kenney_root, "prototype/wall_s", Vector2(x, -2960), 0.45, 2)
		_add_kenney_sprite(kenney_root, "prototype/wall_corner_s", Vector2(x, -2848), 0.40, 2)
	for x in [-256.0, 256.0]:
		_add_kenney_sprite(kenney_root, "prototype/column_s", Vector2(x, -2848), 0.48, 2)
		_add_kenney_sprite(kenney_root, "prototype/pole_s", Vector2(x, -2720), 0.52, 2)


func _place_base(asset_key: String, at: Vector2, size: float) -> void:
	_add_kenney_sprite(kenney_root, asset_key, at, size, -1)


func _add_kenney_sprite(parent: Node2D, asset_key: String, at: Vector2, size: float, z: int) -> void:
	var texture := _kenney_textures.get(asset_key) as Texture2D
	if texture == null:
		push_error("Missing Asset V2 texture: %s" % asset_key)
		return
	var sprite := Sprite2D.new()
	sprite.name = asset_key.replace("/", "_").capitalize()
	sprite.texture = texture
	sprite.position = at
	sprite.scale = Vector2.ONE * size
	sprite.z_index = z
	parent.add_child(sprite)


func _add_road_texture(parent: Node2D, path: String, node_name: String, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.z_index = z
	parent.add_child(sprite)


func _add_filled_rect(parent: Node2D, rect: Rect2, color: Color, node_name: String) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y),
	])
	parent.add_child(polygon)


func _add_region_outline(parent: Node2D, rect: Rect2, color: Color, node_name: String) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.width = 3.0
	line.default_color = color
	line.closed = true
	line.points = PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y),
	])
	parent.add_child(line)


func _add_anchor_marker(parent: Node2D, key: StringName, label_text: String, color: Color) -> void:
	var point: Vector2 = ANCHORS[key]
	var cross := Line2D.new()
	cross.name = String(key).capitalize() + "Cross"
	cross.width = 4.0
	cross.default_color = color
	cross.points = PackedVector2Array([
		point + Vector2(-24, 0), point + Vector2(24, 0),
		point, point + Vector2(0, -24), point + Vector2(0, 24),
	])
	parent.add_child(cross)
	var label := Label.new()
	label.name = String(key).capitalize() + "Label"
	label.text = label_text
	label.position = point + Vector2(28, 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	parent.add_child(label)


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
