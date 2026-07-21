extends SceneTree
const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
func _init() -> void:
	var levels := LEVEL_REGISTRY.new(); var routes := ROUTE_REGISTRY.new(); var errors: Array[String] = []
	if not levels.load_index(): errors.append("level registry failed")
	if not routes.load_index("res://content/routes/routes.json", levels): errors.append("route registry failed")
	var route: RefCounted = routes.get_route(&"sundered_keep")
	if route == null: errors.append("Sundered route missing")
	else:
		var production: Array[RefCounted] = route.resolve_exit(&"production", &"vista_approach", &"continue")
		var debug: Array[RefCounted] = route.resolve_exit(&"debug_direct_keep", &"vista_approach", &"continue")
		if production.size() != 1 or production[0].to_node_id != &"return_causeway": errors.append("production Vista continue did not resolve to Causeway")
		if debug.size() != 1 or debug[0].to_node_id != &"front_gate": errors.append("debug Vista continue did not resolve to Front Gate")
	finish(errors)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteProfileSelectionSmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteProfileSelectionSmoke] %s" % error)
	quit(1)
