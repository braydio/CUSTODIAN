extends Node

signal phase_changed(request_id: String, phase_name: StringName)
signal transition_finished(result: Dictionary)

const HUB_HOST_SCENE := "res://scenes/hub_runtime_host.tscn"
const HUB_SPAWN_ID: StringName = &"Spawn_SouthReach"
const HUB_CONTEXT: StringName = &"hub"
const AWAKENING_CONTEXT: StringName = &"awakening"
const CONTEXT_ALIASES := {
	&"compound": &"hub",
	&"home": &"hub",
}
const AwakeningLayoutScript := preload("res://game/world/awakening/awakening_layout.gd")

enum Phase {
	IDLE,
	VALIDATING,
	REQUESTED,
	SOURCE_FROZEN,
	STAGING_TARGET,
	BINDING_TARGET,
	COMMITTING,
	COMPLETE,
	FAILED,
}

const PHASE_NAMES := {
	Phase.IDLE: &"idle",
	Phase.VALIDATING: &"validating",
	Phase.REQUESTED: &"requested",
	Phase.SOURCE_FROZEN: &"source_frozen",
	Phase.STAGING_TARGET: &"staging_target",
	Phase.BINDING_TARGET: &"binding_target",
	Phase.COMMITTING: &"committing",
	Phase.COMPLETE: &"complete",
	Phase.FAILED: &"failed",
}

var current_context: StringName = &"none"
var phase: Phase = Phase.IDLE
var active_context_root: Node
var active_world_root: Node2D
var last_result: Dictionary = {}
var last_rejection_code: StringName = &""
var hub_host_scene_path := HUB_HOST_SCENE

var _awaiting_startup_awakening := false
var _transition_in_flight := false
var _request_sequence := 0
var _active_request: WorldTransitionRequest
var _source_state: Dictionary = {}
var _binding_order: Array[StringName] = []


func arm_for_startup_awakening() -> void:
	_awaiting_startup_awakening = true


func register_awakening(root: Node) -> bool:
	if not _awaiting_startup_awakening or root == null:
		return false
	if not root.has_signal("awakening_completed"):
		return false
	var completion_callable := Callable(self, "request_awakening_to_hub")
	if not root.is_connected("awakening_completed", completion_callable):
		root.connect("awakening_completed", completion_callable)
	var world := root.get_node_or_null("World") as Node2D
	if world == null:
		return false
	_awaiting_startup_awakening = false
	current_context = AWAKENING_CONTEXT
	active_context_root = root
	active_world_root = world
	world.add_to_group("major_context_world")
	world.set_meta("major_context_authoritative", true)
	root.set_meta("major_context_authoritative", true)
	root.set_meta("major_context", AWAKENING_CONTEXT)
	return true


func request_awakening_to_hub(snapshot: Dictionary, target_scene_override: String = "") -> bool:
	last_rejection_code = &""
	if _transition_in_flight:
		return _reject(&"TRANSITION_IN_PROGRESS")
	if canonical_context(current_context) != AWAKENING_CONTEXT:
		return _reject(&"SOURCE_CONTEXT_MISMATCH")
	if active_context_root == null or not is_instance_valid(active_context_root):
		return _reject(&"SOURCE_CONTEXT_MISSING")
	if get_tree().current_scene != active_context_root:
		return _reject(&"SOURCE_NOT_CURRENT_SCENE")
	if not _snapshot_is_qualified(snapshot, active_context_root):
		return _reject(&"COMPLETION_NOT_QUALIFIED")

	var operator := active_context_root.get_node_or_null("World/Operator") as CharacterBody2D
	var controller := active_context_root.get_node_or_null("World/PlayerController")
	var camera := active_context_root.get_node_or_null("World/Camera2D") as Camera2D
	var hud := active_context_root.get_node_or_null("CustodianHUD")
	if operator == null or controller == null or camera == null or hud == null:
		return _reject(&"SOURCE_BINDING_MISSING")

	_request_sequence += 1
	_active_request = WorldTransitionRequest.new()
	_active_request.request_id = "awakening-hub-%04d" % _request_sequence
	_active_request.source_context = AWAKENING_CONTEXT
	_active_request.target_context = HUB_CONTEXT
	_active_request.target_scene_path = target_scene_override if not target_scene_override.is_empty() else hub_host_scene_path
	_active_request.target_spawn_id = HUB_SPAWN_ID
	_active_request.payload = snapshot.duplicate(true)
	_source_state = _capture_source_state(active_context_root, operator, controller, camera, hud)
	_binding_order.clear()
	_transition_in_flight = true
	_set_phase(Phase.VALIDATING)
	_set_phase(Phase.REQUESTED)
	_freeze_source()
	_set_phase(Phase.SOURCE_FROZEN)
	call_deferred("_run_transition", _active_request)
	return true


