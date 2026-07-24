class_name RouteTraversalManager
extends Node

signal route_started(route_id: StringName, profile_id: StringName)
signal route_start_failed(route_id: StringName, reason: String)
signal route_transition_started(route_id: StringName, edge_id: StringName)
signal route_node_entered(route_id: StringName, node_id: StringName, instance: Node)
signal route_transition_failed(route_id: StringName, edge_id: StringName, reason: String)
signal route_ended(route_id: StringName)
signal route_phase_changed(phase: int)

enum TransitionPhase {
	IDLE,
	REQUESTED,
	VALIDATING,
	FREEZING_SOURCE,
	STAGING_TARGET,
	VALIDATING_TARGET,
	ACTIVATING_TARGET,
	DEACTIVATING_SOURCE,
	FINALIZING,
	COMPLETE,
	ROLLING_BACK,
	FAILED,
}

const WORLD_ORIGIN := &"@world_origin"
const ROUTE_REGISTRY_SCRIPT := preload("res://game/world/routes/route_registry.gd")
const ROUTE_DEFINITION_SCRIPT := preload("res://game/world/routes/route_definition.gd")
const ROUTE_SESSION_SCRIPT := preload("res://game/world/routes/route_session.gd")
const TRANSITION_CONTEXT_SCRIPT := preload("res://game/world/routes/route_transition_context.gd")
const STATE_STORE_SCRIPT := preload("res://game/world/routes/route_state_store.gd")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
const ROUTE_FADE_OUT_DURATION := 0.22
const ROUTE_FADE_IN_DURATION := 0.28

@export_file("*.json") var route_registry_index_path := "res://content/routes/routes.json"

var _route_registry: RefCounted
var _active_route: RefCounted
var _active_session: RefCounted
var _state_store: RefCounted = STATE_STORE_SCRIPT.new()
var _level_loader: Node
var _phase := TransitionPhase.IDLE
var _visual_transition_active := false
var _transition_veil_layer: CanvasLayer
var _transition_veil: ColorRect


func _ready() -> void:
	add_to_group("route_traversal_manager")
	_level_loader = _find_or_create_level_loader()


func _exit_tree() -> void:
	if (
		_transition_veil_layer != null
		and is_instance_valid(_transition_veil_layer)
	):
		_transition_veil_layer.queue_free()
	_transition_veil_layer = null
	_transition_veil = null


func ensure_registry() -> bool:
	if _route_registry != null:
		return true
	_route_registry = ROUTE_REGISTRY_SCRIPT.new()
	var level_registry: RefCounted = _level_loader.call("get_registry") as RefCounted if _level_loader != null else null
	if _route_registry.call("load_index", route_registry_index_path, level_registry):
		return true
	push_error("[RouteTraversalManager] registry load failed: %s" % "; ".join(_route_registry.call("get_errors")))
	return false


func start_route(route_id: StringName, actor: Node, context: Dictionary = {}) -> bool:
	if not ensure_registry():
		route_start_failed.emit(route_id, "route registry is unavailable")
		return false
	var route := _route_registry.call("get_route", route_id) as RefCounted
	if route == null:
		route_start_failed.emit(route_id, "route is not registered")
		return false
	return _start_route_definition(route, actor, context)


func start_single_level_route(level_id: StringName, actor: Node, context: Dictionary = {}) -> bool:
	if _level_loader == null:
		_level_loader = _find_or_create_level_loader()
	var definition: RefCounted = _level_loader.call("get_definition", level_id) as RefCounted
	if definition == null:
		route_start_failed.emit(StringName("single_%s" % level_id), "level is not registered")
		return false
	var spawn_id: StringName = &""
	if not definition.spawns.is_empty():
		spawn_id = definition.spawns[0]
	if definition.ingress != null and not definition.ingress.target_spawn_id.is_empty():
		spawn_id = definition.ingress.target_spawn_id
	if spawn_id.is_empty():
		route_start_failed.emit(StringName("single_%s" % level_id), "level has no declared entry spawn")
		return false
	var route: RefCounted = ROUTE_DEFINITION_SCRIPT.new()
	route.call("configure_from_dictionary", {
		"route_id": "single_%s" % level_id,
		"display_name": "Single Level %s" % level_id,
		"world_context": String(definition.world_context),
		"default_profile": "single",
		"nodes": [{"node_id": "single", "level_id": String(level_id)}],
		"edges": [
			{"edge_id": "enter_single", "from_node_id": String(WORLD_ORIGIN), "exit_id": "enter", "to_node_id": "single", "target_spawn_id": String(spawn_id), "direction": "forward", "transition_style": "fade"},
			{"edge_id": "return_single", "from_node_id": "single", "exit_id": "return_world", "to_node_id": String(WORLD_ORIGIN), "target_spawn_id": "", "direction": "exfil", "transition_style": "fade"},
		],
		"profiles": [{"profile_id": "single", "entry_edge_id": "enter_single", "enabled_edge_ids": ["enter_single", "return_single"]}],
	})
	return _start_route_definition(route, actor, context)


