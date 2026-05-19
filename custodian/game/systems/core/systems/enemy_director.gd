extends Node
class_name EnemyDirector

@export var wave_manager_path: NodePath = NodePath("/root/GameRoot/WaveManager")
@export var threat_model_path: NodePath
@export var enemy_factory_path: NodePath

@export var objective_weights := {
	"harass_player": 1.0,
	"destroy_power": 2.5,
	"destroy_turrets": 2.0,
	"breach_command": 3.0,
}
@export_range(0.1, 2.0, 0.05) var assault_budget_scale: float = 0.9
@export var minimum_assault_budget: int = 3

var wave_manager: Node
var threat_model: Node
var enemy_factory: Node
var lanes: Dictionary = {}

var _active_lane_name: String = ""
var _destroyed_at_wave_start: int = 0
var _last_wave_number: int = 0
var _last_threat: float = 0.0
var _last_budget: int = 0
var _last_lane: String = ""
var _last_objective: String = "destroy_power"
var _last_composition: Array[String] = []
var _last_attack_success: bool = false
var _has_last_attack_result: bool = false

func _ready() -> void:
	randomize()
	_resolve_dependencies()
	_rebuild_lanes()
	_connect_wave_events()

func _resolve_dependencies() -> void:
	wave_manager = get_node_or_null(wave_manager_path)

	if threat_model_path != NodePath():
		threat_model = get_node_or_null(threat_model_path)
	if threat_model == null:
		threat_model = preload("res://game/systems/core/systems/threat_model.gd").new()
		threat_model.name = "ThreatModel"
		add_child(threat_model)

	if enemy_factory_path != NodePath():
		enemy_factory = get_node_or_null(enemy_factory_path)
	if enemy_factory == null:
		enemy_factory = preload("res://game/systems/core/systems/enemy_factory.gd").new()
		enemy_factory.name = "EnemyFactory"
		add_child(enemy_factory)

	if wave_manager != null:
		enemy_factory.set("drone_scene", wave_manager.get("drone_scene"))
		enemy_factory.set("fast_drone_scene", wave_manager.get("fast_drone_scene"))
		enemy_factory.set("heavy_drone_scene", wave_manager.get("heavy_drone_scene"))
		enemy_factory.set("grunt_scene", wave_manager.get("grunt_scene"))

func _connect_wave_events() -> void:
	if wave_manager == null:
		push_warning("[EnemyDirector] WaveManager not found at %s" % String(wave_manager_path))
		return
	if wave_manager.has_signal("wave_started"):
		var start_cb := Callable(self, "_on_wave_started")
		if not wave_manager.is_connected("wave_started", start_cb):
			wave_manager.connect("wave_started", start_cb)
	if wave_manager.has_signal("wave_completed"):
		var complete_cb := Callable(self, "_on_wave_completed")
		if not wave_manager.is_connected("wave_completed", complete_cb):
			wave_manager.connect("wave_completed", complete_cb)

func _rebuild_lanes() -> void:
	for child in get_children():
		if child.get_script() == preload("res://game/systems/core/systems/assault_lane.gd"):
			child.queue_free()
	lanes.clear()
	for node in get_tree().get_nodes_in_group("enemy_spawn"):
		if not (node is SpawnNode):
			continue
		var spawn_node := node as SpawnNode
		if not spawn_node.active:
			continue
		var key := spawn_node.lane
		if not lanes.has(key):
			var lane = preload("res://game/systems/core/systems/assault_lane.gd").new()
			lane.lane_name = key
			lane.display_name = key.capitalize()
			lane.weight = 1.0
			lanes[key] = lane
			add_child(lane)
		lanes[key].register_spawn_node(spawn_node)