func canonical_context(context: StringName) -> StringName:
	return StringName(CONTEXT_ALIASES.get(context, context))


func is_transitioning() -> bool:
	return _transition_in_flight


func get_phase_name() -> StringName:
	return StringName(PHASE_NAMES.get(phase, &"unknown"))


func count_authoritative_worlds() -> int:
	var count := 0
	for world in get_tree().get_nodes_in_group("major_context_world"):
		if is_instance_valid(world) and bool(world.get_meta("major_context_authoritative", false)):
			count += 1
	return count


func _snapshot_is_qualified(snapshot: Dictionary, source_root: Node) -> bool:
	var operator_position: Variant = snapshot.get("operator_global_position")
	if not (operator_position is Vector2) or source_root == null:
		return false
	var operator := source_root.get_node_or_null("World/Operator") as Node2D
	return operator != null \
		and bool(source_root.get("completed")) \
		and bool(source_root.get("opening_console_acknowledged")) \
		and bool(source_root.get("p9_recovered")) \
		and operator.global_position.distance_squared_to(operator_position) <= 1.0 \
		and bool(snapshot.get("completed", false)) \
		and bool(snapshot.get("opening_console_acknowledged", false)) \
		and bool(snapshot.get("p9_recovered", false)) \
		and StringName(str(snapshot.get("final_zone_id", ""))) == &"zone10_road_south_reach" \
		and operator_position is Vector2


func _capture_source_state(root: Node, operator: CharacterBody2D, controller: Node, camera: Camera2D, hud: Node) -> Dictionary:
	return {
		"root": root,
		"world": active_world_root,
		"operator": operator,
		"controller": controller,
		"camera": camera,
		"hud": hud,
		"root_name": root.name,
		"world_name": active_world_root.name,
		"world_process_mode": active_world_root.process_mode,
		"root_processing": _capture_processing(root),
		"operator_processing": _capture_processing(operator),
		"controller_processing": _capture_processing(controller),
		"camera_processing": _capture_processing(camera),
		"hud_processing": _capture_processing(hud),
		"hud_visible": bool(hud.get("visible")) if hud.get("visible") != null else true,
		"operator_position": operator.global_position,
		"operator_velocity": operator.velocity,
		"collision_layer": operator.collision_layer,
		"collision_mask": operator.collision_mask,
		"camera_bounds": AwakeningLayoutScript.WORLD_BOUNDS,
		"objective": str(root.get("current_objective_text")),
	}


func _capture_processing(node: Node) -> Dictionary:
	return {
		"process": node.is_processing(),
		"physics": node.is_physics_processing(),
		"input": node.is_processing_input(),
		"unhandled_input": node.is_processing_unhandled_input(),
		"unhandled_key_input": node.is_processing_unhandled_key_input(),
	}


func _set_processing(node: Node, state: Dictionary) -> void:
	node.set_process(bool(state.get("process", true)))
	node.set_physics_process(bool(state.get("physics", true)))
	node.set_process_input(bool(state.get("input", true)))
	node.set_process_unhandled_input(bool(state.get("unhandled_input", true)))
	node.set_process_unhandled_key_input(bool(state.get("unhandled_key_input", true)))


