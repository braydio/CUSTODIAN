class_name LevelDefinition
extends RefCounted

const WORLD_INGRESS_DEFINITION_SCRIPT := preload("res://game/world/levels/world_ingress_definition.gd")

var level_id: StringName = &""
var display_name: String = ""
var route_scene_path: String = ""
var target_scene_path: String = ""
var authored_data_path: String = ""
var world_context: StringName = &""
var tags: Array[StringName] = []
var ingress: RefCounted


func configure_from_dictionary(data: Dictionary) -> void:
	level_id = StringName(str(data.get("level_id", "")))
	display_name = str(data.get("display_name", ""))
	route_scene_path = str(data.get("route_scene_path", ""))
	target_scene_path = str(data.get("target_scene_path", ""))
	authored_data_path = str(data.get("authored_data_path", ""))
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
	if ingress == null:
		errors.append("ingress definition is required")
	else:
		for ingress_error: String in ingress.validate():
			errors.append("ingress.%s" % ingress_error)
	return errors
