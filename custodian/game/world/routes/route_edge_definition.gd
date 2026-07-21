class_name RouteEdgeDefinition
extends RefCounted

const WORLD_ORIGIN := &"@world_origin"
const DIRECTIONS := [&"forward", &"back", &"lateral", &"exfil"]

var edge_id: StringName = &""
var from_node_id: StringName = &""
var exit_id: StringName = &""
var to_node_id: StringName = &""
var target_spawn_id: StringName = &""
var direction: StringName = &"forward"
var transition_style: StringName = &"fade"


func configure_from_dictionary(data: Dictionary) -> void:
	edge_id = StringName(str(data.get("edge_id", "")))
	from_node_id = StringName(str(data.get("from_node_id", "")))
	exit_id = StringName(str(data.get("exit_id", "")))
	to_node_id = StringName(str(data.get("to_node_id", "")))
	target_spawn_id = StringName(str(data.get("target_spawn_id", "")))
	direction = StringName(str(data.get("direction", "forward")))
	transition_style = StringName(str(data.get("transition_style", "fade")))


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if edge_id.is_empty():
		errors.append("edge_id is required")
	if from_node_id.is_empty():
		errors.append("from_node_id is required")
	if exit_id.is_empty():
		errors.append("exit_id is required")
	if to_node_id.is_empty():
		errors.append("to_node_id is required")
	if not DIRECTIONS.has(direction):
		errors.append("direction is invalid: %s" % direction)
	if to_node_id == WORLD_ORIGIN and direction != &"exfil":
		errors.append("an @world_origin target requires direction exfil")
	if to_node_id != WORLD_ORIGIN and target_spawn_id.is_empty():
		errors.append("target_spawn_id is required for a level target")
	return errors
