extends SceneTree
const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
const LEVEL_LOADER := preload("res://game/world/levels/level_loader.gd")
const ROUTE_MANAGER := preload("res://game/world/routes/route_traversal_manager.gd")
const INGRESS := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const CAMERA := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []; var levels := LEVEL_REGISTRY.new(); var routes := ROUTE_REGISTRY.new()
	if not levels.load_index(): errors.append_array(Array(levels.get_errors()))
	if not routes.load_index("res://content/routes/routes.json", levels): errors.append_array(Array(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"sundered_keep")
	var expected := [
		[&"production", &"@world_origin", &"enter", &"vista_approach"],
		[&"production", &"vista_approach", &"continue", &"return_causeway"],
		[&"production", &"return_causeway", &"continue", &"front_gate"],
		[&"production", &"front_gate", &"backtrack", &"return_causeway"],
		[&"production", &"return_causeway", &"backtrack", &"vista_approach"],
		[&"production", &"vista_approach", &"return_world", &"@world_origin"],
		[&"debug_direct_keep", &"vista_approach", &"continue", &"front_gate"],
	]
	if route == null: errors.append("route missing")
	else:
		for step in expected:
			var matches: Array[RefCounted] = route.resolve_exit(step[0], step[1], step[2])
			if matches.size() != 1 or matches[0].to_node_id != step[3]: errors.append("bad mapping %s/%s/%s" % [step[0], step[1], step[2]])
		for node_id in [&"vista_approach", &"return_causeway", &"front_gate"]:
			var node: RefCounted = route.get_node_definition(node_id); var definition: RefCounted = levels.get_level(node.level_id)
			if definition == null or load(definition.get_entry_scene_path()) == null: errors.append("%s production scene does not load" % node_id)
	await _run_production_chain(errors)
	await _run_profile_chain(&"debug_direct_keep", &"vista_approach", &"continue", &"front_gate", &"exfil", errors)
	await _run_profile_chain(&"causeway_only", &"return_causeway", &"backtrack", &"", &"", errors)
	finish(errors)


func _run_production_chain(errors: Array[String]) -> void:
	var game_root := Node2D.new(); game_root.name = "GameRoot"; root.add_child(game_root)
	var world := Node2D.new(); world.name = "World"; game_root.add_child(world)
	var procgen := Node2D.new(); procgen.name = "ProcGenRuntime"; procgen.process_mode = Node.PROCESS_MODE_ALWAYS; world.add_child(procgen)
	var connected := Node2D.new(); connected.name = "ConnectedMaps"; world.add_child(connected)
	var camera := CAMERA.new(); camera.name = "Camera2D"; camera.runtime_map = procgen; world.add_child(camera)
	var actor := CharacterBody2D.new(); actor.name = "Operator"; actor.add_to_group("player"); actor.global_position = Vector2(24, 32); world.add_child(actor)
	var loader := LEVEL_LOADER.new(); loader.name = "LevelLoader"; world.add_child(loader)
	var manager := ROUTE_MANAGER.new(); manager.name = "RouteTraversalManager"; world.add_child(manager)
	var ingress := INGRESS.new(); ingress.name = "RouteIngress"; ingress.ingress_id = &"sundered_keep"; ingress.configure_route(&"sundered_keep", &"production", procgen); world.add_child(ingress)
	ingress.set("_triggered", true); ingress.call("_enter_approach", actor)
	var expected_nodes := [&"vista_approach", &"return_causeway", &"front_gate", &"return_causeway", &"vista_approach"]
	var exits := [&"continue", &"continue", &"backtrack", &"backtrack"]
	if manager.get_current_node_id() != expected_nodes[0]: errors.append("live production route did not enter Vista")
	for index in exits.size():
		if not manager.request_exit(exits[index], actor): errors.append("live production traversal failed at %s" % exits[index]); break
		if manager.get_current_node_id() != expected_nodes[index + 1]: errors.append("live production traversal reached wrong node after %s" % exits[index])
		var active: Node = loader.get_active_level_instance()
		for child in world.get_children():
			if child != active and child.is_in_group("authored_level") and child.process_mode != Node.PROCESS_MODE_DISABLED:
				errors.append("two Sundered route nodes processed simultaneously")
	if manager.get_current_node_id() == &"vista_approach" and not manager.request_exit(&"return_world", actor): errors.append("live production route did not exfil")
	if manager.has_active_route() or loader.get_active_level_instance() != null: errors.append("live production exfil retained route authority")
	game_root.queue_free(); await process_frame


func _run_profile_chain(profile: StringName, entry_node: StringName, first_exit: StringName, target_node: StringName, final_exit: StringName, errors: Array[String]) -> void:
	var game_root := Node2D.new(); game_root.name = "GameRoot"; root.add_child(game_root)
	var world := Node2D.new(); world.name = "World"; game_root.add_child(world)
	var procgen := Node2D.new(); procgen.name = "ProcGenRuntime"; procgen.process_mode = Node.PROCESS_MODE_ALWAYS; world.add_child(procgen)
	var connected := Node2D.new(); connected.name = "ConnectedMaps"; world.add_child(connected)
	var camera := CAMERA.new(); camera.name = "Camera2D"; camera.runtime_map = procgen; world.add_child(camera)
	var actor := CharacterBody2D.new(); actor.name = "Operator"; actor.add_to_group("player"); world.add_child(actor)
	var loader := LEVEL_LOADER.new(); loader.name = "LevelLoader"; world.add_child(loader)
	var manager := ROUTE_MANAGER.new(); manager.name = "RouteTraversalManager"; world.add_child(manager)
	var ingress := INGRESS.new(); ingress.name = "RouteIngress"; ingress.ingress_id = &"sundered_keep"; ingress.configure_route(&"sundered_keep", profile, procgen); world.add_child(ingress)
	ingress.set("_triggered", true); ingress.call("_enter_approach", actor)
	if manager.get_current_node_id() != entry_node: errors.append("%s entered %s instead of %s" % [profile, manager.get_current_node_id(), entry_node])
	if not manager.request_exit(first_exit, actor): errors.append("%s first exit failed" % profile)
	elif target_node.is_empty():
		if manager.has_active_route(): errors.append("%s did not exfil" % profile)
	else:
		if manager.get_current_node_id() != target_node: errors.append("%s reached wrong target" % profile)
		if not final_exit.is_empty() and not manager.request_exit(final_exit, actor): errors.append("%s final exfil failed" % profile)
	game_root.queue_free(); await process_frame
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[SunderedKeepRouteGraphSmoke] PASS"); quit(0); return
	for error in errors: push_error("[SunderedKeepRouteGraphSmoke] %s" % error)
	quit(1)