func request_exit(exit_id: StringName, actor: Node) -> bool:
	if not has_active_route() or _phase != TransitionPhase.IDLE:
		return false
	if actor != _active_session.actor:
		return _transition_failure(&"", "exit actor is not the active route actor")
	var matches: Array[RefCounted] = _active_route.call(
		"resolve_exit", _active_session.profile_id, _active_session.current_node_id, exit_id
	)
	if matches.size() != 1:
		return _transition_failure(&"", "exit %s resolves to %d enabled edges" % [exit_id, matches.size()])
	return transition_via_edge(matches[0].edge_id, actor)


func transition_via_edge(edge_id: StringName, actor: Node) -> bool:
	if (
		not has_active_route()
		or _phase != TransitionPhase.IDLE
		or _visual_transition_active
	):
		return false
	_set_phase(TransitionPhase.REQUESTED)
	route_transition_started.emit(_active_session.route_id, edge_id)
	_set_phase(TransitionPhase.VALIDATING)
	var edge := _active_route.call("get_edge", edge_id) as RefCounted
	var profile := _active_route.call("get_profile", _active_session.profile_id) as RefCounted
	if edge == null or profile == null or not profile.enabled_edge_ids.has(edge_id):
		return _transition_failure(edge_id, "edge is not enabled in the active profile")
	var expected_source: StringName = WORLD_ORIGIN if _active_session.current_node_id.is_empty() else _active_session.current_node_id
	if edge.from_node_id != expected_source:
		return _transition_failure(edge_id, "edge source does not match current node")
	if actor == null or actor != _active_session.actor:
		return _transition_failure(edge_id, "actor does not match active route actor")
	if _should_use_visual_fade(edge):
		_run_faded_transition(edge, actor)
		return true
	if edge.to_node_id == WORLD_ORIGIN:
		return _transition_to_world(edge, actor)
	return _transition_to_node(edge, actor)


func has_active_route() -> bool:
	return _active_session != null and _active_session.started


func get_active_session() -> RefCounted:
	return _active_session


func get_current_node_id() -> StringName:
	return _active_session.current_node_id if has_active_route() else &""


func get_current_route_id() -> StringName:
	return _active_session.route_id if has_active_route() else &""


func get_current_profile_id() -> StringName:
	return _active_session.profile_id if has_active_route() else &""


func get_phase() -> int:
	return _phase


func get_route_state_store() -> RefCounted:
	return _state_store


func get_route_entry_presentation_profile(route_id: StringName, profile_id: StringName = &"") -> StringName:
	if not ensure_registry():
		return &"gameplay"
	var route := _route_registry.call("get_route", route_id) as RefCounted
	if route == null:
		return &"gameplay"
	var resolved_profile: StringName = profile_id if not profile_id.is_empty() else route.default_profile
	var profile := route.call("get_profile", resolved_profile) as RefCounted
	if profile == null:
		return &"gameplay"
	var edge := route.call("get_edge", profile.entry_edge_id) as RefCounted
	var node := route.call("get_node_definition", edge.to_node_id) as RefCounted if edge != null else null
	var definition := _level_loader.call("get_definition", node.level_id) as RefCounted if node != null else null
	return definition.call("get_presentation_profile") as StringName if definition != null else &"gameplay"


