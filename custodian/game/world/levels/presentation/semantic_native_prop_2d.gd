class_name SemanticNativeProp2D
extends Node2D

const DEFAULT_MANIFEST_PATH := "res://content/metadata/assets/meridian_civic_props_native.semantic.json"
const DEFAULT_TEXTURE_ROOT := "res://content/sprites/environment/props/meridian_civic/native"

static var _manifest_cache: Dictionary = {}

@export_file("*.json") var manifest_path := DEFAULT_MANIFEST_PATH
@export_dir var texture_root := DEFAULT_TEXTURE_ROOT

var runtime_family: StringName = &""
var variant_key: StringName = &""
var anchor_mode: StringName = &""
var role: StringName = &""
var collision_profile: StringName = &"none"
var native_size := Vector2i.ZERO
var uses_y_sort := false
var metadata: Dictionary = {}

var _sprite: Sprite2D


func configure(
		family_id: StringName,
		variant_id: StringName,
		production_spawn := true
) -> bool:
	clear()
	var entry := resolve_variant(manifest_path, family_id, variant_id)
	if entry.is_empty():
		push_warning("Unknown native prop variant %s/%s" % [family_id, variant_id])
		return false
	if production_spawn and bool(entry.get("review_required", false)):
		push_warning("Native prop %s/%s requires review before production use" % [family_id, variant_id])
		return false

	runtime_family = family_id
	variant_key = variant_id
	anchor_mode = StringName(entry.get("anchor_mode", "floor_contact"))
	role = StringName(entry.get("role", "physical_prop"))
	collision_profile = StringName(entry.get("collision_profile", "none"))
	native_size = _vector2i_from_array(entry.get("native_size", []))
	uses_y_sort = bool(entry.get("y_sort", false))
	# Non-y-sorted overlays remain below the physical-prop y-sort plane. The
	# authored parent owns sorting; this component only consumes the manifest's
	# requested participation without inventing geometry or collision.
	z_index = 0 if uses_y_sort else -1
	metadata = entry.duplicate(true)

	var source_file := String(entry.get("source_file", ""))
	var texture_path := "%s/%s/%s" % [texture_root, runtime_family, source_file]
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Native prop texture is unavailable: %s" % texture_path)
		clear()
		return false

	var crop_size := _vector2i_from_array(entry.get("crop_size", []))
	if Vector2i(texture.get_size()) != crop_size:
		push_error("Native prop crop contract mismatch: %s" % texture_path)
		clear()
		return false

	_sprite = Sprite2D.new()
	_sprite.name = "NativeSprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = texture
	_sprite.centered = true
	_sprite.scale = Vector2.ONE * float(entry.get("native_scale", 1.0))
	_sprite.position = Vector2(crop_size) * 0.5 - _vector2_from_array(entry.get("extract_anchor_px", []))
	_sprite.set_meta(&"runtime_family", runtime_family)
	_sprite.set_meta(&"variant_key", variant_key)
	_sprite.set_meta(&"anchor_mode", anchor_mode)
	_sprite.set_meta(&"native_size", native_size)
	_sprite.set_meta(&"role", role)
	_sprite.set_meta(&"collision_profile_hint", collision_profile)
	_sprite.set_meta(&"collision_is_authoritative", false)
	add_child(_sprite)
	return true


func clear() -> void:
	if _sprite != null and is_instance_valid(_sprite):
		_sprite.free()
	_sprite = null
	runtime_family = &""
	variant_key = &""
	anchor_mode = &""
	role = &""
	collision_profile = &"none"
	native_size = Vector2i.ZERO
	uses_y_sort = false
	metadata = {}


func get_sprite() -> Sprite2D:
	return _sprite


static func resolve_variant(
		path: String,
		family_id: StringName,
		variant_id: StringName
) -> Dictionary:
	var index := _get_manifest_index(path)
	return (index.get(String(family_id), {}) as Dictionary).get(String(variant_id), {}) as Dictionary


static func can_spawn_production(
		path: String,
		family_id: StringName,
		variant_id: StringName
) -> bool:
	var entry := resolve_variant(path, family_id, variant_id)
	return not entry.is_empty() and not bool(entry.get("review_required", false))


static func _get_manifest_index(path: String) -> Dictionary:
	if _manifest_cache.has(path):
		return _manifest_cache[path] as Dictionary
	var index: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_error("Semantic native prop manifest is unavailable: %s" % path)
		_manifest_cache[path] = index
		return index
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Semantic native prop manifest is invalid JSON: %s" % path)
		_manifest_cache[path] = index
		return index
	for entry_variant: Variant in (parsed as Dictionary).get("entries", []):
		var entry := entry_variant as Dictionary
		var family := String(entry.get("runtime_family", ""))
		var variant := String(entry.get("variant_key", ""))
		if family.is_empty() or variant.is_empty():
			continue
		if not index.has(family):
			index[family] = {}
		(index[family] as Dictionary)[variant] = entry
	_manifest_cache[path] = index
	return index


static func _vector2_from_array(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


static func _vector2i_from_array(value: Variant) -> Vector2i:
	if value is Array and (value as Array).size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO
