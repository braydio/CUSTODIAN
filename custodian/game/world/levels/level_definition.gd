class_name LevelDefinition
extends RefCounted

const WORLD_INGRESS_DEFINITION_SCRIPT := preload("res://game/world/levels/world_ingress_definition.gd")
const PRESENTATION_PROFILES := [&"gameplay", &"vista_approach", &"cinematic"]
const CACHE_POLICIES := [&"destroy_on_exit", &"destroy_on_forward_exit", &"keep_during_route", &"snapshot_and_unload"]
const STATE_POLICIES := [&"session", &"persistent", &"reset_on_entry"]

var level_id: StringName = &""
var display_name: String = ""
var route_scene_path: String = ""
var target_scene_path: String = ""
var authored_data_path: String = ""
var playtest_scene_path: String = ""
var authoring_scene_path: String = ""
var design_doc_path: String = ""
var world_context: StringName = &""
var tags: Array[StringName] = []
var spawns: Array[StringName] = []
var ingress: RefCounted
var presentation_profile: StringName = &"gameplay"
var lifecycle: Dictionary = {
	"cache_policy": "keep_during_route",
	"state_policy": "session",
}


func configure_from_dictionary(data: Dictionary) -> void:
	level_id = StringName(str(data.get("level_id", "")))
	display_name = str(data.get("display_name", ""))
	route_scene_path = str(data.get("route_scene_path", ""))
	target_scene_path = str(data.get("target_scene_path", ""))
	authored_data_path = str(data.get("authored_data_path", ""))
	playtest_scene_path = str(data.get("playtest_scene_path", ""))
	authoring_scene_path = str(data.get("authoring_scene_path", ""))
	design_doc_path = str(data.get("design_doc_path", ""))
	world_context = StringName(str(data.get("world_context", "")))
	presentation_profile = StringName(str(data.get("presentation_profile", "gameplay")))
	var lifecycle_value: Variant = data.get("lifecycle", {})
	lifecycle = (lifecycle_value as Dictionary).duplicate(true) if lifecycle_value is Dictionary else {}
	if not lifecycle.has("cache_policy"):
		lifecycle["cache_policy"] = "keep_during_route"
	if not lifecycle.has("state_policy"):
		lifecycle["state_policy"] = "session"
	tags.clear()
	for tag: Variant in data.get("tags", []):
		tags.append(StringName(str(tag)))
	spawns.clear()
	for spawn_id: Variant in data.get("spawns", []):
		spawns.append(StringName(str(spawn_id)))
	var ingress_data: Variant = data.get("ingress", {})
	ingress = null
	if ingress_data is Dictionary and not ingress_data.is_empty():
		ingress = WORLD_INGRESS_DEFINITION_SCRIPT.new()
		ingress.call("configure_from_dictionary", ingress_data)


func get_entry_scene_path() -> String:
	if not route_scene_path.is_empty():
		return route_scene_path
	return target_scene_path


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if level_id.is_empty():
		errors.append("level_id is required")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required")
	if get_entry_scene_path().is_empty():
		errors.append("route_scene_path or target_scene_path is required")
	elif not ResourceLoader.exists(get_entry_scene_path(), "PackedScene"):
		errors.append("entry scene does not exist: %s" % get_entry_scene_path())
	if not target_scene_path.is_empty() and not ResourceLoader.exists(target_scene_path, "PackedScene"):
		errors.append("target scene does not exist: %s" % target_scene_path)
	if not authored_data_path.is_empty() and not FileAccess.file_exists(authored_data_path):
		errors.append("authored data does not exist: %s" % authored_data_path)
	_validate_optional_scene(playtest_scene_path, "playtest scene", errors)
	_validate_optional_scene(authoring_scene_path, "authoring scene", errors)
	if not design_doc_path.is_empty() and not _file_exists_project_relative(design_doc_path):
		errors.append("design doc does not exist: %s" % design_doc_path)
	if not PRESENTATION_PROFILES.has(presentation_profile):
		errors.append("presentation_profile is invalid: %s" % presentation_profile)
	var cache_policy := StringName(str(lifecycle.get("cache_policy", "")))
	if not CACHE_POLICIES.has(cache_policy):
		errors.append("lifecycle.cache_policy is invalid: %s" % cache_policy)
	var state_policy := StringName(str(lifecycle.get("state_policy", "")))
	if not STATE_POLICIES.has(state_policy):
		errors.append("lifecycle.state_policy is invalid: %s" % state_policy)
	if has_tag(&"world_ingress") and ingress == null:
		errors.append("ingress definition is required for world_ingress levels")
	elif ingress != null:
		for ingress_error: String in ingress.validate(has_tag(&"world_ingress")):
			errors.append("ingress.%s" % ingress_error)
	var seen_spawns: Dictionary = {}
	for spawn_id in spawns:
		if spawn_id.is_empty():
			errors.append("spawns cannot contain an empty ID")
		elif seen_spawns.has(spawn_id):
			errors.append("duplicate spawn ID: %s" % spawn_id)
		seen_spawns[spawn_id] = true
	return errors


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func get_presentation_profile() -> StringName:
	return presentation_profile


func get_lifecycle() -> Dictionary:
	return lifecycle.duplicate(true)


func has_declared_spawn(spawn_id: StringName) -> bool:
	return spawns.has(spawn_id)


func _validate_optional_scene(path: String, label: String, errors: PackedStringArray) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path, "PackedScene"):
		errors.append("%s does not exist: %s" % [label, path])


func _file_exists_project_relative(path: String) -> bool:
	if path.begins_with("res://") or path.begins_with("user://"):
		return FileAccess.file_exists(path)
	var absolute := ProjectSettings.globalize_path("res://").path_join(path).simplify_path()
	return FileAccess.file_exists(absolute)
