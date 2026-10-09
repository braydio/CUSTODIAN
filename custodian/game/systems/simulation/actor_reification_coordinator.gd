class_name ActorReificationCoordinator
extends Node

const GRUNT_SCENE: PackedScene = preload("res://game/actors/enemies/enemy_grunt.tscn")

var kernel: SimulationKernel
var anchors: Dictionary = {}
var _requests: Array[Dictionary] = []
var _results: Dictionary = {}
var _next_request_id := 1


func bind(simulation_kernel: SimulationKernel, location_anchors: Dictionary) -> bool:
	if simulation_kernel == null or kernel != null:
		return false
	kernel = simulation_kernel
	anchors = location_anchors.duplicate()
	kernel.fixed_step_boundary.connect(_on_fixed_step_boundary)
	return true


func request_abstract(domain_id: String, group_id: String, actor: Enemy, source_location_id: String) -> int:
	return _queue_request({"kind": "abstract", "domain_id": domain_id, "group_id": group_id, "actor": actor, "location_id": source_location_id})


func request_physical(domain_id: String, group_id: String, target_location_id: String) -> int:
	return _queue_request({"kind": "physical", "domain_id": domain_id, "group_id": group_id, "location_id": target_location_id})


func claim_physical_actor(domain_id: String, group_id: String, actor: Enemy, location_id: String) -> bool:
	if kernel == null or actor == null or not is_instance_valid(actor) or actor.is_queued_for_deletion():
		return false
	if String(actor.scene_file_path) != GRUNT_SCENE.resource_path or not actor.is_inside_tree():
		return false
	if actor.dead or actor.life_state != Enemy.LifeState.ALIVE or actor.is_carrying_stolen_resources():
		return false
	if String(actor.get_meta("domain_id", "")) != domain_id \
		or String(actor.get_meta("group_id", "")) != group_id \
		or String(actor.get_meta("location_id", "")) != location_id:
		return false
	var projection := _capture(actor, domain_id, group_id, location_id)
	var actor_id := String(projection.actor_id)
	if _find_actors(domain_id, actor_id).size() != 1 or actor_id.is_empty():
		return false
	return kernel.state.abstract_activity.set_actor_representation(domain_id, group_id, actor_id, "physical", projection, kernel.state.fixed_tick)


func take_result(request_id: int) -> Dictionary:
	var result: Dictionary = _results.get(request_id, {})
	_results.erase(request_id)
	return result.duplicate(true)


func _queue_request(request: Dictionary) -> int:
	if kernel == null:
		return -1
	var request_id := _next_request_id
	_next_request_id += 1
	request.request_id = request_id
	_requests.append(request)
	return request_id


func _on_fixed_step_boundary(fixed_tick: int) -> void:
	var batch := _requests
	_requests = []
	for request in batch:
		var result := _to_abstract(request, fixed_tick) if request.kind == "abstract" else _to_physical(request, fixed_tick)
		_results[int(request.request_id)] = result


func _to_abstract(request: Dictionary, fixed_tick: int) -> Dictionary:
	var domain_id := String(request.domain_id)
	var group_id := String(request.group_id)
	var actor: Enemy = request.actor
	var group := kernel.state.abstract_activity.get_group(domain_id, group_id)
	if group.is_empty() or String(group.get("representation", "abstract")) != "physical":
		return {"ok": false, "reason": "group is not physical-owned"}
	if actor == null or not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.is_inside_tree() or String(actor.scene_file_path) != GRUNT_SCENE.resource_path:
		return {"ok": false, "reason": "actor is not a live registered scene instance"}
	if String(actor.get_meta("actor_id", "")) != String(group.get("actor_id", actor.get_meta("actor_id", ""))) \
		or String(actor.get_meta("group_id", group_id)) != group_id:
		return {"ok": false, "reason": "actor identity does not match group"}
	if String(actor.get_meta("location_id", request.location_id)) != String(request.location_id):
		return {"ok": false, "reason": "actor is not at the declared source location"}
	if actor.dead or actor.life_state != Enemy.LifeState.ALIVE or actor.is_carrying_stolen_resources():
		return {"ok": false, "reason": "dead or loot-bearing actors cannot transfer"}
	var debug: Dictionary = actor.get_debug_snapshot()
	if not String((debug.get("attack", {}) as Dictionary).get("id", "")).is_empty() \
		or bool(actor.get("_path_request_pending")) \
		or bool(actor.get_meta("pending_damage_interaction", false)) \
		or bool(actor.get_meta("pending_projectile", false)):
		return {"ok": false, "reason": "actor has pending combat or navigation work"}
	var actor_id := String(actor.get_meta("actor_id", ""))
	if bool(actor.get_meta("reification_pending", false)) or bool(actor.get_meta("spawn_pending", false)):
		return {"ok": false, "reason": "actor has an unresolved spawn request"}
	var matching_actors := _find_actors(domain_id, actor_id)
	if actor_id.is_empty() or matching_actors.size() != 1 or matching_actors[0] != actor:
		return {"ok": false, "reason": "stable actor identity is missing or duplicated"}
	var projection := _capture(actor, domain_id, group_id, String(request.location_id))
	var parent := actor.get_parent()
	if parent == null:
		return {"ok": false, "reason": "actor parent is unavailable"}
	var index := actor.get_index()
	var global_position := actor.global_position
	var process_mode := actor.process_mode
	var physics_processing := actor.is_physics_processing()
	var processing := actor.is_processing()
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.set_physics_process(false)
	actor.set_process(false)
	parent.remove_child(actor)
	if actor.get_parent() != null or actor.is_inside_tree():
		parent.add_child(actor)
		actor.global_position = global_position
		actor.process_mode = process_mode
		actor.set_physics_process(physics_processing)
		actor.set_process(processing)
		return {"ok": false, "reason": "actor could not be removed from the physical tree"}
	if not kernel.state.abstract_activity.set_actor_representation(domain_id, group_id, actor_id, "abstract", projection, fixed_tick):
		parent.add_child(actor)
		parent.move_child(actor, mini(index, parent.get_child_count() - 1))
		actor.global_position = global_position
		actor.process_mode = process_mode
		actor.set_physics_process(physics_processing)
		actor.set_process(processing)
		return {"ok": false, "reason": kernel.state.abstract_activity.last_error}
	actor.queue_free()
	return {"ok": true, "actor_id": actor_id, "fixed_tick": fixed_tick}


