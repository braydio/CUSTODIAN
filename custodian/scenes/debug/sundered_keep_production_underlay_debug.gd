extends Node2D

const TILE_SIZE := 32.0
const MAP_SIZE_TILES := Vector2i(112, 80)
const GAMEPLAY_CAMERA_ZOOM := Vector2(0.84, 0.84)
const DEFAULT_UNDERLAY_RAIL_RADIUS := 18.0
const UNDERLAY_COLLISION_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_underlay_collision.json"
)

var _camera_bounds := Rect2(Vector2.ZERO, Vector2(MAP_SIZE_TILES) * TILE_SIZE)
var _underlay_collision_data: Dictionary = {}

@onready var _operator: Node2D = $World/Operator
@onready var _camera: Camera2D = $World/Camera2D


func _ready() -> void:
	_underlay_collision_data = _load_underlay_collision_data()
	_build_underlay_boundary_collision()
	_build_underlay_authoring_markers()

	if _operator != null:
		_operator.global_position = get_entry_position()
	if _camera != null:
		_camera.zoom = GAMEPLAY_CAMERA_ZOOM
		if _has_property(_camera, "base_zoom"):
			_camera.set("base_zoom", GAMEPLAY_CAMERA_ZOOM)
		if _has_property(_camera, "target_zoom"):
			_camera.set("target_zoom", GAMEPLAY_CAMERA_ZOOM)
		if _has_property(_camera, "auto_zoom_enabled"):
			_camera.set("auto_zoom_enabled", true)

	await get_tree().process_frame

	if _camera != null and _camera.has_method("set_runtime_map"):
		_camera.call("set_runtime_map", self)
	elif _camera != null and _operator != null:
		_camera.global_position = _operator.global_position


func get_camera_bounds() -> Rect2:
	return _camera_bounds


func get_entry_position() -> Vector2:
	return _marker_position("spawn", minimap_tile_to_global(Vector2i(56, 76)))


func global_to_minimap_tile(global_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(floori(global_position.x / TILE_SIZE), 0, MAP_SIZE_TILES.x - 1),
		clampi(floori(global_position.y / TILE_SIZE), 0, MAP_SIZE_TILES.y - 1)
	)


func minimap_tile_to_global(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) + 0.5, float(tile.y) + 0.5) * TILE_SIZE


func get_underlay_collision_data() -> Dictionary:
	return _underlay_collision_data.duplicate(true)


func get_underlay_debug_state() -> Dictionary:
	return {
		"map_size_tiles": MAP_SIZE_TILES,
		"spawn_tile": global_to_minimap_tile(get_entry_position()),
		"entry_position": get_entry_position(),
		"camera_bounds": _camera_bounds,
		"camera_zoom": _camera.zoom if _camera != null else Vector2.ZERO,
		"operator_position": _operator.global_position if _operator != null else Vector2.ZERO,
		"tiles_enabled": false,
		"collision_data_path": UNDERLAY_COLLISION_DATA_PATH,
		"underlay_boundary_segments": _segments().size(),
		"authoring_markers": get_underlay_authoring_marker_state(),
	}


func get_underlay_authoring_marker_state() -> Dictionary:
	var result := {}
	for marker_id: String in _markers().keys():
		var marker_data := _markers()[marker_id] as Dictionary
		var position := _array_to_vector2(marker_data.get("position", []), Vector2.ZERO)
		result[marker_id] = {
			"kind": str(marker_data.get("kind", marker_id)),
			"label": str(marker_data.get("label", marker_id)),
			"position": position,
			"tile": global_to_minimap_tile(position),
		}
		if marker_data.has("lane"):
			result[marker_id]["lane"] = str(marker_data.get("lane", ""))
	return result


