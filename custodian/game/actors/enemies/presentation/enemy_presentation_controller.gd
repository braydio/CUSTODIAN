extends RefCounted
class_name EnemyPresentationController

var animation_set: EnemyAnimationSet
var body_sprite: AnimatedSprite2D
var fx_sprite: AnimatedSprite2D
var current_action: StringName = &""
var attack_ordinal := 0
var reaction_ordinal := 0
var flavor_ordinal := 0
var stable_spawn_ordinal := 0

const ATTACK_BAGS: Array[Array] = [
	[&"combat.fast_01", &"combat.fast_02", &"combat.fast_01", &"combat.fast_03", &"combat.fast_02", &"combat.fast_03", &"combat.fast_01"],
	[&"combat.fast_02", &"combat.fast_01", &"combat.fast_03", &"combat.fast_01", &"combat.fast_02", &"combat.fast_01", &"combat.fast_03"],
	[&"combat.fast_01", &"combat.fast_03", &"combat.fast_02", &"combat.fast_01", &"combat.fast_03", &"combat.fast_01", &"combat.fast_02"],
]
const FLAVOR_BAGS := {
	&"idle": [&"flavor.bark", &"flavor.bark", &"flavor.taunt_brandish"],
	&"ambient_activity": [&"flavor.bark", &"flavor.taunt_brandish", &"flavor.taunt_point", &"flavor.bark"],
	&"search": [&"flavor.taunt_point", &"flavor.bark", &"flavor.taunt_point"],
	&"lost_target": [&"flavor.taunt_bark", &"flavor.bark", &"flavor.taunt_point"],
}


func setup(set_resource: EnemyAnimationSet, body: AnimatedSprite2D, fx: AnimatedSprite2D = null, spawn_ordinal := 0) -> void:
	animation_set = set_resource
	body_sprite = body
	fx_sprite = fx
	stable_spawn_ordinal = maxi(0, spawn_ordinal)
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


func resolve_animation_name(
	action: StringName,
	direction: Vector2,
	variation_ordinal: int = 0
) -> StringName:
	if animation_set == null:
		return &""
	var clip := animation_set.resolve_clip(
		action,
		_direction_suffix(direction),
		variation_ordinal
	)
	return animation_set.get_animation_name(clip, &"body") \
		if not clip.is_empty() else &""


func get_duration(action: StringName, direction: Vector2, variation_ordinal: int = 0) -> float:
	if animation_set == null:
		return 0.0
	return animation_set.get_clip_duration(action, _direction_suffix(direction), variation_ordinal)


func stop_on_first_frame() -> void:
	if body_sprite == null:
		return
	body_sprite.stop()
	body_sprite.set_frame_and_progress(0, 0.0)


func select_normal_attack() -> StringName:
	var bag: Array = ATTACK_BAGS[stable_spawn_ordinal % ATTACK_BAGS.size()]
	var selected: StringName = bag[attack_ordinal % bag.size()]
	attack_ordinal += 1
	return selected


func select_flinch() -> StringName:
	var actions: Array[StringName] = [&"reaction.flinch_01", &"reaction.flinch_02"]
	var selected := actions[reaction_ordinal % actions.size()]
	reaction_ordinal += 1
	return selected


func select_flinch_for_severity(damage_ratio: float) -> StringName:
	return &"reaction.flinch_02" if damage_ratio >= 0.16 else &"reaction.flinch_01"


func select_flavor(context: StringName = &"idle") -> StringName:
	var actions: Array = FLAVOR_BAGS.get(context, FLAVOR_BAGS[&"idle"])
	var selected: StringName = actions[posmod(stable_spawn_ordinal + flavor_ordinal, actions.size())]
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
