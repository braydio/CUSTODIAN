extends Node
class_name AssaultLane

@export var lane_name: String = "default"
@export var display_name: String = "Default Route"
@export var weight: float = 1.0
@export var active: bool = true

var spawn_nodes: Array[SpawnNode] = []
var recent_attacks: int = 0
var failed_attacks: int = 0
var total_attacks: int = 0
var successful_attacks: int = 0

func _ready() -> void:
	add_to_group("assault_lanes")

func clear_spawn_nodes() -> void:
	spawn_nodes.clear()

func register_spawn_node(node: SpawnNode) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node.active:
		return
	if node.lane != lane_name:
		return
	if not spawn_nodes.has(node):
		spawn_nodes.append(node)

func get_spawn_node() -> SpawnNode:
	if spawn_nodes.is_empty():
		return null
	return spawn_nodes[randi() % spawn_nodes.size()]

func get_attack_score() -> float:
	var score := weight
	score -= float(recent_attacks) * 2.0
	score += float(failed_attacks) * 0.5
	score += randf_range(-2.0, 2.0)
	return max(0.1, score)

func record_attack(success: bool) -> void:
	recent_attacks += 1
	total_attacks += 1
	if success:
		successful_attacks += 1
	if not success:
		failed_attacks += 1

func decay() -> void:
	recent_attacks = max(0, recent_attacks - 1)

func get_success_ratio() -> float:
	if total_attacks <= 0:
		return 0.0
	return float(successful_attacks) / float(total_attacks)
