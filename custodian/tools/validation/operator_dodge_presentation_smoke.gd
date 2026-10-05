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
	var charge_animation := &"shared/attack/dodge_charge_windup_01/s/full_body"
	var chain_animation := &"shared/transition/dodge_chain_link_01/s/full_body"
	_assert(body.sprite_frames.has_animation(charge_animation), "canonical south charge art should be registered")
	_assert(body.sprite_frames.get_frame_count(charge_animation) == 5, "canonical charge art should have five frames")
	_assert(body.sprite_frames.has_animation(chain_animation), "canonical south chain art should be registered")
	_assert(body.sprite_frames.get_frame_count(chain_animation) == 4, "canonical chain art should have four frames")

	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("stamina", 100.0)
	_assert(bool(operator.call("_begin_dodge_charge")), "neutral south charge should begin")
	_assert(body.animation == charge_animation, "south charge should select exact down art")
	_assert(body.frame == 0 and not body.is_playing(), "charge frame zero should be held directly")
	operator.call("_update_dodge_charge_presentation", 0.5)
	_assert(body.frame == 2, "half charge should select frame two")
	operator.call("_update_dodge_charge_presentation", 1.0)
	_assert(body.frame == 4, "full charge should hold frame four")
	operator.get("_dodge_controller").set("_charge_elapsed", 0.30)
	_assert(bool(operator.call("_release_dodge_charge")), "charged release should enter existing dodge opener")
	_assert(not bool(operator.get("_dodge_charge_presentation_active")), "release should clear windup ownership")
	_assert(not String(body.animation).begins_with("operator_dodge_charge_windup"), "windup must not become travel art")

	operator.call("_cancel_dodge")
	operator.get("_dodge_controller").set("_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.set("visual_idle_direction", Vector2.UP)
	_assert(bool(operator.call("_begin_dodge_charge")), "north charge should begin through fallback")
	_assert(body.animation == &"shared/attack/dodge_charge_windup_01/n/full_body", "north charge should select canonical north art")
	var pending_direction: Vector2 = operator.call("get_dodge_runtime_status").get("pending_direction")
	_assert(pending_direction == Vector2.UP, "presentation fallback must not alter pending dodge direction")
	operator.call("_cancel_dodge_charge", &"smoke")
	_assert(not bool(operator.get("_dodge_charge_presentation_active")), "charge cancellation should clear presentation")

	operator.call("_cancel_dodge")
	operator.get("_dodge_controller").set("_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.DOWN, &"committed", 1.0)
	operator.call("_buffer_dodge_chain", Vector2.DOWN, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(body.animation == chain_animation, "clean south link should use canonical south link art")
	_assert(body.frame == 0, "link should restart from frame zero")
	_assert(
		is_equal_approx(
			body.sprite_frames.get_animation_speed(body.animation) * body.speed_scale,
			20.0
		),
		"four link frames should complete during 0.20-second active duration"
	)
	_assert(float(operator.call("get_dodge_runtime_status").get("iframe_remaining")) <= 0.16001, "presentation must preserve the 0.16-second iframe ceiling")
	operator.call("_buffer_dodge_chain", Vector2.DOWN, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(body.animation == chain_animation and body.frame == 0, "back-to-back links should expose no neutral frame")

	operator.call("_buffer_dodge_chain", Vector2.UP, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(String(body.animation).begins_with("shared/transition/dodge_01/n/full_body"), "turns over 90 degrees should use full-dodge pivot art")
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