func _start_route_definition(route: RefCounted, actor: Node, context: Dictionary) -> bool:
	if has_active_route() or _phase != TransitionPhase.IDLE:
		route_start_failed.emit(route.route_id, "another route is active")
		return false
	if actor == null or not is_instance_valid(actor):
		route_start_failed.emit(route.route_id, "actor is unavailable")
		return false
	var profile_id := StringName(str(context.get("route_profile", context.get("profile_id", route.default_profile))))
	if profile_id.is_empty():
		profile_id = route.default_profile
	var profile := route.call("get_profile", profile_id) as RefCounted
	if profile == null:
		route_start_failed.emit(route.route_id, "profile does not exist: %s" % profile_id)
		return false
	var session: RefCounted = ROUTE_SESSION_SCRIPT.new()
	session.route_id = route.route_id
	session.profile_id = profile_id
	session.actor = actor
	session.parent = context.get("parent", get_parent()) as Node
	session.origin_ingress = context.get("origin_ingress") as Node
	session.origin_snapshot = (context.get("origin_snapshot", context.get("source_state", {})) as Dictionary).duplicate(false)
	session.route_state = (context.get("route_state", {}) as Dictionary).duplicate(true)
	session.started = true
	_active_route = route
	_active_session = session
	route_started.emit(route.route_id, profile_id)
	if not transition_via_edge(profile.entry_edge_id, actor):
		_active_session = null
		_active_route = null
		route_start_failed.emit(route.route_id, "entry transition failed")
		return false
	return true


func _transition_to_node(
	edge: RefCounted,
	actor: Node,
	prelocked_actor_mode: int = -1
) -> bool:
	var context: RefCounted = TRANSITION_CONTEXT_SCRIPT.new()
	context.route_id = _active_session.route_id
	context.profile_id = _active_session.profile_id
	context.edge_id = edge.edge_id
	context.source_node_id = _active_session.current_node_id
	context.target_node_id = edge.to_node_id
	context.direction = edge.direction
	context.actor_position = (actor as Node2D).global_position if actor is Node2D else Vector2.ZERO
	context.actor_process_mode = (
		actor.process_mode
		if prelocked_actor_mode < 0
		else prelocked_actor_mode
	)
	var source: Node = _active_session.current_instance
	var source_level_id: StringName = _active_session.current_level_id
	var source_loader_context: Dictionary = _level_loader.call("get_active_level_context") if source != null else {}
	if source != null:
		context.source_activation_state = _level_loader.call("capture_instance_activation_state", source)
		context.source_state = _capture_node_state(context.source_node_id, source)
	_set_phase(TransitionPhase.FREEZING_SOURCE)
	if prelocked_actor_mode < 0:
		_lock_actor(actor)
	if source != null and source.has_method("prepare_route_deactivation"):
		source.call("prepare_route_deactivation", context.call("to_dictionary"))
	_disconnect_exits(source)
	var target_node := _active_route.call("get_node_definition", edge.to_node_id) as RefCounted
	if target_node == null:
		return _rollback(context, null, false, source_level_id, source_loader_context, "target node is unavailable")
	var target: Node = _active_session.cached_instances.get(edge.to_node_id) as Node
	var reused := target != null and is_instance_valid(target)
	var stage: Dictionary
	_set_phase(TransitionPhase.STAGING_TARGET)
	var target_runtime_context := {
		"parent": _active_session.parent,
		"origin_ingress": _active_session.origin_ingress,
		"source_state": _active_session.origin_snapshot,
		"target_spawn_id": edge.target_spawn_id,
		"route_id": _active_session.route_id,
		"route_node_id": edge.to_node_id,
		"route_profile": _active_session.profile_id,
		"compatibility_connection": false,
	}
	if reused:
		stage = {
			"succeeded": true,
			"level_id": target_node.level_id,
			"definition": _level_loader.call("get_definition", target_node.level_id),
			"instance": target,
			"context": target_runtime_context,
		}
	else:
		stage = _level_loader.call("stage_level", target_node.level_id, _active_session.parent, target_runtime_context)
	if not bool(stage.get("succeeded", false)):
		return _rollback(context, stage.get("instance") as Node, false, source_level_id, source_loader_context, str(stage.get("reason", "target staging failed")))
	context.target_stage = stage
	target = stage.get("instance") as Node
	_set_phase(TransitionPhase.VALIDATING_TARGET)
	if target == null or not is_instance_valid(target):
		return _rollback(context, target, not reused, source_level_id, source_loader_context, "target instance is unavailable")
	_set_phase(TransitionPhase.ACTIVATING_TARGET)
	_clear_camera_presentation_for_handoff()
	var commit: Dictionary
	if reused:
		commit = _level_loader.call("activate_existing_level", target_node.level_id, target, actor, edge.target_spawn_id, target_runtime_context, source)
	else:
		commit = _level_loader.call("commit_staged_level", stage, actor, edge.target_spawn_id, source)
	if not bool(commit.get("succeeded", false)):
		return _rollback(context, target, not reused, source_level_id, source_loader_context, str(commit.get("reason", "target activation failed")))
	var state_result := _restore_node_state(edge.to_node_id, target, target_node.level_id)
	if not bool(state_result.get("succeeded", false)):
		return _rollback(context, target, not reused, source_level_id, source_loader_context, str(state_result.get("reason", "state restoration failed")))
	if target.has_method("complete_route_activation"):
		var completion: Variant = target.call("complete_route_activation", context.call("to_dictionary"))
		if completion is bool and not bool(completion):
			return _rollback(context, target, not reused, source_level_id, source_loader_context, "target completion hook rejected activation")
	if target.has_method("refresh_route_camera") and not bool(target.call("refresh_route_camera", actor)):
		return _rollback(context, target, not reused, source_level_id, source_loader_context, "target camera binding failed")
	var bind_result := _bind_exits(target, edge.to_node_id)
	if not bool(bind_result.get("succeeded", false)):
		return _rollback(context, target, not reused, source_level_id, source_loader_context, str(bind_result.get("reason", "exit binding failed")))
	_set_phase(TransitionPhase.DEACTIVATING_SOURCE)
	_apply_source_policy(context.source_node_id, source_level_id, source, edge.direction)
	_active_session.cached_instances.erase(edge.to_node_id)
	_set_phase(TransitionPhase.FINALIZING)
	_active_session.current_node_id = edge.to_node_id
	_active_session.current_level_id = target_node.level_id
	_active_session.current_instance = target
	_active_session.last_edge_id = edge.edge_id
	_active_session.history.append(edge.edge_id)
	_unlock_actor(actor, context.actor_process_mode)
	_set_phase(TransitionPhase.COMPLETE)
	route_node_entered.emit(_active_session.route_id, edge.to_node_id, target)
	_observe(&"route_node_entered", {"route_id": String(_active_session.route_id), "profile_id": String(_active_session.profile_id), "node_id": String(edge.to_node_id), "edge_id": String(edge.edge_id)})
	_set_phase(TransitionPhase.IDLE)
	return true


