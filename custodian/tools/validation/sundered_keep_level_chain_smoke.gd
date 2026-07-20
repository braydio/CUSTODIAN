extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")

var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await _check_default_causeway_branch()
	await _check_direct_keep_branch()
	await _check_return_causeway_branch()
	_finish()


func _check_default_causeway_branch() -> void:
	var fixture := _create_fixture()
	var game_root := fixture["game_root"] as Node2D
	var world := fixture["world"] as Node2D
	var procgen := fixture["procgen"] as Node2D
	var connected_maps := fixture["connected_maps"] as Node2D
	var loader := fixture["loader"] as Node
	var actor := fixture["actor"] as Node2D

	var approach := APPROACH_SCENE.instantiate()
	approach.name = "SunderedKeepApproach"
	approach.call("configure_connection", procgen, Vector2(88.0, 96.0))
	world.add_child(approach)
	actor.global_position = approach.call("get_entry_position")
	await process_frame
	await process_frame
	_expect(not procgen.visible and procgen.process_mode == Node.PROCESS_MODE_DISABLED, "Vista entry did not isolate ProcGenRuntime before presentation")
	_expect(not connected_maps.visible and connected_maps.process_mode == Node.PROCESS_MODE_DISABLED, "Vista entry did not isolate ConnectedMaps")
	var harvest_marker := fixture["harvest_marker"] as CanvasItem
	var aspect_marker := fixture["aspect_marker"] as CanvasItem
	_expect(not harvest_marker.is_visible_in_tree(), "Harvest marker remained visible during Vista Approach")
	_expect(not aspect_marker.is_visible_in_tree(), "Aspect marker remained visible during Vista Approach")

	var vista_exit := approach.get_node_or_null("EventRuntime/LevelExitTrigger") as SunderedKeepTransitionTrigger
	_expect(vista_exit != null, "Default branch Vista endpoint transition trigger is missing")
	if vista_exit != null:
		_expect(not bool(approach.get("bypass_return_causeway_for_keep_testing")), "Return Causeway bypass should be disabled by default")
		_expect(vista_exit.target_scene_path.ends_with("ReturnCausewayApproach.tscn"), "Default Vista endpoint does not target Return Causeway")
		_expect(vista_exit.target_node_name == &"ReturnCausewayApproach", "Default Vista endpoint target node name is unstable")
		_expect(vista_exit.target_level_id == &"return_causeway", "Default Vista endpoint changed its level id")
		vista_exit.vista_controller_path = NodePath()
		vista_exit.call("transition_actor", actor)
		await process_frame
		await process_frame

		var causeway := connected_maps.get_node_or_null("ReturnCausewayApproach")
		_expect(causeway != null, "Default Vista endpoint did not instantiate Return Causeway")
		_expect(connected_maps.get_node_or_null("SunderedKeepMap") == null, "Default path unexpectedly instantiated Sundered Keep directly")
		if causeway != null:
			_expect(actor.global_position.is_equal_approx(causeway.call("get_entry_position")), "Operator did not enter Return Causeway at its authored spawn")
			_expect(String(loader.call("get_active_level_id")) == "return_causeway", "LevelLoader did not adopt Return Causeway")
		_expect(not is_instance_valid(approach), "Vista Approach should retire after its Causeway handoff")

	game_root.queue_free()
	await process_frame
	await process_frame


