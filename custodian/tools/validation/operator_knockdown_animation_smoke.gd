extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CombatConstants := preload("res://game/systems/combat/combat_constants.gd")
const RUNTIME_FRAMES := preload(
	"res://content/sprites/operator/runtime/operator_runtime_frames.tres"
)

const REACTION_BODY := {
	&"unarmed/reaction/bodyslam_knockdown_01/e/full_body": {"frames": 12, "fps": 12.0},
	&"unarmed/reaction/bodyslam_knockdown_01/w/full_body": {"frames": 12, "fps": 12.0},
	&"unarmed/reaction/light_hitreact_01/s/full_body": {"frames": 3, "fps": 10.0},
}
const REACTION_FX := {
	&"unarmed/reaction/bodyslam_knockdown_01/e/fx": {"frames": 12, "fps": 12.0},
	&"unarmed/reaction/bodyslam_knockdown_01/w/fx": {"frames": 12, "fps": 12.0},
	&"unarmed/reaction/light_hitreact_01/s/fx": {"frames": 3, "fps": 10.0},
}

var _failed := false
var _feedback_event_count := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorKnockdownAnimationSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var observatory := get_root().get_node_or_null("DevObservatory")
	if observatory != null and observatory.has_signal("event_logged"):
		observatory.connect("event_logged", _on_observability_event)

	for animation_name: StringName in REACTION_BODY:
		var contract: Dictionary = REACTION_BODY[animation_name]
		_assert_animation(RUNTIME_FRAMES, animation_name, contract)
	for animation_name: StringName in REACTION_FX:
		var contract: Dictionary = REACTION_FX[animation_name]
		_assert_animation(RUNTIME_FRAMES, animation_name, contract)

	var operator := await _new_operator(root)
	await _assert_heavy_state_entry(operator)
	operator.queue_free()
	await process_frame

	operator = await _new_operator(root)
	await _assert_heavy_reaction(
		operator,
		operator.get_node("AnimatedSprite2D"),
		operator.get_node("MeleeFxOverlaySprite"),
		Vector2.RIGHT,
		&"e"
	)
	_assert_reaction_cleanup(operator, operator.get_node("MeleeFxOverlaySprite"))
	operator.queue_free()
	await process_frame

	operator = await _new_operator(root)
	await _assert_heavy_reaction(
		operator,
		operator.get_node("AnimatedSprite2D"),
		operator.get_node("MeleeFxOverlaySprite"),
		Vector2.LEFT,
		&"w"
	)
	_assert_reaction_cleanup(operator, operator.get_node("MeleeFxOverlaySprite"))
	operator.queue_free()
	await process_frame

	operator = await _new_operator(root)
	await _assert_light_fallback(
		operator,
		operator.get_node("AnimatedSprite2D"),
		operator.get_node("MeleeFxOverlaySprite")
	)
	_assert_reaction_cleanup(operator, operator.get_node("MeleeFxOverlaySprite"))
	operator.queue_free()
	if _failed:
		push_error("operator_knockdown_animation_smoke failed")
		quit(1)
		return
	print("operator_knockdown_animation_smoke passed")
	quit()


func _new_operator(root: Node2D) -> Node:
	Engine.time_scale = 1.0
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	return operator


func _assert_heavy_state_entry(operator: Node) -> void:
	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.HEAVY)
	operator.set("_last_damage_reaction_direction", Vector2.RIGHT)
	operator.set("velocity", Vector2.ZERO)
	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.call("_request_damage_reaction", 1.0, CombatConstants.HitStrength.HEAVY)
	await create_timer(0.05).timeout
	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert(
		body.animation == &"unarmed/reaction/bodyslam_knockdown_01/e/full_body",
		"heavy reaction state should enter the canonical east body animation"
	)
	_assert(bool(operator.call("_is_movement_locked")), "heavy reaction state should retain its movement lock")
	_assert(
		is_equal_approx(float(operator.call("get_damage_reaction_duration", "hit_recoil")), 1.0),
		"heavy reaction state should retain one-second recovery"
	)
	operator.call("finish_damage_reaction_presentation")


