class_name AshBellCatastrophePropLayer2D
extends Node2D

const PLACEMENT_PATH := "res://game/world/levels/authored/ash_bell/common/ash_bell_catastrophe_prop_placements.json"
const MANIFEST_PATH := "res://content/metadata/assets/meridian_civic_ruins_native.semantic.json"
const TEXTURE_ROOT := "res://content/sprites/environment/props/meridian_civic/ruins_native"
const NativeProp := preload("res://game/world/levels/presentation/semantic_native_prop_2d.gd")
const CELL_SIZE := 32

@export var map_origin := Vector2.ZERO

var _debug_snapshot: Array[Dictionary] = []
var _errors := PackedStringArray()
var _manifest_by_id: Dictionary = {}


func _ready() -> void:
	rebuild()


func rebuild() -> bool:
	for child in get_children():
		child.free()
	_debug_snapshot.clear()
	_errors.clear()
	_manifest_by_id.clear()
	var semantic_document := _load_json(MANIFEST_PATH)
	if semantic_document.is_empty():
		return false
	for entry_variant: Variant in semantic_document.get("entries", []):
		var entry := entry_variant as Dictionary
		_manifest_by_id[int(entry.get("source_id", -1))] = entry
	var document := _load_json(PLACEMENT_PATH)
	if document.is_empty():
		return false
	if String(document.get("level_id", "")) != "lower_quarter":
		_fail("Catastrophe placement authority targets an unexpected level")
		return false
	var authored_origin := _vector2(document.get("map_origin", []))
	if authored_origin != map_origin:
		_fail("Catastrophe map origin mismatch: scene=%s manifest=%s" % [map_origin, authored_origin])
		return false
	for record_variant: Variant in document.get("placements", []):
		if not _instantiate_record(record_variant as Dictionary):
			return false
	return true


func _instantiate_record(record: Dictionary) -> bool:
	if not bool(record.get("enabled", true)):
		return true
	var placement_id := String(record.get("placement_id", ""))
	var scale_contract := _vector2(record.get("scale", []))
	if scale_contract != Vector2.ONE:
		_fail("Catastrophe prop %s violates native scale" % placement_id)
		return false
	if bool(record.get("collision_enabled", true)):
		_fail("Catastrophe prop %s attempts to own collision" % placement_id)
		return false
	var cell := _vector2(record.get("cell", []))
	var offset := _vector2(record.get("offset_px", []))
	var world_anchor := map_origin + cell * CELL_SIZE + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0) + offset
	var source_id := int(record.get("source_id", -1))
	var semantic := _manifest_by_id.get(source_id, {}) as Dictionary
	if semantic.is_empty():
		_fail("Unknown catastrophe source_id %s for %s" % [source_id, placement_id])
		return false
	if String(semantic.get("semantic_name", "")) != String(record.get("semantic_name", "")):
		_fail("Catastrophe semantic mismatch for %s" % placement_id)
		return false
	var prop := NativeProp.new() as SemanticNativeProp2D
	prop.name = placement_id.to_pascal_case()
	prop.position = world_anchor
	prop.scale = Vector2.ONE
	prop.rotation = 0.0
	prop.manifest_path = MANIFEST_PATH
	prop.texture_root = TEXTURE_ROOT
	# This layer is itself exact authored authority. review_required compound
	# extracts are allowed here only because their explicit placement is named in
	# the checked-in placement document; generic production selection stays shut.
	if not prop.configure(
			StringName(semantic.get("runtime_family", "")),
			StringName(semantic.get("variant_key", "")),
			false
	):
		prop.free()
		_fail("Unable to resolve catastrophe source_id %s for %s" % [source_id, placement_id])
		return false
	prop.set_meta(&"placement_id", placement_id)
	prop.set_meta(&"source_id", source_id)
	prop.set_meta(&"history_layer", &"catastrophe_aftermath")
	prop.set_meta(&"collision_enabled", false)
	add_child(prop)
	var sprite := prop.get_sprite()
	_debug_snapshot.append({
		"placement_id": placement_id,
		"source_id": source_id,
		"zone": String(record.get("zone", "")),
		"resolved_texture": sprite.texture.resource_path if sprite != null else "",
		"root_world_position": world_anchor,
		"native_size": prop.native_size,
		"anchor": prop.anchor_mode,
		"role": prop.role,
		"scale": prop.scale,
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
		_fail("Missing authored catastrophe data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_fail("Invalid authored catastrophe JSON: %s" % path)
		return {}
	return parsed as Dictionary


func _vector2(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.INF