func _freeze_source() -> void:
	var root := _source_state["root"] as Node
	var world := _source_state["world"] as Node2D
	var operator := _source_state["operator"] as CharacterBody2D
	var controller := _source_state["controller"] as Node
	var camera := _source_state["camera"] as Camera2D
	var hud := _source_state["hud"] as Node
	root.set_process(false)
	root.set_process_input(false)
	root.set_process_unhandled_input(false)
	root.set_process_unhandled_key_input(false)
	root.name = "OutgoingAwakening"
	world.set_meta("major_context_authoritative", false)
	root.set_meta("major_context_authoritative", false)
	world.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	operator.velocity = Vector2.ZERO
	operator.set_deferred("collision_layer", 0)
	operator.set_deferred("collision_mask", 0)
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set_process_input(false)
	operator.set_process_unhandled_input(false)
	operator.set_process_unhandled_key_input(false)
	controller.set_process(false)
	controller.set_physics_process(false)
	controller.set_process_input(false)
	controller.set_process_unhandled_input(false)
	controller.set_process_unhandled_key_input(false)
	camera.set_process(false)
	camera.set_physics_process(false)
	hud.set("visible", false)
	current_context = &"none"
	active_context_root = null
	active_world_root = null
	_binding_order.append(&"source_frozen")


