extends RefCounted
class_name OperatorWeaponSocketLibrary

const DEFAULT_DATA_PATH := "res://content/data/operator/generated/operator_weapon_sockets.generated.json"
const REQUIRED_SECTORS: Array[StringName] = [&"e", &"w", &"se", &"sw"]

var _tracks: Dictionary = {}
var _loaded_path: String = ""


func load_generated(path: String = DEFAULT_DATA_PATH) -> bool:
	_tracks.clear()
	_loaded_path = path
	if not FileAccess.file_exists(path):
		push_error("Missing production operator weapon socket data: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to read production operator weapon socket data: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("Invalid operator weapon socket JSON: %s" % path)
		return false
	var parsed_tracks: Variant = parsed.get("tracks", {})
	if not (parsed_tracks is Dictionary) or parsed_tracks.is_empty():
		push_error("Operator weapon socket JSON has no tracks: %s" % path)
		return false
	_tracks = parsed_tracks
	return true


func is_loaded() -> bool:
	return not _tracks.is_empty()


func has_socket(animation: StringName, frame: int) -> bool:
	var frames: Variant = _tracks.get(String(animation), [])
	return frames is Array and frame >= 0 and frame < frames.size() and frames[frame] is Dictionary


func get_socket(animation: StringName, frame: int, required: bool = true) -> Dictionary:
	if has_socket(animation, frame):
		return _decode_socket(_tracks[String(animation)][frame])
	if required:
		push_error("Missing production weapon socket entry: %s frame %d (%s)" % [animation, frame, _loaded_path])
	return {}


func validate_track(
	animation: StringName,
	frame_count: int,
	required_fields: Array[StringName] = [
		&"grip", &"support_grip", &"muzzle", &"ejection",
	]
) -> PackedStringArray:
	var errors := PackedStringArray()
	for frame in range(frame_count):
		if not has_socket(animation, frame):
			errors.append("%s frame %d" % [animation, frame])
			continue
		var socket := _tracks[String(animation)][frame] as Dictionary
		for key in required_fields:
			if not socket.has(key):
				errors.append("%s frame %d missing %s" % [animation, frame, key])
	return errors


func get_interpolated_socket(
	animation: StringName,
	frame: int,
	frame_progress: float,
	required: bool = true
) -> Dictionary:
	var frames: Variant = _tracks.get(String(animation), [])
	if not (frames is Array) or frames.is_empty():
		if required:
			push_error("Missing production weapon socket track: %s (%s)" % [animation, _loaded_path])
		return {}
	if frame < 0 or frame >= frames.size():
		if required:
			push_error("Invalid production weapon socket frame: %s frame %d (%s)" % [animation, frame, _loaded_path])
		return {}
	var next_frame: int = (frame + 1) % int(frames.size())
	if not has_socket(animation, frame) or not has_socket(animation, next_frame):
		if required:
			push_error("Incomplete production weapon socket interpolation: %s frames %d/%d (%s)" % [animation, frame, next_frame, _loaded_path])
		return {}
	var current := get_socket(animation, frame, false)
	var next := get_socket(animation, next_frame, false)
	var linear_progress := clampf(frame_progress, 0.0, 1.0)
	var smooth_progress := linear_progress * linear_progress * (3.0 - 2.0 * linear_progress)
	return {
		"grip": (current.grip as Vector2).lerp(next.grip as Vector2, smooth_progress),
		"support_grip": (current.support_grip as Vector2).lerp(next.support_grip as Vector2, smooth_progress),
		"muzzle": (current.muzzle as Vector2).lerp(next.muzzle as Vector2, smooth_progress),
		"ejection": (current.ejection as Vector2).lerp(next.ejection as Vector2, smooth_progress),
		"weapon_angle_deg": lerp_angle(
			deg_to_rad(float(current.weapon_angle_deg)),
			deg_to_rad(float(next.weapon_angle_deg)),
			smooth_progress
		) * 180.0 / PI,
		"weapon_z": int(current.weapon_z),
		"current_frame": frame,
		"next_frame": next_frame,
		"linear_progress": linear_progress,
		"smooth_progress": smooth_progress,
	}


static func resolve_aim_sector(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var octant := posmod(int(round(direction.angle() / (PI / 4.0))), 8)
	match octant:
		0:
			return &"e"
		1:
			return &"se"
		2:
			return &"s"
		3:
			return &"sw"
		4:
			return &"w"
		5:
			return &"nw"
		6:
			return &"n"
		_:
			return &"ne"


static func sector_direction(sector: StringName) -> Vector2:
	match sector:
		&"n": return Vector2.UP
		&"ne": return Vector2(1.0, -1.0).normalized()
		&"e": return Vector2.RIGHT
		&"se": return Vector2(1.0, 1.0).normalized()
		&"s": return Vector2.DOWN
		&"sw": return Vector2(-1.0, 1.0).normalized()
		&"w": return Vector2.LEFT
		&"nw": return Vector2(-1.0, -1.0).normalized()
	return Vector2.DOWN


static func animation_suffix_for_sector(sector: StringName) -> String:
	match sector:
		&"n": return "up"
		&"ne": return "up_right"
		&"e": return "right"
		&"se": return "down_right"
		&"s": return "down"
		&"sw": return "down_left"
		&"w": return "left"
		&"nw": return "up_left"
	return "down"


static func resolve_animation_suffix(direction: Vector2) -> String:
	return animation_suffix_for_sector(resolve_aim_sector(direction))


static func _decode_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


static func _decode_socket(raw: Dictionary) -> Dictionary:
	return {
		"grip": _decode_vector(raw.get("grip", [])),
		"support_grip": _decode_vector(raw.get("support_grip", [])),
		"muzzle": _decode_vector(raw.get("muzzle", [])),
		"ejection": _decode_vector(raw.get("ejection", [])),
		"weapon_angle_deg": float(raw.get("weapon_angle_deg", 0.0)),
		"weapon_z": int(raw.get("weapon_z", 3)),
	}
