extends Node2D
class_name SpawnNode

@export var lane: String = "default"
@export var spawn_weight: float = 1.0
@export var active: bool = true

func _ready():
	add_to_group("enemy_spawn")
	add_to_group("spawn_node_" + lane)
