extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CombatConstants := preload(
	"res://game/systems/combat/combat_constants.gd"
)

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorModularIdleHitreactSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	var lower := operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var head := operator.get_node("ModularHeadSprite") as AnimatedSprite2D
	var legacy := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	for sprite in [lower, upper]:
		for animation_name in [
			&"operator_idle_hitreact_modular_up",
			&"operator_idle_hitreact_modular_down",
		]:
			_assert(
				sprite.sprite_frames.has_animation(animation_name),
				"%s should contain %s" % [sprite.name, animation_name]
			)
			_assert(
				sprite.sprite_frames.get_frame_count(animation_name) == 5,
				"%s should contain five frames" % animation_name
			)

	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.LIGHT)
	_assert_reaction_direction(
		operator,
		Vector2.UP,
		&"operator_idle_hitreact_modular_up",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(1.0, -1.0),
		&"operator_idle_hitreact_modular_up",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(-1.0, -1.0),
		&"operator_idle_hitreact_modular_up",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2.DOWN,
		&"operator_idle_hitreact_modular_down",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(1.0, 1.0),
		&"operator_idle_hitreact_modular_down",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(-1.0, 1.0),
		&"operator_idle_hitreact_modular_down",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")

	operator.set("visual_idle_direction", Vector2.UP)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "north setup should begin")
	operator.call("finish_damage_reaction_presentation")
	operator.set("visual_idle_direction", Vector2.RIGHT)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "east tie should begin")
	_assert(lower.animation == &"operator_idle_hitreact_modular_up", "east should preserve previous north sector")
	operator.call("finish_damage_reaction_presentation")
	operator.set("visual_idle_direction", Vector2.DOWN)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "south setup should begin")
	operator.call("finish_damage_reaction_presentation")
	operator.set("visual_idle_direction", Vector2.LEFT)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "west tie should begin")
	_assert(lower.animation == &"operator_idle_hitreact_modular_down", "west should preserve previous south sector")
	operator.call("_update_animation")
	_assert(lower.animation == &"operator_idle_hitreact_modular_down", "locomotion must not overwrite active modular reaction")
	operator.call("finish_damage_reaction_presentation")

	var original_upper_frames := upper.sprite_frames
	var incomplete_frames := original_upper_frames.duplicate() as SpriteFrames
	incomplete_frames.remove_animation(&"operator_idle_hitreact_modular_down")
	upper.sprite_frames = incomplete_frames
	operator.set("visual_idle_direction", Vector2.DOWN)
	var lower_visibility_before := lower.visible
	var upper_visibility_before := upper.visible
	_assert(
		not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")),
		"missing required upper art should use legacy fallback"
	)
	_assert(
		lower.visible == lower_visibility_before and upper.visible == upper_visibility_before,
		"missing required art should fail atomically"
	)
	upper.sprite_frames = original_upper_frames

	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.HEAVY)
	_assert(not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "knockdown/heavy reaction should retain higher priority")
	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.LIGHT)
	operator.set("_paired_execution_active", true)
	_assert(not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "execution should retain higher priority")
	operator.set("_paired_execution_active", false)
	operator.set("_is_dead", true)
	_assert(not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "death should retain higher priority")
	operator.set("_is_dead", false)

	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("movement_direction", Vector2.ZERO)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "cleanup setup should begin")
	operator.call("finish_damage_reaction_presentation")
	_assert(not bool(operator.get("_modular_damage_reaction_active")), "cleanup should clear modular reaction ownership")
	await process_frame
	_assert(lower.visible and upper.visible, "cleanup should restore modular idle presentation")

	root.queue_free()
	await process_frame
	if _failed:
		push_error("operator_modular_idle_hitreact_smoke failed")
		quit(1)
		return
	print("[OperatorModularIdleHitreactSmoke] synchronized N/S reaction, fallback, priority, and cleanup passed.")
	quit(0)


func _assert_reaction_direction(
	operator: Node,
	direction: Vector2,
	expected_animation: StringName,
	lower: AnimatedSprite2D,
	upper: AnimatedSprite2D,
	head: AnimatedSprite2D,
	legacy: AnimatedSprite2D
) -> void:
	operator.set("visual_idle_direction", direction)
	_assert(
		bool(operator.call("begin_modular_damage_reaction", "hit_recoil")),
		"reaction should begin for %s" % direction
	)
	_assert(lower.animation == expected_animation, "lower should resolve %s" % expected_animation)
	_assert(upper.animation == expected_animation, "upper should resolve %s" % expected_animation)
	_assert(lower.frame == 0 and upper.frame == 0, "required layers should start on frame zero")
	_assert(lower.visible and upper.visible, "required modular layers should be visible")
	_assert(not legacy.visible, "legacy and modular bodies must not render together")
	if head.sprite_frames.has_animation(expected_animation):
		_assert(head.visible and head.animation == expected_animation, "optional head should join matching reaction")
		_assert(head.frame == lower.frame, "optional head should start synchronized")


func _assert(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
