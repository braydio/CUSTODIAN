extends SceneTree

const LEVEL_LOADER := preload("res://game/world/levels/level_loader.gd")
const ROUTE_MANAGER := preload("res://game/world/routes/route_traversal_manager.gd")
const INGRESS := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const CAMERA := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")


class InventoryCounter:
	extends Node

	var add_item_calls := 0

	func has_item(_item_id: StringName, _amount := 1) -> bool:
		return false

	func add_item(_item_id: StringName, _amount := 1) -> bool:
		add_item_calls += 1
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var runtime := _build_runtime()
	var manager: Node = runtime.manager
	var loader: Node = runtime.loader
	var actor: CharacterBody2D = runtime.actor
	var inventory: InventoryCounter = runtime.inventory

	runtime.ingress.set("_triggered", true)
	runtime.ingress.call("_enter_approach", actor)
	_traverse(manager, &"continue", &"return_causeway", actor, errors)
	_traverse(manager, &"continue", &"front_gate", actor, errors)

	var first_front_gate: Node = loader.call("get_active_level_instance")
	if first_front_gate == null:
		errors.append("Front Gate did not become active")
		_finish(runtime.game_root, errors)
		return

	var original_state: Dictionary = first_front_gate.call("capture_route_state")
	var expected_keys := [
		"has_sundered_gate_key",
		"main_gate_open",
		"return_mooring_created",
		"great_hall_door_open",
		"sidearm_locker_opened",
		"routekeeper_trace_recovered",
		"siege_started",
		"siege_wave_index",
		"siege_pressure_tick",
		"siege_state",
		"siege_game_over_triggered",
		"siege_objectives",
		"great_hall_ambush",
	]
	for key in expected_keys:
		if not original_state.has(key):
			errors.append("Front Gate capture omitted %s" % key)

	var objective_signal_counts := {
		"damaged": 0,
		"repaired": 0,
		"destroyed": 0,
		"state_changed": 0,
	}
	var objectives: Dictionary = first_front_gate.get("_siege_objectives")
	for objective: Node in objectives.values():
		for signal_name in objective_signal_counts.keys():
			objective.connect(
				signal_name,
				func(_a = null, _b = null) -> void:
					objective_signal_counts[signal_name] += 1
			)

	var representative := original_state.duplicate(true)
	representative.merge({
		"has_sundered_gate_key": true,
		"main_gate_open": true,
		"return_mooring_created": true,
		"great_hall_door_open": true,
		"sidearm_locker_opened": true,
		"routekeeper_trace_recovered": true,
		"siege_started": true,
		"siege_wave_index": 2,
		"siege_pressure_tick": 7,
		"siege_state": "active",
		"siege_game_over_triggered": false,
	}, true)
	var objective_states: Dictionary = representative.siege_objectives
	var objective_index := 0
	for objective_id_variant: Variant in objective_states.keys():
		var objective_state: Dictionary = objective_states[objective_id_variant]
		objective_state["current_health"] = 54.0 + objective_index
		objective_state["state"] = "damaged"
		objective_state["last_damage_source"] = "route_state_smoke"
		objective_index += 1
	representative["great_hall_ambush"] = {
		"exists": false,
		"state": "complete",
		"marine_alive": false,
		"marine_position": Vector2(480.0, 320.0),
		"marine_health": 0.0,
	}

	if not bool(first_front_gate.call("restore_route_state", representative)):
		errors.append("representative Front Gate state was rejected")
	for signal_name in objective_signal_counts:
		if int(objective_signal_counts[signal_name]) != 0:
			errors.append("objective restoration replayed %s" % signal_name)
	var inventory_calls_before_revisit := inventory.add_item_calls

	_traverse(manager, &"backtrack", &"return_causeway", actor, errors)
	await process_frame
	if is_instance_valid(first_front_gate):
		errors.append("snapshot-and-unload retained the original Front Gate instance")

	_traverse(manager, &"continue", &"front_gate", actor, errors)
	var restored_front_gate: Node = loader.call("get_active_level_instance")
	if restored_front_gate == null:
		errors.append("Front Gate revisit did not become active")
	else:
		if restored_front_gate == first_front_gate:
			errors.append("Front Gate revisit reused the unloaded instance")
		_assert_restored_state(
			restored_front_gate,
			representative,
			inventory_calls_before_revisit,
			inventory,
			errors
		)

	if manager.call("has_active_route") \
	and not manager.call("request_exit", &"exfil", actor):
		errors.append("Front Gate exfil failed")
	if manager.call("has_active_route"):
		errors.append("exfil retained route authority")
	if loader.call("get_active_level_instance") != null:
		errors.append("exfil retained loader instance authority")
	if not (loader.call("get_active_level_id") as StringName).is_empty():
		errors.append("exfil retained loader level identity")

	_finish(runtime.game_root, errors)


