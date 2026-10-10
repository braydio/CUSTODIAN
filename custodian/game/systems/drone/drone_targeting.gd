extends RefCounted
class_name DroneTargeting

const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const RelationshipResolver := preload("res://game/systems/combat/actor_relationship_resolver.gd")
const OPERATOR_ALLIED: StringName = &"operator_allied"

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
		if not is_valid_autonomous_target(enemy, drone):
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


func is_valid_autonomous_target(target: Variant, seeker: Node = null) -> bool:
	if not _is_live_target(target):
		return false
	var target_node := target as Node
	if target_node.has_method("is_passive_enemy") and bool(target_node.call("is_passive_enemy")):
		return false
	return RelationshipResolver.can_target(seeker, target_node, &"defense")


func is_valid_command_target(target: Variant, seeker: Node = null) -> bool:
	if not _is_live_target(target):
		return false
	var target_node := target as Node
	if not target_node.is_in_group("drone_command_target"):
		return is_valid_autonomous_target(target_node, seeker)
	# This opt-in group is the narrow exception for explicit Operator orders such
	# as a passive Shrumb. It bypasses hostility, never targetability or safety.
	if RelationshipResolver.resolve_allegiance(target_node) == OPERATOR_ALLIED:
		return false
	return _is_targetable_by(target_node, seeker)


func is_invalid_enemy(enemy: Variant, seeker: Node = null) -> bool:
	return not is_valid_autonomous_target(enemy, seeker)


func _is_live_target(target: Variant) -> bool:
	if target == null or not is_instance_valid(target) or not (target is Node2D):
		return false
	var target_node := target as Node2D
	return not (target_node.has_method("is_dead") and bool(target_node.call("is_dead")))


func _is_targetable_by(target: Node, seeker: Node) -> bool:
	if target.has_method("is_combat_targetable_by"):
		return bool(target.call("is_combat_targetable_by", seeker, &"defense"))
	return true
