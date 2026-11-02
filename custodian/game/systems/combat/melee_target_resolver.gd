extends RefCounted
class_name MeleeTargetResolver


static func get_reach_model(profile: MeleeAttackProfile) -> Dictionary:
	if profile == null:
		return {
			"base_hit_range": 0.0, "base_drive": 0.0,
			"reliable_drive": 0.0, "reliable_reach": 0.0,
			"assist_reach": 0.0,
		}
	var reliable_drive := profile.drive_distance_px * profile.target_reliable_drive_fraction
	var reliable_reach := profile.range_px + reliable_drive
	return {
		"base_hit_range": profile.range_px,
		"base_drive": profile.drive_distance_px,
		"reliable_drive": reliable_drive,
		"reliable_reach": reliable_reach,
		"assist_reach": reliable_reach + profile.target_acquire_extra_px,
	}


static func score_candidate(
	origin: Vector2,
	input_direction: Vector2,
	candidate: Dictionary,
	current_target: Node2D,
	preview_reach: float,
	acquire_cone_degrees: float,
	retain_cone_degrees: float,
	retain_range_bonus_px: float,
	current_bonus: float,
	reliable_reach: float
) -> Dictionary:
	var target: Node2D = candidate.get("target") as Node2D
	var point: Vector2 = candidate.get("target_point", Vector2.ZERO)
	var offset := point - origin
	var distance := offset.length()
	if target == null or distance <= 0.001:
		return {}
	var is_current := target == current_target
	var cone := retain_cone_degrees if is_current else acquire_cone_degrees
	var range_limit := preview_reach + (retain_range_bonus_px if is_current else 0.0)
	var angle_error := absf(rad_to_deg(input_direction.normalized().angle_to(offset.normalized())))
	if distance > range_limit or angle_error > cone:
		return {}
	var distance_score := 1.0 - clampf(distance / maxf(preview_reach, 1.0), 0.0, 1.0)
	var angle_score := 1.0 - clampf(angle_error / maxf(acquire_cone_degrees, 1.0), 0.0, 1.0)
	var score := angle_score * 0.58 + distance_score * 0.30
	if distance <= reliable_reach:
		score += 0.12
	if is_current:
		score += current_bonus
	return {
		"target": target,
		"target_point": point,
		"distance": distance,
		"angle_error_degrees": angle_error,
		"distance_score": distance_score,
		"angle_score": angle_score,
		"score": score,
		"within_reliable_reach": distance <= reliable_reach,
		"within_assist_reach": false,
	}


static func select_target(
	origin: Vector2,
	input_direction: Vector2,
	candidates: Array[Dictionary],
	current_target: Node2D,
	config: Dictionary
) -> Dictionary:
	if input_direction.length_squared() <= 0.0001:
		return {}
	var best: Dictionary = {}
	var current: Dictionary = {}
	for candidate in candidates:
		var scored := score_candidate(
			origin, input_direction, candidate, current_target,
			float(config.get("preview_reach", 0.0)),
			float(config.get("acquire_cone_degrees", 42.0)),
			float(config.get("retain_cone_degrees", 58.0)),
			float(config.get("retain_range_bonus_px", 20.0)),
			float(config.get("current_bonus", 0.18)),
			float(config.get("reliable_reach", 0.0))
		)
		if scored.is_empty():
			continue
		if scored.target == current_target:
			current = scored
		if best.is_empty() or float(scored.score) > float(best.score):
			best = scored
	if not current.is_empty() and not best.is_empty() and best.target != current_target:
		if float(best.score) < float(current.score) + float(config.get("switch_margin", 0.14)):
			return current
	return best


static func build_preview(candidate: Dictionary, reach: Dictionary, preview_reach: float, acquire_cone: float) -> Dictionary:
	if candidate.is_empty():
		return {}
	var distance := float(candidate.get("distance", INF))
	var reliable_reach := float(reach.get("reliable_reach", 0.0))
	var proximity := 0.0
	if distance <= reliable_reach:
		proximity = 1.0
	elif distance < preview_reach:
		proximity = 1.0 - (distance - reliable_reach) / maxf(preview_reach - reliable_reach, 1.0)
	var alignment := 1.0 - clampf(
		float(candidate.get("angle_error_degrees", 180.0)) / maxf(acquire_cone, 1.0),
		0.0, 1.0
	)
	var result := candidate.duplicate()
	result.merge(reach, true)
	result["preview_reach"] = preview_reach
	result["proximity"] = clampf(proximity, 0.0, 1.0)
	result["alignment"] = alignment
	result["reliable_contact"] = distance <= reliable_reach
	return result


static func resolve_attack(
	origin: Vector2,
	requested_direction: Vector2,
	target: Node2D,
	target_point: Vector2,
	profile: MeleeAttackProfile
) -> Dictionary:
	var input_direction := requested_direction.normalized()
	if input_direction == Vector2.ZERO:
		input_direction = Vector2.RIGHT
	var reach := get_reach_model(profile)
	var result := {
		"target": null,
		"input_direction": input_direction,
		"target_direction": input_direction,
		"assisted_direction": input_direction,
		"aim_correction_degrees": 0.0,
		"target_distance": 0.0,
		"base_hit_range": float(reach.base_hit_range),
		"base_drive_distance": float(reach.base_drive),
		"assist_drive_distance": 0.0,
		"resolved_drive_distance": float(reach.base_drive),
		"reliable_reach": float(reach.reliable_reach),
		"assist_reach": float(reach.assist_reach),
		"reliable_contact": false,
	}
	if profile == null or not profile.target_assist_enabled or target == null:
		return result
	var offset := target_point - origin
	var distance := offset.length()
	if distance <= 0.001:
		return result
	var target_direction := offset.normalized()
	var error := input_direction.angle_to(target_direction)
	var error_degrees := absf(rad_to_deg(error))
	if distance > float(reach.assist_reach) or error_degrees > profile.target_assist_cone_degrees:
		return result
	var correction := clampf(
		error,
		-deg_to_rad(profile.target_aim_correction_degrees),
		deg_to_rad(profile.target_aim_correction_degrees)
	)
	var assist_drive := minf(
		maxf(0.0, distance - float(reach.reliable_reach)),
		profile.target_drive_bonus_max_px
	)
	result["target"] = target
	result["target_direction"] = target_direction
	result["assisted_direction"] = input_direction.rotated(correction).normalized()
	result["aim_correction_degrees"] = rad_to_deg(correction)
	result["target_distance"] = distance
	result["assist_drive_distance"] = assist_drive
	result["resolved_drive_distance"] = profile.drive_distance_px + assist_drive
	result["reliable_contact"] = distance <= float(reach.reliable_reach)
	return result