func _check_direct_keep_branch() -> void:
	var fixture := _create_fixture()
	var game_root := fixture["game_root"] as Node2D
	var world := fixture["world"] as Node2D
	var procgen := fixture["procgen"] as Node2D
	var connected_maps := fixture["connected_maps"] as Node2D
	var loader := fixture["loader"] as Node
	var actor := fixture["actor"] as Node2D

	var approach := APPROACH_SCENE.instantiate()
	approach.name = "SunderedKeepApproach"
	approach.set("bypass_return_causeway_for_keep_testing", true)
	approach.call("configure_connection", procgen, Vector2(88.0, 96.0))
	world.add_child(approach)
	actor.global_position = approach.call("get_entry_position")
	await process_frame
	await process_frame
	_expect(not procgen.visible and procgen.process_mode == Node.PROCESS_MODE_DISABLED, "Vista entry did not isolate ProcGenRuntime before presentation")
	_expect(not connected_maps.visible and connected_maps.process_mode == Node.PROCESS_MODE_DISABLED, "Vista entry did not isolate ConnectedMaps")
	var harvest_marker := fixture["harvest_marker"] as CanvasItem
	var aspect_marker := fixture["aspect_marker"] as CanvasItem
	_expect(not harvest_marker.is_visible_in_tree(), "Harvest marker remained visible during Vista Approach")
	_expect(not aspect_marker.is_visible_in_tree(), "Aspect marker remained visible during Vista Approach")

	var vista_exit := approach.get_node_or_null("EventRuntime/LevelExitTrigger") as SunderedKeepTransitionTrigger
	_expect(vista_exit != null, "Direct branch Vista endpoint transition trigger is missing")
	if vista_exit != null:
		_expect(bool(approach.get("bypass_return_causeway_for_keep_testing")), "Return Causeway bypass should be enabled when forced")
		_expect(vista_exit.target_scene_path.ends_with("sundered_keep_map.gd"), "Direct Vista endpoint does not target Sundered Keep directly")
		_expect(vista_exit.target_node_name == &"SunderedKeepMap", "Direct Vista endpoint target node name is unstable")
		_expect(vista_exit.target_level_id == &"sundered_keep_front_gate", "Direct Vista endpoint changed the front-gate level id")
		vista_exit.vista_controller_path = NodePath()
		vista_exit.call("transition_actor", actor)
		await process_frame
		await process_frame

		var keep := connected_maps.get_node_or_null("SunderedKeepMap")
		_expect(keep != null, "Direct Vista endpoint did not instantiate Sundered Keep")
		_expect(connected_maps.get_node_or_null("ReturnCausewayApproach") == null, "Direct bypass unexpectedly instantiated Return Causeway")
		if keep != null:
			_expect(actor.global_position.is_equal_approx(keep.call("get_entry_position")), "Direct Vista endpoint did not use the Keep entry position")
			_expect(keep.get("main_map") == procgen, "Direct Keep return ownership should point to the upstream world map")
			_expect(String(loader.call("get_active_level_id")) == "sundered_keep_front_gate", "LevelLoader did not adopt the direct Keep target")
			keep.call("return_to_main", actor)
			_expect(procgen.visible and procgen.process_mode != Node.PROCESS_MODE_DISABLED, "Direct Keep return did not reactivate the upstream world map")
			_expect(not keep.visible and keep.process_mode == Node.PROCESS_MODE_DISABLED, "Direct Keep return did not deactivate the Keep branch")
			_expect(actor.global_position.is_equal_approx(Vector2(88.0, 96.0)), "Direct Keep return did not restore the configured world position")
		_expect(not is_instance_valid(approach), "Vista Approach should retire after direct Keep handoff")

	game_root.queue_free()
	await process_frame
	await process_frame


