extends SceneTree

const DodgeController := preload("res://game/actors/operator/traversal/operator_dodge_controller.gd")

var _errors: Array[String] = []
var _cancel_reasons: Array[StringName] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller := DodgeController.new()
	controller.charge_cancelled.connect(func(reason: StringName) -> void: _cancel_reasons.append(reason))
	var tuning := _test_tuning()

	_assert(bool(controller.begin_charge(Vector2.RIGHT).get("started")), "charge should begin when traversal is idle")
	controller.advance_charge(0.24, 0.60, 0.30)
	var release := controller.release_charge(0.60, 0.12, 0.30, 0.30)
	_assert(bool(release.get("released")), "charge should release exactly once")
	_assert(release.get("profile") == &"long", "hold between long and committed thresholds must select long roll")
	_assert(is_equal_approx(float(release.get("hold_time", -1.0)), 0.24), "release must report controller-owned hold time")
	_assert(not controller.is_charging(), "release must clear charge state")

	controller.begin_charge(Vector2.UP)
	var cancelled := controller.cancel_charge(&"incoming_hit", 0.30)
	_assert(bool(cancelled.get("cancelled")), "explicit interruption should cancel charge")
	_assert(_cancel_reasons == [&"incoming_hit"], "controller must publish the exact cancellation reason")
	_assert(not controller.is_busy(), "cancelled charge must release the traversal lock")

	var started := controller.start_dodge(Vector2.RIGHT, &"committed", 1.0, true, 100.0, false, tuning)
	_assert(bool(started.get("started")), "controller should start a committed dodge")
	_assert(is_equal_approx(float(started.get("stamina_cost", 0.0)), 26.0), "committed dodge must retain authored stamina cost")
	controller.advance_clocks(0.05)
	_assert(is_equal_approx(controller.get_iframe_remaining(), 0.11), "fixed-step clock advancement must remain controller-owned")
	var active := controller.advance_active(0.20, tuning)
	_assert(bool(active.get("ended")), "active clock should produce an explicit recovery transition")
	var recovery := controller.begin_recovery(0.42)
	_assert(controller.is_recovering(), "completed active movement should enter recovery")
	_assert(is_equal_approx(float(recovery.get("duration", 0.0)), 0.256), "committed opener recovery multiplier must remain intact")
	controller.cancel(&"impact", true, tuning)
	_assert(not controller.is_busy() and not controller.is_iframe_active(), "impact cancellation must clear traversal and iframe state")
	_assert(is_zero_approx(controller.get_flow_value()), "impact cancellation must clear Flow")

	if _errors.is_empty():
		print("[OperatorDodgeControllerSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[OperatorDodgeControllerSmoke] %s" % error)
	quit(1)


func _test_tuning() -> Dictionary:
	return {
		"speed": 480.0,
		"duration": 0.20,
		"iframe_duration": 0.16,
		"recovery_duration": 0.16,
		"cooldown": 0.42,
		"stamina_cost": 16.0,
		"long_distance_multiplier": 1.15,
		"committed_distance_multiplier": 1.30,
		"long_recovery_multiplier": 1.25,
		"committed_recovery_multiplier": 1.60,
		"long_stamina_cost": 20.0,
		"committed_stamina_cost": 26.0,
		"flow_decay_delay": 0.22,
		"flow_decay_per_second": 1.8,
		"flow_speed_bonus": 0.12,
		"flow_distance_bonus": 0.18,
		"flow_recovery_reduction": 0.35,
		"exit_carry_duration": 0.18,
		"combat_chain_stamina_costs": PackedFloat32Array([16.0, 20.0, 26.0, 34.0]),
		"combat_chain_iframe_durations": PackedFloat32Array([0.16, 0.135, 0.115, 0.10]),
		"combat_recovery_ceiling": 0.20,
		"combat_exit_carry_speed_mult": 1.25,
		"combat_exit_carry_duration": 0.12,
		"base_speed": 150.0,
		"committed_min_hold": 0.30,
	}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
