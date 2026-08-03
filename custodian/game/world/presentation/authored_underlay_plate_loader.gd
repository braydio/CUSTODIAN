@tool
class_name AuthoredUnderlayPlateLoader
extends Node2D

signal manifest_loaded(plate_count: int)
signal initial_region_ready()
signal plate_loaded(plate_id: StringName)
signal plate_unloaded(plate_id: StringName)

const SUPPORTED_SCHEMA := "custodian.authored_underlay_plate_manifest.v1"

@export_file("*.json") var manifest_path := ""
@export var streaming_enabled := true
@export var preview_all_in_editor := false
@export var camera_path: NodePath
@export_range(0.01, 2.0, 0.01) var streaming_refresh_sec := 0.12
@export_range(0.0, 8192.0, 1.0) var preload_margin_world := 768.0
@export_range(0.0, 16384.0, 1.0) var unload_margin_world := 1536.0
@export_range(1, 32, 1) var max_loads_per_tick := 2
@export var load_initial_view_synchronously := true

var _manifest: Dictionary = {}
var _plate_definitions: Array[Dictionary] = []
var _loaded_plates: Dictionary = {}
var _plate_root: Node2D
var _camera: Camera2D
var _streaming_accumulator := 0.0
var _initial_region_emitted := false


func _ready() -> void:
	_plate_root = get_node_or_null("PlateRoot") as Node2D
	if _plate_root == null:
		_plate_root = Node2D.new()
		_plate_root.name = "PlateRoot"
		add_child(_plate_root)

	if Engine.is_editor_hint() and not preview_all_in_editor:
		return

	if not reload_manifest():
		return

	if Engine.is_editor_hint() or not streaming_enabled:
		force_load_all()
		_emit_initial_region_ready_once()
		return

	_resolve_camera()
	_refresh_streaming(load_initial_view_synchronously)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not streaming_enabled or _plate_definitions.is_empty():
		return

	_streaming_accumulator += maxf(delta, 0.0)
	if _streaming_accumulator < streaming_refresh_sec:
		return
	_streaming_accumulator = 0.0

	_resolve_camera()
	_refresh_streaming(false)


func reload_manifest() -> bool:
	clear_loaded()
	_plate_definitions.clear()
	_manifest.clear()

	if manifest_path.is_empty():
		push_error("[AuthoredUnderlayPlateLoader] manifest_path is empty.")
		return false
	if not FileAccess.file_exists(manifest_path):
		push_error(
			"[AuthoredUnderlayPlateLoader] Missing manifest: %s"
			% manifest_path
		)
		return false

	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(manifest_path)
	)
	if not (parsed is Dictionary):
		push_error(
			"[AuthoredUnderlayPlateLoader] Manifest root is not an object: %s"
			% manifest_path
		)
		return false

	_manifest = parsed as Dictionary
	if String(_manifest.get("schema", "")) != SUPPORTED_SCHEMA:
		push_error(
			"[AuthoredUnderlayPlateLoader] Unsupported schema: %s"
			% String(_manifest.get("schema", ""))
		)
		_manifest.clear()
		return false

	for value: Variant in (_manifest.get("plates", []) as Array):
		if value is Dictionary:
			_plate_definitions.append(value as Dictionary)

	var layout := _manifest.get("layout", {}) as Dictionary
	z_as_relative = false
	z_index = int(layout.get("z_index", -120))
	manifest_loaded.emit(_plate_definitions.size())
	return true


func force_load_all() -> void:
	for definition: Dictionary in _plate_definitions:
		_load_plate(definition)


func clear_loaded() -> void:
	for plate_id_variant: Variant in _loaded_plates.keys():
		_unload_plate(StringName(plate_id_variant))
	_loaded_plates.clear()
	_initial_region_emitted = false


func get_loaded_plate_count() -> int:
	return _loaded_plates.size()


func get_manifest_plate_count() -> int:
	return _plate_definitions.size()


func get_master_world_rect() -> Rect2:
	var layout := _manifest.get("layout", {}) as Dictionary
	return _array_to_rect2(layout.get("master_world_rect", []) as Array)


func get_manifest() -> Dictionary:
	return _manifest.duplicate(true)


func _resolve_camera() -> void:
	if _camera != null and is_instance_valid(_camera):
		return
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path) as Camera2D
	if _camera == null:
		_camera = get_viewport().get_camera_2d()


