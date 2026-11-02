class_name LowerQuarterNativePropLayer2D
extends Node2D

const PLACEMENT_PATH := "res://game/world/levels/authored/ash_bell/common/lower_quarter_native_prop_placements.json"
const MANIFEST_PATH := "res://content/metadata/assets/meridian_civic_props_native.semantic.json"
const OVERRIDE_PATH := "res://game/world/levels/authored/ash_bell/common/lower_quarter_gothic_scifi_prop_overrides.json"
const NativeProp := preload("res://game/world/levels/presentation/semantic_native_prop_2d.gd")
const CELL_SIZE := 32

@export_enum("lower_quarter", "west_gate_works", "station_ix") var level_id := "lower_quarter"
@export var map_origin := Vector2.ZERO

var _debug_snapshot: Array[Dictionary] = []
var _errors := PackedStringArray()
var _overrides: Dictionary = {}
var _override_manifest_path := ""


func _ready() -> void:
	rebuild()


func rebuild() -> bool:
	for child in get_children():
		child.free()
	_debug_snapshot.clear()
	_errors.clear()
	_overrides.clear()
	_override_manifest_path = ""
	var override_document := _load_json(OVERRIDE_PATH)
	if not override_document.is_empty():
		_overrides = override_document.get("overrides", {}) as Dictionary
		_override_manifest_path = String(override_document.get("manifest", ""))
	var document := _load_json(PLACEMENT_PATH)
	if document.is_empty():
		return false
	var levels := document.get("levels", {}) as Dictionary
	var level := levels.get(level_id, {}) as Dictionary
	if level.is_empty():
		_fail("Unknown authored native-prop level: %s" % level_id)
		return false
	var authored_origin := _vector2(level.get("map_origin", []))
	if authored_origin != map_origin:
		_fail("Map origin mismatch for %s: scene=%s manifest=%s" % [level_id, map_origin, authored_origin])
		return false
	for record_variant: Variant in level.get("placements", []):
		if not bool((record_variant as Dictionary).get("enabled", true)):
			continue
		if not _instantiate_record(record_variant as Dictionary):
			return false
	return true


func _instantiate_record(record: Dictionary) -> bool:
	var placement_id := String(record.get("placement_id", ""))
	var cell := _vector2(record.get("cell", []))
	var offset := _vector2(record.get("offset_px", []))
	var calculated := map_origin + cell * CELL_SIZE + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0) + offset
	var expected := _vector2(record.get("world_anchor", []))
	if calculated != expected:
		_fail("World-anchor mismatch for %s: calculated=%s expected=%s" % [placement_id, calculated, expected])
		return false
	if int(record.get("rotation_quarters", 0)) != 0:
		_fail("Unsupported rotation contract for %s" % placement_id)
		return false
	var prop := NativeProp.new() as SemanticNativeProp2D
	prop.name = placement_id.to_pascal_case()
	prop.position = calculated
	prop.scale = Vector2.ONE
	prop.rotation = 0.0
	var resolved_record := record.duplicate(true)
	var override := _overrides.get(placement_id, {}) as Dictionary
	if not override.is_empty():
		resolved_record.merge(override, true)
		prop.manifest_path = _override_manifest_path
	if not prop.configure(
		StringName(resolved_record.get("runtime_family", "")),
		StringName(resolved_record.get("variant_key", "")),
		not bool(resolved_record.get("allow_review", false))
	):
		prop.free()
		_fail("Unable to resolve source_id %s for %s" % [record.get("source_id"), placement_id])
		return false
	# Collision is deliberately disabled for this visual-placement pass. Existing
	# authored topology remains authority until each footprint is route-proven.
	prop.set_meta(&"placement_id", placement_id)
	prop.set_meta(&"source_id", int(record.get("source_id", -1)))
	prop.set_meta(&"visual_override", not override.is_empty())
	prop.set_meta(&"collision_enabled", false)
	add_child(prop)
	var sprite := prop.get_sprite()
	_debug_snapshot.append({
		"placement_id": placement_id,
		"source_id": int(record.get("source_id", -1)),
		"resolved_texture": sprite.texture.resource_path if sprite != null else "",
		"root_world_position": calculated,
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
		_fail("Missing authored native-prop data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_fail("Invalid authored native-prop JSON: %s" % path)
		return {}
	return parsed as Dictionary


func _vector2(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.INF
