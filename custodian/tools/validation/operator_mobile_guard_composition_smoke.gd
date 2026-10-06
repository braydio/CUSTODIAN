extends SceneTree

## Mobile guard composition lifecycle.
##
## While the unarmed Operator is guarding AND moving, the lower body is
## movement-owned locomotion and only the upper body plays the defensive action;
## stationary guard keeps the authored paired defensive pose; guard break stays
## impact-locked and never composes.

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const Controller = preload("res://game/actors/operator/presentation/operator_presentation_controller.gd")
const Phase = OperatorGuardController.Phase

const WALK_E := &"unarmed/locomotion/walk_01/e/lower_body"
const WALK_W := &"unarmed/locomotion/walk_01/w/lower_body"
const WALK_S := &"unarmed/locomotion/walk_01/s/lower_body"
const ENTER_LOWER_E := &"unarmed/defense/block_enter_01/e/lower_body"
const ENTER_UPPER_E := &"unarmed/defense/block_enter_01/e/upper_body"
const HOLD_LOWER_E := &"unarmed/defense/block_hold_01/e/lower_body"
const HOLD_UPPER_E := &"unarmed/defense/block_hold_01/e/upper_body"
const HIT_LOWER_E := &"unarmed/defense/block_hit_01/e/lower_body"
const HIT_UPPER_E := &"unarmed/defense/block_hit_01/e/upper_body"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorMobileGuardCompositionSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	_validate_decision_matrix()

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	_validate_moving_lifecycle(operator)
	_validate_opposed_and_orthogonal_directions(operator)
	_validate_stationary_paired(operator)
	_validate_stop_mid_phase(operator)
	_validate_guard_break_never_composes(operator)
	_validate_missing_layer_falls_back_to_paired(operator)
	_validate_movement_semantics_unchanged(operator)
	operator.queue_free()

	if _failed:
		push_error("operator_mobile_guard_composition_smoke failed")
		quit(1)
		return
	print("operator_mobile_guard_composition_smoke passed")
	quit()


func _validate_decision_matrix() -> void:
	var moving: int = Controller.GuardComposition.MOVEMENT_LOWER_UPPER_ACTION
	var paired: int = Controller.GuardComposition.PAIRED
	for phase in [&"enter", &"hold", &"recoil", &"exit"]:
		_assert_true(Controller.decide_guard_composition(phase, true, false) == moving, "moving %s should compose" % phase)
		_assert_true(Controller.decide_guard_composition(phase, false, false) == paired, "stationary %s should stay paired" % phase)
		_assert_true(Controller.decide_guard_composition(phase, true, true) == paired, "impact-locked %s must never compose" % phase)
	for phase in [&"guard_break", &"parry", &"success", &"recovery", &""]:
		_assert_true(Controller.decide_guard_composition(phase, true, false) == paired, "%s must not use the mobile composition" % phase)