func _run_transition(request: WorldTransitionRequest) -> void:
	_set_phase(Phase.STAGING_TARGET)
	if not ResourceLoader.exists(request.target_scene_path, "PackedScene"):
		await _rollback(&"TARGET_SCENE_UNAVAILABLE", "Target Hub host could not be loaded")
		return
	var packed := ResourceLoader.load(request.target_scene_path) as PackedScene
	if packed == null:
		await _rollback(&"TARGET_SCENE_UNAVAILABLE", "Target Hub host could not be loaded")
		return
	var target_root := packed.instantiate() as Node2D
	if target_root == null:
		await _rollback(&"TARGET_SCENE_INVALID", "Target Hub host root is not Node2D")
		return
	target_root.name = "GameRoot"
	get_tree().root.add_child(target_root)
	var target_world := target_root.get_node_or_null("World") as Node2D
	var map := target_root.get_node_or_null("World/Level")
	var navigation := target_root.get_node_or_null("NavigationSystem")
	if target_world == null or map == null or navigation == null:
		await _rollback(&"TARGET_BINDING_MISSING", "Hub host must provide World, Level and NavigationSystem", target_root)
		return
	target_world.add_to_group("major_context_world")
	target_world.set_meta("major_context_authoritative", false)
	if not map.has_method("has_spawn") or not bool(map.call("has_spawn", request.target_spawn_id)):
		await _rollback(&"TARGET_SPAWN_MISSING", "Hub host does not expose Spawn_SouthReach", target_root)
		return
	await get_tree().process_frame
	if not is_instance_valid(target_root) or not is_instance_valid(map) or not navigation.is_inside_tree():
		await _rollback(&"TARGET_STAGE_FAILED", "Hub target was not stable after scene staging", target_root)
		return

	_set_phase(Phase.BINDING_TARGET)
	var operator := _source_state["operator"] as CharacterBody2D
	var controller := _source_state["controller"] as Node
	var camera := _source_state["camera"] as Camera2D
	var hud := _source_state["hud"] as Node
	if not _move_node(operator, target_world) \
		or not _move_node(controller, target_world) \
		or not _move_node(camera, target_world) \
		or not _move_node(hud, target_root):
		await _rollback(&"SOURCE_TRANSFER_FAILED", "Could not transfer the frozen player bindings", target_root)
		return
	operator.global_position = map.call("get_spawn_position", request.target_spawn_id) as Vector2
	operator.velocity = Vector2.ZERO
	if not map.has_method("complete_route_activation") or not bool(map.call("complete_route_activation", {"major_context": HUB_CONTEXT})):
		await _rollback(&"NAVIGATION_BIND_FAILED", "Hub authored navigation activation failed", target_root)
		return
	var provider: Variant = navigation.get("runtime_navigation_provider")
	if provider != map.get("authored_navigation"):
		await _rollback(&"NAVIGATION_BIND_FAILED", "Hub navigation provider is not the H1 authored provider", target_root)
		return
	_binding_order.append(&"navigation_bound")
	if not camera.has_method("set_runtime_map") or not camera.has_method("get_runtime_map"):
		await _rollback(&"CAMERA_BIND_FAILED", "Camera does not expose runtime map binding", target_root)
		return
	camera.set("operator_ref", operator)
	camera.set("follow_target", operator)
	camera.call("set_runtime_map", map)
	camera.make_current()
	var bounds: Variant = camera.get("map_bounds")
	var path: Variant = navigation.call("compute_path_immediate", operator.global_position, map.call("get_spawn_position", &"ForumSouth"))
	if camera.call("get_runtime_map") != map or not (bounds is Rect2) or not (bounds as Rect2).has_point(operator.global_position):
		await _rollback(&"CAMERA_BIND_FAILED", "Camera bounds/map binding did not contain the Hub spawn", target_root)
		return
	if not (path is PackedVector2Array) or (path as PackedVector2Array).is_empty():
		await _rollback(&"NAVIGATION_VALIDATION_FAILED", "Hub navigation could not route from Spawn_SouthReach to ForumSouth", target_root)
		return
	_binding_order.append(&"camera_bound")
	if controller.get("operator") != operator:
		await _rollback(&"CONTROLLER_BIND_FAILED", "PlayerController lost its Operator binding during transfer", target_root)
		return
	if active_world_root == target_world or count_authoritative_worlds() != 0:
		await _rollback(&"DUAL_WORLD_AUTHORITY", "A gameplay world remained authoritative during target commit", target_root)
		return

	_set_phase(Phase.COMMITTING)
	var source_root := _source_state["root"] as Node
	source_root.name = "OutgoingAwakening"
	target_root.set_meta("major_context", HUB_CONTEXT)
	target_world.add_to_group("major_context_world")
	target_world.set_meta("major_context_authoritative", true)
	target_root.set_meta("major_context_authoritative", true)
	get_tree().current_scene = target_root
	active_context_root = target_root
	active_world_root = target_world
	current_context = HUB_CONTEXT
	source_root.queue_free()
	await get_tree().process_frame
	if is_instance_valid(source_root) or count_authoritative_worlds() != 1:
		if is_instance_valid(source_root):
			source_root.free()
		if count_authoritative_worlds() != 1:
			push_error("[WorldTransitionManager] SOURCE_RELEASE_FAILED: expected exactly one authoritative world")
		return
	_binding_order.append(&"authority_committed")
	operator.collision_layer = int(_source_state["collision_layer"])
	operator.collision_mask = int(_source_state["collision_mask"])
	_set_processing(operator, _source_state["operator_processing"])
	_set_processing(controller, _source_state["controller_processing"])
	_set_processing(camera, _source_state["camera_processing"])
	_set_processing(hud, _source_state["hud_processing"])
	hud.set("visible", _source_state["hud_visible"])
	if hud.has_method("hide_interaction"):
		hud.call("hide_interaction")
	if hud.has_method("set_location"):
		hud.call("set_location", "HUB // SOUTH REACH")
	if hud.has_method("set_objective"):
		hud.call("set_objective", "")
	_binding_order.append(&"input_unlocked")
	_set_phase(Phase.COMPLETE)
	_finish_result(true, &"", "", operator.global_position)


func _move_node(node: Node, new_parent: Node) -> bool:
	if node == null or new_parent == null or node.get_parent() == null:
		return false
	node.reparent(new_parent)
	return node.get_parent() == new_parent


