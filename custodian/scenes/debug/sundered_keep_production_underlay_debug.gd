extends Node2D

const TILE_SIZE := 32.0
const MAP_SIZE_TILES := Vector2i(112, 80)
const SPAWN_TILE := Vector2i(56, 76)
const GAMEPLAY_CAMERA_ZOOM := Vector2(0.84, 0.84)

var _camera_bounds := Rect2(Vector2.ZERO, Vector2(MAP_SIZE_TILES) * TILE_SIZE)

@onready var _operator: Node2D = $World/Operator
@onready var _camera: Camera2D = $World/Camera2D


func _ready() -> void:
	if _operator != null:
		_operator.global_position = minimap_tile_to_global(SPAWN_TILE)
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
	return minimap_tile_to_global(SPAWN_TILE)


func global_to_minimap_tile(global_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(floori(global_position.x / TILE_SIZE), 0, MAP_SIZE_TILES.x - 1),
		clampi(floori(global_position.y / TILE_SIZE), 0, MAP_SIZE_TILES.y - 1)
	)


func minimap_tile_to_global(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) + 0.5, float(tile.y) + 0.5) * TILE_SIZE


func get_underlay_debug_state() -> Dictionary:
	return {
		"map_size_tiles": MAP_SIZE_TILES,
		"spawn_tile": SPAWN_TILE,
		"entry_position": get_entry_position(),
		"camera_bounds": _camera_bounds,
		"camera_zoom": _camera.zoom if _camera != null else Vector2.ZERO,
		"operator_position": _operator.global_position if _operator != null else Vector2.ZERO,
		"tiles_enabled": false,
	}


func _has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false
