extends Node
class_name EnemyPerceptionComponent

signal became_suspicious(target_position: Vector2)
signal noticed_operator(operator: Node)
signal lost_operator(last_known_position: Vector2)
signal heard_noise(noise_position: Vector2, strength: float)

var detection_meter: float = 0.0
var last_known_position: Vector2 = Vector2.ZERO
var has_line_of_sight: bool = false
var _was_alerted := false


func update_perception(enemy: Node2D, profile: Resource, blackboard: Node, delta: float) -> void:
	if enemy == null or profile == null or blackboard == null:
		return
	var operator := _find_operator(enemy)
	if operator == null:
		_decay(profile, delta)
		return

	var snapshot := _get_operator_snapshot(operator)
	var operator_position := snapshot.get("global_position", operator.global_position) as Vector2
	var distance := enemy.global_position.distance_to(operator_position)
	var visible: bool = distance <= float(profile.get("vision_range_px")) and _is_in_vision_arc(enemy, operator_position, profile) and _has_line_of_sight(enemy, operator)
	has_line_of_sight = visible

	if visible:
		last_known_position = operator_position
		blackboard.last_known_operator_position = operator_position
		blackboard.operator_ref = operator
		var visibility_mult := float(snapshot.get("visibility_mult", 1.0))
		var distance_mult := _distance_detection_mult(distance, profile.vision_range_px)
		detection_meter = clampf(detection_meter + float(profile.get("detection_gain_per_sec")) * visibility_mult * distance_mult * delta, 0.0, 1.0)
	else:
		_decay(profile, delta)

	var noise_radius := float(snapshot.get("noise_radius_px", 0.0))
	if not visible and noise_radius > 0.0 and distance <= min(float(profile.get("hearing_range_px")) + noise_radius, float(profile.get("hearing_range_px")) * 2.5):
		last_known_position = operator_position
		blackboard.investigation_position = operator_position
		blackboard.set("investigation_timer", float(profile.get("investigation_memory_sec")))
		blackboard.is_suspicious = true
		heard_noise.emit(operator_position, noise_radius)
		became_suspicious.emit(operator_position)

	if detection_meter >= float(profile.get("detection_notice_threshold")) and not bool(blackboard.get("is_suspicious")):
		blackboard.is_suspicious = true
		blackboard.investigation_position = operator_position
		became_suspicious.emit(operator_position)

	if detection_meter >= float(profile.get("detection_alert_threshold")):
		blackboard.has_seen_operator = true
		blackboard.is_alerted = true
		if not _was_alerted:
			noticed_operator.emit(operator)
		_was_alerted = true
	elif _was_alerted and detection_meter <= 0.01:
		blackboard.is_alerted = false
		_was_alerted = false
		lost_operator.emit(last_known_position)


func force_noise(noise_position: Vector2, strength: float, blackboard: Node) -> void:
	last_known_position = noise_position
	if blackboard != null:
		blackboard.investigation_position = noise_position
		blackboard.investigation_timer = maxf(blackboard.investigation_timer, strength)
		blackboard.is_suspicious = true
	heard_noise.emit(noise_position, strength)


func _decay(profile: Resource, delta: float) -> void:
	detection_meter = clampf(detection_meter - float(profile.get("detection_decay_per_sec")) * delta, 0.0, 1.0)


func _find_operator(enemy: Node) -> Node2D:
	var tree := enemy.get_tree()
	if tree == null:
		return null
	var player := tree.get_first_node_in_group("player")
	return player as Node2D


func _get_operator_snapshot(operator: Node2D) -> Dictionary:
	if operator.has_method("get_stealth_snapshot"):
		var snapshot = operator.call("get_stealth_snapshot")
		if snapshot is Dictionary:
			return snapshot
	return {
		"global_position": operator.global_position,
		"visibility_mult": 1.0,
		"noise_radius_px": 25.0,
		"velocity": Vector2.ZERO,
	}


func _is_in_vision_arc(enemy: Node2D, target_position: Vector2, profile: Resource) -> bool:
	var to_target := target_position - enemy.global_position
	if to_target.length_squared() <= 0.001:
		return true
	var facing := Vector2.DOWN
	if "velocity" in enemy and (enemy as CharacterBody2D).velocity.length_squared() > 0.001:
		facing = (enemy as CharacterBody2D).velocity.normalized()
	elif enemy.has_method("get_last_move_direction"):
		facing = Vector2(enemy.call("get_last_move_direction"))
	var angle: float = abs(rad_to_deg(facing.angle_to(to_target.normalized())))
	var cone_degrees := float(profile.get("vision_cone_degrees"))
	return angle <= cone_degrees * 0.5 or angle <= cone_degrees * float(profile.get("peripheral_vision_mult"))


func _has_line_of_sight(enemy: Node2D, target: Node2D) -> bool:
	var space := enemy.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(enemy.global_position, target.global_position)
	query.exclude = [enemy.get_rid(), target.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	return hit.is_empty()


func _distance_detection_mult(distance: float, range_px: float) -> float:
	var alpha := distance / maxf(1.0, range_px)
	if alpha <= 0.25:
		return 1.25
	if alpha <= 0.75:
		return 1.0
	return 0.45
