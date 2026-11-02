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
		var production: Array[RefCounted] = route.resolve_exit(&"production", &"@world_origin", &"enter")
		var legacy: Array[RefCounted] = route.resolve_exit(&"legacy_vista_debug", &"vista_approach", &"continue")
		if production.size() != 1 or production[0].to_node_id != &"vista_approach": errors.append("production ingress did not resolve to Approach and Outskirts")
		elif production[0].transition_style != &"fade": errors.append("production ingress is not a short fade")
		if legacy.size() != 1 or legacy[0].to_node_id != &"front_gate": errors.append("legacy Vista continue did not resolve to Front Gate")
	finish(errors)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteProfileSelectionSmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteProfileSelectionSmoke] %s" % error)
	quit(1)