func _check_return_causeway_branch() -> void:
	var fixture := _create_fixture()
	var game_root := fixture["game_root"] as Node2D
	var world := fixture["world"] as Node2D
	var procgen := fixture["procgen"] as Node2D
	var connected_maps := fixture["connected_maps"] as Node2D
	var loader := fixture["loader"] as Node
	var actor := fixture["actor"] as Node2D

	var approach := APPROACH_SCENE.instantiate()
	approach.name = "SunderedKeepApproach"
	approach.set("bypass_return_causeway_for_keep_testing", false)
	approach.call("configure_connection", procgen, Vector2(88.0, 96.0))
	world.add_child(approach)
	actor.global_position = approach.call("get_entry_position")
	await process_frame
	await process_frame

	var vista_exit := approach.get_node_or_null("EventRuntime/LevelExitTrigger") as SunderedKeepTransitionTrigger
	_expect(vista_exit != null, "Causeway branch Vista endpoint transition trigger is missing")
	if vista_exit == null:
		game_root.queue_free()
		await process_frame
		return
	_expect(vista_exit.target_scene_path.ends_with("ReturnCausewayApproach.tscn"), "Disabled bypass does not target Return Causeway")
	_expect(vista_exit.target_node_name == &"ReturnCausewayApproach", "Causeway branch endpoint target node name is unstable")
	_expect(vista_exit.target_level_id == &"return_causeway", "Causeway branch endpoint changed its level id")
	vista_exit.vista_controller_path = NodePath()
	vista_exit.call("transition_actor", actor)
	await process_frame
	await process_frame

	var causeway := connected_maps.get_node_or_null("ReturnCausewayApproach")
	_expect(causeway != null, "Vista endpoint did not instantiate the enabled Return Causeway branch")
	if causeway != null:
		_expect(actor.global_position.is_equal_approx(causeway.call("get_entry_position")), "Operator did not enter Return Causeway at its authored spawn")
		_expect(String(loader.call("get_active_level_id")) == "return_causeway", "LevelLoader did not adopt Return Causeway")
		var entry_title := causeway.find_child("ReturnCausewayEntryAffordance", true, false) as Label
		_expect(entry_title != null, "Return Causeway entry affordance is missing")
		if entry_title != null:
			_expect(entry_title.text.contains("RETURN CAUSEWAY"), "Return Causeway entry title is unclear")
			_expect(entry_title.text.contains("RE-ESTABLISHING KEEP APPROACH"), "Return Causeway entry objective is unclear")
		var observatory := root.get_node_or_null("DevObservatory")
		if observatory != null and observatory.has_method("get_recent_events"):
			var causeway_events: Array = observatory.call("get_recent_events", 5, &"sundered_keep_flow_entered_return_causeway")
			_expect(not causeway_events.is_empty(), "Return Causeway did not emit its flow-entry Observatory event")
	_expect(not is_instance_valid(approach), "Vista Approach should retire after its Causeway handoff")
	if causeway == null:
		game_root.queue_free()
		await process_frame
		return

	var keep_controller := causeway.get_node_or_null("KeepTransitionController") as SunderedKeepTransitionTrigger
	var travel_gate := causeway.get_node_or_null("TravelToSunderedKeepGate")
	_expect(keep_controller != null, "Return Causeway is missing its Keep transition controller")
	_expect(travel_gate != null, "Return Causeway is missing its north travel gate")
	if travel_gate != null:
		_expect(travel_gate.get("connected_map") == keep_controller, "Return Causeway travel gate is not connected to the Keep transition")
	if keep_controller != null and travel_gate != null:
		travel_gate.call("interact", actor)
		await process_frame
		await process_frame

		var keep := connected_maps.get_node_or_null("SunderedKeepMap")
		_expect(keep != null, "Return Causeway did not instantiate Sundered Keep")
		if keep != null:
			_expect(not causeway.visible and causeway.process_mode == Node.PROCESS_MODE_DISABLED, "Return Causeway should pause while the Keep is active")
			_expect(actor.global_position.is_equal_approx(keep.call("get_entry_position")), "Operator did not enter the Keep at its authored entrance")
			_expect(keep.get("main_map") == causeway, "Keep return ownership should point to Return Causeway")
			_expect(String(loader.call("get_active_level_id")) == "sundered_keep_front_gate", "LevelLoader did not adopt Sundered Keep")
			var expected_return: Vector2 = causeway.call("_get_keep_return_position")
			keep.call("return_to_main", actor)
			_expect(causeway.visible and causeway.process_mode != Node.PROCESS_MODE_DISABLED, "Keep return did not reactivate Return Causeway")
			_expect(not keep.visible and keep.process_mode == Node.PROCESS_MODE_DISABLED, "Keep return did not deactivate the Keep branch")
			_expect(actor.global_position.is_equal_approx(expected_return), "Keep return did not use the Causeway north anchor")
			_expect(String(loader.call("get_active_level_id")) == "return_causeway", "Keep return did not restore Return Causeway as the active level")
			_expect(not bool(keep_controller.get("_triggered")), "Keep return did not re-arm the Causeway transition")

	game_root.queue_free()
	await process_frame
	await process_frame


func _create_fixture() -> Dictionary:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var procgen := Node2D.new()
	procgen.name = "ProcGenRuntime"
	world.add_child(procgen)
	var harvest_marker := Polygon2D.new()
	harvest_marker.name = "HarvestMarkerFixture"
	harvest_marker.add_to_group("resource_nodes")
	procgen.add_child(harvest_marker)
	var aspect_marker := Polygon2D.new()
	aspect_marker.name = "AspectMarkerFixture"
	aspect_marker.add_to_group("aspect_markers")
	procgen.add_child(aspect_marker)
	var connected_maps := Node2D.new()
	connected_maps.name = "ConnectedMaps"
	world.add_child(connected_maps)
	var loader := LEVEL_LOADER_SCRIPT.new()
	loader.name = "LevelLoader"
	world.add_child(loader)
	var actor := Node2D.new()
	actor.name = "Operator"
	actor.add_to_group("player")
	world.add_child(actor)
	return {
		"game_root": game_root,
		"world": world,
		"procgen": procgen,
		"connected_maps": connected_maps,
		"loader": loader,
		"actor": actor,
		"harvest_marker": harvest_marker,
		"aspect_marker": aspect_marker,
	}


func _expect(value: bool, message: String) -> void:
	if not value:
		_errors.append(message)


func _finish() -> void:
	if _errors.is_empty():
		print("[SunderedKeepLevelChainSmoke] PASS")
		quit(0)
		return
	for message in _errors:
		push_error("[SunderedKeepLevelChainSmoke] %s" % message)
	quit(1)