func _load_underlay_collision_data() -> Dictionary:
	var file := FileAccess.open(UNDERLAY_COLLISION_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("[SunderedKeepUnderlayDebug] Missing collision data: %s" % UNDERLAY_COLLISION_DATA_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("[SunderedKeepUnderlayDebug] Invalid collision JSON: %s" % UNDERLAY_COLLISION_DATA_PATH)
		return {}
	var data := parsed as Dictionary
	if str(data.get("schema", "")) != "custodian.sundered_keep.underlay_collision.v1":
		push_error("[SunderedKeepUnderlayDebug] Unsupported collision schema")
		return {}
	return data


func _segments() -> Array:
	return _underlay_collision_data.get("segments", []) as Array


func _markers() -> Dictionary:
	return _underlay_collision_data.get("markers", {}) as Dictionary


func _marker_position(marker_id: String, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var marker_data: Variant = _markers().get(marker_id, {})
	if marker_data is Dictionary:
		return _array_to_vector2((marker_data as Dictionary).get("position", []), fallback)
	return fallback


func _build_underlay_boundary_collision() -> void:
	var world := get_node_or_null("World") as Node2D
	if world == null:
		return

	var bounds_root := world.get_node_or_null("MappedUnderlayBounds") as Node2D
	if bounds_root == null:
		bounds_root = Node2D.new()
		bounds_root.name = "MappedUnderlayBounds"
		world.add_child(bounds_root)
	_clear_children(bounds_root)

	var body := StaticBody2D.new()
	body.name = "UnderlayBoundaryCollision"
	body.collision_layer = 1
	body.collision_mask = 1
	bounds_root.add_child(body)

	var radius := float(_underlay_collision_data.get("rail_radius", DEFAULT_UNDERLAY_RAIL_RADIUS))
	var index := 1
	for segment_variant: Variant in _segments():
		if not (segment_variant is Array):
			continue
		var segment := segment_variant as Array
		if segment.size() < 2:
			continue
		_add_underlay_boundary_segment(
			body,
			"UnderlayBoundarySegment_%03d" % index,
			_array_to_vector2(segment[0], Vector2.ZERO),
			_array_to_vector2(segment[1], Vector2.ZERO),
			radius
		)
		index += 1


func _build_underlay_authoring_markers() -> void:
	var world := get_node_or_null("World") as Node2D
	if world == null:
		return
	var root := world.get_node_or_null("UnderlayAuthoringMarkers") as Node2D
	if root == null:
		root = Node2D.new()
		root.name = "UnderlayAuthoringMarkers"
		world.add_child(root)
	_clear_children(root)
	root.z_as_relative = false
	root.z_index = 200
	for marker_id: String in _markers().keys():
		var marker_data := _markers()[marker_id] as Dictionary
		var marker := Marker2D.new()
		marker.name = marker_id.to_pascal_case()
		marker.position = _array_to_vector2(marker_data.get("position", []), Vector2.ZERO)
		marker.set_meta("marker_id", marker_id)
		marker.set_meta("marker_kind", str(marker_data.get("kind", marker_id)))
		root.add_child(marker)
		_add_underlay_marker_visual(
			marker,
			str(marker_data.get("label", marker_id.to_upper())),
			_underlay_marker_color(str(marker_data.get("kind", marker_id)))
		)


func _add_underlay_marker_visual(parent: Node2D, label: String, color: Color) -> void:
	var swatch := Polygon2D.new()
	swatch.name = "MarkerSwatch"
	swatch.polygon = PackedVector2Array([
		Vector2(0.0, -14.0),
		Vector2(14.0, 0.0),
		Vector2(0.0, 14.0),
		Vector2(-14.0, 0.0),
	])
	swatch.color = color
	parent.add_child(swatch)
	var text := Label.new()
	text.name = "MarkerLabel"
	text.text = label
	text.position = Vector2(18.0, -18.0)
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78, 0.96))
	parent.add_child(text)


func _underlay_marker_color(kind: String) -> Color:
	match kind:
		"spawn":
			return Color(0.42, 0.85, 1.0, 0.85)
		"return_causeway":
			return Color(0.56, 0.72, 1.0, 0.85)
		"key":
			return Color(1.0, 0.82, 0.30, 0.90)
		"gate":
			return Color(1.0, 0.42, 0.24, 0.90)
		"level_exit":
			return Color(0.46, 1.0, 0.58, 0.90)
		"enemy_spawn":
			return Color(1.0, 0.20, 0.24, 0.90)
		_:
			return Color(0.92, 0.92, 0.92, 0.85)


func _add_underlay_boundary_segment(
	parent: StaticBody2D,
	node_name: String,
	a: Vector2,
	b: Vector2,
	radius: float
) -> CollisionShape2D:
	var direction := b - a
	var length := direction.length()
	var rail := CapsuleShape2D.new()
	rail.radius = radius
	rail.height = maxf(length + radius * 2.0, radius * 2.0)

	var shape := CollisionShape2D.new()
	shape.name = node_name
	shape.shape = rail
	shape.position = (a + b) * 0.5
	if length > 0.001:
		shape.rotation = direction.angle() - PI * 0.5
	shape.set_meta("boundary_a", a)
	shape.set_meta("boundary_b", b)
	shape.set_meta("collision_authority", "underlay_mapper")
	parent.add_child(shape)
	return shape


func _array_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false