func _on_wave_started(wave_number: int) -> void:
	if wave_manager == null:
		return
	_rebuild_lanes()
	_destroyed_at_wave_start = _count_destroyed_structures()

	var threat: float = float(threat_model.calculate_threat(wave_number, _destroyed_at_wave_start))
	var budget: int = max(minimum_assault_budget, int(round(threat * assault_budget_scale)))
	var composition: Array[String] = enemy_factory.generate_composition(budget, wave_number)
	if composition.is_empty():
		composition.append("drone")

	var lane := _choose_lane()
	_active_lane_name = lane
	var objective := _choose_objective()
	_last_wave_number = wave_number
	_last_threat = threat
	_last_budget = budget
	_last_lane = lane
	_last_objective = objective
	_last_composition = composition.duplicate()

	if wave_manager.has_method("set_external_wave_plan"):
		wave_manager.call("set_external_wave_plan", composition, lane, objective)
	print("[EnemyDirector] wave=%d threat=%.2f budget=%d lane=%s objective=%s count=%d" % [wave_number, threat, budget, lane, objective, composition.size()])

func _on_wave_completed(_wave_number: int) -> void:
	var destroyed_now := _count_destroyed_structures()
	var success := destroyed_now > _destroyed_at_wave_start
	_last_attack_success = success
	_has_last_attack_result = true
	if lanes.has(_active_lane_name):
		lanes[_active_lane_name].record_attack(success)
	for lane in lanes.values():
		lane.decay()
	_active_lane_name = ""

func get_director_status() -> Dictionary:
	var lane_stats: Array[Dictionary] = []
	for key in lanes.keys():
		var lane = lanes[key]
		lane_stats.append({
			"lane": key,
			"recent_attacks": int(lane.recent_attacks),
			"failed_attacks": int(lane.failed_attacks),
			"total_attacks": int(lane.total_attacks),
			"successful_attacks": int(lane.successful_attacks),
			"success_ratio": float(lane.get_success_ratio()),
		})
	lane_stats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("lane", "")) < str(b.get("lane", ""))
	)
	return {
		"wave": _last_wave_number,
		"threat": _last_threat,
		"budget": _last_budget,
		"lane": _last_lane,
		"active_lane": _active_lane_name,
		"objective": _last_objective,
		"composition_count": _last_composition.size(),
		"composition": _last_composition.duplicate(),
		"has_last_attack_result": _has_last_attack_result,
		"last_attack_success": _last_attack_success,
		"lane_stats": lane_stats,
	}

func spawn_test_enemy(spawn_position: Vector2) -> bool:
	return spawn_debug_enemy_type("drone", spawn_position)


func spawn_debug_enemy_type(enemy_type: String, spawn_position: Vector2) -> bool:
	if wave_manager != null and wave_manager.has_method("debug_spawn_enemy_type"):
		return bool(wave_manager.call("debug_spawn_enemy_type", enemy_type, spawn_position, 1.0))
	if enemy_factory != null and enemy_factory.has_method("get_scene_for_type"):
		var scene_variant: Variant = enemy_factory.call("get_scene_for_type", enemy_type)
		if scene_variant is PackedScene:
			var parent := get_node_or_null("/root/GameRoot/World/Enemies")
			if parent == null:
				return false
			var enemy := (scene_variant as PackedScene).instantiate()
			if enemy is Node2D:
				(enemy as Node2D).global_position = spawn_position
			parent.add_child(enemy)
			return true
	return false

func _choose_lane() -> String:
	var active_lanes: Array = []
	for lane in lanes.values():
		if lane.active and not lane.spawn_nodes.is_empty():
			active_lanes.append(lane)
	if active_lanes.is_empty():
		return ""

	var best_lane: Node = active_lanes[0]
	var best_score: float = -INF
	for lane in active_lanes:
		var score: float = float(lane.get_attack_score())
		if score > best_score:
			best_score = score
			best_lane = lane
	return best_lane.lane_name

func _choose_objective() -> String:
	var total_weight := 0.0
	for value in objective_weights.values():
		total_weight += float(value)
	if total_weight <= 0.0:
		return "destroy_power"

	var roll := randf() * total_weight
	for key in objective_weights.keys():
		roll -= float(objective_weights[key])
		if roll <= 0.0:
			return String(key)
	return "destroy_power"

func _count_destroyed_structures() -> int:
	var destroyed := 0
	for node in get_tree().get_nodes_in_group("structure"):
		if node == null or not is_instance_valid(node):
			continue
		if node.has_method("is_dead") and bool(node.is_dead()):
			destroyed += 1
		elif "state" in node and String(node.state) == "destroyed":
			destroyed += 1
	return destroyed
