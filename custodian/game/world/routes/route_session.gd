class_name RouteSession
extends RefCounted

var route_id: StringName = &""
var profile_id: StringName = &""
var current_node_id: StringName = &""
var current_level_id: StringName = &""
var current_instance: Node
var origin_ingress: Node
var origin_snapshot: Dictionary = {}
var actor: Node
var parent: Node
var history: Array[StringName] = []
var last_edge_id: StringName = &""
var cached_instances: Dictionary = {}
var node_state: Dictionary = {}
var route_state: Dictionary = {}
var started := false


func to_serializable_snapshot() -> Dictionary:
	return {
		"route_id": String(route_id),
		"profile_id": String(profile_id),
		"current_node_id": String(current_node_id),
		"history": _string_name_array(history),
		"last_edge_id": String(last_edge_id),
		"node_state": node_state.duplicate(true),
		"route_state": route_state.duplicate(true),
	}


func _string_name_array(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
