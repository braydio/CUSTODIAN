extends Node
class_name EnemyFactory

@export var drone_scene: PackedScene
@export var fast_drone_scene: PackedScene
@export var heavy_drone_scene: PackedScene
@export var siege_drone_scene: PackedScene
@export_range(0.0, 1.0, 0.05) var wolf_composition_weight: float = 0.35

const ENEMY_COST := {
	"drone": 1,
	"fast": 2,
	"heavy": 4,
	"siege": 6,
	"wolf": 2,
}

const UNLOCK_WAVE := {
	"drone": 0,
	"fast": 3,
	"heavy": 6,
	"siege": 10,
	"wolf": 1,
}

func generate_composition(budget: int, wave_number: int) -> Array[String]:
	var enemies: Array[String] = []
	var remaining: int = max(0, budget)
	var rng := RandomNumberGenerator.new()
	rng.seed = _stable_composition_seed(budget, wave_number)

	while remaining > 0:
		var enemy_type := _choose_enemy(remaining, wave_number, rng)
		if enemy_type.is_empty():
			break
		enemies.append(enemy_type)
		remaining -= int(ENEMY_COST[enemy_type])

	return enemies

func _choose_enemy(budget: int, wave: int, rng: RandomNumberGenerator) -> String:
	var options: Array[Dictionary] = []

	for enemy_type in ["drone", "wolf", "fast", "heavy", "siege"]:
		if budget < int(ENEMY_COST[enemy_type]):
			continue
		if wave < int(UNLOCK_WAVE[enemy_type]):
			continue
		if get_scene_for_type(enemy_type) == null:
			continue
		var weight := 1.0
		if enemy_type == "wolf":
			weight = clampf(wolf_composition_weight, 0.0, 1.0)
		options.append({"id": enemy_type, "weight": weight})

	if options.is_empty():
		return ""

	var total := 0.0
	for option in options:
		total += max(0.0, float(option["weight"]))
	if total <= 0.0:
		return String(options[0]["id"])
	var roll := rng.randf() * total
	for option in options:
		roll -= max(0.0, float(option["weight"]))
		if roll <= 0.0:
			return String(option["id"])
	return String(options[options.size() - 1]["id"])


func _stable_composition_seed(budget: int, wave: int) -> int:
	var text := "%d:%d:enemy_composition" % [budget, wave]
	var value := 2166136261
	for index in range(text.length()):
		value = value ^ text.unicode_at(index)
		value = (value * 16777619) & 0x7fffffff
	return maxi(1, value)

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
		"wolf":
			return drone_scene
		_:
			return null
