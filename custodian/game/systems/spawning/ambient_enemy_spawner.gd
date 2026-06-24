extends Node
class_name AmbientEnemySpawner

const CAMP_SCRIPT := preload("res://game/systems/spawning/ambient_enemy_camp.gd")

@export var enemy_scene: PackedScene
@export var marker_group: StringName = &"ambient_enemy_camp_marker"
@export var min_distance_from_player_start_px: float = 420.0
@export var min_camp_spacing_px: float = 700.0
@export var max_generated_camps: int = 3
@export var max_active_ambient_enemies: int = 12


func _ready() -> void:
	call_deferred("spawn_from_markers")


func spawn_from_markers() -> int:
	if enemy_scene == null:
		return 0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var accepted: Array[Vector2] = []
	var created := 0
	for marker in get_tree().get_nodes_in_group(marker_group):
		if created >= max_generated_camps or not (marker is Node2D):
			break
		var position := (marker as Node2D).global_position
		if player != null and position.distance_to(player.global_position) < min_distance_from_player_start_px:
			continue
		var too_close := false
		for existing in accepted:
			if position.distance_to(existing) < min_camp_spacing_px:
				too_close = true
				break
		if too_close:
			continue
		var camp := CAMP_SCRIPT.new() as AmbientEnemyCamp
		camp.camp_id = StringName("generated_camp_%d" % created)
		camp.enemy_scene = enemy_scene
		(marker as Node2D).add_child(camp)
		camp.global_position = position
		accepted.append(position)
		created += 1
	return created


func get_active_enemy_count() -> int:
	var total := 0
	for camp in get_tree().get_nodes_in_group("ambient_enemy_camp"):
		if camp.has_method("get_active_enemy_count"):
			total += int(camp.call("get_active_enemy_count"))
	return total
