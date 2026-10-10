extends "res://game/world/procgen/ingress/world_ingress_site.gd"


var _return_spawn_id: StringName = &""


func configure_hub_route(
	route_id: StringName,
	profile_id: StringName,
	hub_map: Node,
	return_spawn_id: StringName
) -> void:
	configure_route(route_id, profile_id, hub_map)
	_return_spawn_id = return_spawn_id
	requires_explicit_interaction = true
	prompt_text = "ENTER TWIN SOLARIA"
	interaction_distance = 92.0


func restore_world_origin(actor: Node, source_state: Dictionary = {}) -> Dictionary:
	var snapshot := source_state.duplicate(false)
	var route_manager := _find_route_traversal_manager()
	var session: RefCounted = route_manager.call("get_active_session") as RefCounted if route_manager != null else null
	if session != null and bool(session.get("started")):
		var marker: Node2D = null
		if _main_map != null and is_instance_valid(_main_map):
			marker = _main_map.call("get_named_marker", _return_spawn_id) as Node2D
		if marker == null:
			return {
				"succeeded": false,
				"reason": "Hub return marker is unavailable: %s" % _return_spawn_id,
			}
		snapshot["actor_position"] = marker.global_position
		snapshot.erase("camera_position")
		snapshot["camera_runtime_map"] = _main_map
	return super.restore_world_origin(actor, snapshot)
