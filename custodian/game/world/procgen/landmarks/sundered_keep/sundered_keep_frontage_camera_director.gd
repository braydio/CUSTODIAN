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
	var frontage_enter := _segment_progress(
		operator_position,
		anchors.get("frontage_reveal_start", Vector2.ZERO),
		anchors.get("frontage_apex", Vector2.ZERO)
	)
	var frontage_return := _segment_progress(
		operator_position,
		anchors.get("frontage_apex", Vector2.ZERO),
		anchors.get("gameplay_return", Vector2.ZERO)
	)
	var first_weight := (
		_smootherstep(first_enter)
		* (1.0 - _smootherstep(first_return))
	)
	var frontage_weight := (
		_smootherstep(frontage_enter)
		* (1.0 - _smootherstep(frontage_return))
	)
	return {
		"first_enter_progress": first_enter,
		"first_return_progress": first_return,
		"frontage_enter_progress": frontage_enter,
		"frontage_return_progress": frontage_return,
		"first_weight": first_weight,
		"frontage_weight": frontage_weight,
		"camera_weight": maxf(first_weight, frontage_weight),
	}


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
