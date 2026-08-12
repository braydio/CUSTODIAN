extends Node
class_name SensorIntelligenceReadModel

const ActivityClassifier := preload("res://game/systems/intel/sensor_activity_classifier.gd")

@export var collection_interval_sec := 0.20

var _contact_ids: Dictionary = {}
var _first_seen_ticks: Dictionary = {}
var _next_contact_number := 1
var _contacts: Array[Dictionary] = []
var _accumulator := 0.0


func _ready() -> void:
	add_to_group("sensor_intelligence_read_model")


func _physics_process(delta: float) -> void:
	_accumulator += delta
	if _accumulator < collection_interval_sec:
		return
	_accumulator = 0.0
	collect_now()


func collect_now(tick_override: int = -1) -> Dictionary:
	var tick := tick_override if tick_override >= 0 else _resolve_simulation_tick()
	var current: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("enemy"):
		if not _is_observable_hostile(node):
			continue
		var enemy := node as Node2D
		var instance_id := enemy.get_instance_id()
		if not _contact_ids.has(instance_id):
			_contact_ids[instance_id] = "C-%03d" % _next_contact_number
			_first_seen_ticks[instance_id] = tick
			_next_contact_number += 1
		var behavior: Dictionary = enemy.call("get_behavior_snapshot") if enemy.has_method("get_behavior_snapshot") else {}
		var blackboard: Dictionary = behavior.get("blackboard", {})
		var carrying_loot := bool(blackboard.get("carrying_loot", false))
		var objective_type := String(blackboard.get("objective_type", "none"))
		var state := String(behavior.get("state", "idle"))
		var max_health := maxf(1.0, float(enemy.get("max_health")) if "max_health" in enemy else 1.0)
		var health := float(enemy.get("health")) if "health" in enemy else max_health
		current.append({
			"contact_id": _contact_ids[instance_id],
			"entity_instance_id": instance_id,
			"first_seen_tick": int(_first_seen_ticks[instance_id]),
			"last_seen_tick": tick,
			"observed": true,
			"stale": false,
			"world_position": enemy.global_position,
			"velocity": enemy.velocity if enemy is CharacterBody2D else Vector2.ZERO,
			"sector": _nearest_sector(enemy.global_position),
			"class_id": String(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name).to_lower().replace(" ", "_"),
			"class_label": String(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name).to_upper(),
			"health_pct": clampf(health / max_health, 0.0, 1.0),
			"behavior_state": state,
			"objective_type": objective_type,
			"carrying_loot": carrying_loot,
			"activity": ActivityClassifier.classify(state, objective_type, carrying_loot),
		})
	current.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["contact_id"]) < String(b["contact_id"]))
	_contacts = current
	return get_truth_snapshot()


func get_truth_snapshot() -> Dictionary:
	return {"contacts": _contacts.duplicate(true), "current_count": _contacts.size()}


func _is_observable_hostile(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or not node is Node2D or node.is_queued_for_deletion():
		return false
	if node.is_in_group("ambient_critter"):
		return false
	if node.has_method("is_passive_enemy") and bool(node.call("is_passive_enemy")):
		return false
	if node.has_method("is_dead") and bool(node.call("is_dead")):
		return false
	return true


func _nearest_sector(position: Vector2) -> String:
	var best := "UNCONFIRMED"
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("sector"):
		if not node is Node2D:
			continue
		var distance := position.distance_squared_to((node as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			best = String(node.get("sector_name") if "sector_name" in node else node.name).to_upper()
	return best


func _resolve_simulation_tick() -> int:
	var runtime := get_node_or_null("/root/GameRoot/WorldSimulationRuntime")
	if runtime != null:
		for property_name in ["tick", "current_tick", "simulation_tick"]:
			if property_name in runtime:
				return int(runtime.get(property_name))
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and "tick" in game_state:
		return int(game_state.get("tick"))
	return Engine.get_physics_frames()
