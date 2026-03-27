extends RefCounted
class_name AnimationResolver


static func resolve(base: String, direction: Vector2, sprite: AnimatedSprite2D) -> StringName:
	if sprite == null or sprite.sprite_frames == null:
		return StringName(base)

	var directional_name := "%s_%s" % [base, _get_direction_suffix(direction)]
	if sprite.sprite_frames.has_animation(StringName(directional_name)):
		return StringName(directional_name)

	var right_fallback := "%s_right" % base
	if sprite.sprite_frames.has_animation(StringName(right_fallback)):
		return StringName(right_fallback)

	if sprite.sprite_frames.has_animation(StringName(base)):
		return StringName(base)

	return StringName(base)


static func _get_direction_suffix(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right"
	return "down" if direction.y > 0.0 else "up"
