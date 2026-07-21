class_name RouteStateStore
extends RefCounted

var _states: Dictionary = {}


func set_node_state(route_id: StringName, node_id: StringName, state: Dictionary) -> void:
	_states[_key(route_id, node_id)] = state.duplicate(true)


func get_node_state(route_id: StringName, node_id: StringName) -> Dictionary:
	var value: Variant = _states.get(_key(route_id, node_id), {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func has_node_state(route_id: StringName, node_id: StringName) -> bool:
	return _states.has(_key(route_id, node_id))


func clear_route(route_id: StringName) -> void:
	var prefix := "%s::" % route_id
	for key: Variant in _states.keys():
		if str(key).begins_with(prefix):
			_states.erase(key)


func clear() -> void:
	_states.clear()


func _key(route_id: StringName, node_id: StringName) -> String:
	return "%s::%s" % [route_id, node_id]
