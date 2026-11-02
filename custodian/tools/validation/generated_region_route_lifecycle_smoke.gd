extends SceneTree

const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const LEVEL_DEFINITION := preload("res://game/world/levels/level_definition.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
const LEVEL_LOADER := preload("res://game/world/levels/level_loader.gd")
const ROUTE_MANAGER := preload("res://game/world/routes/route_traversal_manager.gd")
const CAMERA := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	_validate_definition_contract(errors)
	var levels: RefCounted = LEVEL_REGISTRY.new()
	if not levels.call("load_index", "res://tools/validation/fixtures/generated_route_levels.json"):
		errors.append_array(Array(levels.call("get_errors")))
		_finish(errors)
		return
	var routes: RefCounted = ROUTE_REGISTRY.new()
	if not routes.call("load_index", "res://tools/validation/fixtures/generated_route_registry.json", levels):
		errors.append_array(Array(routes.call("get_errors")))
		_finish(errors)
		return
	await _exercise_route_lifecycle(levels, errors)
	_finish(errors)


func _validate_definition_contract(errors: Array[String]) -> void:
	var definition: RefCounted = LEVEL_DEFINITION.new()
	definition.call("configure_from_dictionary", {
		"schema": "custodian.level_definition.v1",
		"level_id": "missing_generated_request",
		"display_name": "Missing Generated Request",
		"runtime_kind": "generated_region",
		"spawns": ["EntrySpawn"],
	})
	if definition.call("validate", false).is_empty():
		errors.append("generated-region definition accepted without a generation request")
	definition.call("configure_from_dictionary", {
		"schema": "custodian.level_definition.v1",
		"level_id": "generated_request_without_seed",
		"display_name": "Generated Request Without Seed",
		"runtime_kind": "generated_region",
		"spawns": ["EntrySpawn"],
		"generated_region": {"scene_path": "res://game/world/procgen/proc_gen_map.tscn", "profile_id": "test", "map_size": [48, 48]},
	})
	if definition.call("validate", false).is_empty():
		errors.append("generated-region definition accepted without explicit seed")


func _exercise_route_lifecycle(_levels: RefCounted, errors: Array[String]) -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var camera: Camera2D = CAMERA.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var actor := CharacterBody2D.new()
	actor.name = "Operator"
	world.add_child(actor)
	var loader: Node = LEVEL_LOADER.new()
	loader.name = "LevelLoader"
	loader.set("registry_index_path", "res://tools/validation/fixtures/generated_route_levels.json")
	world.add_child(loader)
	var manager: Node = ROUTE_MANAGER.new()
	manager.name = "RouteTraversalManager"
	manager.set("route_registry_index_path", "res://tools/validation/fixtures/generated_route_registry.json")
	world.add_child(manager)
	await process_frame
	var actor_id := actor.get_instance_id()
	if not bool(manager.call("start_route", &"generated_region_lifecycle_smoke", actor, {"parent": world})):
		errors.append("route did not enter authored fixture")
		game_root.queue_free()
		await process_frame
		return
	var authored: Node = loader.call("get_active_level_instance")
	if manager.call("get_current_node_id") != &"authored" or authored == null:
		errors.append("authored source did not become active")
		game_root.queue_free()
		await process_frame
		return
	var entered: Array[Node] = []
	var transition_failures: Array[String] = []
	manager.connect("route_node_entered", func(_route: StringName, node_id: StringName, instance: Node) -> void:
		if node_id == &"generated":
			entered.append(instance)
	, CONNECT_DEFERRED)
	manager.connect("route_transition_failed", func(_route: StringName, _edge: StringName, reason: String) -> void:
		transition_failures.append(reason)
	, CONNECT_DEFERRED)
	if not bool(manager.call("transition_via_edge", &"enter_generated", actor)):
		errors.append("manager rejected generated target transition")
		game_root.queue_free()
		await process_frame
		return
	var wait_frames := 0
	while entered.is_empty() and transition_failures.is_empty() and wait_frames < 300:
		await process_frame
		wait_frames += 1
	if entered.is_empty():
		errors.append("generated entry did not commit: %s" % (transition_failures.back() if not transition_failures.is_empty() else "timeout"))
		game_root.queue_free()
		await process_frame
		return
	var generated: Node = entered.back()
	var first_map: Node = generated.get("_map") as Node
	var first_rooms: Array = (first_map.get("procgen_node") as Node).call("get_rooms")
	var first_spawn: Vector2 = generated.call("get_spawn_position", &"EntrySpawn")
	if generated == authored or actor.get_instance_id() != actor_id:
		errors.append("generated entry replaced the authored source or persistent actor")
	if is_instance_valid(authored) and (authored.process_mode != Node.PROCESS_MODE_DISABLED or authored.visible):
		errors.append("retained authored source was not deactivated after generated commit")
	if camera.get("runtime_map") != first_map:
		errors.append("shared camera did not bind to the generated ProcGenTilemap")
	if actor.global_position != first_spawn:
		errors.append("Operator did not arrive at the named generated spawn")
	var generated_activation: Dictionary = loader.call("capture_instance_activation_state", generated)
	if generated_activation.get("process_mode") != Node.PROCESS_MODE_INHERIT:
		errors.append("generated destination is not the sole active route authority")
	if not await _transition_and_wait(manager, &"return_authored", actor, &"authored", errors):
		game_root.queue_free()
		await process_frame
		return
	await process_frame
	authored = loader.call("get_active_level_instance") as Node
	if authored == null or not authored.visible:
		errors.append("back traversal did not restore the authored source")
	if is_instance_valid(generated) and generated.is_inside_tree():
		errors.append("destroy_on_exit retained the generated runtime after leaving")
	if not await _transition_and_wait(manager, &"enter_generated", actor, &"generated", errors):
		game_root.queue_free()
		await process_frame
		return
	var regenerated: Node = loader.call("get_active_level_instance")
	var second_map: Node = regenerated.get("_map") as Node
	var second_rooms: Array = (second_map.get("procgen_node") as Node).call("get_rooms")
	var second_spawn: Vector2 = regenerated.call("get_spawn_position", &"EntrySpawn")
	if first_rooms != second_rooms or first_spawn != second_spawn:
		errors.append("same-seed generated-region revisit was not deterministic")
	if regenerated == generated:
		errors.append("destroy_on_exit revisit reused the previous live generated node")
	if not await _transition_and_wait(manager, &"return_authored", actor, &"authored", errors):
		game_root.queue_free()
		await process_frame
		return
	authored = loader.call("get_active_level_instance") as Node
	# Corrupt the route edge after registry validation to prove a late missing-spawn
	# failure leaves the active authored source, actor, and camera identity intact.
	var route: RefCounted = manager.get("_active_route") as RefCounted
	var edge: RefCounted = route.call("get_edge", &"enter_generated") as RefCounted
	edge.target_spawn_id = &"MissingSpawn"
	var failure: Array[String] = []
	manager.connect("route_transition_failed", func(_route: StringName, _edge: StringName, reason: String) -> void:
		failure.append(reason)
	, CONNECT_ONE_SHOT)
	var origin_position := actor.global_position
	manager.call("transition_via_edge", &"enter_generated", actor)
	var failure_wait_frames := 0
	while failure.is_empty() and failure_wait_frames < 300:
		await process_frame
		failure_wait_frames += 1
	if failure.is_empty():
		errors.append("failed-stage rollback did not emit a transition failure")
		game_root.queue_free()
		await process_frame
		return
	if manager.call("get_current_node_id") != &"authored" or loader.call("get_active_level_instance") != authored:
		errors.append("failed generated staging did not roll back to the authored source")
	if actor.get_instance_id() != actor_id or actor.global_position != origin_position:
		errors.append("failed generated staging changed Operator identity or position")
	if authored.process_mode == Node.PROCESS_MODE_DISABLED or camera.get("runtime_map") != authored:
		errors.append("failed generated staging did not restore source processing and camera binding")
	# Replace only the generated scene request after registry validation. This fixture
	# is a ProcGenTilemap with no ProcGen owner, so generation must fail explicitly
	# and let the real route rollback transaction restore the authored source.
	edge.target_spawn_id = &"EntrySpawn"
	var generated_definition: RefCounted = loader.call("get_definition", &"generated_route_procgen_fixture")
	var generation_request: Dictionary = generated_definition.get("generated_region")
	generation_request["scene_path"] = "res://tools/validation/fixtures/generated_region_missing_procgen_map.tscn"
	generated_definition.set("generated_region", generation_request)
	var generation_failure: Array[String] = []
	manager.connect("route_transition_failed", func(_route: StringName, _edge: StringName, reason: String) -> void:
		generation_failure.append(reason)
	, CONNECT_ONE_SHOT)
	var generation_origin_position := actor.global_position
	manager.call("transition_via_edge", &"enter_generated", actor)
	var generation_wait_frames := 0
	while generation_failure.is_empty() and generation_wait_frames < 30:
		await process_frame
		generation_wait_frames += 1
	if generation_failure.is_empty():
		errors.append("invalid ProcGen dependency did not resolve generated staging promptly")
	elif not generation_failure.back().contains("no ProcGen owner"):
		errors.append("invalid ProcGen dependency returned an unhelpful failure: %s" % generation_failure.back())
	if manager.call("get_current_node_id") != &"authored" or loader.call("get_active_level_instance") != authored:
		errors.append("generation failure did not roll back to the authored source")
	if actor.get_instance_id() != actor_id or actor.global_position != generation_origin_position:
		errors.append("generation failure changed Operator identity or position")
	if not authored.visible or authored.process_mode == Node.PROCESS_MODE_DISABLED or camera.get("runtime_map") != authored:
		errors.append("generation failure did not restore source visibility, processing, and camera binding")
	game_root.queue_free()
	await process_frame


func _transition_and_wait(manager: Node, edge_id: StringName, actor: Node, node_id: StringName, errors: Array[String]) -> bool:
	var wait_frames := 0
	var failures: Array[String] = []
	manager.connect("route_transition_failed", func(_route: StringName, _failed_edge: StringName, reason: String) -> void:
		failures.append(reason)
	, CONNECT_DEFERRED)
	if not bool(manager.call("transition_via_edge", edge_id, actor)):
		errors.append("route rejected transition edge %s" % edge_id)
		return false
	while (manager.call("get_current_node_id") != node_id or manager.call("get_phase") != 0) and failures.is_empty() and wait_frames < 300:
		await process_frame
		wait_frames += 1
	var entered: bool = manager.call("get_current_node_id") == node_id and manager.call("get_phase") == 0
	if not entered:
		errors.append("route transition %s did not reach %s: %s; current=%s phase=%s" % [edge_id, node_id, failures.back() if not failures.is_empty() else "timeout", manager.call("get_current_node_id"), manager.call("get_phase")])
	return entered


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[GeneratedRegionRouteLifecycleSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("[GeneratedRegionRouteLifecycleSmoke] %s" % error)
	quit(1)
