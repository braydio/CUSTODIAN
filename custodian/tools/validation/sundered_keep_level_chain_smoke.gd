extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")

var _errors: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var procgen := Node2D.new()
	procgen.name = "ProcGenRuntime"
	world.add_child(procgen)
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

	var approach := APPROACH_SCENE.instantiate()
	approach.name = "SunderedKeepApproach"
	world.add_child(approach)
	approach.call("configure_connection", procgen, Vector2(88.0, 96.0))
	actor.global_position = approach.call("get_entry_position")
	await process_frame
	await process_frame

	var vista_exit := approach.get_node_or_null("EventRuntime/LevelExitTrigger") as SunderedKeepTransitionTrigger
	_expect(vista_exit != null, "Vista endpoint transition trigger is missing")
	if vista_exit == null:
		_finish()
		return
	_expect(vista_exit.target_scene_path.ends_with("ReturnCausewayApproach.tscn"), "Vista endpoint does not target Return Causeway")
	_expect(vista_exit.target_node_name == &"ReturnCausewayApproach", "Vista endpoint target node name is unstable")
	vista_exit.vista_controller_path = NodePath()
	vista_exit.call("transition_actor", actor)
	await process_frame
	await process_frame

	var causeway := connected_maps.get_node_or_null("ReturnCausewayApproach")
	_expect(causeway != null, "Vista endpoint did not instantiate Return Causeway")
	if causeway == null:
		_finish()
		return
	_expect(actor.global_position.is_equal_approx(causeway.call("get_entry_position")), "Operator did not enter Return Causeway at its authored spawn")
	_expect(String(loader.call("get_active_level_id")) == "return_causeway", "LevelLoader did not adopt Return Causeway")
	_expect(not is_instance_valid(approach), "Vista Approach should retire after its endpoint handoff")

	var keep_controller := causeway.get_node_or_null("KeepTransitionController") as SunderedKeepTransitionTrigger
	var travel_gate := causeway.get_node_or_null("TravelToSunderedKeepGate")
	_expect(keep_controller != null, "Return Causeway is missing its Keep transition controller")
	_expect(travel_gate != null, "Return Causeway is missing its north travel gate")
	if travel_gate != null:
		_expect(travel_gate.get("connected_map") == keep_controller, "Return Causeway travel gate is not connected to the Keep transition")
	if keep_controller == null or travel_gate == null:
		_finish()
		return
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

	_finish()


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
