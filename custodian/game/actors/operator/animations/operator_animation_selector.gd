class_name OperatorAnimationSelector
extends RefCounted
## Runtime-only identity selection. SOUTH is temporary and never crosses identity fields.

signal operator_animation_south_fallback(details: Dictionary)

const SECTORS: Array[StringName] = [&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne"]

var _frames: SpriteFrames
var _warned: Dictionary = {}
var south_fallback_count: int = 0


func _init(frames: SpriteFrames) -> void:
	_frames = frames


static func vector_to_sector(direction: Vector2) -> StringName:
	if direction.is_zero_approx():
		return &"s"
	return SECTORS[posmod(int(floor(direction.angle() / (PI / 4.0) + 0.5)), 8)]


static func sector_direction(sector: StringName) -> Vector2:
	var index := SECTORS.find(sector)
	return Vector2.from_angle(float(index) * PI / 4.0) if index >= 0 else Vector2.ZERO


static func animation_name(
	profile: StringName, group: StringName, action: StringName,
	sector: StringName, layer: StringName, weapon_id: StringName = &""
) -> StringName:
	var identity := "%s/%s/%s/%s/%s" % [profile, group, action, sector, layer]
	return StringName(identity if weapon_id.is_empty() else "weapon/%s/%s" % [weapon_id, identity])


func resolve(
	profile: StringName, group: StringName, action: StringName,
	direction: Vector2, layer: StringName, weapon_id: StringName = &""
) -> StringName:
	var sector := vector_to_sector(direction)
	var exact := animation_name(profile, group, action, sector, layer, weapon_id)
	if _has_animation(exact):
		return exact
	if sector != &"s":
		var south := animation_name(profile, group, action, &"s", layer, weapon_id)
		if _has_animation(south):
			south_fallback_count += 1
			var details := {
				"profile": profile, "group": group, "action": action,
				"requested_direction": sector, "layer": layer, "weapon_id": weapon_id,
			}
			operator_animation_south_fallback.emit(details)
			if not _warned.has(exact):
				_warned[exact] = true
				push_warning("operator_animation_south_fallback: %s -> %s" % [exact, south])
			return south
	push_error("Missing required Operator runtime animation: %s" % exact)
	return &""


func resolve_omni(
	profile: StringName, group: StringName, action: StringName,
	layer: StringName, weapon_id: StringName = &""
) -> StringName:
	var exact := animation_name(profile, group, action, &"omni", layer, weapon_id)
	if _has_animation(exact):
		return exact
	push_error("Missing required Operator runtime animation: %s" % exact)
	return &""


func _has_animation(identity: StringName) -> bool:
	return _frames != null and _frames.has_animation(identity) and _frames.get_frame_count(identity) > 0
