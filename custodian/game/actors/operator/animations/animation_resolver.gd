extends RefCounted
class_name AnimationResolver


static func resolve(base: String, direction: Vector2, sprite: AnimatedSprite2D) -> StringName:
	if sprite == null or sprite.sprite_frames == null:
		return StringName(base)

	var directional_name := "%s_%s" % [base, _get_direction_suffix(direction)]
	if _has_playable_animation(sprite.sprite_frames, StringName(directional_name)):
		return StringName(directional_name)

	var left_fallback := "%s_left" % base
	if direction.x < -0.05 and _has_playable_animation(sprite.sprite_frames, StringName(left_fallback)):
		return StringName(left_fallback)

	var right_fallback := "%s_right" % base
	if _has_playable_animation(sprite.sprite_frames, StringName(right_fallback)):
		return StringName(right_fallback)

	if _has_playable_animation(sprite.sprite_frames, StringName(base)):
		return StringName(base)

	return StringName(base)


static func _has_playable_animation(sprite_frames: SpriteFrames, animation_name: StringName) -> bool:
	return sprite_frames.has_animation(animation_name) and sprite_frames.get_frame_count(animation_name) > 0


static func _get_direction_suffix(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "left" if direction.x < 0.0 else "right"
	return "down" if direction.y > 0.0 else "up"
