class_name RouteTransitionContext
extends RefCounted

var route_id: StringName = &""
var profile_id: StringName = &""
var edge_id: StringName = &""
var source_node_id: StringName = &""
var target_node_id: StringName = &""
var direction: StringName = &""
var actor_position := Vector2.ZERO
var actor_process_mode := Node.PROCESS_MODE_INHERIT
var source_activation_state: Dictionary = {}
var source_state: Dictionary = {}
var target_stage: Dictionary = {}


func to_dictionary() -> Dictionary:
	return {
		"route_id": route_id,
		"profile_id": profile_id,
		"edge_id": edge_id,
		"source_node_id": source_node_id,
		"target_node_id": target_node_id,
		"direction": direction,
	}