func _assert_restored_state(
	front_gate: Node,
	expected: Dictionary,
	inventory_calls_before_revisit: int,
	inventory: InventoryCounter,
	errors: Array[String]
) -> void:
	var captured: Dictionary = front_gate.call("capture_route_state")
	for key in expected.keys():
		if captured.get(key) != expected[key]:
			errors.append("restored Front Gate state differs for %s" % key)
	if inventory.add_item_calls != inventory_calls_before_revisit:
		errors.append("route restoration repeated a pickup or reward")
	var main_gate_blockers: Array = front_gate.get("_main_gate_blockers")
	var great_hall_blockers: Array = front_gate.get("_great_hall_door_blockers")
	if not main_gate_blockers.is_empty():
		errors.append("open main gate restored with blockers")
	if not great_hall_blockers.is_empty():
		errors.append("open Great Hall door restored with blockers")
	for property_name in [
		"_key_pickup_interaction",
		"_sidearm_locker_interaction",
		"_main_gate_interaction",
		"_great_hall_door_interaction",
	]:
		var interaction: Node = front_gate.get(property_name)
		if interaction != null and is_instance_valid(interaction):
			if interaction.visible or interaction.is_in_group("interactable"):
				errors.append("completed interactable replayed: %s" % property_name)
	var timer: Timer = front_gate.get("_siege_timer")
	if timer == null or timer.is_stopped():
		errors.append("active restored siege did not resume its pressure timer")
	if not (front_gate.get("_siege_live_enemies") as Dictionary).is_empty():
		errors.append("route restoration retained stale live-enemy references")
	if not (front_gate.get("_siege_required_enemy_ids") as Dictionary).is_empty():
		errors.append("route restoration retained stale required-enemy IDs")
	if bool(front_gate.get("_siege_wave_spawning")):
		errors.append("route restoration retained wave-spawning state")
	var ambush: Dictionary = captured.get("great_hall_ambush", {})
	if bool(ambush.get("exists", true)) \
	or str(ambush.get("state", "")) != "complete":
		errors.append("completed Great Hall ambush replayed")


func _traverse(
	manager: Node,
	exit_id: StringName,
	expected_node_id: StringName,
	actor: Node,
	errors: Array[String]
) -> void:
	if not bool(manager.call("request_exit", exit_id, actor)):
		errors.append("route transition failed through %s" % exit_id)
	elif manager.call("get_current_node_id") != expected_node_id:
		errors.append(
			"route transition through %s reached %s instead of %s"
			% [exit_id, manager.call("get_current_node_id"), expected_node_id]
		)


func _build_runtime() -> Dictionary:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var inventory := InventoryCounter.new()
	inventory.name = "InventoryManager"
	root.add_child(inventory)
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
	var actor := CharacterBody2D.new()
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
	ingress.configure_route(&"sundered_keep", &"production", procgen)
	world.add_child(ingress)
	return {
		"game_root": game_root,
		"inventory": inventory,
		"actor": actor,
		"loader": loader,
		"manager": manager,
		"ingress": ingress,
	}


func _finish(game_root: Node, errors: Array[String]) -> void:
	game_root.queue_free()
	var inventory := root.get_node_or_null("InventoryManager")
	if inventory != null:
		inventory.queue_free()
	if errors.is_empty():
		print("[SunderedKeepRouteStateSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepRouteStateSmoke] %s" % error)
	quit(1)