func _transition_to_world(
	edge: RefCounted,
	actor: Node,
	prelocked_actor_mode: int = -1
) -> bool:
	var source: Node = _active_session.current_instance
	var ingress: Node = _active_session.origin_ingress
	if source == null or ingress == null or not is_instance_valid(ingress) or _active_session.origin_snapshot.is_empty():
		return _transition_failure(edge.edge_id, "world origin ingress or snapshot is unavailable")
	var actor_position := (actor as Node2D).global_position if actor is Node2D else Vector2.ZERO
	var actor_mode := (
		actor.process_mode
		if prelocked_actor_mode < 0
		else prelocked_actor_mode
	)
	var source_activation: Dictionary = _level_loader.call("capture_instance_activation_state", source)
	_capture_node_state(_active_session.current_node_id, source)
	_set_phase(TransitionPhase.FREEZING_SOURCE)
	if prelocked_actor_mode < 0:
		_lock_actor(actor)
	if source.has_method("prepare_route_deactivation"):
		source.call("prepare_route_deactivation", {"edge_id": edge.edge_id, "direction": edge.direction})
	_disconnect_exits(source)
	_level_loader.call("deactivate_instance_immediately", source)
	_clear_camera_presentation_for_handoff()
	var result: Variant = ingress.call("restore_world_origin", actor, _active_session.origin_snapshot)
	var restore_result := result as Dictionary if result is Dictionary else {"succeeded": false, "reason": "origin restore returned no result"}
	if not bool(restore_result.get("succeeded", false)):
		_set_phase(TransitionPhase.ROLLING_BACK)
		_level_loader.call("reactivate_instance", source, source_activation)
		if actor is Node2D:
			(actor as Node2D).global_position = actor_position
		if source.has_method("refresh_route_camera"):
			source.call("refresh_route_camera", actor)
		_bind_exits(source, _active_session.current_node_id)
		_unlock_actor(actor, actor_mode)
		return _transition_failure(edge.edge_id, str(restore_result.get("reason", "origin restoration failed")))
	var ended_route_id: StringName = _active_session.route_id
	ingress.call("reset_after_level_return")
	_level_loader.call("clear_active_level", source)
	_level_loader.call("release_level_instance", source, _level_loader.call("get_definition", _active_session.current_level_id).call("get_lifecycle"), true)
	for cached: Variant in _active_session.cached_instances.values():
		if cached is Node and is_instance_valid(cached):
			var cached_node_id := _find_cached_node_id(cached as Node)
			var cached_definition := _definition_for_node(cached_node_id)
			var lifecycle: Dictionary = cached_definition.call("get_lifecycle") if cached_definition != null else {}
			_level_loader.call("release_level_instance", cached, lifecycle, true)
	_active_session.cached_instances.clear()
	_active_session.node_state.clear()
	_unlock_actor(actor, actor_mode)
	_active_session = null
	_active_route = null
	_set_phase(TransitionPhase.COMPLETE)
	route_ended.emit(ended_route_id)
	_observe(&"route_ended", {"route_id": String(ended_route_id), "edge_id": String(edge.edge_id)})
	_set_phase(TransitionPhase.IDLE)
	return true