func _refresh_streaming(force_all_desired: bool) -> void:
	if _camera == null:
		# Fail visibly rather than leave the authored level blank.
		force_load_all()
		_emit_initial_region_ready_once()
		return

	var view_rect := _get_camera_world_rect(_camera)
	var load_rect := view_rect.grow(preload_margin_world)
	var keep_rect := view_rect.grow(
		maxf(unload_margin_world, preload_margin_world)
	)

	var desired: Array[Dictionary] = []
	var desired_ids := {}

	for definition: Dictionary in _plate_definitions:
		var plate_rect := _definition_world_rect(definition)
		var plate_id := StringName(String(definition.get("id", "")))
		if plate_id.is_empty():
			continue
		if plate_rect.intersects(load_rect, true):
			desired.append(definition)
			desired_ids[plate_id] = true

	for loaded_id_variant: Variant in _loaded_plates.keys():
		var loaded_id := StringName(loaded_id_variant)
		var definition := _find_definition(loaded_id)
		if definition.is_empty():
			_unload_plate(loaded_id)
			continue
		if not _definition_world_rect(definition).intersects(
			keep_rect,
			true
		):
			_unload_plate(loaded_id)

	desired.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_distance := (
				_definition_world_rect(a).get_center()
				.distance_squared_to(view_rect.get_center())
			)
			var b_distance := (
				_definition_world_rect(b).get_center()
				.distance_squared_to(view_rect.get_center())
			)
			if is_equal_approx(a_distance, b_distance):
				return String(a.get("id", "")) < String(b.get("id", ""))
			return a_distance < b_distance
	)

	var remaining := desired.size() if force_all_desired else max_loads_per_tick
	for definition: Dictionary in desired:
		if remaining <= 0:
			break
		var plate_id := StringName(String(definition.get("id", "")))
		if _loaded_plates.has(plate_id):
			continue
		if _load_plate(definition):
			remaining -= 1

	if _all_desired_loaded(desired_ids):
		_emit_initial_region_ready_once()


func _all_desired_loaded(desired_ids: Dictionary) -> bool:
	for plate_id: Variant in desired_ids.keys():
		if not _loaded_plates.has(plate_id):
			return false
	return true


func _emit_initial_region_ready_once() -> void:
	if _initial_region_emitted:
		return
	_initial_region_emitted = true
	initial_region_ready.emit()


func _load_plate(definition: Dictionary) -> bool:
	var plate_id := StringName(String(definition.get("id", "")))
	if plate_id.is_empty():
		return false
	if _loaded_plates.has(plate_id):
		return true

	var texture_path := String(definition.get("res_path", ""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		push_error(
			"[AuthoredUnderlayPlateLoader] Missing plate resource: %s"
			% texture_path
		)
		return false

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error(
			"[AuthoredUnderlayPlateLoader] Could not load texture: %s"
			% texture_path
		)
		return false

	var sprite := Sprite2D.new()
	sprite.name = "Plate_%s" % String(plate_id)
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = _array_to_rect2(
		definition.get("texture_core_rect", []) as Array
	)
	sprite.region_filter_clip_enabled = false

	var world_rect := _definition_world_rect(definition)
	sprite.position = world_rect.position
	var units_per_pixel := float(
		definition.get("world_units_per_pixel", 1.0)
	)
	sprite.scale = Vector2(units_per_pixel, units_per_pixel)
	sprite.z_as_relative = true
	sprite.z_index = 0
	sprite.texture_filter = _get_texture_filter()

	_plate_root.add_child(sprite)
	_loaded_plates[plate_id] = sprite
	plate_loaded.emit(plate_id)
	return true


func _unload_plate(plate_id: StringName) -> void:
	var node := _loaded_plates.get(plate_id) as Node
	_loaded_plates.erase(plate_id)
	if node != null and is_instance_valid(node):
		node.queue_free()
	plate_unloaded.emit(plate_id)


func _find_definition(plate_id: StringName) -> Dictionary:
	for definition: Dictionary in _plate_definitions:
		if StringName(String(definition.get("id", ""))) == plate_id:
			return definition
	return {}


func _definition_world_rect(definition: Dictionary) -> Rect2:
	return _array_to_rect2(definition.get("world_rect", []) as Array)


func _get_camera_world_rect(camera: Camera2D) -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_zoom := Vector2(
		maxf(camera.zoom.x, 0.0001),
		maxf(camera.zoom.y, 0.0001)
	)
	var world_size := viewport_size / safe_zoom
	var center := camera.get_screen_center_position()
	return Rect2(center - world_size * 0.5, world_size)


func _get_texture_filter() -> CanvasItem.TextureFilter:
	var layout := _manifest.get("layout", {}) as Dictionary
	match String(layout.get("texture_filter", "linear_mipmaps")):
		"nearest":
			return CanvasItem.TEXTURE_FILTER_NEAREST
		"linear":
			return CanvasItem.TEXTURE_FILTER_LINEAR
		"nearest_mipmaps":
			return CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		_:
			return CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _array_to_rect2(values: Array) -> Rect2:
	if values.size() < 4:
		return Rect2()
	return Rect2(
		float(values[0]),
		float(values[1]),
		float(values[2]),
		float(values[3])
	)
