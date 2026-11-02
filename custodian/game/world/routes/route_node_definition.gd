class_name RouteNodeDefinition
extends RefCounted

const WORLD_ORIGIN := &"@world_origin"

var node_id: StringName = &""
var level_id: StringName = &""


func configure_from_dictionary(data: Dictionary) -> void:
	node_id = StringName(str(data.get("node_id", "")))
	level_id = StringName(str(data.get("level_id", "")))


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if node_id.is_empty():
		errors.append("node_id is required")
	if node_id == WORLD_ORIGIN:
		errors.append("@world_origin is reserved and cannot be a route node")
	if level_id.is_empty():
		errors.append("level_id is required")
	return errors
