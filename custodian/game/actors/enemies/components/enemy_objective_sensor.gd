extends Node
class_name EnemyObjectiveSensor


func choose_objective(enemy: Node2D, profile: Resource, blackboard: Node) -> Dictionary:
	var scores := {
		"operator": score_operator(enemy, profile, blackboard),
		"storage": score_storage(enemy, profile, blackboard),
		"exit": score_exit_with_loot(enemy, profile, blackboard),
		"investigate": score_investigation(enemy, profile, blackboard),
	}
	blackboard.objective_debug_scores = scores.duplicate(true)
	var best_type := &"none"
	var best_score := 0.0
	for key in scores.keys():
		var score := float(scores[key])
		if score > best_score:
			best_score = score
			best_type = StringName(str(key))
	return {"type": best_type, "score": best_score}


func score_operator(enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	var operator_ref: Node = blackboard.get("operator_ref")
	if operator_ref == null or not is_instance_valid(operator_ref):
		return 0.0
	if not bool(blackboard.get("is_alerted")) and not bool(blackboard.get("has_seen_operator")):
		return 0.0
	var operator := operator_ref as Node2D
	if operator == null:
		return 0.0
	var proximity := clampf(1.0 - enemy.global_position.distance_to(operator.global_position) / maxf(1.0, float(profile.get("vision_range_px"))), 0.0, 1.0)
	return float(profile.get("aggression_weight")) * 100.0 + proximity * 45.0


func score_storage(enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	if not bool(profile.get("can_steal_resources")) or bool(blackboard.get("is_carrying_loot")):
		return 0.0
	var manager := _get_vault_manager(enemy)
	if manager == null or not manager.has_method("find_best_storage_for_enemy"):
		return 0.0
	var storage = manager.call("find_best_storage_for_enemy", enemy)
	if not (storage is Node2D):
		return 0.0
	blackboard.set("target_storage", storage)
	var dist := enemy.global_position.distance_to((storage as Node2D).global_position)
	var distance_penalty := minf(45.0, dist / 32.0)
	return maxf(0.0, float(profile.get("theft_weight")) * 100.0 - distance_penalty)


func score_exit_with_loot(enemy: Node2D, _profile: Resource, blackboard: Node) -> float:
	return 1000.0 if bool(blackboard.get("is_carrying_loot")) else 0.0


func score_investigation(_enemy: Node2D, profile: Resource, blackboard: Node) -> float:
	if not bool(blackboard.get("is_suspicious")) or float(blackboard.get("investigation_timer")) <= 0.0:
		return 0.0
	return float(profile.get("curiosity_weight")) * 100.0


func _get_vault_manager(enemy: Node) -> Node:
	if enemy == null or enemy.get_tree() == null:
		return null
	var autoload := enemy.get_node_or_null("/root/VaultManager")
	if autoload != null:
		return autoload
	return enemy.get_tree().get_first_node_in_group("vault_manager")
