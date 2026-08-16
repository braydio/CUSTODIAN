extends RefCounted
class_name OperatorAnimationCatalog

const EXPECTED_SCHEMA := "custodian.operator_animation_catalog.v2"
const DEFAULT_PATH := "res://content/data/operator/generated/operator_animation_catalog.generated.json"

var _animations: Dictionary = {}
var _weapons: Dictionary = {}
var _loaded_path := ""


func load_catalog(path: String = DEFAULT_PATH) -> bool:
	_animations.clear()
	_weapons.clear()
	_loaded_path = path
	if not FileAccess.file_exists(path):
		push_error("Missing Operator animation catalog: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not (parsed is Dictionary) or parsed.get("schema", "") != EXPECTED_SCHEMA:
		push_error("Invalid Operator animation catalog schema: %s" % path)
		return false
	_animations = parsed.get("animations", {})
	_weapons = parsed.get("weapons", {})
	return true


func _key(profile: StringName, group: StringName, action: StringName, direction: StringName) -> String:
	return "%s/%s/%s/%s" % [profile, group, action, direction]


func has_animation(profile: StringName, group: StringName, action: StringName, direction: StringName) -> bool:
	return _animations.has(_key(profile, group, action, direction))


func get_animation(profile: StringName, group: StringName, action: StringName, direction: StringName, required := true) -> Dictionary:
	var semantic_key := _key(profile, group, action, direction)
	var entry: Variant = _animations.get(semantic_key, {})
	if required and not (entry is Dictionary and not entry.is_empty()):
		push_error("Missing Operator animation catalog entry: %s (%s)" % [semantic_key, _loaded_path])
	return entry if entry is Dictionary else {}


func get_layer(profile: StringName, group: StringName, action: StringName, direction: StringName, layer: StringName, required := true) -> Dictionary:
	var entry := get_animation(profile, group, action, direction, required)
	var layers: Variant = entry.get("layers", {})
	var value: Variant = layers.get(String(layer), {}) if layers is Dictionary else {}
	if required and not (value is Dictionary and not value.is_empty()):
		push_error("Missing Operator animation layer: %s/%s" % [_key(profile, group, action, direction), layer])
	return value if value is Dictionary else {}


func get_layer_path(profile: StringName, group: StringName, action: StringName, direction: StringName, layer: StringName, required := true) -> String:
	return String(get_layer(profile, group, action, direction, layer, required).get("path", ""))


func get_frame_count(profile: StringName, group: StringName, action: StringName, direction: StringName, layer: StringName) -> int:
	return int(get_layer(profile, group, action, direction, layer).get("frames", 0))


func get_frame_size(profile: StringName, group: StringName, action: StringName, direction: StringName, layer: StringName) -> Vector2i:
	var value: Variant = get_layer(profile, group, action, direction, layer).get("frame_size", [])
	return Vector2i(int(value[0]), int(value[1])) if value is Array and value.size() >= 2 else Vector2i.ZERO


func get_weapon_profile(weapon_id: StringName) -> StringName:
	return StringName(_weapons.get(String(weapon_id), {}).get("animation_profile", ""))


func get_weapon_presentation_mode(weapon_id: StringName) -> String:
	return String(_weapons.get(String(weapon_id), {}).get("presentation_mode", "hybrid"))


func get_weapon_held_texture(weapon_id: StringName, direction: StringName) -> String:
	return String(_weapons.get(String(weapon_id), {}).get("held", {}).get(String(direction), {}).get("path", ""))


func get_weapon_override(weapon_id: StringName, group: StringName, action: StringName, direction: StringName) -> Dictionary:
	var key := "%s/%s/%s" % [group, action, direction]
	var value: Variant = _weapons.get(String(weapon_id), {}).get("overrides", {}).get(key, {})
	return value if value is Dictionary else {}