func _to_physical(request: Dictionary, fixed_tick: int) -> Dictionary:
	var domain_id := String(request.domain_id)
	var group_id := String(request.group_id)
	var group := kernel.state.abstract_activity.get_group(domain_id, group_id)
	if group.is_empty() or String(group.get("representation", "abstract")) != "abstract":
		return {"ok": false, "reason": "group is not abstract-owned"}
	var location_id := String(request.location_id)
	var anchor: Variant = anchors.get(location_id)
	if anchor == null or not is_instance_valid(anchor) or not anchor is Node2D or not anchor.is_inside_tree():
		return {"ok": false, "reason": "target location has no live safe anchor"}
	if not _find_actors(domain_id, String(group.get("actor_id", ""))).is_empty():
		return {"ok": false, "reason": "actor identity already has a physical instance"}
	var projection: Dictionary = group.get("actor_projection", {})
	if projection.is_empty() or String(projection.get("location_id", "")) != location_id:
		return {"ok": false, "reason": "actor projection does not match target location"}
	var actor := GRUNT_SCENE.instantiate() as Enemy
	if actor == null:
		return {"ok": false, "reason": "Grunt scene failed to instantiate"}
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.set_physics_process(false)
	actor.set_process(false)
	_apply_projection(actor, projection)
	add_child(actor)
	actor.global_position = anchor.global_position
	if not actor.is_inside_tree() or actor.dead or actor.health <= 0.0:
		actor.queue_free()
		return {"ok": false, "reason": "staged Grunt failed validation"}
	if not kernel.state.abstract_activity.set_actor_representation(domain_id, group_id, String(group.actor_id), "physical", projection, fixed_tick):
		actor.queue_free()
		return {"ok": false, "reason": kernel.state.abstract_activity.last_error}
	actor.process_mode = Node.PROCESS_MODE_INHERIT
	actor.set_physics_process(true)
	actor.set_process(true)
	return {"ok": true, "actor": actor, "actor_id": String(group.actor_id), "fixed_tick": fixed_tick}


func _capture(actor: Enemy, domain_id: String, group_id: String, location_id: String) -> Dictionary:
	return {
		"domain_id": domain_id,
		"group_id": group_id,
		"actor_id": String(actor.get_meta("actor_id", "")),
		"location_id": location_id,
		"health": actor.health,
		"max_health": actor.max_health,
		"condition": clampf(actor.health / maxf(1.0, actor.max_health), 0.0, 1.0),
		"attack_objective": actor.attack_objective,
		"behavior_profile_id": String(actor.behavior_profile_id),
		"position": [actor.global_position.x, actor.global_position.y],
	}


func _apply_projection(actor: Enemy, projection: Dictionary) -> void:
	actor.set_meta("actor_id", String(projection.actor_id))
	actor.set_meta("group_id", String(projection.group_id))
	actor.set_meta("domain_id", String(projection.domain_id))
	actor.set_meta("location_id", String(projection.location_id))
	actor.health = float(projection.health)
	actor.max_health = float(projection.max_health)
	actor.attack_objective = String(projection.attack_objective)
	actor.behavior_profile_id = StringName(String(projection.behavior_profile_id))
	actor.behavior_state_machine_enabled = true


func _find_actors(domain_id: String, actor_id: String) -> Array[Enemy]:
	var found: Array[Enemy] = []
	if actor_id.is_empty():
		return found
	for candidate in get_tree().get_nodes_in_group("enemy_behavior_agent"):
		if candidate is Enemy and String(candidate.get_meta("domain_id", "")) == domain_id \
			and String(candidate.get_meta("actor_id", "")) == actor_id:
			found.append(candidate)
	return found
