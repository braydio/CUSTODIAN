extends RefCounted
class_name EnemyPresentationController

var animation_set: EnemyAnimationSet
var body_sprite: AnimatedSprite2D
var fx_sprite: AnimatedSprite2D
var current_action: StringName = &""
var attack_ordinal := 0
var reaction_ordinal := 0
var flavor_ordinal := 0


func setup(set_resource: EnemyAnimationSet, body: AnimatedSprite2D, fx: AnimatedSprite2D = null) -> void:
	animation_set = set_resource
	body_sprite = body
	fx_sprite = fx
	if body_sprite != null:
		body_sprite.sprite_frames = animation_set.build_sprite_frames(&"body")
	if fx_sprite != null:
		fx_sprite.sprite_frames = animation_set.build_sprite_frames(&"fx")
		fx_sprite.visible = false


func play(action: StringName, direction: Vector2, variation_ordinal: int = 0, restart := false) -> bool:
	if animation_set == null or body_sprite == null:
		return false
	var clip := animation_set.resolve_clip(action, _direction_suffix(direction), variation_ordinal)
	if clip.is_empty():
		return false
	var animation_name := animation_set.get_animation_name(clip, &"body")
	if not body_sprite.sprite_frames.has_animation(animation_name):
		return false
	current_action = action
	if restart or body_sprite.animation != animation_name:
		body_sprite.play(animation_name)
	_play_fx(clip, animation_name, restart)
	return true


func stop_on_first_frame() -> void:
	if body_sprite == null:
		return
	body_sprite.stop()
	body_sprite.set_frame_and_progress(0, 0.0)


func select_normal_attack() -> StringName:
	var actions: Array[StringName] = [&"combat.fast_01", &"combat.fast_02", &"combat.fast_03"]
	var selected := actions[attack_ordinal % actions.size()]
	attack_ordinal += 1
	return selected


func select_flinch() -> StringName:
	var actions: Array[StringName] = [&"reaction.flinch_01", &"reaction.flinch_02"]
	var selected := actions[reaction_ordinal % actions.size()]
	reaction_ordinal += 1
	return selected


func select_flavor() -> StringName:
	var actions: Array[StringName] = [&"flavor.bark", &"flavor.taunt_bark", &"flavor.taunt_brandish", &"flavor.taunt_point"]
	var selected := actions[flavor_ordinal % actions.size()]
	flavor_ordinal += 1
	return selected



func _play_fx(clip: Dictionary, _body_animation_name: StringName, restart: bool) -> void:
	var animation_name := animation_set.get_animation_name(clip, &"fx")
	if fx_sprite == null or not fx_sprite.sprite_frames.has_animation(animation_name):
		if fx_sprite != null:
			fx_sprite.visible = false
		return
	fx_sprite.visible = true
	if restart or fx_sprite.animation != animation_name:
		fx_sprite.play(animation_name)


func _direction_suffix(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var suffixes: Array[StringName] = [&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne"]
	return suffixes[int(round(wrapf(direction.angle(), 0.0, TAU) / (PI / 4.0))) % 8]
