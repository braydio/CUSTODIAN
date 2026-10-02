extends RefCounted
class_name WorldPlacementContext

## Read-only query surface for placement services working on one accepted world.
## The map is retained by instance ID so callers never receive the live Node.
## Level data is copied on input and whenever it is returned.

var _accepted_map_instance_id: int = 0
var _level_data: Dictionary = {}
var _observer: Callable


func _init(accepted_map: Node = null, level_data: Dictionary = {}, observer: Callable = Callable()) -> void:
	if accepted_map != null and is_instance_valid(accepted_map):
		_accepted_map_instance_id = accepted_map.get_instance_id()
	_level_data = level_data.duplicate(true)
	_observer = observer


func has_accepted_map() -> bool:
	return _get_accepted_map() != null


func get_level_data_snapshot() -> Dictionary:
	return _level_data.duplicate(true)


func get_level_value(key: StringName, fallback: Variant = null) -> Variant:
	var value: Variant = _level_data.get(key, fallback)
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func has_anchor_tile(anchor_key: StringName) -> bool:
	return _level_data.get(anchor_key) is Vector2i


func get_anchor_tile(anchor_key: StringName) -> Vector2i:
	var value: Variant = _level_data.get(anchor_key)
	return value as Vector2i if value is Vector2i else Vector2i.ZERO


func get_compound_rect() -> Rect2i:
	var value: Variant = _level_data.get("compound_rect")
	return value as Rect2i if value is Rect2i else Rect2i()


func get_compound_ingress_tiles() -> Array[Vector2i]:
	return vector2i_items(_level_data.get("compound_ingress", []))


func get_compound_rooms_by_sector_id() -> Dictionary:
	var rooms := {}
	for room_variant in _level_data.get("compound_rooms", []):
		if not (room_variant is Dictionary):
			continue
		var room := room_variant as Dictionary
		var sector_id := String(room.get("sector_id", "")).strip_edges().to_upper()
		if sector_id.is_empty() or rooms.has(sector_id):
			continue
		rooms[sector_id] = room.duplicate(true)
	return rooms


func get_vector2i_items(key: StringName) -> Array[Vector2i]:
	return vector2i_items(_level_data.get(key, []))


static func vector2i_items(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if value is Array:
		for item in value:
			if item is Vector2i:
				result.append(item)
	return result


func get_region_type(tile: Vector2i) -> String:
	var map := _get_accepted_map()
	if map != null and map.has_method("get_region_type_at_tile"):
		return String(map.call("get_region_type_at_tile", tile))
	return "exterior"


func get_intensity(tile: Vector2i) -> float:
	var map := _get_accepted_map()
	if map != null and map.has_method("get_intensity_at_tile"):
		return float(map.call("get_intensity_at_tile", tile))
	return 0.0


func is_walkable_floor_tile(tile: Vector2i) -> bool:
	var map := _get_accepted_map()
	if map == null:
		return false
	if map.has_method("is_placement_floor_tile"):
		return bool(map.call("is_placement_floor_tile", tile))
	var walls_variant: Variant = map.get("walls_tilemap")
	if walls_variant is TileMapLayer and (walls_variant as TileMapLayer).get_cell_source_id(tile) >= 0:
		return false
	var floor_variant: Variant = map.get("floor_tilemap")
	if not (floor_variant is TileMapLayer) or (floor_variant as TileMapLayer).get_cell_source_id(tile) < 0:
		return false
	return not map.has_method("is_hole_tile") or not bool(map.call("is_hole_tile", tile))


func has_canonical_tile_transform() -> bool:
	var map := _get_accepted_map()
	return map != null and map.has_method("tile_to_global_position")


func tile_to_global_position(tile: Vector2i) -> Vector2:
	var map := _get_accepted_map()
	if map == null or not map.has_method("tile_to_global_position"):
		return Vector2.ZERO
	return map.call("tile_to_global_position", tile) as Vector2


func observe(event_name: StringName, payload: Dictionary) -> void:
	if not _observer.is_valid():
		return
	_observer.call(event_name, payload.duplicate(true))


static func stable_seed(values: Array[int]) -> int:
	var value := 2166136261
	for number in values:
		value = value ^ int(number)
		value = (value * 16777619) & 0x7fffffff
	return value


func _get_accepted_map() -> Node:
	if _accepted_map_instance_id <= 0:
		return null
	var instance := instance_from_id(_accepted_map_instance_id)
	if instance is Node and is_instance_valid(instance):
		return instance as Node
	return null
