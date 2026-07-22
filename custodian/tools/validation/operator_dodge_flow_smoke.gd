extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var _errors: Array[String] = []
var _chain_started_events: Array[Dictionary] = []
var _chain_ended_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	world.name = "OperatorDodgeFlowSmoke"
	get_root().add_child(world)
	current_scene = world
	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	await process_frame
	operator.dodge_chain_started.connect(_on_chain_started)
	operator.dodge_chain_ended.connect(_on_chain_ended)

	_validate_flow_sources(operator)
	_validate_turn_retention(operator)
	await _validate_input_buffer_window(operator)
	_validate_charged_chain_and_redirect(operator)
	_validate_reverse_break(operator)
	_validate_late_grace(operator)
	_validate_exit_carry_and_decay(operator)
	_validate_stamina_constraint(operator)

	operator.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[OperatorDodgeFlowSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[OperatorDodgeFlowSmoke] %s" % error)
	quit(1)


func _validate_flow_sources(operator: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 100.0)
	_assert(bool(operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"tap")), "tap opener should start")
	_assert(is_equal_approx(float(operator.get("_dodge_flow")), 0.35), "tap opener must establish 0.35 Flow")
	_assert(is_zero_approx(float(operator.get("_dodge_cooldown_remaining"))), "cooldown must not run during the opener")

	_reset_operator(operator)
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"long")
	_assert(is_equal_approx(float(operator.get("_dodge_flow")), 0.65), "long opener must establish 0.65 Flow")

	_reset_operator(operator)
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"committed", 1.0)
	_assert(is_equal_approx(float(operator.get("_dodge_flow")), 1.0), "committed charged opener must establish maximum Flow")


func _validate_turn_retention(operator: Node) -> void:
	var retention_45 := float(operator.call("_flow_retention_for_turn", Vector2.RIGHT, Vector2.RIGHT.rotated(deg_to_rad(45.0))))
	var retention_90 := float(operator.call("_flow_retention_for_turn", Vector2.RIGHT, Vector2.UP))
	var retention_135 := float(operator.call("_flow_retention_for_turn", Vector2.RIGHT, Vector2.RIGHT.rotated(deg_to_rad(135.0))))
	var retention_180 := float(operator.call("_flow_retention_for_turn", Vector2.RIGHT, Vector2.LEFT))
	_assert(is_equal_approx(retention_45, 1.0), "45-degree continuation must retain all Flow")
	_assert(is_equal_approx(retention_90, 0.75), "90-degree redirect must retain 75 percent Flow")
	_assert(is_equal_approx(retention_135, 0.40), "135-degree cut must retain 40 percent Flow")
	_assert(is_zero_approx(retention_180), "reverse must break Flow")


func _validate_input_buffer_window(operator: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"tap")
	operator.set("_dodge_timer", float(operator.get("_active_dodge_duration")) - 0.05)
	Input.action_release("dodge")
	await process_frame
	Input.action_press("dodge")
	operator.call("_handle_dodge_input", 0.0)
	_assert(not bool(operator.get("_dodge_chain_buffered")), "press before 0.10 seconds must not buffer a chain")
	_assert(not bool(operator.get("_dodge_charge_active")), "dodge press during active movement must never begin another charge")
	Input.action_release("dodge")
	await process_frame
	operator.set("_dodge_timer", float(operator.get("_active_dodge_duration")) - 0.12)
	Input.action_press("dodge")
	operator.call("_handle_dodge_input", 0.0)
	_assert(bool(operator.get("_dodge_chain_buffered")), "press during the latter active half must buffer a chain")
	_assert(not bool(operator.get("_dodge_charge_active")), "held chain input must be treated as a tap continuation")
	Input.action_release("dodge")


