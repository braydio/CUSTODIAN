extends SceneTree

const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
const LEVEL_LOADER := preload("res://game/world/levels/level_loader.gd")
const ROUTE_MANAGER := preload("res://game/world/routes/route_traversal_manager.gd")
const INGRESS := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const CAMERA := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

const LEVEL_IDS := {
	&"vista_approach": &"sundered_keep_vista_approach",
	&"return_causeway": &"sundered_keep_return_causeway",
	&"front_gate": &"sundered_keep_front_gate",
}

const EXPECTED_EXITS := {
	&"vista_approach": [&"continue", &"return_world"],
	&"return_causeway": [&"continue", &"backtrack"],
	&"front_gate": [&"backtrack", &"exfil"],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	_validate_registry(errors)
	await _run_production_chain(errors)
	await _run_debug_direct_keep(errors)
	await _run_causeway_only(errors)
	_finish(errors)


func _validate_registry(errors: Array[String]) -> void:
	var levels := LEVEL_REGISTRY.new()
	var routes := ROUTE_REGISTRY.new()
	if not levels.load_index():
		errors.append_array(Array(levels.get_errors()))
	if not routes.load_index("res://content/routes/routes.json", levels):
		errors.append_array(Array(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"sundered_keep")
	if route == null:
		errors.append("route missing")
		return
	var expected := [
		[&"production", &"@world_origin", &"enter", &"vista_approach"],
		[&"production", &"vista_approach", &"continue", &"return_causeway"],
		[&"production", &"return_causeway", &"continue", &"front_gate"],
		[&"production", &"front_gate", &"backtrack", &"return_causeway"],
		[&"production", &"return_causeway", &"backtrack", &"vista_approach"],
		[&"production", &"vista_approach", &"return_world", &"@world_origin"],
		[&"debug_direct_keep", &"vista_approach", &"continue", &"front_gate"],
		[&"causeway_only", &"@world_origin", &"enter", &"return_causeway"],
		[&"causeway_only", &"return_causeway", &"backtrack", &"@world_origin"],
	]
	for step in expected:
		var matches: Array[RefCounted] = route.resolve_exit(
			step[0],
			step[1],
			step[2]
		)
		if matches.size() != 1 or matches[0].to_node_id != step[3]:
			errors.append("bad mapping %s/%s/%s" % [step[0], step[1], step[2]])
	for node_id in LEVEL_IDS:
		var node: RefCounted = route.get_node_definition(node_id)
		var definition: RefCounted = levels.get_level(node.level_id)
		if definition == null or load(definition.get_entry_scene_path()) == null:
			errors.append("%s production scene does not load" % node_id)


func _run_production_chain(errors: Array[String]) -> void:
	var runtime := _build_runtime(&"production")
	var manager: Node = runtime.manager
	var loader: Node = runtime.loader
	var actor: CharacterBody2D = runtime.actor
	runtime.ingress.set("_triggered", true)
	runtime.ingress.call("_enter_approach", actor)
	_assert_active(runtime, &"vista_approach", &"EntrySpawn", errors)
	var first_vista: Node = loader.call("get_active_level_instance")

	var physics_transitioned := await _trigger_physics_exit(
		runtime,
		&"continue",
		&"return_causeway",
		errors
	)
	if not physics_transitioned:
		_cleanup_runtime(runtime)
		await process_frame
		return
	_assert_active(runtime, &"return_causeway", &"OperatorSpawn", errors)
	await process_frame
	if is_instance_valid(first_vista):
		errors.append("Vista was retained after its forward destroy policy")
	var first_causeway: Node = loader.call("get_active_level_instance")

	_transition(runtime, &"continue", &"front_gate", &"EntrySpawn", errors)
	if not is_instance_valid(first_causeway):
		errors.append("Causeway was released despite keep_during_route policy")
	else:
		_assert_inactive(first_causeway, "retained Causeway", errors)
	var first_front_gate: Node = loader.call("get_active_level_instance")

	_transition(
		runtime,
		&"backtrack",
		&"return_causeway",
		&"KeepReturnSpawn",
		errors
	)
	if loader.call("get_active_level_instance") != first_causeway:
		errors.append("Causeway backtrack did not reactivate its retained instance")
	await process_frame
	if is_instance_valid(first_front_gate):
		errors.append("Front Gate was retained despite snapshot-and-unload policy")

	_transition(
		runtime,
		&"backtrack",
		&"vista_approach",
		&"ReturnTopdown",
		errors
	)
	if is_instance_valid(first_causeway):
		_assert_inactive(first_causeway, "cached Causeway after reverse exit", errors)
	_transition_to_world(runtime, &"return_world", errors)
	if is_instance_valid(first_causeway):
		await process_frame
	if is_instance_valid(first_causeway):
		errors.append("production exfil retained the cached Causeway")
	_cleanup_runtime(runtime)
	await process_frame


func _run_debug_direct_keep(errors: Array[String]) -> void:
	var runtime := _build_runtime(&"debug_direct_keep")
	var actor: Node = runtime.actor
	runtime.ingress.set("_triggered", true)
	runtime.ingress.call("_enter_approach", actor)
	_assert_active(runtime, &"vista_approach", &"EntrySpawn", errors)
	_transition(runtime, &"continue", &"front_gate", &"EntrySpawn", errors)
	_transition_to_world(runtime, &"exfil", errors)
	_cleanup_runtime(runtime)
	await process_frame


func _run_causeway_only(errors: Array[String]) -> void:
	var runtime := _build_runtime(&"causeway_only")
	var actor: Node = runtime.actor
	runtime.ingress.set("_triggered", true)
	runtime.ingress.call("_enter_approach", actor)
	_assert_active(runtime, &"return_causeway", &"OperatorSpawn", errors)
	var active: Node = runtime.loader.call("get_active_level_instance")
	var continue_exit := _find_exit(active, &"continue")
	if continue_exit == null:
		errors.append("causeway_only could not find authored continue exit")
	else:
		var original_node: StringName = runtime.manager.call("get_current_node_id")
		if continue_exit.call("request_transition", actor):
			errors.append("disabled causeway_only continue exit accepted a request")
		await process_frame
		if runtime.manager.call("get_current_node_id") != original_node:
			errors.append("disabled causeway_only continue exit changed route node")
	_transition_to_world(runtime, &"backtrack", errors)
	_cleanup_runtime(runtime)
	await process_frame


func _transition(
	runtime: Dictionary,
	exit_id: StringName,
	node_id: StringName,
	spawn_id: StringName,
	errors: Array[String]
) -> void:
	if not bool(runtime.manager.call("request_exit", exit_id, runtime.actor)):
		errors.append("route transition failed through %s" % exit_id)
		return
	_assert_active(runtime, node_id, spawn_id, errors)


func _transition_to_world(
	runtime: Dictionary,
	exit_id: StringName,
	errors: Array[String]
) -> void:
	if not bool(runtime.manager.call("request_exit", exit_id, runtime.actor)):
		errors.append("route exfil failed through %s" % exit_id)
	if runtime.manager.call("has_active_route"):
		errors.append("exfil through %s retained route authority" % exit_id)
	if runtime.loader.call("get_active_level_instance") != null:
		errors.append("exfil through %s retained loader instance" % exit_id)
	if not (runtime.loader.call("get_active_level_id") as StringName).is_empty():
		errors.append("exfil through %s retained loader identity" % exit_id)
	if runtime.camera.runtime_map != runtime.procgen:
		errors.append("exfil through %s did not restore the world camera map" % exit_id)


func _trigger_physics_exit(
	runtime: Dictionary,
	exit_id: StringName,
	expected_node: StringName,
	errors: Array[String]
) -> bool:
	await process_frame
	var active: Node = runtime.loader.call("get_active_level_instance")
	var exit_node: LevelExit2D = _find_exit(active, exit_id)
	if exit_node == null:
		errors.append("physics transition could not find %s" % exit_id)
		return false
	var counters := {
		"body_entered": 0,
		"transition_requested": 0,
	}
	exit_node.body_entered.connect(
		func(_body: Node) -> void:
			counters.body_entered += 1
	)
	exit_node.transition_requested.connect(
		func(_requested_exit: StringName, _actor: Node) -> void:
			counters.transition_requested += 1
	)
	var validation_collision_layer := 1 << 19
	exit_node.collision_layer = 0
	exit_node.collision_mask = validation_collision_layer
	exit_node.call("reset_transition_lock")
	runtime.actor.collision_layer = validation_collision_layer
	runtime.actor.collision_mask = 0
	var start_position := exit_node.global_position + Vector2(-160.0, 0.0)
	runtime.actor.global_position = start_position
	runtime.actor.force_update_transform()
	await physics_frame
	await physics_frame
	for _step in range(1, 9):
		runtime.actor.move_and_collide(Vector2(32.0, 0.0))
		await physics_frame
		if int(counters.body_entered) > 0:
			break
	await process_frame
	if int(counters.body_entered) == 0:
		errors.append("authored %s exit did not receive body_entered" % exit_id)
	if int(counters.transition_requested) == 0:
		errors.append("authored %s exit did not emit transition_requested" % exit_id)
	if runtime.manager.call("get_current_node_id") != expected_node:
		errors.append("deferred physics exit did not reach %s" % expected_node)
		return false
	return (
		int(counters.body_entered) > 0
		and int(counters.transition_requested) > 0
	)


func _assert_active(
	runtime: Dictionary,
	node_id: StringName,
	spawn_id: StringName,
	errors: Array[String]
) -> void:
	var manager: Node = runtime.manager
	var loader: Node = runtime.loader
	var active: Node = loader.call("get_active_level_instance")
	if manager.call("get_current_node_id") != node_id:
		errors.append("active route node is not %s" % node_id)
	if loader.call("get_active_level_id") != LEVEL_IDS[node_id]:
		errors.append("active level ID does not match %s" % node_id)
	if active == null or active != manager.call("get_active_session").current_instance:
		errors.append("active instance does not match the route session for %s" % node_id)
		return
	var expected_position: Vector2 = active.call("get_spawn_position", spawn_id)
	if not runtime.actor.global_position.is_equal_approx(expected_position):
		errors.append("actor did not arrive at %s/%s" % [node_id, spawn_id])
	if runtime.camera.runtime_map != active:
		errors.append("camera runtime map does not match %s" % node_id)
	if active.process_mode == Node.PROCESS_MODE_DISABLED or not active.visible:
		errors.append("active node %s is disabled or hidden" % node_id)
	var visible_processing_route_nodes := 0
	for child: Node in runtime.world.get_children():
		if not child.has_method("activate_route_node") \
		or not child.has_method("complete_route_activation"):
			continue
		if child == active:
			if child.process_mode != Node.PROCESS_MODE_DISABLED and child.visible:
				visible_processing_route_nodes += 1
		elif child.process_mode != Node.PROCESS_MODE_DISABLED or child.visible:
			errors.append(
				"inactive route node is visible or processing while %s is active"
				% node_id
			)
	if visible_processing_route_nodes != 1:
		errors.append(
			"expected one visible/processing route node at %s, found %d"
			% [node_id, visible_processing_route_nodes]
		)
	var session: RefCounted = manager.call("get_active_session")
	for cached: Node in session.cached_instances.values():
		if cached != active and is_instance_valid(cached):
			_assert_inactive(
				cached,
				"cached route node while %s is active" % node_id,
				errors
			)
	var expected_exit_ids: Array = EXPECTED_EXITS[node_id]
	var seen_exit_ids: Array[StringName] = []
	for exit_node: LevelExit2D in _collect_exits(active):
		seen_exit_ids.append(exit_node.exit_id)
		var should_be_enabled := expected_exit_ids.has(exit_node.exit_id)
		var profile_id: StringName = manager.call("get_active_session").profile_id
		if profile_id == &"causeway_only" and exit_node.exit_id == &"continue":
			should_be_enabled = false
		if exit_node.monitoring != should_be_enabled:
			errors.append(
				"%s/%s enabled state does not match profile %s"
				% [node_id, exit_node.exit_id, profile_id]
			)
	for expected_exit_id in expected_exit_ids:
		if not seen_exit_ids.has(expected_exit_id):
			errors.append("%s lacks authored exit %s" % [node_id, expected_exit_id])


func _assert_inactive(level: Node, label: String, errors: Array[String]) -> void:
	if level == null or not is_instance_valid(level):
		errors.append("%s is unavailable" % label)
		return
	if level.process_mode != Node.PROCESS_MODE_DISABLED:
		errors.append("%s still processes" % label)
	if level.visible:
		errors.append("%s is still visible" % label)


func _find_exit(root_node: Node, exit_id: StringName) -> LevelExit2D:
	for exit_node in _collect_exits(root_node):
		if exit_node.exit_id == exit_id:
			return exit_node
	return null


func _collect_exits(root_node: Node) -> Array[LevelExit2D]:
	var exits: Array[LevelExit2D] = []
	if root_node == null or not is_instance_valid(root_node):
		return exits
	_collect_exits_recursive(root_node, exits)
	return exits


func _collect_exits_recursive(
	node: Node,
	exits: Array[LevelExit2D]
) -> void:
	if node is LevelExit2D:
		exits.append(node)
	for child: Node in node.get_children():
		_collect_exits_recursive(child, exits)


func _build_runtime(profile: StringName) -> Dictionary:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var procgen := Node2D.new()
	procgen.name = "ProcGenRuntime"
	procgen.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(procgen)
	var connected := Node2D.new()
	connected.name = "ConnectedMaps"
	world.add_child(connected)
	var camera := CAMERA.new()
	camera.name = "Camera2D"
	camera.runtime_map = procgen
	world.add_child(camera)
	var actor := OPERATOR_SCENE.instantiate() as CharacterBody2D
	actor.name = "Operator"
	actor.add_to_group("player")
	world.add_child(actor)
	var loader := LEVEL_LOADER.new()
	loader.name = "LevelLoader"
	world.add_child(loader)
	var manager := ROUTE_MANAGER.new()
	manager.name = "RouteTraversalManager"
	world.add_child(manager)
	var ingress := INGRESS.new()
	ingress.name = "RouteIngress"
	ingress.ingress_id = &"sundered_keep"
	ingress.configure_route(&"sundered_keep", profile, procgen)
	world.add_child(ingress)
	return {
		"game_root": game_root,
		"world": world,
		"procgen": procgen,
		"camera": camera,
		"actor": actor,
		"loader": loader,
		"manager": manager,
		"ingress": ingress,
	}


func _cleanup_runtime(runtime: Dictionary) -> void:
	var game_root: Node = runtime.game_root
	if is_instance_valid(game_root):
		game_root.queue_free()


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepRouteGraphSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepRouteGraphSmoke] %s" % error)
	quit(1)
