extends RefCounted
class_name InstantReplayPlayer


static func sample_frames(
	frames: Array[Dictionary],
	cursor_sec: float
) -> Dictionary:
	if frames.is_empty():
		return {}
	if frames.size() == 1 or cursor_sec <= float(frames[0].get("timestamp_sec", 0.0)):
		return frames[0]
	var last := frames[frames.size() - 1]
	if cursor_sec >= float(last.get("timestamp_sec", 0.0)):
		return last
	for index in range(frames.size() - 1):
		var left := frames[index]
		var right := frames[index + 1]
		var left_time := float(left.get("timestamp_sec", 0.0))
		var right_time := float(right.get("timestamp_sec", left_time))
		if cursor_sec > right_time:
			continue
		var weight := inverse_lerp(left_time, right_time, cursor_sec)
		return _interpolate(left, right, weight)
	return last


static func _interpolate(
	left: Dictionary,
	right: Dictionary,
	weight: float
) -> Dictionary:
	var right_by_id: Dictionary = {}
	for entity: Dictionary in right.get("entities", []):
		right_by_id[int(entity.get("id", 0))] = entity
	var entities: Array[Dictionary] = []
	for left_entity: Dictionary in left.get("entities", []):
		var entity := left_entity.duplicate(true)
		var replay_id := int(entity.get("id", 0))
		var right_entity: Dictionary = right_by_id.get(replay_id, {})
		if not right_entity.is_empty():
			entity["position"] = (entity.get("position", Vector2.ZERO) as Vector2).lerp(
				right_entity.get("position", Vector2.ZERO) as Vector2,
				weight
			)
			entity["rotation"] = lerp_angle(
				float(entity.get("rotation", 0.0)),
				float(right_entity.get("rotation", 0.0)),
				weight
			)
		entities.append(entity)
	var camera := (left.get("camera", {}) as Dictionary).duplicate(true)
	var right_camera := right.get("camera", {}) as Dictionary
	if not camera.is_empty() and not right_camera.is_empty():
		camera["position"] = (camera.get("position", Vector2.ZERO) as Vector2).lerp(
			right_camera.get("position", Vector2.ZERO) as Vector2,
			weight
		)
		camera["zoom"] = (camera.get("zoom", Vector2.ONE) as Vector2).lerp(
			right_camera.get("zoom", Vector2.ONE) as Vector2,
			weight
		)
	return {
		"timestamp_sec": lerpf(
			float(left.get("timestamp_sec", 0.0)),
			float(right.get("timestamp_sec", 0.0)),
			weight
		),
		"entities": entities,
		"camera": camera,
	}
