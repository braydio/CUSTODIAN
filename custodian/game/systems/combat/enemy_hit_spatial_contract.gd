extends RefCounted
class_name EnemyHitSpatialContract


static func radial_arc(attacker_position: Vector2, target_position: Vector2, attack_forward: Vector2, nominal_range_px: float, grace_multiplier: float, grace_px: float, arc_degrees: float) -> Dictionary:
	var delta := target_position - attacker_position
	var separation := delta.length()
	var allowed_range := nominal_range_px * grace_multiplier + grace_px
	var forward := attack_forward.normalized()
	if forward.length_squared() <= 0.0001:
		forward = delta.normalized() if delta.length_squared() > 0.0001 else Vector2.RIGHT
	var target_direction := delta.normalized() if delta.length_squared() > 0.0001 else forward
	var angle_error := absf(rad_to_deg(forward.angle_to(target_direction)))
	var range_valid := separation <= allowed_range
	var arc_valid := angle_error <= arc_degrees * 0.5
	return {"contact_model": "radial_arc", "attacker_position": attacker_position, "target_position": target_position, "contact_position": target_position, "separation_px": separation, "nominal_range_px": nominal_range_px, "allowed_range_px": allowed_range, "range_ratio": separation / allowed_range if allowed_range > 0.001 else INF, "contact_margin_px": allowed_range - separation, "arc_degrees": arc_degrees, "angle_error_degrees": angle_error, "range_valid": range_valid, "arc_valid": arc_valid, "spatial_valid": range_valid and arc_valid, "spatial_reason": "" if range_valid and arc_valid else ("target_out_of_range" if not range_valid else "target_out_of_arc")}


static func directional_lane(attacker_position: Vector2, target_position: Vector2, forward: Vector2, backward_reach_px: float, forward_reach_px: float, lateral_reach_px: float) -> Dictionary:
	var axis := forward.normalized()
	if axis.length_squared() <= 0.0001:
		axis = Vector2.RIGHT
	var delta := target_position - attacker_position
	var separation := delta.length()
	var forward_distance := delta.dot(axis)
	var lateral_distance := absf(delta.cross(axis))
	var forward_valid := forward_distance >= -backward_reach_px and forward_distance <= forward_reach_px
	var lateral_valid := lateral_distance <= lateral_reach_px
	var valid := forward_valid and lateral_valid
	return {"contact_model": "directional_lane", "attacker_position": attacker_position, "target_position": target_position, "contact_position": target_position, "separation_px": separation, "forward_distance_px": forward_distance, "allowed_forward_px": forward_reach_px, "backward_tolerance_px": backward_reach_px, "lateral_distance_px": lateral_distance, "allowed_lateral_px": lateral_reach_px, "contact_utilization_ratio": maxf(forward_distance / maxf(forward_reach_px, 0.001) if forward_distance >= 0.0 else absf(forward_distance) / maxf(backward_reach_px, 0.001), lateral_distance / maxf(lateral_reach_px, 0.001)), "spatial_valid": valid, "spatial_reason": "" if valid else ("outside_forward_lane" if not forward_valid else "outside_lateral_lane")}


static func directional_actor_lane(
	attacker: Node2D,
	target: Node2D,
	forward: Vector2,
	backward_reach_px: float,
	forward_reach_px: float,
	lateral_reach_px: float
) -> Dictionary:
	var axis := forward.normalized()
	if axis.length_squared() <= 0.0001:
		axis = Vector2.RIGHT
	var body_extension := 0.0
	if _has_body_collision(attacker) and _has_body_collision(target):
		body_extension = _collision_support(attacker, axis) + _collision_support(target, axis)
	var spatial := directional_lane(
	attacker.global_position,
		target.global_position,
		axis,
		backward_reach_px,
		forward_reach_px + body_extension,
		lateral_reach_px
	)
	spatial["configured_forward_reach_px"] = forward_reach_px
	spatial["collision_body_extension_px"] = body_extension
	return spatial


static func _has_body_collision(actor: Node2D) -> bool:
	if actor == null:
		return false
	var collision_shape := actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return collision_shape != null and not collision_shape.disabled and collision_shape.shape != null


static func _collision_support(actor: Node2D, axis: Vector2) -> float:
	if actor == null:
		return 0.0
	var collision_shape := actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
		return 0.0
	var bounds := collision_shape.shape.get_rect()
	var transform := collision_shape.global_transform
	var x_axis := transform.x.normalized()
	var y_axis := transform.y.normalized()
	var x_extent := bounds.size.x * 0.5 * transform.x.length()
	var y_extent := bounds.size.y * 0.5 * transform.y.length()
	return absf(axis.dot(x_axis)) * x_extent + absf(axis.dot(y_axis)) * y_extent