func _capture_node_state(node_id: StringName, instance: Node) -> Dictionary:
	if instance == null or node_id.is_empty():
		return {}
	var definition := _definition_for_node(node_id)
	if definition == null:
		return {}
	var policy := StringName(str(definition.call("get_lifecycle").get("state_policy", "reset_on_entry")))
	if policy == &"reset_on_entry":
		_active_session.node_state.erase(node_id)
		return {}
	var state: Dictionary = instance.call("capture_route_state") if instance.has_method("capture_route_state") else {}
	if policy == &"persistent":
		_state_store.call("set_node_state", _active_session.route_id, node_id, state)
	else:
		_active_session.node_state[node_id] = state.duplicate(true)
	return state


func _restore_node_state(node_id: StringName, instance: Node, _level_id: StringName) -> Dictionary:
	var definition := _definition_for_node(node_id)
	if definition == null:
		return {"succeeded": false, "reason": "target level definition is unavailable"}
	var policy := StringName(str(definition.call("get_lifecycle").get("state_policy", "reset_on_entry")))
	if policy == &"reset_on_entry":
		return {"succeeded": true}
	var state: Dictionary
	if policy == &"persistent":
		state = _state_store.call("get_node_state", _active_session.route_id, node_id)
	else:
		state = (_active_session.node_state.get(node_id, {}) as Dictionary).duplicate(true)
	if state.is_empty() or not instance.has_method("restore_route_state"):
		return {"succeeded": true}
	if instance.has_method("can_restore_route_state") and not bool(instance.call("can_restore_route_state", state)):
		return {"succeeded": false, "reason": "target rejected route state preflight"}
	var result: Variant = instance.call("restore_route_state", state)
	if result is bool and not bool(result):
		return {"succeeded": false, "reason": "target rejected route state"}
	return {"succeeded": true}


func _apply_source_policy(node_id: StringName, level_id: StringName, instance: Node, direction: StringName) -> void:
	if instance == null or node_id.is_empty():
		return
	var definition: RefCounted = _level_loader.call("get_definition", level_id) as RefCounted
	var lifecycle: Dictionary = definition.call("get_lifecycle") if definition != null else {}
	var cache_policy := StringName(str(lifecycle.get("cache_policy", "destroy_on_exit")))
	var retain := cache_policy == &"keep_during_route" or (
		cache_policy == &"destroy_on_forward_exit" and direction in [&"back", &"lateral"]
	)
	if retain:
		_level_loader.call("deactivate_instance_immediately", instance)
		_active_session.cached_instances[node_id] = instance
	else:
		_level_loader.call("release_level_instance", instance, lifecycle, false)


