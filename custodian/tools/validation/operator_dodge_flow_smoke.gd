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
	_validate_traversal_dodge_is_free(operator)
	_validate_combat_pressure_dodge_fatigue(operator)

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
	_assert(is_equal_approx(float(operator.get("stamina")), stamina_after_opener), "traversal (out-of-combat) chain link must remain free -- 0 stamina")
	_assert(is_equal_approx(float(operator.get("_dodge_iframe_timer")), float(operator.get("dodge_iframe_duration"))), "Flow must not extend the iframe clock")
	_assert(is_equal_approx(float(operator.get("_active_dodge_speed")), float(operator.get("dodge_speed")) * 1.12), "maximum Flow chain must gain 12 percent peak speed")
	_assert(is_equal_approx(float(operator.get("_active_dodge_recovery_duration")), float(operator.get("dodge_recovery_duration")) * 0.65), "maximum Flow chain must reduce recovery by 35 percent")
	var end_factor := float(operator.call("_get_dodge_flow_end_speed_factor", 1.0))
	var integrated_distance_ratio := 1.12 * ((1.0 + end_factor) * 0.5) / ((1.0 + 0.45) * 0.5)
	_assert(is_equal_approx(integrated_distance_ratio, 1.18), "maximum Flow velocity curve must produce 18 percent travel gain")
	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert(body.animation == &"operator_dodge_chain_link_right", "clean chain must use the dedicated directional link")
	_assert(body.frame == 0, "clean chain must restart dedicated link art at frame zero")
	_assert(is_equal_approx(body.sprite_frames.get_animation_speed(body.animation) * body.speed_scale, 20.0), "four-frame link must complete over the fixed 0.20-second active clock")

	operator.call("_buffer_dodge_chain", Vector2.UP, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(int(operator.get("_dodge_chain_index")) == 2, "redirect must continue the same movement sequence")
	_assert(is_equal_approx(float(operator.get("_dodge_flow")), 0.75), "90-degree redirect must spend one quarter of Flow")
	_assert(is_equal_approx(float(operator.get("_dodge_chain_last_turn_angle")), 90.0), "redirect telemetry must retain the turn angle")
	_assert(is_equal_approx(float(operator.get("_dodge_chain_last_retention")), 0.75), "redirect telemetry must retain the multiplier")
	_assert(String(body.animation).begins_with("operator_dodge_chain_link"), "90-degree redirect must use dedicated link art")
	_assert(body.frame == 0, "back-to-back links must restart at frame zero without exposing neutral")
	_assert(_chain_started_events.size() == 2, "each successful continuation must emit one chain-start signal")


func _validate_reverse_break(operator: Node) -> void:
	operator.call("_buffer_dodge_chain", Vector2.DOWN, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(int(operator.get("_dodge_chain_index")) == 3, "reverse pivot remains a legal uncapped chain link")
	_assert(is_zero_approx(float(operator.get("_dodge_flow"))), "reverse pivot must clear Flow")
	var body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert(String(body.animation).begins_with("operator_dodge_full"), "reverse pivot must retain the full-dodge atlas")
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
	# Stamina can only meaningfully gate a dodge under combat pressure --
	# traversal dodges are free (see _validate_traversal_dodge_is_free).
	_set_combat_pressure(operator, true)
	_reset_operator(operator)
	operator.set("stamina", 26.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"committed", 1.0)
	_assert(is_zero_approx(float(operator.get("stamina"))), "committed opener setup must consume remaining stamina under combat pressure")
	operator.call("_buffer_dodge_chain", Vector2.RIGHT, &"smoke")
	operator.call("_update_dodge", 1.0)
	_assert(not bool(operator.get("_dodge_active")), "chain without stamina must not launch")
	_assert(bool(operator.get("_dodge_recovery_active")), "rejected chain must continue into ordinary recovery")
	_assert(operator.get("_dodge_chain_end_reason") == &"insufficient_stamina", "stamina rejection must become the termination reason")
	_set_combat_pressure(operator, false)


## Combat tempo pass: traversal (out-of-combat) dodge chains remain free,
## regardless of chain link index -- only combat pressure activates the
## escalating fatigue schedule.
func _validate_traversal_dodge_is_free(operator: Node) -> void:
	_set_combat_pressure(operator, false)
	_reset_operator(operator)
	operator.set("stamina", 40.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"tap")
	_assert(is_equal_approx(float(operator.get("stamina")), 40.0), "traversal opener must be free")
	for _link in range(3):
		operator.call("_buffer_dodge_chain", Vector2.RIGHT, &"smoke")
		operator.call("_update_dodge", 1.0)
	_assert(is_equal_approx(float(operator.get("stamina")), 40.0), "traversal chain links must stay free regardless of chain length")
	_assert(is_equal_approx(float(operator.get("_dodge_iframe_timer")), float(operator.get("dodge_iframe_duration"))), "traversal iframe duration must stay flat regardless of chain length")


## Combat tempo pass: under combat pressure, stamina cost escalates per
## link (16/20/26/34+), iframe duration shrinks per link (0.16/0.135/
## 0.115/0.10+), and long-chain terminal recovery is pulled toward the
## combat ceiling instead of the traversal -35% reduction reward.
func _validate_combat_pressure_dodge_fatigue(operator: Node) -> void:
	_set_combat_pressure(operator, true)
	_reset_operator(operator)
	operator.set("stamina", 200.0)
	operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, &"committed", 1.0)
	var stamina_after_opener := float(operator.get("stamina"))

	var expected_costs := [20.0, 26.0, 34.0, 34.0]
	var expected_iframes := [0.135, 0.115, 0.10, 0.10]
	var stamina_before := stamina_after_opener
	for link_index in range(expected_costs.size()):
		operator.call("_buffer_dodge_chain", Vector2.RIGHT, &"smoke")
		operator.call("_update_dodge", 1.0)
		var stamina_now := float(operator.get("stamina"))
		_assert(
			is_equal_approx(stamina_before - stamina_now, expected_costs[link_index]),
			"combat-pressure chain link %d must cost %.1f stamina, cost was %.1f" % [link_index + 1, expected_costs[link_index], stamina_before - stamina_now]
		)
		_assert(
			is_equal_approx(float(operator.get("_dodge_iframe_timer")), expected_iframes[link_index]),
			"combat-pressure chain link %d iframe duration must be %.3f, was %.3f" % [link_index + 1, expected_iframes[link_index], float(operator.get("_dodge_iframe_timer"))]
		)
		stamina_before = stamina_now

	# Long chain at (near-)maximum Flow: recovery must be pulled toward the
	# combat ceiling, not reduced toward the traversal -35% floor.
	var recovery := float(operator.get("_active_dodge_recovery_duration"))
	_assert(
		recovery >= 0.18 - 0.01 and recovery <= 0.22 + 0.01,
		"long combat-pressure chain terminal recovery must be within 0.18-0.22s, was %.3f" % recovery
	)

	# Exit carry must be capped under combat pressure.
	operator.call("_update_dodge", 1.0)
	operator.call("_update_dodge_recovery", 1.0)
	var flow_before_exit := float(operator.get("_dodge_flow"))
	_assert(float(operator.get("_dodge_exit_timer")) <= 0.12 + 0.001, "combat-pressure exit carry duration must be capped at ~0.12s")
	var expected_exit_speed := 150.0 * lerpf(1.0, 1.25, flow_before_exit)
	_assert(
		is_equal_approx((operator.get("_dodge_exit_velocity") as Vector2).length(), expected_exit_speed),
		"combat-pressure exit carry speed must cap at ~1.25x instead of the traversal 1.45x"
	)
	_set_combat_pressure(operator, false)


func _set_combat_pressure(operator: Node, active: bool) -> void:
	var tracker = operator.get("_engagement_tracker")
	if tracker != null:
		tracker.set("engagement_active", active)


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