func _assert_heavy_reaction(
	operator: Node,
	body: AnimatedSprite2D,
	fx: AnimatedSprite2D,
	direction: Vector2,
	sector: StringName
) -> void:
	var feedback_count_before := _feedback_event_count
	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.HEAVY)
	operator.set("_last_damage_reaction_direction", direction)
	operator.set("velocity", Vector2.ZERO)
	operator.set("_enemy_impact_lock_timer", 0.0)
	var body_animation := StringName(
		"unarmed/reaction/bodyslam_knockdown_01/%s/full_body" % sector
	)
	var fx_animation := StringName(
		"unarmed/reaction/bodyslam_knockdown_01/%s/fx" % sector
	)
	_assert(
		operator.call("get_damage_reaction_animation", "hit_recoil") == body_animation,
		"heavy impact should resolve canonical %s body art" % sector
	)
	body.play(body_animation)
	operator.call("play_damage_reaction_fx", body_animation, false)
	_assert(body.animation == body_animation, "heavy impact should play canonical %s body art" % sector)
	_assert(body.visible and not body.flip_h, "authored %s knockdown should be visible and unmirrored" % sector)
	_assert(fx.visible and fx.animation == fx_animation, "heavy impact should start synchronized canonical %s FX" % sector)
	_assert(
		is_equal_approx(float(operator.call("get_damage_reaction_duration", "hit_recoil")), 1.0),
		"knockdown should preserve its one-second reaction duration"
	)
	_assert(
		is_equal_approx(RUNTIME_FRAMES.get_animation_speed(body_animation), 12.0)
			and RUNTIME_FRAMES.get_frame_count(body_animation) == 12,
		"knockdown should preserve the authored one-second, 12-frame playback"
	)
	_assert_damage_package(operator, "heavy fallback", feedback_count_before)


func _assert_light_fallback(
	operator: Node,
	body: AnimatedSprite2D,
	fx: AnimatedSprite2D
) -> void:
	var feedback_count_before := _feedback_event_count
	# Remove one required modular layer identity to force the real fallback branch
	# atomically; the legacy sprite still owns the canonical runtime database.
	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var original_frames := upper.sprite_frames
	var incomplete_frames := original_frames.duplicate() as SpriteFrames
	incomplete_frames.remove_animation(
		&"unarmed/locomotion/idle_hitreact_01/s/upper_body"
	)
	upper.sprite_frames = incomplete_frames
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("_last_damage_reaction_direction", Vector2.DOWN)
	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.LIGHT)
	operator.set("velocity", Vector2.ZERO)
	operator.set("_enemy_impact_lock_timer", 0.0)
	_assert(
		not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")),
		"incomplete modular hit-react art should select the canonical fallback"
	)
	var body_animation := &"unarmed/reaction/light_hitreact_01/s/full_body"
	var fx_animation := &"unarmed/reaction/light_hitreact_01/s/fx"
	_assert(
		operator.call("get_damage_reaction_animation", "hit_recoil") == body_animation,
		"non-modular light fallback should resolve canonical light reaction body"
	)
	body.play(body_animation)
	operator.call("play_damage_reaction_fx", body_animation, false)
	_assert(body.animation == body_animation, "non-modular light fallback should play canonical light reaction body")
	_assert(body.visible, "canonical light fallback body should be visible")
	_assert(fx.visible and fx.animation == fx_animation, "light fallback should play canonical reaction FX")
	_assert(
		is_equal_approx(float(operator.call("get_damage_reaction_duration", "hit_recoil")), 0.22),
		"light reaction should preserve the 0.22-second stun window"
	)
	_assert_damage_package(operator, "light fallback", feedback_count_before)
	upper.sprite_frames = original_frames


func _assert_damage_package(operator: Node, label: String, feedback_count_before: int) -> void:
	# The production reaction entry point invokes the shared package once. Its
	# directional recoil and optional observability event are stable headless
	# evidence; hit-stop itself is time-bound and intentionally not sampled.
	_assert((operator.get("velocity") as Vector2).length() > 0.0, "%s should trigger shared directional recoil" % label)
	var observatory := get_root().get_node_or_null("DevObservatory")
	if observatory != null and bool(observatory.get("_telemetry_allowed")):
		_assert(
			_feedback_event_count == feedback_count_before + 1,
			"%s should emit exactly one shared damage-feedback event" % label
		)


func _assert_reaction_cleanup(operator: Node, fx: AnimatedSprite2D) -> void:
	operator.call("finish_damage_reaction_presentation")
	_assert(not fx.visible, "reaction FX should hide when its state exits")
	_assert(not bool(operator.get("_modular_damage_reaction_active")), "reaction ownership should clear on exit")


func _assert_animation(frames: SpriteFrames, animation_name: StringName, contract: Dictionary) -> void:
	_assert(frames != null and frames.has_animation(animation_name), "missing canonical animation %s" % animation_name)
	if frames == null or not frames.has_animation(animation_name):
		return
	_assert(frames.get_frame_count(animation_name) == int(contract["frames"]), "%s should contain %d frames" % [animation_name, contract["frames"]])
	_assert(is_equal_approx(frames.get_animation_speed(animation_name), float(contract["fps"])), "%s should play at %s FPS" % [animation_name, contract["fps"]])
	_assert(not frames.get_animation_loop(animation_name), "%s should be a one-shot" % animation_name)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _on_observability_event(kind: StringName, _data: Dictionary) -> void:
	if kind == &"operator_damage_feedback_presented":
		_feedback_event_count += 1
