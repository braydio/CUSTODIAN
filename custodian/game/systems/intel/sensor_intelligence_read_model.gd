extends Node
class_name SensorIntelligenceReadModel

const ActivityClassifier := preload("res://game/systems/intel/sensor_activity_classifier.gd")

@export var collection_interval_sec := 0.20
@export var stale_contact_ttl_ticks := 180

var _contact_ids: Dictionary = {}
var _first_seen_ticks: Dictionary = {}
var _records_by_instance: Dictionary = {}
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
	var observed_instance_ids: Dictionary = {}
	for node in get_tree().get_nodes_in_group("enemy"):
		if not _is_observable_hostile(node):
			continue
		var enemy := node as Node2D
		var instance_id := enemy.get_instance_id()
		observed_instance_ids[instance_id] = true
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
		var sector_info := _nearest_sector_info(enemy.global_position)
		_records_by_instance[instance_id] = {
			"contact_id": _contact_ids[instance_id],
			"entity_instance_id": instance_id,
			"first_seen_tick": int(_first_seen_ticks[instance_id]),
			"last_seen_tick": tick,
			"observed": true,
			"stale": false,
			"world_position": enemy.global_position,
			"velocity": enemy.velocity if enemy is CharacterBody2D else Vector2.ZERO,
			"sector": sector_info.get("name", "UNCONFIRMED"),
			"sector_map_position": sector_info.get("position", enemy.global_position),
			"class_id": String(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name).to_lower().replace(" ", "_"),
			"class_label": String(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name).to_upper(),
			"health_pct": clampf(health / max_health, 0.0, 1.0),
			"behavior_state": state,
			"objective_type": objective_type,
			"carrying_loot": carrying_loot,
			"activity": ActivityClassifier.classify(state, objective_type, carrying_loot),
		}
	var expired_instance_ids: Array = []
	for instance_id in _records_by_instance.keys():
		if observed_instance_ids.has(instance_id):
			continue
		var record: Dictionary = _records_by_instance[instance_id]
		if tick - int(record.get("last_seen_tick", tick)) > stale_contact_ttl_ticks:
			expired_instance_ids.append(instance_id)
			continue
		record["observed"] = false
		record["stale"] = true
	for instance_id in expired_instance_ids:
		_records_by_instance.erase(instance_id)
		_contact_ids.erase(instance_id)
		_first_seen_ticks.erase(instance_id)
	var current: Array[Dictionary] = []
	for record: Dictionary in _records_by_instance.values():
		current.append(record.duplicate(true))
	current.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["contact_id"]) < String(b["contact_id"]))
	_contacts = current
	return get_truth_snapshot()


func get_truth_snapshot() -> Dictionary:
	var current_count := 0
	var stale_count := 0
	for contact: Dictionary in _contacts:
		if bool(contact.get("stale", false)):
			stale_count += 1
		else:
			current_count += 1
	return {"contacts": _contacts.duplicate(true), "tracked_count": _contacts.size(), "current_count": current_count, "stale_count": stale_count}


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


func _nearest_sector_info(position: Vector2) -> Dictionary:
	var best := {"name": "UNCONFIRMED", "position": position}
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("sector"):
		if not node is Node2D:
			continue
		var distance := position.distance_squared_to((node as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			best = {
				"name": String(node.get("sector_name") if "sector_name" in node else node.name).to_upper(),
				"position": (node as Node2D).global_position,
			}
	return best


func _resolve_simulation_tick() -> int:
	var runtime := get_node_or_null("/root/GameRoot/WorldSimulationRuntime")
	if runtime != null:
		if runtime.has_method("current_snapshot"):
			var snapshot = runtime.call("current_snapshot")
			if snapshot != null and "fixed_tick" in snapshot:
				return int(snapshot.fixed_tick)
		if "clock" in runtime and runtime.clock != null:
			return int(runtime.clock.fixed_tick)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and "tick" in game_state:
		return int(game_state.get("tick"))
	return Engine.get_physics_frames()