func _validate_charged_chain_and_redirect(operator: Node) -> void:
	_reset_operator(operator)
	_chain_started_events.clear()
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"committed", 1.0)
	var stamina_after_opener := float(operator.get("stamina"))
	_assert(bool(operator.call("_buffer_dodge_chain", Vector2.RIGHT, &"smoke")), "active dodge must accept a buffered chain")
	operator.call("_update_dodge", 1.0)
	_assert(bool(operator.get("_dodge_active")), "buffered chain must launch at active completion")
	_assert(operator.get("_active_dodge_profile") == &"chain", "chain link must use the explicit chain profile")
	_assert(int(operator.get("_dodge_chain_index")) == 1, "first continuation must be chain index one")
	_assert(is_equal_approx(float(operator.get("_dodge_flow")), 1.0), "same-direction link must preserve maximum Flow")
	_assert(is_equal_approx(float(operator.get("stamina")), stamina_after_opener - 16.0), "ordinary chain link must cost 16 stamina")
	_assert(is_equal_approx(float(operator.get("_dodge_iframe_timer")), float(operator.get("dodge_iframe_duration"))), "Flow must not extend the iframe clock")
	_assert(is_equal_approx(float(operator.get("_active_dodge_speed")), float(operator.get("dodge_speed")) * 1.12), "maximum Flow chain must gain 12 percent peak speed")
	_assert(is_equal_approx(float(operator.get("_active_dodge_recovery_duration")), float(operator.get("dodge_recovery_duration")) * 0.65), "maximum Flow chain must reduce recovery by 35 percent")
	var end_factor := float(operator.call("_get_dodge_flow_end_speed_factor", 1.0))
	var integrated_distance_ratio := 1.12 * ((1.0 + end_factor) * 0.5) / ((1.0 + 0.45) * 0.5)
	_assert(is_equal_approx(integrated_distance_ratio, 1.18), "maximum Flow velocity curve must produce 18 percent travel gain")
	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert(body.frame == 2, "clean chain must enter the existing atlas at frame two")

	operator.call("_buffer_dodge_chain", Vector2.UP, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(int(operator.get("_dodge_chain_index")) == 2, "redirect must continue the same movement sequence")
	_assert(is_equal_approx(float(operator.get("_dodge_flow")), 0.75), "90-degree redirect must spend one quarter of Flow")
	_assert(is_equal_approx(float(operator.get("_dodge_chain_last_turn_angle")), 90.0), "redirect telemetry must retain the turn angle")
	_assert(is_equal_approx(float(operator.get("_dodge_chain_last_retention")), 0.75), "redirect telemetry must retain the multiplier")
	_assert(body.frame == 1, "90-degree redirect must re-enter the atlas at frame one")
	_assert(_chain_started_events.size() == 2, "each successful continuation must emit one chain-start signal")


func _validate_reverse_break(operator: Node) -> void:
	operator.call("_buffer_dodge_chain", Vector2.DOWN, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(int(operator.get("_dodge_chain_index")) == 3, "reverse pivot remains a legal uncapped chain link")
	_assert(is_zero_approx(float(operator.get("_dodge_flow"))), "reverse pivot must clear Flow")
	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert(body.frame == 0, "reverse pivot must replay the full plant frame")


func _validate_late_grace(operator: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 100.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"tap")
	operator.call("_update_dodge", 1.0)
	_assert(bool(operator.get("_dodge_recovery_active")), "unbuffered opener must enter recovery")
	operator.call("_update_dodge_recovery", 0.05)
	_assert(float(operator.get("_dodge_recovery_elapsed")) <= float(operator.get("dodge_chain_late_grace")), "test input must remain inside late grace")
	operator.call("_buffer_dodge_chain", Vector2.UP, &"late_grace")
	_assert(bool(operator.call("_launch_buffered_dodge_chain")), "late-grace input must cancel recovery into a chain")
	_assert(bool(operator.get("_dodge_active")) and not bool(operator.get("_dodge_recovery_active")), "late chain must return directly to active movement")
	_assert(is_zero_approx(float(operator.get("_dodge_cooldown_remaining"))), "late chain must clear the provisional final-link cooldown")


func _validate_exit_carry_and_decay(operator: Node) -> void:
	operator.call("_update_dodge", 1.0)
	_assert(bool(operator.get("_dodge_recovery_active")), "final link must enter recovery when no chain is buffered")
	_assert(float(operator.get("_dodge_cooldown_remaining")) >= float(operator.get("dodge_cooldown")), "ordinary cooldown must begin only after the final active link")
	var flow_before_exit := float(operator.get("_dodge_flow"))
	operator.call("_update_dodge_recovery", 1.0)
	_assert(not bool(operator.get("_dodge_recovery_active")), "final recovery must complete")
	_assert(float(operator.get("_dodge_exit_timer")) > 0.0, "chain termination must create authored exit carry")
	var expected_exit_speed := 150.0 * lerpf(1.0, 1.45, flow_before_exit)
	_assert(is_equal_approx((operator.get("_dodge_exit_velocity") as Vector2).length(), expected_exit_speed), "exit carry speed must derive from retained Flow")
	_assert(is_equal_approx((operator.get("velocity") as Vector2).length(), expected_exit_speed), "exit carry must take movement ownership without a neutral stop")
	operator.set("_dodge_exit_timer", 0.0)
	operator.set("_dodge_flow_decay_timer", 0.0)
	operator.call("_update_dodge_flow_decay", 0.10)
	_assert(float(operator.get("_dodge_flow")) < flow_before_exit, "Flow must decay after exit carry and its delay")
	_assert(not _chain_ended_events.is_empty(), "completed chain must emit one termination signal")


func _validate_stamina_constraint(operator: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 26.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"committed", 1.0)
	_assert(is_zero_approx(float(operator.get("stamina"))), "committed opener setup must consume remaining stamina")
	operator.call("_buffer_dodge_chain", Vector2.RIGHT, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(not bool(operator.get("_dodge_active")), "chain without stamina must not launch")
	_assert(bool(operator.get("_dodge_recovery_active")), "rejected chain must continue into ordinary recovery")
	_assert(operator.get("_dodge_chain_end_reason") == &"insufficient_stamina", "stamina rejection must become the termination reason")


func _reset_operator(operator: Node) -> void:
	operator.call("_cancel_dodge")
	operator.call("_clear_attack_buffer")
	operator.set("_dodge_cooldown_remaining", 0.0)
	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.set("_melee_active", false)
	operator.set("_melee_heavy_anticipating", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)


func _on_chain_started(index: int, flow: float, direction: Vector2) -> void:
	_chain_started_events.append({"index": index, "flow": flow, "direction": direction})


func _on_chain_ended(count: int, flow: float, reason: StringName) -> void:
	_chain_ended_events.append({"count": count, "flow": flow, "reason": reason})


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