func _rollback(
	context: RefCounted,
	target: Node,
	target_is_new: bool,
	source_level_id: StringName,
	source_loader_context: Dictionary,
	reason: String
) -> bool:
	_set_phase(TransitionPhase.ROLLING_BACK)
	var source: Node = _active_session.current_instance
	var target_owns_loader_authority: bool = (
		target != null
		and is_instance_valid(target)
		and _level_loader.call("get_active_level_instance") == target
	)
	if target != null and is_instance_valid(target):
		_disconnect_exits(target)
		_level_loader.call("deactivate_instance_immediately", target)
	if target_owns_loader_authority:
		if not bool(_level_loader.call("clear_active_level", target)):
			push_error("[RouteTraversalManager] rollback could not clear target loader authority")
	if target != null and is_instance_valid(target) and target_is_new:
		target.queue_free()
	if source != null and is_instance_valid(source):
		_level_loader.call("reactivate_instance", source, context.source_activation_state)
		_level_loader.call("restore_active_level_identity", source_level_id, source, source_loader_context)
		if source.has_method("refresh_route_camera"):
			source.call("refresh_route_camera", _active_session.actor)
		var bind_result := _bind_exits(source, _active_session.current_node_id)
		if not bool(bind_result.get("succeeded", false)):
			push_error(
				"[RouteTraversalManager] rollback source exit rebind failed: %s"
				% bind_result.get("reason", "unknown failure")
			)
	if _active_session.actor is Node2D:
		(_active_session.actor as Node2D).global_position = context.actor_position
	_unlock_actor(_active_session.actor, context.actor_process_mode)
	return _transition_failure(context.edge_id, reason)


func _bind_exits(instance: Node, node_id: StringName = &"") -> Dictionary:
	if instance == null:
		return {"succeeded": false, "reason": "active route node is unavailable"}
	var seen: Dictionary = {}
	for exit_node in _collect_route_exits(instance):
		var exit_id: StringName = exit_node.exit_id
		if exit_id.is_empty():
			return {"succeeded": false, "reason": "route exit has an empty exit_id"}
		if seen.has(exit_id):
			return {"succeeded": false, "reason": "duplicate route exit_id in active scene: %s" % exit_id}
		seen[exit_id] = true
		var resolved_node_id := node_id if not node_id.is_empty() else _node_id_for_instance(instance)
		var matches: Array[RefCounted] = _active_route.call("resolve_exit", _active_session.profile_id, resolved_node_id, exit_id)
		var enabled := matches.size() == 1
		exit_node.set_route_enabled(enabled)
		if not enabled:
			push_error("[RouteTraversalManager] disabled exit %s: active profile resolves %d legal edges" % [exit_id, matches.size()])
		if enabled and not exit_node.transition_requested.is_connected(_on_exit_requested):
			exit_node.transition_requested.connect(_on_exit_requested)
	return {"succeeded": true}


