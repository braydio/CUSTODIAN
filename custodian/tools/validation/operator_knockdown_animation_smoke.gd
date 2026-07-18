extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CombatConstants := preload("res://game/systems/combat/combat_constants.gd")

const BODY_ANIMATIONS := {
	&"unarmed_bodyslam_knockdown_right": 12,
	&"unarmed_bodyslam_knockdown_left": 12,
}
const FX_ANIMATIONS := {
	&"unarmed_bodyslam_knockdown_fx_right": 12,
	&"unarmed_bodyslam_knockdown_fx_left": 12,
}

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorKnockdownAnimationSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var fx := operator.get_node("MeleeFxOverlaySprite") as AnimatedSprite2D
	for animation_name in BODY_ANIMATIONS:
		_assert_animation(body.sprite_frames, animation_name, int(BODY_ANIMATIONS[animation_name]))
	for animation_name in FX_ANIMATIONS:
		_assert_animation(fx.sprite_frames, animation_name, int(FX_ANIMATIONS[animation_name]))

	operator.call("take_damage", 1.0, true, {
		"hit_strength": CombatConstants.HitStrength.HEAVY,
		"hit_direction": Vector2.LEFT,
	})
	_assert_true(body.animation == &"unarmed_bodyslam_knockdown_left", "leftward heavy impact should select the authored west body strip")
	_assert_true(body.visible and not body.flip_h, "authored knockdown body should be visible and unmirrored")
	_assert_true(fx.visible and fx.animation == &"unarmed_bodyslam_knockdown_fx_left", "heavy hit should start the synchronized west FX strip")
	_assert_true(bool(operator.call("_is_movement_locked")), "knockdown recovery should retain movement lock until the full-body strip completes")
	_assert_true(is_equal_approx(float(operator.call("get_damage_reaction_duration", "hit_recoil")), 1.0), "knockdown state should preserve the full 12-frame playback duration")

	operator.call("_update_animation_state_machine", 1.01)
	_assert_true(not fx.visible, "knockdown FX should hide when the reaction state exits")

	operator.queue_free()
	if _failed:
		push_error("operator_knockdown_animation_smoke failed")
		quit(1)
		return
	print("operator_knockdown_animation_smoke passed")
	quit()


func _assert_animation(frames: SpriteFrames, animation_name: StringName, expected_frames: int) -> void:
	_assert_true(frames != null and frames.has_animation(animation_name), "missing animation %s" % String(animation_name))
	if frames == null or not frames.has_animation(animation_name):
		return
	_assert_true(frames.get_frame_count(animation_name) == expected_frames, "%s should contain %d frames" % [String(animation_name), expected_frames])
	_assert_true(is_equal_approx(frames.get_animation_speed(animation_name), 12.0), "%s should play at 12 FPS" % String(animation_name))
	_assert_true(not frames.get_animation_loop(animation_name), "%s should be a one-shot" % String(animation_name))


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
