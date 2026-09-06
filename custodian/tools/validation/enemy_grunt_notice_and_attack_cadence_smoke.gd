extends SceneTree

## Combat tempo pass: baseline raider_grunt notice timing (item 6) and
## normal-melee attack cadence eligibility (item 7). Drives the behavior
## state machine and enemy attack-windup timers directly and deterministically
## rather than through full perception simulation.

const ENEMY_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")

var _failed := false


class DummyTarget:
	extends Node2D

	var hits := 0

	func _ready() -> void:
		add_to_group("player")

	func take_damage(amount: float, _hit_strength: int = 0, _reaction_damage: float = -1.0) -> Dictionary:
		hits += 1
		return {"applied_damage": amount, "eligible_hostile": true, "target_was_alive": true, "target_health_before": 100.0, "target_health_after": 100.0 - amount}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture := Node2D.new()
	fixture.name = "EnemyGruntCadenceSmokeRoot"
	root.add_child(fixture)
	current_scene = fixture

	_validate_notice_to_engage_timing(fixture)
	_validate_attack_cadence(fixture)

	fixture.queue_free()
	await process_frame
	if _failed:
		push_error("enemy_grunt_notice_and_attack_cadence_smoke failed")
		quit(1)
		return
	print("[EnemyGruntNoticeAndAttackCadenceSmoke] PASS")
	quit(0)


func _spawn_grunt(fixture: Node2D) -> CharacterBody2D:
	var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
	fixture.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.set_process(false)
	return enemy


func _validate_notice_to_engage_timing(fixture: Node2D) -> void:
	var enemy := _spawn_grunt(fixture)
	var bsm := enemy.get_node("EnemyBehaviorStateMachine")
	var operator_stub := Node2D.new()
	fixture.add_child(operator_stub)
	operator_stub.global_position = enemy.global_position + Vector2(50.0, 0.0)

	var notice_duration := float(bsm.get("notice_duration_sec"))
	_assert(
		notice_duration >= 0.18 and notice_duration <= 0.24,
		"baseline grunt notice duration must be within 0.18-0.24s, got %s" % notice_duration
	)

	bsm.call("force_notice", operator_stub)
	_assert(String(bsm.get("current_state")) == "notice", "force_notice() must enter NOTICE")

	var blackboard = bsm.get("blackboard")
	blackboard.target_visible = true

	# Just short of the configured duration: must remain in NOTICE.
	bsm.set("state_time", notice_duration - 0.02)
	bsm.call("_update_notice", enemy, 0.0)
	_assert(
		String(bsm.get("current_state")) == "notice",
		"must remain in NOTICE before the configured notice duration elapses"
	)

	# state_time is advanced by physics_update, not _update_notice itself --
	# drive it directly to deterministically simulate elapsed time.
	bsm.set("state_time", notice_duration + 0.001)
	bsm.call("_update_notice", enemy, 0.0)
	_assert(
		String(bsm.get("current_state")) == "engage_operator",
		"must reach ENGAGE_OPERATOR after the configured notice duration elapses"
	)

	enemy.queue_free()
	operator_stub.queue_free()


func _validate_attack_cadence(fixture: Node2D) -> void:
	var enemy := _spawn_grunt(fixture)
	var target := DummyTarget.new()
	fixture.add_child(target)
	target.global_position = enemy.global_position + Vector2(20.0, 0.0)
	enemy.set("target", target)

	var windup := float(enemy.get("attack_windup_duration"))
	var recovery := float(enemy.get("attack_recovery_duration"))
	var redecision := float(enemy.get("attack_redecision_delay_sec"))
	_assert(is_equal_approx(windup, 0.42), "grunt windup must remain the authored ~0.42s, got %s" % windup)
	_assert(is_equal_approx(recovery, 0.40), "grunt attack recovery must remain the authored ~0.40s, got %s" % recovery)
	_assert(
		redecision >= 0.20 and redecision <= 0.35,
		"post-recovery redecision delay must be within 0.20-0.35s, got %s" % redecision
	)

	_assert(
		bool(enemy.call("_is_baseline_melee_attack_eligible")),
		"a fresh grunt must be attack-eligible before its first attack"
	)
	enemy.call("behavior_attack_target")
	_assert(
		float(enemy.get("_attack_windup_timer")) > 0.0,
		"an eligible grunt must begin windup promptly once in range"
	)

	# Resolve the windup deterministically.
	var ticks := 0
	while float(enemy.get("_attack_windup_timer")) > 0.0 and ticks < 200:
		enemy.call("_update_attack_windup", 0.02)
		ticks += 1
	_assert(ticks < 200, "windup did not resolve within the expected number of ticks")

	# Immediately after resolve: recovery + redecision pending, must not
	# silently re-fire a second windup this same instant.
	_assert(
		not bool(enemy.call("_is_baseline_melee_attack_eligible")),
		"must not be attack-eligible immediately after an attack resolves"
	)
	enemy.call("behavior_attack_target")
	_assert(
		is_zero_approx(float(enemy.get("_attack_windup_timer"))),
		"must not begin a new windup while recovery/redecision is pending"
	)

	# Advance exactly through recovery, then redecision.
	enemy.call("_update_attack_recovery_and_redecision", recovery + 0.001)
	_assert(
		float(enemy.get("_attack_redecision_timer")) > 0.0,
		"redecision timer must begin once recovery completes"
	)
	_assert(
		not bool(enemy.call("_is_baseline_melee_attack_eligible")),
		"must still not be eligible during the redecision window"
	)
	enemy.call("_update_attack_recovery_and_redecision", redecision + 0.001)
	_assert(
		bool(enemy.call("_is_baseline_melee_attack_eligible")),
		"must become eligible again once recovery + redecision fully elapse"
	)

	enemy.call("behavior_attack_target")
	_assert(
		float(enemy.get("_attack_windup_timer")) > 0.0,
		"second attack must begin promptly once eligible again"
	)

	enemy.queue_free()
	target.queue_free()


func _assert(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
