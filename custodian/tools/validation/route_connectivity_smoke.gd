extends SceneTree
const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
func _init() -> void:
	var levels := LEVEL_REGISTRY.new(); var routes := ROUTE_REGISTRY.new(); var errors: Array[String] = []
	if not levels.load_index(): errors.append_array(Array(levels.get_errors()))
	if not routes.load_index("res://content/routes/routes.json", levels): errors.append_array(Array(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"sundered_keep")
	if route != null:
		for profile_id in [&"production", &"debug_direct_keep", &"causeway_only"]:
			var profile: RefCounted = route.get_profile(profile_id)
			if profile == null: errors.append("missing profile %s" % profile_id)
			elif route.get_edge(profile.entry_edge_id).from_node_id != &"@world_origin": errors.append("%s entry is not world-origin" % profile_id)
	finish(errors)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteConnectivitySmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteConnectivitySmoke] %s" % error)
	quit(1)
