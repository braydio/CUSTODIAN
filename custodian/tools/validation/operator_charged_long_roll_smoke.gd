extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	world.name = "OperatorChargedLongRollSmoke"
	get_root().add_child(world)
	current_scene = world
	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	await process_frame

	_assert(operator.call("_get_dodge_profile_for_hold", 0.05) == &"tap", "short release must select tap")
	_assert(operator.call("_get_dodge_profile_for_hold", 0.12) == &"long", "long threshold must select long")
	_assert(operator.call("_get_dodge_profile_for_hold", 0.30) == &"committed", "committed threshold must select committed")
	_assert(operator.call("_get_dodge_profile_for_hold", 2.0) == &"committed", "hold time must clamp to committed")

	_validate_profile(operator, &"tap", 1.0, 1.0, 16.0)
	_validate_profile(operator, &"long", 1.30, 1.25, 20.0)
	_validate_profile(operator, &"committed", 1.55, 1.60, 26.0)
	_validate_charge_vulnerability(operator)
	await _validate_tap_release_input(operator)
	await _validate_hold_release_input(operator)

	operator.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[OperatorChargedLongRollSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[OperatorChargedLongRollSmoke] %s" % error)
	quit(1)


func _validate_profile(operator: Node, profile: StringName, speed_multiplier: float, recovery_multiplier: float, stamina_cost: float) -> void:
	_reset_dodge(operator)
	var stamina_before := 100.0
	operator.set("stamina", stamina_before)
	var started := bool(operator.call("_try_start_dodge_with_profile", Vector2.RIGHT, profile))
	_assert(started, "%s profile should start" % String(profile))
	_assert(operator.get("_active_dodge_profile") == profile, "%s profile identity should remain active" % String(profile))
	_assert(is_equal_approx(float(operator.get("_active_dodge_speed")), float(operator.get("dodge_speed")) * speed_multiplier), "%s speed multiplier should match" % String(profile))
	_assert(is_equal_approx(float(operator.get("_dodge_iframe_timer")), float(operator.get("dodge_iframe_duration"))), "%s must not extend iframes" % String(profile))
	_assert(is_equal_approx(float(operator.get("_active_dodge_recovery_duration")), float(operator.get("dodge_recovery_duration")) * recovery_multiplier), "%s recovery multiplier should match" % String(profile))
	_assert(is_equal_approx(float(operator.get("stamina")), stamina_before - stamina_cost), "%s stamina cost should match" % String(profile))
	if profile != &"tap":
		operator.set("combat_loadout_mode", "melee")
		operator.set("primary_weapon_equipped", false)
		operator.set("using_unarmed", true)
		operator.call("_try_melee_attack", "unarmed_fast")
		_assert(not bool(operator.get("_dodge_fast_attack_buffered")), "%s must not use tap roll-exit cancellation" % String(profile))
		_assert(String(operator.get("_buffered_attack_kind")) == "fast", "%s attack should wait in the ordinary buffer" % String(profile))
		operator.call("_update_dodge", 1.0)
		_assert(bool(operator.get("_dodge_recovery_active")), "%s should enter its committed recovery" % String(profile))
		operator.call("_update_dodge_recovery", 1.0)
		_assert(not bool(operator.get("_dodge_recovery_active")), "%s recovery should complete" % String(profile))
		_assert(String(operator.get("_buffered_attack_kind")).is_empty(), "%s buffered attack should be consumed only after recovery" % String(profile))


func _validate_charge_vulnerability(operator: Node) -> void:
	_reset_dodge(operator)
	operator.set("stamina", 100.0)
	_assert(bool(operator.call("_begin_dodge_charge")), "charge should begin from neutral")
	operator.set("_dodge_charge_timer", 0.20)
	_assert(not bool(operator.call("is_dodge_invulnerable")), "charge must not grant invulnerability")
	_assert(operator.call("get_dodge_telemetry_phase") == &"windup", "charge should report the windup telemetry phase")
	operator.call("receive_enemy_hit", 0.0, &"test")
	_assert(not bool(operator.get("_dodge_charge_active")), "incoming hit should cancel charge")


func _validate_hold_release_input(operator: Node) -> void:
	_reset_dodge(operator)
	operator.set("stamina", 100.0)
	Input.action_release("dodge")
	await process_frame
	Input.action_press("dodge")
	operator.call("_handle_dodge_input", 0.0)
	_assert(bool(operator.get("_dodge_charge_active")), "dodge press should begin charge detection")
	operator.call("_handle_dodge_input", 0.32)
	Input.action_release("dodge")
	operator.call("_handle_dodge_input", 0.0)
	_assert(bool(operator.get("_dodge_active")), "release should execute a dodge")
	_assert(operator.get("_active_dodge_profile") == &"committed", "0.32 second hold should execute committed roll")
	Input.action_release("dodge")


func _validate_tap_release_input(operator: Node) -> void:
	_reset_dodge(operator)
	operator.set("stamina", 100.0)
	Input.action_release("dodge")
	await process_frame
	Input.action_press("dodge")
	operator.call("_handle_dodge_input", 0.0)
	Input.action_release("dodge")
	operator.call("_handle_dodge_input", 0.0)
	_assert(bool(operator.get("_dodge_active")), "tap release should execute a dodge")
	_assert(operator.get("_active_dodge_profile") == &"tap", "short press/release should preserve tap dodge")
	Input.action_release("dodge")


func _reset_dodge(operator: Node) -> void:
	operator.call("_cancel_dodge")
	operator.call("_clear_attack_buffer")
	operator.set("_dodge_cooldown_remaining", 0.0)
	operator.set("_melee_active", false)
	operator.set("_melee_heavy_anticipating", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
