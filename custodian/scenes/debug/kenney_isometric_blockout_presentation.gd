class_name KenneyIsometricBlockoutPresentation
extends RefCounted

const ROAD_SCRIPT := preload("res://game/world/hub/road_of_witnesses_prototype.gd")
const CELL_SIZE := 32
const EVALUATION_BOUNDS := Rect2(-2600, -4300, 5200, 4650)

const ANCHORS := {
	&"spawn_south_reach": Vector2(-6, 162),
	&"forum_south": Vector2(0, -2464),
	&"adjudication_dais": Vector2(0, -3136),
}

const SAMPLE_REGIONS := {
	&"north_processional": Rect2(-512, -2400, 1024, 1152),
	&"ashen_forum": Rect2(-1280, -4032, 2560, 1792),
}

const KENNEY_DOMAIN := "res://content/tiles/experiments/kenney_feasibility"
const PROTOTYPE_STATES := [
	"floor_s", "slab_s", "block_s", "wall_s", "wall_corner_s",
	"stairs_s", "slope_s", "doorway_s", "column_s", "pole_s",
]
const BASE_STATES := [
	"base_grass_flat_s", "base_stone_flat_s", "base_stone_high_s",
	"square_stone_flat_s", "base_dirt_detail_s", "square_dirt_high_s",
]


static func load_kenney_textures() -> Dictionary:
	var textures := {}
	for state in PROTOTYPE_STATES:
		var path := "%s/kenney_iso_miniature_prototype_ref_%s_256.png" % [KENNEY_DOMAIN, state]
		textures["prototype/%s" % state] = load(path) as Texture2D
	for state in BASE_STATES:
		var path := "%s/kenney_iso_miniature_bases_ref_%s_256.png" % [KENNEY_DOMAIN, state]
		textures["bases/%s" % state] = load(path) as Texture2D
	return textures


static func selected_textures_valid(textures: Dictionary) -> bool:
	if textures.size() != PROTOTYPE_STATES.size() + BASE_STATES.size():
		return false
	for texture: Variant in textures.values():
		if not texture is Texture2D or texture.get_size() != Vector2(256, 512):
			return false
	return true


static func build(
	shared_sample: Node2D,
	anchor_markers: Node2D,
	native_root: Node2D,
	kenney_root: Node2D,
	textures: Dictionary
) -> void:
	_build_shared_sample(shared_sample, anchor_markers)
	_build_native_presentation(native_root)
	_build_kenney_presentation(kenney_root, textures)


static func _build_shared_sample(shared_sample: Node2D, anchor_markers: Node2D) -> void:
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


static func _build_native_presentation(native_root: Node2D) -> void:
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


static func _build_kenney_presentation(kenney_root: Node2D, textures: Dictionary) -> void:
	# Presentation-only floor pieces; the shared anchors and extents remain unchanged.
	for row in range(10):
		var y := -1264.0 - float(row) * 128.0
		for column in range(9):
			var x := -512.0 + float(column) * 128.0
			_add_kenney_sprite(kenney_root, "prototype/floor_s", Vector2(x, y), 0.58, -3, textures)

	# Bases and props repeat the bounded vocabulary at the Forum threshold and dais.
	_place_base(kenney_root, "bases/base_grass_flat_s", Vector2(-896, -3040), 0.90, textures)
	_place_base(kenney_root, "bases/base_grass_flat_s", Vector2(896, -3040), 0.90, textures)
	_place_base(kenney_root, "bases/base_stone_flat_s", Vector2(-608, -3120), 0.95, textures)
	_place_base(kenney_root, "bases/base_stone_flat_s", Vector2(608, -3120), 0.95, textures)
	_place_base(kenney_root, "bases/base_stone_high_s", Vector2(0, -3040), 1.25, textures)
	_place_base(kenney_root, "bases/square_stone_flat_s", Vector2(-1088, -2992), 0.92, textures)
	_place_base(kenney_root, "bases/square_stone_flat_s", Vector2(1088, -2992), 0.92, textures)
	_place_base(kenney_root, "bases/base_dirt_detail_s", Vector2(-1280, -3040), 0.88, textures)
	_place_base(kenney_root, "bases/square_dirt_high_s", Vector2(1280, -2960), 0.88, textures)

	for x in [-192.0, 0.0, 192.0]:
		_add_kenney_sprite(kenney_root, "prototype/slab_s", Vector2(x, -3008), 0.56, 0, textures)
	_add_kenney_sprite(kenney_root, "prototype/block_s", Vector2(0, -2912), 0.48, 1, textures)
	_add_kenney_sprite(kenney_root, "prototype/doorway_s", Vector2(0, -2500), 0.48, 1, textures)
	_add_kenney_sprite(kenney_root, "prototype/stairs_s", Vector2(0, -2700), 0.54, 1, textures)
	_add_kenney_sprite(kenney_root, "prototype/slope_s", Vector2(-192, -2544), 0.44, 1, textures)
	_add_kenney_sprite(kenney_root, "prototype/slope_s", Vector2(192, -2544), 0.44, 1, textures)

	for x in [-1056.0, 1056.0]:
		_add_kenney_sprite(kenney_root, "prototype/wall_s", Vector2(x, -2960), 0.45, 2, textures)
		_add_kenney_sprite(kenney_root, "prototype/wall_corner_s", Vector2(x, -2848), 0.40, 2, textures)
	for x in [-256.0, 256.0]:
		_add_kenney_sprite(kenney_root, "prototype/column_s", Vector2(x, -2848), 0.48, 2, textures)
		_add_kenney_sprite(kenney_root, "prototype/pole_s", Vector2(x, -2720), 0.52, 2, textures)


static func _place_base(parent: Node2D, asset_key: String, at: Vector2, size: float, textures: Dictionary) -> void:
	_add_kenney_sprite(parent, asset_key, at, size, -1, textures)


static func _add_kenney_sprite(parent: Node2D, asset_key: String, at: Vector2, size: float, z: int, textures: Dictionary) -> void:
	var texture := textures.get(asset_key) as Texture2D
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


static func _add_road_texture(parent: Node2D, path: String, node_name: String, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.z_index = z
	parent.add_child(sprite)


static func _add_filled_rect(parent: Node2D, rect: Rect2, color: Color, node_name: String) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y),
	])
	parent.add_child(polygon)


static func _add_region_outline(parent: Node2D, rect: Rect2, color: Color, node_name: String) -> void:
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


static func _add_anchor_marker(parent: Node2D, key: StringName, label_text: String, color: Color) -> void:
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
