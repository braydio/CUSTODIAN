class_name LowerQuarterNativeWallModuleLayer2D
extends Node2D

const PLACEMENT_PATH := "res://game/world/levels/authored/ash_bell/common/lower_quarter_gothic_scifi_wall_placements.json"
const MANIFEST_PATH := "res://content/metadata/assets/lower_quarter_gothic_scifi_walls_native.semantic.json"
const NativeProp := preload("res://game/world/levels/presentation/semantic_native_prop_2d.gd")
const CELL_SIZE := 32

@export var map_origin := Vector2.ZERO

var _errors := PackedStringArray()
var _debug_snapshot: Array[Dictionary] = []


func _ready() -> void:
	if not rebuild():
		push_error("Lower Quarter Gothic wall module layer failed to build")


func rebuild() -> bool:
	for child in get_children():
		child.free()
	_errors.clear()
	_debug_snapshot.clear()
	var document := _load_json(PLACEMENT_PATH)
	if document.is_empty():
		return false
	if _vector2(document.get("map_origin", [])) != map_origin:
		_fail("Gothic wall map origin mismatch")
		return false
	for record_variant: Variant in document.get("placements", []):
		if not _instantiate_record(record_variant as Dictionary):
			return false
	return true


func _instantiate_record(record: Dictionary) -> bool:
	var placement_id := String(record.get("placement_id", ""))
	var cell := _vector2(record.get("cell", []))
	var offset := _vector2(record.get("offset_px", []))
	var calculated := map_origin + cell * CELL_SIZE + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0) + offset
	if calculated != _vector2(record.get("world_anchor", [])):
		_fail("Gothic wall world-anchor mismatch for %s" % placement_id)
		return false
	if int(record.get("rotation_quarters", 0)) != 0 or bool(record.get("mirror", false)):
		_fail("Gothic wall %s violates no-rotation/no-mirror contract" % placement_id)
		return false
	var prop := NativeProp.new() as SemanticNativeProp2D
	prop.name = placement_id.to_pascal_case()
	prop.position = calculated
	prop.scale = Vector2.ONE
	prop.manifest_path = MANIFEST_PATH
	if not prop.configure(
		StringName(record.get("runtime_family", "")),
		StringName(record.get("variant_key", "")),
		not bool(record.get("allow_review", false))
	):
		prop.free()
		_fail("Unable to resolve Gothic wall %s" % placement_id)
		return false
	prop.set_meta(&"collision_enabled", false)
	prop.set_meta(&"placement_id", placement_id)
	add_child(prop)
	var sprite := prop.get_sprite()
	_debug_snapshot.append({
		"placement_id": placement_id,
		"resolved_texture": sprite.texture.resource_path if sprite != null else "",
		"root_world_position": calculated,
		"scale": prop.scale,
		"rotation": prop.rotation,
		"mirror": false,
		"collision_enabled": false,
	})
	return true


func get_debug_snapshot() -> Array[Dictionary]:
	return _debug_snapshot.duplicate(true)


func get_errors() -> PackedStringArray:
	return _errors.duplicate()


func _fail(message: String) -> void:
	_errors.append(message)
	push_error(message)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("Missing Gothic wall placement data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_fail("Invalid Gothic wall placement JSON: %s" % path)
		return {}
	return parsed as Dictionary


func _vector2(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.INF