func _rollback(code: StringName, reason: String, target_root: Node = null) -> void:
	var operator := _source_state.get("operator") as CharacterBody2D
	var controller := _source_state.get("controller") as Node
	var camera := _source_state.get("camera") as Camera2D
	var hud := _source_state.get("hud") as Node
	var source_world := _source_state.get("world") as Node2D
	var source_root := _source_state.get("root") as Node
	if is_instance_valid(operator) and is_instance_valid(source_world) and operator.get_parent() != source_world:
		operator.reparent(source_world)
	if is_instance_valid(controller) and is_instance_valid(source_world) and controller.get_parent() != source_world:
		controller.reparent(source_world)
	if is_instance_valid(camera) and is_instance_valid(source_world) and camera.get_parent() != source_world:
		camera.reparent(source_world)
	if is_instance_valid(hud) and is_instance_valid(source_root) and hud.get_parent() != source_root:
		hud.reparent(source_root)
	if target_root != null and is_instance_valid(target_root):
		target_root.queue_free()
	await get_tree().process_frame
	if is_instance_valid(source_root):
		source_root.name = str(_source_state.get("root_name", "GameRoot"))
	if is_instance_valid(source_world):
		source_world.name = str(_source_state.get("world_name", "World"))
		source_world.process_mode = int(_source_state.get("world_process_mode", Node.PROCESS_MODE_INHERIT))
	if is_instance_valid(operator):
		# The source snapshot is captured from the completion trigger. Return south
		# of that trigger on rollback so the still-qualified Operator cannot
		# immediately re-enter the completion volume and spin another failed handoff.
		operator.global_position = AwakeningLayoutScript.SOUTH_REACH_COMPLETION_CENTER + Vector2(0.0, 128.0)
		operator.velocity = Vector2.ZERO
		operator.collision_layer = int(_source_state.get("collision_layer", 1))
		operator.collision_mask = int(_source_state.get("collision_mask", 1))
		_set_processing(operator, _source_state.get("operator_processing", {}))
	if is_instance_valid(controller):
		_set_processing(controller, _source_state.get("controller_processing", {}))
	if is_instance_valid(camera):
		camera.set("operator_ref", operator)
		camera.set("follow_target", operator)
		camera.call("clear_presentation_framing", true)
		camera.call("set_runtime_map", null)
		camera.call("set_authored_map_bounds", _source_state.get("camera_bounds", AwakeningLayoutScript.WORLD_BOUNDS))
		camera.call("snap_to_player_spawn", operator.global_position)
		_set_processing(camera, _source_state.get("camera_processing", {}))
	if is_instance_valid(hud):
		hud.set("visible", _source_state.get("hud_visible", true))
		if hud.has_method("set_objective"):
			hud.call("set_objective", str(_source_state.get("objective", "RETURN TO POST")))
		_set_processing(hud, _source_state.get("hud_processing", {}))
	if is_instance_valid(source_root):
		_set_processing(source_root, _source_state.get("root_processing", {}))
		if source_root.has_method("restore_after_handoff_failure"):
			source_root.call("restore_after_handoff_failure")
		get_tree().current_scene = source_root
		active_context_root = source_root
		active_world_root = source_world
		current_context = AWAKENING_CONTEXT
		if is_instance_valid(source_world):
			source_world.set_meta("major_context_authoritative", true)
			source_root.set_meta("major_context_authoritative", true)
	_binding_order.append(&"source_rollback_complete")
	_set_phase(Phase.FAILED)
	_finish_result(false, code, reason, operator.global_position if is_instance_valid(operator) else Vector2.ZERO)


func _finish_result(succeeded: bool, code: StringName, reason: String, operator_position: Vector2) -> void:
	var result := WorldTransitionResult.new()
	result.request_id = _active_request.request_id if _active_request != null else ""
	result.succeeded = succeeded
	result.source_context = AWAKENING_CONTEXT
	result.final_context = canonical_context(current_context)
	result.final_phase = get_phase_name()
	result.failure_code = code
	result.failure_reason = reason
	result.operator_position = operator_position
	result.binding_order = _binding_order.duplicate()
	last_result = result.to_dictionary()
	_transition_in_flight = false
	_active_request = null
	_source_state.clear()
	transition_finished.emit(last_result.duplicate(true))


func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	var phase_name := get_phase_name()
	if _active_request != null:
		phase_changed.emit(_active_request.request_id, phase_name)


func _reject(code: StringName) -> bool:
	last_rejection_code = code
	return false
