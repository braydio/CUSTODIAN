extends SceneTree
const GENERATOR := preload("res://tools/level_authoring/level_scaffold_generator.gd")
const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
const OUTPUT := "user://level_scaffold_route_generator_smoke"
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var generator := GENERATOR.new(); generator.call("_remove_tree", ProjectSettings.globalize_path(OUTPUT))
	var errors: Array[String] = []
	var create := _request("route_alpha", "node_a", true)
	create.edges = [
		_edge("enter_a", "@world_origin", "enter", "node_a", "EntrySpawn", "forward"),
		_edge("a_exfil", "node_a", "return_world", "@world_origin", "", "exfil"),
	]
	var first: Dictionary = generator.generate(create)
	if not bool(first.get("ok", false)): errors.append("route creation failed: %s" % first.get("errors", []))
	var append := _request("route_beta", "node_b", false)
	append.exits = [{"exit_id": "return_world", "node_name": "Exit_Main"}, {"exit_id": "backtrack", "node_name": "Exit_Back"}]
	append.edges = [
		_edge("a_to_b", "node_a", "continue", "node_b", "EntrySpawn", "forward"),
		_edge("b_to_world", "node_b", "return_world", "@world_origin", "", "exfil"),
	]
	var second: Dictionary = generator.generate(append)
	if not bool(second.get("ok", false)): errors.append("route append failed: %s" % second.get("errors", []))
	var levels := LEVEL_REGISTRY.new(); var routes := ROUTE_REGISTRY.new()
	var level_index := OUTPUT + "/custodian/content/levels/levels.json"
	var route_index := OUTPUT + "/custodian/content/routes/routes.json"
	if not levels.load_index(level_index): errors.append_array(Array(levels.get_errors()))
	if not routes.load_index(route_index, levels): errors.append_array(Array(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"fixture_generated_route")
	if route == null or route.nodes.size() != 2 or route.edges.size() != 4: errors.append("generated route registry does not contain the appended graph")
	var scene := load(OUTPUT + "/custodian/game/world/levels/authored/smoke/route_alpha/route_alpha.tscn") as PackedScene
	if scene == null: errors.append("generated route-node scene did not load")
	else:
		var instance := scene.instantiate(); var exit := instance.get_node_or_null("Exits/Exit_Main") as LevelExit2D
		if exit == null or exit.exit_id != &"return_world" or exit.get_node_or_null("CollisionShape2D") == null: errors.append("generated generic exit contract is incomplete")
		instance.free()
	var duplicate := _request("route_gamma", "node_b", false)
	duplicate.edges = [_edge("duplicate_edge", "node_b", "side", "@world_origin", "", "exfil")]
	if bool((generator.generate(duplicate) as Dictionary).get("ok", false)): errors.append("duplicate node append was accepted")
	var duplicate_path := ProjectSettings.globalize_path(OUTPUT + "/custodian/content/levels/smoke/route_gamma/route_gamma.json")
	if FileAccess.file_exists(duplicate_path): errors.append("failed append left generated files behind")
	generator.call("_remove_tree", ProjectSettings.globalize_path(OUTPUT))
	finish(errors)
func _request(level_id: String, node_id: String, create: bool) -> Dictionary:
	return {"level_id": level_id, "display_name": level_id, "region": "smoke", "output_root": OUTPUT, "register_level": true, "route_id": "fixture_generated_route", "route_node_id": node_id, "entry_spawn_id": "EntrySpawn", "exits": [{"exit_id": "return_world", "node_name": "Exit_Main"}, {"exit_id": "continue", "node_name": "Exit_Forward"}], "create_route": create, "append_to_route": not create}
func _edge(id: String, source: String, exit_id: String, target: String, spawn: String, direction: String) -> Dictionary:
	return {"edge_id": id, "from_node_id": source, "exit_id": exit_id, "to_node_id": target, "target_spawn_id": spawn, "direction": direction, "transition_style": "fade", "profiles": ["production"]}
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[LevelScaffoldRouteGeneratorSmoke] PASS"); quit(0); return
	for error in errors: push_error("[LevelScaffoldRouteGeneratorSmoke] %s" % error)
	quit(1)
