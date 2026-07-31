extends RefCounted
class_name SunderedKeepFrontageCameraDirector


func evaluate(
	operator_position: Vector2,
	anchors: Dictionary
) -> Dictionary:
	var first_enter := _segment_progress(
		operator_position,
		anchors.get("first_influence_start", Vector2.ZERO),
		anchors.get("first_reveal_apex", Vector2.ZERO)
	)
	var first_return := _segment_progress(
		operator_position,
		anchors.get("first_reveal_apex", Vector2.ZERO),
		anchors.get("first_return_complete", Vector2.ZERO)
	)
	var first_weight := (
		_smootherstep(first_enter)
		* (1.0 - _smootherstep(first_return))
	)
	var corridor_distance := _distance_to_segment(
		operator_position,
		anchors.get("first_influence_start", Vector2.ZERO),
		anchors.get("first_return_complete", Vector2.ZERO)
	)
	if corridor_distance > 256.0:
		first_weight = 0.0
	return {
		"first_enter_progress": first_enter,
		"first_return_progress": first_return,
		"frontage_enter_progress": 0.0,
		"frontage_return_progress": 0.0,
		"first_weight": first_weight,
		"frontage_weight": 0.0,
		"camera_weight": first_weight,
	}


func _distance_to_segment(
	point: Vector2,
	start: Vector2,
	end: Vector2
) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _segment_progress(
	point: Vector2,
	start: Vector2,
	end: Vector2
) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return 0.0
	return clampf(
		(point - start).dot(segment) / length_squared,
		0.0,
		1.0
	)


func _smootherstep(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