func _disconnect_exits(instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	for exit_node in _collect_route_exits(instance):
		if exit_node.transition_requested.is_connected(_on_exit_requested):
			exit_node.transition_requested.disconnect(_on_exit_requested)
		exit_node.set_route_enabled(false)


func _collect_route_exits(root: Node) -> Array[LevelExit2D]:
	var result: Array[LevelExit2D] = []
	_collect_route_exits_recursive(root, result)
	return result


func _collect_route_exits_recursive(node: Node, result: Array[LevelExit2D]) -> void:
	if node is LevelExit2D:
		result.append(node as LevelExit2D)
	for child in node.get_children():
		_collect_route_exits_recursive(child, result)


func _on_exit_requested(exit_id: StringName, actor: Node) -> void:
	# Physics overlap callbacks may not mutate monitoring or process authority.
	# Resolve the route transaction on the next idle turn.
	call_deferred("request_exit", exit_id, actor)


func _should_use_visual_fade(edge: RefCounted) -> bool:
	return (
		edge != null
		and edge.transition_style == &"fade"
		and DisplayServer.get_name() != "headless"
	)


func _run_faded_transition(
	edge: RefCounted,
	actor: Node
) -> void:
	_visual_transition_active = true
	var actor_mode := actor.process_mode
	_lock_actor(actor)
	await _fade_transition_veil(
		1.0,
		ROUTE_FADE_OUT_DURATION
	)

	var succeeded := false
	if actor != null and is_instance_valid(actor):
		if edge.to_node_id == WORLD_ORIGIN:
			succeeded = _transition_to_world(
				edge,
				actor,
				actor_mode
			)
		else:
			succeeded = _transition_to_node(
				edge,
				actor,
				actor_mode
			)
	else:
		_transition_failure(
			edge.edge_id,
			"actor became unavailable during route fade"
		)

	if succeeded and actor != null and is_instance_valid(actor):
		_lock_actor(actor)
	await _fade_transition_veil(
		0.0,
		ROUTE_FADE_IN_DURATION
	)
	if succeeded:
		_unlock_actor(actor, actor_mode)
	_visual_transition_active = false


func _fade_transition_veil(
	target_alpha: float,
	duration: float
) -> void:
	_ensure_transition_veil()
	if _transition_veil == null:
		return

	_transition_veil.visible = true
	_transition_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween() \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		_transition_veil,
		"modulate:a",
		clampf(target_alpha, 0.0, 1.0),
		maxf(duration, 0.001)
	)
	await tween.finished
	if target_alpha <= 0.0:
		_transition_veil.visible = false
		_transition_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ensure_transition_veil() -> void:
	if (
		_transition_veil != null
		and is_instance_valid(_transition_veil)
	):
		return

	_transition_veil_layer = CanvasLayer.new()
	_transition_veil_layer.name = "RouteTransitionVeilLayer"
	_transition_veil_layer.layer = 10000
	_transition_veil_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_transition_veil_layer)

	_transition_veil = ColorRect.new()
	_transition_veil.name = "RouteTransitionVeil"
	_transition_veil.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	_transition_veil.color = Color.BLACK
	_transition_veil.modulate.a = 0.0
	_transition_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_veil.visible = false
	_transition_veil_layer.add_child(_transition_veil)


func _clear_camera_presentation_for_handoff() -> void:
	var camera := get_node_or_null(
		"/root/GameRoot/World/Camera2D"
	)
	if (
		camera != null
		and camera.has_method("clear_presentation_framing")
	):
		camera.call(
			"clear_presentation_framing",
			true
		)


func _lock_actor(actor: Node) -> void:
	if actor is CharacterBody2D:
		(actor as CharacterBody2D).velocity = Vector2.ZERO
	actor.process_mode = Node.PROCESS_MODE_DISABLED


func _unlock_actor(actor: Node, previous_mode: int) -> void:
	if actor != null and is_instance_valid(actor):
		actor.process_mode = previous_mode


func _transition_failure(edge_id: StringName, reason: String) -> bool:
	var route_id := get_current_route_id()
	_set_phase(TransitionPhase.FAILED)
	push_error("[RouteTraversalManager] %s/%s failed: %s" % [route_id, edge_id, reason])
	route_transition_failed.emit(route_id, edge_id, reason)
	_observe(&"route_transition_failed", {"route_id": String(route_id), "edge_id": String(edge_id), "reason": reason})
	_set_phase(TransitionPhase.IDLE)
	return false


func _set_phase(value: int) -> void:
	_phase = value
	route_phase_changed.emit(value)


func _definition_for_node(node_id: StringName) -> RefCounted:
	if _active_route == null:
		return null
	var node := _active_route.call("get_node_definition", node_id) as RefCounted
	return _level_loader.call("get_definition", node.level_id) as RefCounted if node != null else null


func _node_id_for_instance(instance: Node) -> StringName:
	if _active_session.current_instance == instance:
		return _active_session.current_node_id
	for node_id: Variant in _active_session.cached_instances.keys():
		if _active_session.cached_instances[node_id] == instance:
			return node_id as StringName
	var context: Dictionary = instance.get_meta("route_runtime_context", {}) as Dictionary
	return StringName(str(context.get("route_node_id", "")))


func _find_cached_node_id(instance: Node) -> StringName:
	for node_id: Variant in _active_session.cached_instances.keys():
		if _active_session.cached_instances[node_id] == instance:
			return node_id as StringName
	return &""


func _find_or_create_level_loader() -> Node:
	var sibling := get_parent().get_node_or_null("LevelLoader") if get_parent() != null else null
	if sibling != null:
		return sibling
	var loader := LEVEL_LOADER_SCRIPT.new()
	loader.name = "LevelLoader"
	if get_parent() != null:
		get_parent().add_child(loader)
	return loader


func _observe(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
