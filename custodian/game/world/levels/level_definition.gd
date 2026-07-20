class_name LevelDefinition
extends RefCounted

const WORLD_INGRESS_DEFINITION_SCRIPT := preload("res://game/world/levels/world_ingress_definition.gd")

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
var ingress: RefCounted


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
	tags.clear()
	for tag: Variant in data.get("tags", []):
		tags.append(StringName(str(tag)))
	var ingress_data: Variant = data.get("ingress", {})
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
	if ingress == null:
		errors.append("ingress definition is required")
	else:
		for ingress_error: String in ingress.validate():
			errors.append("ingress.%s" % ingress_error)
	return errors


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


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
