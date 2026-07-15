extends RefCounted
class_name DroneTargeting

const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")

func acquire_target(drone: Node2D, anchor: Node2D, mode: int, profile: Resource, max_range_override: float = -1.0) -> Node2D:
	if drone == null or anchor == null or profile == null:
		return null
	return acquire_target_at_position(drone, anchor.global_position, mode, profile, max_range_override)


func acquire_target_at_position(drone: Node2D, anchor_position: Vector2, mode: int, profile: Resource, max_range_override: float = -1.0) -> Node2D:
	if drone == null or profile == null:
		return null
	var max_range: float = max_range_override if max_range_override > 0.0 else profile.drone_engage_range
	var best: Node2D = null
	var best_score := INF
	for candidate in drone.get_tree().get_nodes_in_group("enemy"):
		if not (candidate is Node2D):
			continue
		var enemy := candidate as Node2D
		if is_invalid_enemy(enemy):
			continue
		var anchor_distance := enemy.global_position.distance_to(anchor_position)
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


func is_valid_command_target(target: Variant) -> bool:
	if target == null or not is_instance_valid(target) or not (target is Node):
		return false
	var target_node := target as Node
	if target_node.has_method("is_dead") and bool(target_node.call("is_dead")):
		return false
	if target_node.is_in_group("drone_command_target"):
		return true
	return not is_invalid_enemy(target_node)


func is_invalid_enemy(enemy: Variant) -> bool:
	if enemy == null or not is_instance_valid(enemy) or not (enemy is Node):
		return true
	var enemy_node := enemy as Node
	if enemy_node.has_method("is_dead") and bool(enemy_node.call("is_dead")):
		return true
	if enemy_node.has_method("is_passive_enemy") and bool(enemy_node.call("is_passive_enemy")):
		return true
	return false
