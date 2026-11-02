extends RefCounted
class_name RangedBallisticAimResolver

const ALIGNMENT_DISPLAY_DEGREES := 30.0


static func resolve_fine_correction(
	sector_forward: Vector2,
	intent_direction: Vector2,
	limit_degrees: float,
	weight: float = 1.0
) -> float:
	if sector_forward.length_squared() <= 0.0001 \
	or intent_direction.length_squared() <= 0.0001:
		return 0.0
	var limit := deg_to_rad(maxf(0.0, limit_degrees))
	return clampf(
		sector_forward.normalized().angle_to(intent_direction.normalized()),
		-limit,
		limit
	) * clampf(weight, 0.0, 1.0)


static func pursue_correction(
	current: float,
	desired: float,
	response: float,
	delta: float
) -> float:
	var response_weight := 1.0 - exp(-maxf(0.0, response) * maxf(0.0, delta))
	return lerp_angle(current, desired, clampf(response_weight, 0.0, 1.0))


static func alignment(ballistic_direction: Vector2, intent_direction: Vector2) -> Dictionary:
	if ballistic_direction.length_squared() <= 0.0001 \
	or intent_direction.length_squared() <= 0.0001:
		return {"aim_error_degrees": 180.0, "alignment_ratio": 0.0}
	var dot := clampf(
		ballistic_direction.normalized().dot(intent_direction.normalized()),
		-1.0,
		1.0
	)
	var error_degrees := rad_to_deg(acos(dot))
	return {
		"aim_error_degrees": error_degrees,
		"alignment_ratio": 1.0 - clampf(
			error_degrees / ALIGNMENT_DISPLAY_DEGREES,
			0.0,
			1.0
		),
	}


static func predict(
	space_state: PhysicsDirectSpaceState2D,
	origin: Vector2,
	direction: Vector2,
	display_distance: float,
	max_range: float,
	exclusions: Array[RID],
	terrain_provider: Node = null
) -> Dictionary:
	var resolved_direction := direction.normalized()
	var resolved_distance := clampf(display_distance, 0.0, maxf(0.0, max_range))
	var target := origin + resolved_direction * resolved_distance
	var result := {
		"predicted_world_position": target,
		"predicted_collider": null,
		"obstructed": false,
	}
	if resolved_direction.length_squared() <= 0.0001 or resolved_distance <= 0.0:
		return result
	if terrain_provider != null and terrain_provider.has_method("can_trace_projectile"):
		var terrain_variant: Variant = terrain_provider.call(
			"can_trace_projectile",
			origin,
			target
		)
		if terrain_variant is Dictionary:
			var terrain := terrain_variant as Dictionary
			if not bool(terrain.get("allowed", true)):
				result["predicted_world_position"] = terrain.get(
					"blocked_at_world",
					target
				)
				result["obstructed"] = true
				return result
	if space_state == null:
		return result
	var ray_exclusions := exclusions.duplicate()
	for _pass_index in range(8):
		var query := PhysicsRayQueryParameters2D.create(origin, target)
		query.exclude = ray_exclusions
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: Variant = hit.get("collider")
		var generated_terrain_allowed := collider is Node \
			and terrain_provider != null \
			and terrain_provider.has_method("is_terrain_collision_body") \
			and bool(terrain_provider.call("is_terrain_collision_body", collider as Node))
		if generated_terrain_allowed and collider is CollisionObject2D:
			ray_exclusions.append((collider as CollisionObject2D).get_rid())
			continue
		result["predicted_world_position"] = hit.get("position", target)
		result["predicted_collider"] = collider
		result["obstructed"] = true
		break
	return result


static func solve(
	space_state: PhysicsDirectSpaceState2D,
	desired_world_point: Vector2,
	muzzle_world_position: Vector2,
	ballistic_direction: Vector2,
	max_range: float,
	exclusions: Array[RID],
	terrain_provider: Node = null
) -> Dictionary:
	var intent_vector := desired_world_point - muzzle_world_position
	var intent_direction := intent_vector.normalized()
	var resolved_axis := ballistic_direction.normalized()
	if resolved_axis.length_squared() <= 0.0001:
		resolved_axis = intent_direction if intent_direction.length_squared() > 0.0001 else Vector2.RIGHT
	var display_distance := minf(intent_vector.length(), maxf(0.0, max_range))
	var prediction := predict(
		space_state,
		muzzle_world_position,
		resolved_axis,
		display_distance,
		max_range,
		exclusions,
		terrain_provider
	)
	var alignment_result := alignment(resolved_axis, intent_direction)
	return {
		"valid": true,
		"desired_world_point": desired_world_point,
		"intent_direction": intent_direction,
		"muzzle_world_position": muzzle_world_position,
		"ballistic_direction": resolved_axis,
		"display_distance": display_distance,
		"predicted_world_position": prediction.get("predicted_world_position", muzzle_world_position),
		"predicted_collider": prediction.get("predicted_collider", null),
		"obstructed": bool(prediction.get("obstructed", false)),
		"aim_error_degrees": float(alignment_result.get("aim_error_degrees", 0.0)),
		"alignment_ratio": float(alignment_result.get("alignment_ratio", 1.0)),
	}