func _prepare(operator: Node) -> void:
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("is_sprinting", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("movement_direction", Vector2.RIGHT)
	operator.set("velocity", Vector2.RIGHT * 32.0)
	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.call("_exit_ranged_ready")


func _set_phase(operator: Node, phase: int, key: StringName) -> void:
	(operator.get("_guard_controller") as OperatorGuardController).phase = phase
	operator.call("_play_block_animation", key)


func _sprites(operator: Node) -> Dictionary:
	return {
		"lower": operator.get("modular_lower_body_sprite") as AnimatedSprite2D,
		"upper": operator.get("modular_upper_body_sprite") as AnimatedSprite2D,
		"legacy": operator.get("animated_sprite") as AnimatedSprite2D,
	}


func _validate_moving_lifecycle(operator: Node) -> void:
	_prepare(operator)
	var s := _sprites(operator)
	var lower: AnimatedSprite2D = s["lower"]
	var upper: AnimatedSprite2D = s["upper"]
	_assert_true(lower != null and upper != null, "modular body layers should exist")
	if lower == null or upper == null:
		return

	# Moving enter: lower is movement-owned walk, upper plays block_enter only.
	_set_phase(operator, Phase.GUARD_ENTER, &"melee_2h_block_enter")
	_assert_true(lower.visible and upper.visible, "moving enter should show both modular layers")
	_assert_true(lower.animation == WALK_E, "moving enter lower should be locomotion walk, got %s" % lower.animation)
	_assert_true(upper.animation == ENTER_UPPER_E, "moving enter upper should play block_enter, got %s" % upper.animation)
	_assert_true(lower.animation != ENTER_LOWER_E, "moving enter must not play the planted paired lower")
	_assert_true(is_equal_approx(lower.speed_scale, float(operator.get("block_move_multiplier"))), "lower walk uses the existing guard movement scale")
	_assert_true(upper.is_playing(), "upper enter should play")
	_assert_true((operator.get("animated_sprite") as AnimatedSprite2D) == null or not (operator.get("animated_sprite") as AnimatedSprite2D).visible, "legacy full body must be hidden")

	# Lower locomotion progress is preserved across every upper phase change.
	lower.set_frame_and_progress(2, 0.4)
	var lower_frame := lower.frame
	_set_phase(operator, Phase.GUARD_HOLD, &"melee_2h_block_hold")
	_assert_true(lower.animation == WALK_E and lower.frame == lower_frame, "enter -> hold must not restart the unchanged lower walk")
	_assert_true(upper.animation == HOLD_UPPER_E, "hold upper should be block_hold, got %s" % upper.animation)

	_set_phase(operator, Phase.LIGHT_RECOIL, &"melee_2h_block_hitreact")
	_assert_true(lower.animation == WALK_E and lower.frame == lower_frame, "light recoil must keep the lower walk running")
	_assert_true(upper.animation == HIT_UPPER_E, "no dedicated light recoil is canonical yet, so upper falls back to block_hit_01")
	_set_phase(operator, Phase.HEAVY_RECOIL, &"melee_2h_block_hitreact")
	_assert_true(lower.animation == WALK_E and lower.frame == lower_frame, "heavy recoil must keep the lower walk running")
	_assert_true(upper.animation == HIT_UPPER_E, "no dedicated heavy recoil is canonical yet, so upper falls back to block_hit_01")

	_set_phase(operator, Phase.GUARD_HOLD, &"melee_2h_block_hold")
	_assert_true(lower.animation == WALK_E and lower.frame == lower_frame, "recoil -> hold must not restart the lower walk")
	_assert_true(upper.animation == HOLD_UPPER_E, "recovery returns the upper to block_hold")

	# Per-frame upkeep never restarts a running upper or the lower.
	upper.set_frame_and_progress(3, 0.2)
	for _i in 3:
		operator.call("_sync_modular_block_movement_presentation")
	_assert_true(upper.frame == 3 and lower.frame == lower_frame, "repeated sync must not restart either layer")

	# Exit: lower keeps locomotion, upper plays the enter action in reverse; completion keys from the upper.
	_set_phase(operator, Phase.GUARD_EXIT, &"melee_2h_block_exit")
	_assert_true(lower.animation == WALK_E and lower.frame == lower_frame, "moving exit keeps the lower walk")
	_assert_true(upper.animation == ENTER_UPPER_E and upper.get_playing_speed() < 0.0, "moving exit reverses block_enter on the upper")
	_assert_true(is_equal_approx(upper.speed_scale, float(operator.get("guard_exit_speed_scale"))), "exit keeps its authored speed scale")
	var upper_clock_done := not upper.is_playing()
	_assert_true(bool(operator.call("_is_block_animation_finished")) == upper_clock_done, "guard completion must key from the upper action, not the lower locomotion clock")
	_reset_guard(operator)


func _validate_opposed_and_orthogonal_directions(operator: Node) -> void:
	_prepare(operator)
	var s := _sprites(operator)
	var lower: AnimatedSprite2D = s["lower"]
	var upper: AnimatedSprite2D = s["upper"]
	# Move west while guarding east.
	operator.set("movement_direction", Vector2.LEFT)
	operator.set("velocity", Vector2.LEFT * 32.0)
	_set_phase(operator, Phase.GUARD_ENTER, &"melee_2h_block_enter")
	_assert_true(lower.animation == WALK_W, "moving west lower should resolve the west walk, got %s" % lower.animation)
	_assert_true(upper.animation == ENTER_UPPER_E, "aiming east keeps the east guard upper, got %s" % upper.animation)
	# Move south while guarding east.
	operator.set("movement_direction", Vector2.DOWN)
	operator.set("velocity", Vector2.DOWN * 32.0)
	_set_phase(operator, Phase.GUARD_HOLD, &"melee_2h_block_hold")
	_assert_true(lower.animation == WALK_S, "moving south lower should resolve the south walk, got %s" % lower.animation)
	_assert_true(upper.animation == HOLD_UPPER_E, "aiming east keeps block_hold east, got %s" % upper.animation)
	_assert_true(not lower.flip_h and not upper.flip_h, "canonical sectored identities are never mirrored at runtime")
	_reset_guard(operator)


func _validate_stationary_paired(operator: Node) -> void:
	_prepare(operator)
	operator.set("velocity", Vector2.ZERO)
	var s := _sprites(operator)
	var lower: AnimatedSprite2D = s["lower"]
	var upper: AnimatedSprite2D = s["upper"]
	_set_phase(operator, Phase.GUARD_ENTER, &"melee_2h_block_enter")
	_assert_true(lower.animation == ENTER_LOWER_E and upper.animation == ENTER_UPPER_E, "stationary enter keeps the paired lower+upper block_enter")
	_set_phase(operator, Phase.LIGHT_RECOIL, &"melee_2h_block_hitreact")
	_assert_true(lower.animation == HIT_LOWER_E and upper.animation == HIT_UPPER_E, "stationary recoil keeps the paired block_hit_01")
	_set_phase(operator, Phase.GUARD_HOLD, &"melee_2h_block_hold")
	_assert_true(lower.animation == HOLD_LOWER_E and upper.animation == HOLD_UPPER_E, "stationary hold keeps the paired block_hold_01")
	_set_phase(operator, Phase.GUARD_EXIT, &"melee_2h_block_exit")
	_assert_true(upper.animation == ENTER_UPPER_E and upper.get_playing_speed() < 0.0, "stationary exit keeps the reversed block_enter upper")
	_reset_guard(operator)


func _validate_stop_mid_phase(operator: Node) -> void:
	_prepare(operator)
	var s := _sprites(operator)
	var lower: AnimatedSprite2D = s["lower"]
	var upper: AnimatedSprite2D = s["upper"]
	_set_phase(operator, Phase.GUARD_ENTER, &"melee_2h_block_enter")
	_assert_true(lower.animation == WALK_E, "precondition: moving enter composes")
	upper.set_frame_and_progress(2, 0.1)
	operator.set("velocity", Vector2.ZERO)
	var handled := bool(operator.call("_sync_modular_block_movement_presentation"))
	_assert_true(handled, "stopping mid-phase should hand the lower back to the paired action")
	_assert_true(lower.animation == ENTER_LOWER_E, "stopped enter lower should be the paired block_enter lower, got %s" % lower.animation)
	_assert_true(upper.animation == ENTER_UPPER_E and upper.frame == 2, "the upper clip and its progress are untouched when the player stops")
	_reset_guard(operator)


func _validate_guard_break_never_composes(operator: Node) -> void:
	_prepare(operator)
	# guard_on_break leaves recoil velocity that is not movement intent.
	operator.set("velocity", Vector2.RIGHT * 90.0)
	operator.set("_enemy_impact_lock_timer", 0.5)
	var s := _sprites(operator)
	var lower: AnimatedSprite2D = s["lower"]
	var upper: AnimatedSprite2D = s["upper"]
	_set_phase(operator, Phase.GUARD_BREAK, &"melee_2h_block_hitreact")
	_assert_true(lower.animation == HIT_LOWER_E and upper.animation == HIT_UPPER_E, "guard break presents the paired impact pose, never the mobile composition")
	_assert_true(lower.animation != WALK_E, "guard break must not select locomotion")
	_assert_true(bool(operator.call("_is_guard_presentation_impact_locked")), "break phase is impact-locked")
	operator.call("_sync_modular_block_movement_presentation")
	_assert_true(lower.animation == HIT_LOWER_E, "per-frame upkeep must not compose a break")
	operator.set("_enemy_impact_lock_timer", 0.0)
	_reset_guard(operator)


func _validate_missing_layer_falls_back_to_paired(operator: Node) -> void:
	_prepare(operator)
	var s := _sprites(operator)
	var lower: AnimatedSprite2D = s["lower"]
	var upper: AnimatedSprite2D = s["upper"]
	var canonical_frames: SpriteFrames = lower.sprite_frames
	# Duplicate before mutating: the renderer shares the canonical resource.
	var broken: SpriteFrames = canonical_frames.duplicate()
	broken.remove_animation(WALK_E)
	lower.sprite_frames = broken
	_set_phase(operator, Phase.GUARD_ENTER, &"melee_2h_block_enter")
	_assert_true(lower.visible and upper.visible, "a missing lower must never leave half a body")
	_assert_true(lower.animation == ENTER_LOWER_E and upper.animation == ENTER_UPPER_E, "missing locomotion lower falls back to the complete paired pose")
	lower.sprite_frames = canonical_frames
	_reset_guard(operator)


func _validate_movement_semantics_unchanged(operator: Node) -> void:
	_prepare(operator)
	for phase in [Phase.GUARD_ENTER, Phase.GUARD_HOLD, Phase.LIGHT_RECOIL, Phase.HEAVY_RECOIL, Phase.GUARD_EXIT]:
		(operator.get("_guard_controller") as OperatorGuardController).phase = phase
		_assert_true(not bool(operator.call("_is_movement_locked")), "guard phase %d must remain movement-permissive" % phase)
	_assert_true(float(operator.get("block_move_multiplier")) < 1.0, "guard still slows movement")
	_reset_guard(operator)


func _reset_guard(operator: Node) -> void:
	(operator.get("_guard_controller") as OperatorGuardController).phase = Phase.NEUTRAL
	operator.set("velocity", Vector2.ZERO)
	operator.set("_guard_presentation_mode", &"")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
