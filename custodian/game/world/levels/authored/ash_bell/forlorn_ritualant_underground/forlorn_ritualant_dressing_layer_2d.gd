class_name ForlornRitualantDressingLayer2D
extends Node2D

const PLACEMENT_PATH := "res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_dressing_placements.json"
const MANIFEST_PATH := "res://content/metadata/assets/lower_quarter_gothic_scifi_v2_extract.semantic.json"
const PLACEMENT_SCHEMA := "custodian.ritualant_dressing_placements.v1"
const MANIFEST_SCHEMA := "custodian.lower_quarter_gothic_scifi_v2_extract.v1"

var _debug_snapshot: Array[Dictionary] = []
var _errors := PackedStringArray()


func _ready() -> void:
	rebuild()


func rebuild() -> bool:
	for child in get_children():
		child.free()
	_debug_snapshot.clear()
	_errors.clear()
	var placements := _load_json(PLACEMENT_PATH)
	var manifest := _load_json(MANIFEST_PATH)
	if placements.is_empty() or manifest.is_empty():
		return false
	if String(placements.get("schema", "")) != PLACEMENT_SCHEMA:
		_fail("Unsupported Ritualant dressing schema: %s" % placements.get("schema", ""))
		return false
	if String(manifest.get("schema", "")) != MANIFEST_SCHEMA:
		_fail("Unsupported Ritualant dressing manifest: %s" % manifest.get("schema", ""))
		return false
	var variants := _index_variants(manifest)
	var seen_ids: Dictionary = {}
	for value: Variant in placements.get("placements", []):
		if not value is Dictionary:
			_fail("Ritualant dressing placement must be an object")
			return false
		var record := value as Dictionary
		var placement_id := String(record.get("id", ""))
		var variant_key := String(record.get("variant_key", ""))
		if placement_id.is_empty() or seen_ids.has(placement_id):
			_fail("Missing or duplicate Ritualant dressing id: %s" % placement_id)
			return false
		seen_ids[placement_id] = true
		var variant := variants.get(variant_key, {}) as Dictionary
		if variant.is_empty():
			_fail("Unknown Ritualant dressing variant: %s" % variant_key)
			return false
		if not _instantiate_record(record, variant):
			return false
	return true


func _index_variants(manifest: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for group_name in [&"props", &"walls"]:
		for value: Variant in manifest.get(group_name, []):
			var entry := value as Dictionary
			var key := String(entry.get("variant_key", ""))
			if key.is_empty() or result.has(key):
				_fail("Missing or duplicate dressing variant: %s" % key)
				continue
			result[key] = entry
	return result


func _instantiate_record(record: Dictionary, variant: Dictionary) -> bool:
	var texture_path := String(variant.get("runtime_path", ""))
	var texture := load(texture_path) as Texture2D
	if texture == null:
		_fail("Missing Ritualant dressing texture: %s" % texture_path)
		return false
	var expected_size := _vector2i(variant.get("runtime_size", []))
	if Vector2i(texture.get_size()) != expected_size:
		_fail("Dressing texture size mismatch for %s" % record.get("variant_key", ""))
		return false
	var position_value := _vector2(record.get("position", []))
	if not position_value.is_finite():
		_fail("Invalid Ritualant dressing position: %s" % record.get("id", ""))
		return false
	var sprite := Sprite2D.new()
	sprite.name = String(record.get("id", "")).to_pascal_case()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = texture
	sprite.position = position_value
	sprite.flip_h = bool(record.get("flip_h", false))
	sprite.z_as_relative = false
	sprite.z_index = int(record.get("z_index", 0))
	sprite.set_meta(&"placement_id", String(record.get("id", "")))
	sprite.set_meta(&"variant_key", String(record.get("variant_key", "")))
	sprite.set_meta(&"collision_is_authoritative", false)
	add_child(sprite)
	_debug_snapshot.append({
		"placement_id": sprite.get_meta(&"placement_id"),
		"variant_key": sprite.get_meta(&"variant_key"),
		"position": sprite.position,
		"flip_h": sprite.flip_h,
		"z_index": sprite.z_index,
		"texture_path": texture_path,
		"texture_size": Vector2i(texture.get_size()),
		"collision_enabled": false,
	})
	return true


func get_debug_snapshot() -> Array[Dictionary]:
	return _debug_snapshot.duplicate(true)


func get_errors() -> PackedStringArray:
	return _errors.duplicate()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("Missing Ritualant dressing data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_fail("Invalid Ritualant dressing JSON: %s" % path)
		return {}
	return parsed as Dictionary


func _fail(message: String) -> void:
	_errors.append(message)
	push_error(message)


func _vector2(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.INF


func _vector2i(value: Variant) -> Vector2i:
	if value is Array and (value as Array).size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO
