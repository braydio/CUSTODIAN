extends Node
class_name EnemyFactory

@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene
@export var siege_drone_scene: PackedScene

const ENEMY_COST := {
	"drone": 1,
	"fast": 2,
	"heavy": 4,
	"siege": 6,
}

const UNLOCK_WAVE := {
	"drone": 0,
	"fast": 3,
	"heavy": 6,
	"siege": 10,
}

func generate_composition(budget: int, wave_number: int) -> Array[String]:
	var enemies: Array[String] = []
	var remaining: int = max(0, budget)

	while remaining > 0:
		var enemy_type := _choose_enemy(remaining, wave_number)
		if enemy_type.is_empty():
			break
		enemies.append(enemy_type)
		remaining -= int(ENEMY_COST[enemy_type])

	return enemies

func _choose_enemy(budget: int, wave: int) -> String:
	var options: Array[String] = []

	for enemy_type in ["drone", "fast", "heavy", "siege"]:
		if budget < int(ENEMY_COST[enemy_type]):
			continue
		if wave < int(UNLOCK_WAVE[enemy_type]):
			continue
		if get_scene_for_type(enemy_type) == null:
			continue
		options.append(enemy_type)

	if options.is_empty():
		return ""

	return options[randi() % options.size()]

func get_scene_for_type(enemy_type: String) -> PackedScene:
	match enemy_type:
		"drone":
			return drone_scene
		"fast":
			return fast_drone_scene
		"heavy":
			return heavy_drone_scene
		"siege":
			return siege_drone_scene
		_:
			return null
