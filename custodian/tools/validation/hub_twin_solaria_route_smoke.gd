extends SceneTree

const AWAKENING_SCENE := preload("res://scenes/awakening_first_return.tscn")
const HUB_MAP_SCRIPT := preload("res://game/world/hub/first_set/hub_first_set_map.gd")
const TWIN_SCRIPT := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria_layout.gd")

var _route_failure_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var transition_manager := root.get_node_or_null("WorldTransitionManager")
	if transition_manager == null:
		_fail("WorldTransitionManager autoload is missing")
		return
	transition_manager.call("arm_for_startup_awakening")
	var awakening := AWAKENING_SCENE.instantiate()
	root.add_child(awakening)
	current_scene = awakening
	await process_frame
	awakening.set("completed", true)
	awakening.set("opening_console_acknowledged", true)
	awakening.set("p9_recovered", true)
	var operator := awakening.get_node("World/Operator") as CharacterBody2D
	operator.global_position = Vector2(0.0, -6336.0)
	var snapshot := {
		"completed": true,
		"opening_console_acknowledged": true,
		"p9_recovered": true,
		"final_zone_id": &"zone10_road_south_reach",
		"operator_global_position": operator.global_position,
	}
	if not bool(transition_manager.call("request_awakening_to_hub", snapshot)):
		_fail("Qualified Awakening did not start the production Hub handoff")
		return
	await _wait_for_context(transition_manager, &"hub")
	var hub_root := current_scene
	var hub_world := hub_root.get_node("World")
	var hub_map := hub_world.get_node("Level") as HUB_MAP_SCRIPT
	var route_manager := hub_world.get_node_or_null("RouteTraversalManager")
	var level_loader := hub_world.get_node_or_null("LevelLoader")
	var navigation := hub_root.get_node("NavigationSystem")
	var camera := hub_world.get_node("Camera2D") as Camera2D
	var ingress := hub_world.get_node_or_null("CrownTransferIngress")
	_expect(route_manager != null and level_loader != null, "Hub host omitted authored route services", failures)
	_expect(ingress != null and ingress.is_in_group("interactable"), "CrownTransfer is not a production interaction", failures)
	if not failures.is_empty():
		_finish(failures)
		return
	route_manager.route_transition_failed.connect(_on_route_transition_failed)
	var registry_ok := bool(route_manager.call("ensure_registry"))
	_expect(registry_ok, "Hub route registry did not load", failures)
	var route := route_manager.get("_route_registry").call("get_route", &"hub_twin_solaria") as RefCounted
	_expect(route != null, "Crown Transfer route is absent", failures)
	if not failures.is_empty():
		_finish(failures)
		return

	var hub_identity := hub_map.get_instance_id()
	var retained_state := Node.new()
	retained_state.name = "H4RetainedHubStateProbe"
	hub_map.add_child(retained_state)
	var original_navigation: Node = navigation.get("runtime_navigation_provider")
	var ingress_actor_start := hub_map.get_named_marker(&"CrownTransfer").global_position
	operator.global_position = ingress_actor_start
	ingress.call("interact", operator)
	await _wait_for_node(route_manager, &"hub_twin_solaria")
	var session: RefCounted = route_manager.call("get_active_session") as RefCounted
	var twin := session.get("current_instance") as TWIN_SCRIPT if session != null else null
	_expect(twin != null, "CrownTransfer did not activate Twin Solaria", failures)
	if twin == null:
		_finish(failures)
		return
	_expect(session.get("current_level_id") == &"hub_twin_solaria", "route entered the wrong authored level", failures)
	_expect(operator.global_position == twin.get_spawn_position(&"Spawn_CrownCauseway"), "Operator missed Spawn_CrownCauseway", failures)
	_expect(not hub_map.visible and hub_map.process_mode == Node.PROCESS_MODE_DISABLED, "H1 Hub remained active during Twin traversal", failures)
	_expect(navigation.get("runtime_navigation_provider") == twin.authored_navigation, "Twin navigation was not bound before route input resumed", failures)
	_expect(camera.call("get_runtime_map") == twin, "Twin runtime camera map was not bound", failures)
	_expect(
		not twin.authored_navigation.compute_path(
			twin.get_spawn_position(&"Spawn_CrownCauseway"),
			twin.get_node("Exits/Exit_ReturnHub").global_position
		).is_empty(),
		"Twin navigation cannot reach its Hub return interaction",
		failures
	)
	_expect(int(transition_manager.call("count_authoritative_worlds")) == 1, "route entry changed major-world authority", failures)
	var exit := twin.get_node_or_null("Exits/Exit_ReturnHub") as Node2D
	_expect(exit != null and exit.is_in_group("interactable"), "Twin lacks its explicit Hub return interaction", failures)
	if exit == null:
		_finish(failures)
		return

	operator.global_position = exit.global_position
	exit.call("interact", operator)
	await _wait_for_route_end(route_manager)
	_expect(route_manager.call("get_active_session") == null, "Twin return did not end its route session", failures)
	_expect(hub_map.get_instance_id() == hub_identity, "Hub return replaced the original H1 instance", failures)
	_expect(hub_map.visible and hub_map.process_mode != Node.PROCESS_MODE_DISABLED, "Hub map did not resume after Twin return", failures)
	_expect(operator.global_position == hub_map.get_spawn_position(&"Spawn_TwinReturn"), "Hub return missed Spawn_TwinReturn", failures)
	_expect(hub_map.get_node_or_null("H4RetainedHubStateProbe") == retained_state, "Hub session state was lost during Twin traversal", failures)
	_expect(navigation.get("runtime_navigation_provider") == original_navigation, "Hub navigation provider was not restored", failures)
	_expect(camera.call("get_runtime_map") == hub_map, "Hub camera map was not restored", failures)
	_expect(
		camera.global_position == hub_map.get_spawn_position(&"Spawn_TwinReturn") + camera.get("player_offset"),
		"Hub camera did not snap to Spawn_TwinReturn",
		failures
	)
	await create_timer(0.30).timeout

	# A second complete cycle must reuse the Hub host and release the prior Twin instance.
	operator.global_position = ingress_actor_start
	ingress.call("interact", operator)
	await _wait_for_node(route_manager, &"hub_twin_solaria")
	var second_session: RefCounted = route_manager.call("get_active_session") as RefCounted
	var second_twin := second_session.get("current_instance") as TWIN_SCRIPT if second_session != null else null
	_expect(second_twin != null and second_twin != twin, "repeat entry did not stage a fresh Twin route node", failures)
	_expect(_count_named_children(hub_world, "TwinSolaria") == 1, "repeat entry created duplicate Twin instances", failures)
	if second_twin != null:
		operator.global_position = second_twin.get_node("Exits/Exit_ReturnHub").global_position
		second_twin.get_node("Exits/Exit_ReturnHub").call("interact", operator)
		await _wait_for_route_end(route_manager)
		_expect(hub_map.get_instance_id() == hub_identity, "repeat return replaced the H1 Hub instance", failures)
		_expect(operator.global_position == hub_map.get_spawn_position(&"Spawn_TwinReturn"), "repeat return missed Spawn_TwinReturn", failures)
		_expect(
			camera.global_position == hub_map.get_spawn_position(&"Spawn_TwinReturn") + camera.get("player_offset"),
			"repeat return camera missed Spawn_TwinReturn",
			failures
		)
	await create_timer(0.30).timeout
	_expect(_count_named_children(hub_world, "TwinSolaria") == 0, "route end retained an extra Twin instance", failures)

	# A bad authored target spawn must fail during staging and restore the Hub origin.
	var entry_edge := route.call("get_edge", &"crown_transfer_to_twin_solaria") as RefCounted
	var valid_spawn: StringName = entry_edge.get("target_spawn_id")
	entry_edge.set("target_spawn_id", &"MissingCrownSpawn")
	operator.global_position = ingress_actor_start
	var stage_failure_count := _route_failure_count
	ingress.call("interact", operator)
	_expect(await _wait_for_route_failure(route_manager, stage_failure_count), "staging failure path was not exercised", failures)
	_expect(route_manager.call("get_active_session") == null, "failed staging retained a route session", failures)
	_expect(hub_map.visible and operator.get_parent() == hub_world, "failed staging did not restore the Hub source", failures)
	_expect(operator.global_position == ingress_actor_start, "failed entry did not restore the original entry position", failures)
	entry_edge.set("target_spawn_id", valid_spawn)
	operator.global_position = hub_map.get_named_marker(&"Spawn_TwinReturn").global_position
	await create_timer(0.30).timeout

	# A conflicting loader identity forces the staged-level commit guard to reject activation.
	var sentinel := Node.new()
	sentinel.name = "H4UnexpectedLoaderAuthority"
	hub_world.add_child(sentinel)
	level_loader.call("adopt_active_level", &"h4_sentinel", sentinel)
	operator.global_position = ingress_actor_start
	var activation_origin := ingress.call("capture_world_origin", operator) as Dictionary
	ingress.call("isolate_world_origin", operator, &"gameplay")
	var activation_failure_count := _route_failure_count
	var activation_started := bool(route_manager.call("start_route", &"hub_twin_solaria", operator, {
		"parent": hub_world,
		"origin_ingress": ingress,
		"origin_snapshot": activation_origin,
		"source_state": activation_origin,
		"route_profile": &"production",
	}))
	_expect(not activation_started, "active-loader commit guard accepted a conflicting identity", failures)
	_expect(_route_failure_count > activation_failure_count, "activation failure path was not exercised", failures)
	var activation_restore := ingress.call("restore_world_origin", operator, activation_origin) as Dictionary
	_expect(bool(activation_restore.get("succeeded", false)), "activation rollback could not restore the Hub origin", failures)
	ingress.call("reset_after_level_return")
	_expect(level_loader.call("get_active_level_instance") == sentinel, "activation rollback changed unrelated loader identity", failures)
	_expect(hub_map.visible and operator.get_parent() == hub_world, "activation failure did not restore the Hub origin", failures)
	_expect(int(transition_manager.call("count_authoritative_worlds")) == 1, "activation failure changed major-world authority", failures)
	level_loader.call("clear_active_level", sentinel)
	sentinel.queue_free()
	retained_state.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Crown Transfer entry, Twin spawn/navigation/camera, exact Hub return, retained Hub session, and stage/activation rollback")
	else:
		_finish(failures)
		return
	quit(0)


