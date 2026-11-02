extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CombatConstants := preload("res://game/systems/combat/combat_constants.gd")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorGuardFlowSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.aim_direction = Vector2.RIGHT
	operator.visual_idle_direction = Vector2.RIGHT
	var guard = operator.get_guard_controller()
	var config = operator.guard_config
	_assert_close(config.movement_multiplier, 0.60, 0.001, "guard movement multiplier")

	_assert_true(guard.start_guard(), "guard should enter from neutral")
	_assert_true(String(guard.phase_name()) == "guard_enter", "guard should expose GUARD_ENTER")
	guard.held_timer = config.full_activation_time
	guard.update_animation_state(true)
	_assert_true(guard.is_guard_fully_active(), "guard enter should reach GUARD_HOLD")

	operator.stamina = 100.0
	var light: Dictionary = operator.try_guard_incoming_attack(
		20.0, Vector2.LEFT, -1.0, CombatConstants.HitStrength.LIGHT
	)
	_assert_true(bool(light.get("blocked", false)), "light frontal hit should block")
	_assert_close(float(light.get("stamina_cost", 0.0)), 9.0, 0.01, "light posture cost")
	_assert_true(String(light.get("recoil", "")) == "light", "light hit should use LIGHT_RECOIL")
	guard.phase_timer = 0.0
	guard.update_animation_state(true)
	_assert_true(guard.is_guard_fully_active(), "light recoil should return to hold")

	var heavy: Dictionary = operator.try_guard_incoming_attack(
		20.0, Vector2.LEFT, -1.0, CombatConstants.HitStrength.HEAVY
	)
	_assert_close(float(heavy.get("stamina_cost", 0.0)), 21.0, 0.01, "heavy posture cost")
	_assert_true(String(heavy.get("recoil", "")) == "heavy", "heavy hit should use HEAVY_RECOIL")
	guard.phase_timer = 0.0
	guard.update_animation_state(true)

	operator.stamina = 100.0
	var guarded_falcon: Dictionary = operator.receive_enemy_hit(
		24.0, &"falcon_punch", "enemy", null, Vector2.LEFT, -1.0,
		{"hit_strength": CombatConstants.HitStrength.HEAVY}
	)
	_assert_true(bool(guarded_falcon.get("blocked", false)), "healthy guard should block Falcon")
	_assert_true(not bool(guarded_falcon.get("guard_broken", false)), "healthy guard should survive Falcon")
	guard.phase_timer = 0.0
	guard.update_animation_state(true)
	operator.stamina = 20.0
	var falcon_break: Dictionary = operator.receive_enemy_hit(
		24.0, &"falcon_punch", "enemy", null, Vector2.LEFT, -1.0,
		{"hit_strength": CombatConstants.HitStrength.HEAVY}
	)
	_assert_true(bool(falcon_break.get("blocked", false)), "low-stamina Falcon should still resolve as guarded")
	_assert_true(bool(falcon_break.get("guard_broken", false)), "low-stamina Falcon block should guard-break")
	_assert_close(operator.stamina, 0.0, 0.001, "guard break should collapse stamina")
	_assert_true(String(guard.phase_name()) == "guard_break", "guard break should be explicit")
	_assert_true(not guard.begin_parry(), "parry must be locked during guard break")
	_assert_true(not guard.start_guard(), "guard must be locked during break")
	guard.tick(config.break_impact_time + 0.01)
	_assert_true(String(guard.phase_name()) == "break_recovery", "break should enter recovery")
	guard.tick(config.break_recovery_time + 0.01)
	_assert_true(String(guard.phase_name()) == "neutral", "break recovery should return neutral")
	_assert_true(not guard.start_guard(), "guard re-raise remains locked after break recovery")
	guard.tick(config.reraise_lockout_time)
	guard.repress_required = false
	_assert_true(guard.start_guard(), "guard should re-raise after lockout and fresh input")

	guard.reset()
	operator.stamina = 100.0
	_assert_true(guard.begin_parry(), "parry should start from valid guard context")
	guard.tick(config.parry_windup_time + 0.001)
	_assert_true(guard.parry_active, "parry should enter active window")
	_assert_true(
		operator.try_parry_incoming_attack(null, Vector2.LEFT, {"damage": 10.0}),
		"frontal active parry should succeed"
	)
	_assert_true(String(guard.parry_phase_name()) == "success", "parry success should be explicit")

	guard.reset()
	guard.begin_parry()
	guard.tick(config.parry_windup_time + 0.001)
	guard.tick(config.parry_active_time + 0.001)
	_assert_true(not guard.parry_active, "missed parry should leave active window")
	_assert_true(String(guard.parry_phase_name()) == "recovery", "missed parry should recover")

	guard.reset()
	guard.start_guard()
	guard.held_timer = config.full_activation_time
	guard.update_animation_state(true)
	guard.release_guard()
	_assert_true(String(guard.phase_name()) == "guard_exit", "release should enter GUARD_EXIT")

	root.queue_free()
	await process_frame
	if not _failed:
		print("operator_guard_flow_smoke: PASS")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _assert_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	_assert_true(absf(actual - expected) <= tolerance, "%s expected=%.3f actual=%.3f" % [message, expected, actual])
