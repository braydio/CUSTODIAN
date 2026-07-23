extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorDodgePresentationSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	for animation_name in [
		&"operator_dodge_charge_windup_right",
		&"operator_dodge_charge_windup_down",
		&"operator_dodge_charge_windup_left",
	]:
		_assert(body.sprite_frames.has_animation(animation_name), "%s should be registered" % animation_name)
		_assert(body.sprite_frames.get_frame_count(animation_name) == 5, "%s should have five frames" % animation_name)
	for animation_name in [
		&"operator_dodge_chain_link_right",
		&"operator_dodge_chain_link_down",
		&"operator_dodge_chain_link_left",
	]:
		_assert(body.sprite_frames.has_animation(animation_name), "%s should be registered" % animation_name)
		_assert(body.sprite_frames.get_frame_count(animation_name) == 4, "%s should have four frames" % animation_name)

	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("stamina", 100.0)
	_assert(bool(operator.call("_begin_dodge_charge")), "neutral south charge should begin")
	_assert(body.animation == &"operator_dodge_charge_windup_down", "south charge should select exact down art")
	_assert(body.frame == 0 and not body.is_playing(), "charge frame zero should be held directly")
	operator.call("_update_dodge_charge_presentation", 0.5)
	_assert(body.frame == 2, "half charge should select frame two")
	operator.call("_update_dodge_charge_presentation", 1.0)
	_assert(body.frame == 4, "full charge should hold frame four")
	operator.set("_dodge_charge_timer", 0.30)
	_assert(bool(operator.call("_release_dodge_charge")), "charged release should enter existing dodge opener")
	_assert(not bool(operator.get("_dodge_charge_presentation_active")), "release should clear windup ownership")
	_assert(not String(body.animation).begins_with("operator_dodge_charge_windup"), "windup must not become travel art")

	operator.call("_cancel_dodge")
	operator.set("_dodge_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.set("visual_idle_direction", Vector2.UP)
	_assert(bool(operator.call("_begin_dodge_charge")), "north charge should begin through fallback")
	_assert(body.animation == &"operator_dodge_charge_windup_right", "north tie should deterministically select east/right art")
	var pending_direction: Vector2 = operator.get("_pending_dodge_direction")
	_assert(pending_direction == Vector2.UP, "presentation fallback must not alter pending dodge direction")
	operator.call("_cancel_dodge_charge", &"smoke")
	_assert(not bool(operator.get("_dodge_charge_presentation_active")), "charge cancellation should clear presentation")

	operator.call("_cancel_dodge")
	operator.set("_dodge_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.DOWN, &"committed", 1.0)
	operator.call("_buffer_dodge_chain", Vector2.DOWN, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(body.animation == &"operator_dodge_chain_link_down", "clean south link should use exact down link art")
	_assert(body.frame == 0, "link should restart from frame zero")
	_assert(
		is_equal_approx(
			body.sprite_frames.get_animation_speed(body.animation) * body.speed_scale,
			20.0
		),
		"four link frames should complete during 0.20-second active duration"
	)
	_assert(float(operator.get("_dodge_iframe_timer")) <= 0.16001, "presentation must preserve the 0.16-second iframe ceiling")
	operator.call("_buffer_dodge_chain", Vector2.DOWN, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(body.animation == &"operator_dodge_chain_link_down" and body.frame == 0, "back-to-back links should expose no neutral frame")

	operator.call("_buffer_dodge_chain", Vector2.UP, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(String(body.animation).begins_with("operator_dodge_full"), "turns over 90 degrees should use full-dodge pivot art")
	_assert(body.frame == 0, "hard pivot should begin at its plant frame")

	root.queue_free()
	await process_frame
	if _failed:
		push_error("operator_dodge_presentation_smoke failed")
		quit(1)
		return
	print("[OperatorDodgePresentationSmoke] charge frames, fallback, link cycle, pivot, and iframe invariance passed.")
	quit(0)


func _assert(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