func _wait_for_context(manager: Node, expected: StringName) -> void:
	for _frame in range(300):
		if StringName(manager.get("current_context")) == expected and not bool(manager.call("is_transitioning")):
			return
		await process_frame


func _wait_for_node(manager: Node, expected_level: StringName) -> void:
	for _frame in range(300):
		var session: RefCounted = manager.call("get_active_session") as RefCounted
		if session != null and session.get("current_level_id") == expected_level:
			return
		await process_frame


func _wait_for_route_end(manager: Node) -> void:
	for _frame in range(300):
		if manager.call("get_active_session") == null:
			return
		await process_frame



func _wait_for_route_failure(manager: Node, previous_failure_count: int) -> bool:
	for _frame in range(300):
		if _route_failure_count > previous_failure_count and manager.call("get_active_session") == null:
			return true
		await process_frame
	return false


func _on_route_transition_failed(_route_id: StringName, _edge_id: StringName, _reason: String) -> void:
	_route_failure_count += 1


func _count_named_children(parent: Node, target_name: String) -> int:
	var count := 1 if String(parent.name) == target_name else 0
	for child in parent.get_children():
		count += _count_named_children(child, target_name)
	return count


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	for failure in failures:
		push_error("FAIL: %s" % failure)
	quit(1)


func _fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)
