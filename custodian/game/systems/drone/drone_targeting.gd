extends RefCounted
class_name DroneTargeting

const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")

func acquire_target(drone: Node2D, anchor: Node2D, mode: int, profile: Resource) -> Node2D:
	if drone == null or anchor == null or profile == null:
		return null
	var max_range: float = profile.drone_engage_range
	var best: Node2D = null
	var best_score := INF
	for candidate in drone.get_tree().get_nodes_in_group("enemy"):
		if not (candidate is Node2D):
			continue
		var enemy := candidate as Node2D
		if is_invalid_enemy(enemy):
			continue
		var anchor_distance := enemy.global_position.distance_to(anchor.global_position)
		var drone_distance := enemy.global_position.distance_to(drone.global_position)
		if mode != DroneCommandProfileScript.Mode.HOLD and anchor_distance > max_range:
			continue
		if mode == DroneCommandProfileScript.Mode.HOLD and drone_distance > max_range:
			continue
		var score := drone_distance
		if mode == DroneCommandProfileScript.Mode.INTERCEPT:
			score = anchor_distance * 0.65 + drone_distance * 0.35
		if score < best_score:
			best_score = score
			best = enemy
	return best


func is_invalid_enemy(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return true
	if enemy.has_method("is_dead") and bool(enemy.call("is_dead")):
		return true
	if enemy.has_method("is_passive_enemy") and bool(enemy.call("is_passive_enemy")):
		return true
	return false
