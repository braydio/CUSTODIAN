extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")

class DummyTarget:
	extends CharacterBody2D

	var hits: Array[Dictionary] = []
	var result_mode: StringName = &"damaged"
	var falcon_impacts: int = 0

	func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy", _attacker: Node2D = null, _hit_direction: Vector2 = Vector2.ZERO) -> Dictionary:
		var result := {
			"result": result_mode,
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": result_mode == &"parried",
			"applied_damage": 0.0 if result_mode == &"parried" else amount,
		}
		hits.append(result)
		return result

	func apply_enemy_falcon_punch_impact(_direction: Vector2, _knockback_px: float, _victim_hitstop_sec: float) -> void:
		falcon_impacts += 1


var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")
	var scene_root := Node2D.new()
	scene_root.name = "GruntFalconPunchSmokeRoot"
	get_root().add_child(scene_root)
	current_scene = scene_root

	var grunt := GRUNT_SCENE.instantiate()
	scene_root.add_child(grunt)
	var target := DummyTarget.new()
	target.name = "DummyPlayer"
	target.add_to_group("player")
	target.global_position = Vector2(112.0, 0.0)
	scene_root.add_child(target)
	await process_frame
	grunt.set_physics_process(false)
	_assert_near(float(grunt.get("grunt_falcon_punch_windup_time")), 0.46, 0.001, "live grunt should use the longer Falcon tell")
	_assert_near(float(grunt.get("grunt_falcon_punch_recovery_time")), 0.70, 0.001, "live grunt should use the longer punish recovery")
	_assert_near(float(grunt.get("grunt_falcon_punch_recovery_speed")), 0.0, 0.001, "live grunt recovery should have zero forward drift")
	_assert_near(float(grunt.get("grunt_falcon_punch_stop_short_px")), 30.0, 0.001, "live grunt should target a stop-short contact point")

	grunt.global_position = Vector2.ZERO
	grunt.set("target", target)
	grunt.set("grunt_falcon_punch_enabled", true)
	grunt.set("grunt_falcon_punch_windup_time", 0.02)
	grunt.set("grunt_falcon_punch_leap_time", 0.20)
	grunt.set("grunt_falcon_punch_impact_lock_time", 0.01)
	grunt.set("grunt_falcon_punch_recovery_time", 0.04)
	grunt.set("grunt_falcon_punch_distance_px", 120.0)
	grunt.set("grunt_falcon_punch_cooldown", 0.0)
	grunt.set("grunt_falcon_punch_chance", 1.0)
	grunt.set("grunt_falcon_punch_after_normal_attacks_min", 0)
	grunt.set("grunt_falcon_punch_victim_hitstop", 0.0)
	grunt.set("grunt_falcon_punch_attacker_hitstop", 0.0)
	grunt.set("_grunt_falcon_punch_decision_credit", 1.0)

	_assert_true(bool(grunt.call("_attack_grunt_falcon_punch_target", 0.016)), "grunt should start falcon-punch attack in launch band")
	var body_sprite := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "windup", "falcon punch should start in windup")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_windup_e", "windup should use special_windup_e")

	grunt.call("_update_grunt_falcon_punch_attack", 0.03)
	await process_frame
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "leap", "falcon punch should advance to leap")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_inflight_e", "leap should use special_inflight_e")
	_assert_true(float(grunt.get("_grunt_falcon_punch_current_distance")) < 120.0, "falcon punch should stop short of the target center")

	target.global_position = grunt.global_position + Vector2(24.0, 0.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.12)
	await process_frame
	_assert_true(target.hits.size() == 1, "falcon punch should resolve one hit")
	_assert_true(String(target.hits[0].get("hit_kind", "")) == "falcon_punch", "falcon punch hit should preserve hit_kind")
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "impact_lock", "resolved hit should enter impact lock")
	_assert_true(target.falcon_impacts == 1, "damaging falcon punch should trigger dedicated Operator impact")
	_assert_true(grunt.global_position.distance_to(target.global_position) >= 27.9, "falcon contact should preserve minimum body separation")

	grunt.call("_update_grunt_falcon_punch_attack", 0.02)
	await process_frame
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "recovery", "impact lock should enter recovery")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_recovery_e", "recovery should use special_recovery_e")
	_assert_true((grunt.get("velocity") as Vector2).is_zero_approx(), "falcon recovery must not drift forward")

	grunt.call("_update_grunt_falcon_punch_attack", 0.06)
	await process_frame
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")).is_empty(), "recovery should finish the special attack")

	# A parried result must cancel the entire attack even when the target stub does not call back into Enemy.
	var impact_events_before_parry := 0
	if observatory != null:
		impact_events_before_parry = (observatory.call("get_recent_events", 100, &"grunt_falcon_punch_impact_lock") as Array).size()
	target.result_mode = &"parried"
	target.global_position = Vector2(100.0, 0.0)
	grunt.global_position = Vector2.ZERO
	grunt.set("_grunt_falcon_punch_decision_credit", 1.0)
	_assert_true(bool(grunt.call("_attack_grunt_falcon_punch_target", 0.016)), "parry scenario should start falcon punch")
	grunt.call("_start_grunt_falcon_punch_leap")
	target.global_position = grunt.global_position + Vector2(20.0, 0.0)
	grunt.set("_grunt_falcon_punch_timer", 0.10)
	grunt.call("_try_apply_grunt_falcon_punch_hit")
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")).is_empty(), "parry should hard-cancel falcon punch")
	_assert_true(float(grunt.get("_grunt_falcon_punch_recent_parry_timer")) > 0.0, "parry should start the special lockout")
	if observatory != null:
		var impact_events_after_parry := (observatory.call("get_recent_events", 100, &"grunt_falcon_punch_impact_lock") as Array).size()
		_assert_true(impact_events_after_parry == impact_events_before_parry, "parried Falcon Punch must not emit normal impact lock")
		_assert_true(int(observatory.get("counters").get("falcon_punch_parried", 0)) == 1, "Falcon parry counter should increment once")
	grunt.set("_grunt_falcon_punch_decision_credit", 1.0)
	target.global_position = grunt.global_position + Vector2(100.0, 0.0)
	_assert_true(not bool(grunt.call("_should_start_grunt_falcon_punch_now", target)), "recent parry should block immediate re-falcon")

	# An ally occupying the forward corridor blocks the special, without blocking ordinary pathing.
	grunt.set("_grunt_falcon_punch_recent_parry_timer", 0.0)
	grunt.set("_grunt_falcon_punch_cooldown_timer", 0.0)
	grunt.set("_grunt_falcon_punch_normal_attacks_since_special", 1)
	grunt.set("_grunt_falcon_punch_decision_credit", 1.0)
	grunt.global_position = Vector2.ZERO
	target.result_mode = &"damaged"
	target.global_position = Vector2(120.0, 0.0)
	var ally_blocker := Node2D.new()
	ally_blocker.name = "AllyLaneBlocker"
	ally_blocker.add_to_group("enemy")
	ally_blocker.global_position = Vector2(55.0, 8.0)
	scene_root.add_child(ally_blocker)
	_assert_true(not bool(grunt.call("_is_grunt_falcon_punch_lane_clear", target)), "ally in launch lane should block falcon punch")
	ally_blocker.global_position = Vector2(18.0, 8.0)
	_assert_true((grunt.call("_get_enemy_separation_vector", 34.0) as Vector2).length_squared() > 0.0, "nearby enemy should contribute movement separation")
	ally_blocker.queue_free()
	await process_frame
	_assert_true(bool(grunt.call("_is_grunt_falcon_punch_lane_clear", target)), "clear launch lane should allow falcon punch consideration")
	grunt.set("grunt_falcon_punch_after_normal_attacks_min", 1)
	grunt.set("_grunt_falcon_punch_normal_attacks_since_special", 0)
	grunt.set("_grunt_falcon_punch_decision_credit", 0.0)
	_assert_true(not bool(grunt.call("_should_start_grunt_falcon_punch_now", target)), "falcon punch should require normal melee pressure first")
	grunt.call("_start_attack_windup", 13.0, false)
	_assert_true(bool(grunt.call("_should_start_grunt_falcon_punch_now", target)), "normal melee pressure should advance deterministic Falcon eligibility")

	# A terminal leap without a hit goes directly to recovery and records why.
	grunt.call("_clear_pending_attack_context")
	grunt.set("_grunt_falcon_punch_recent_parry_timer", 0.0)
	grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
	grunt.call("_start_grunt_falcon_punch_leap")
	grunt.call("_resolve_grunt_falcon_punch_whiff", &"target_out_of_range")
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "recovery", "Falcon whiff should skip successful impact lock")
	if observatory != null:
		_assert_true(int(observatory.get("counters").get("falcon_punch_whiffed", 0)) == 1, "Falcon whiff counter should identify terminal miss")
		_assert_true(int(observatory.get("counters").get("enemy_attack_whiffed_out_of_range", 0)) == 1, "Falcon range whiff should expose reason counter")

	if _failed:
		push_error("grunt_falcon_punch_smoke failed")
		quit(1)
		return
	print("[GruntFalconPunchSmoke] stop-short, separation, impact, parry lockout, lane gate, and zero-drift recovery resolved.")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)


func _assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	_assert_true(absf(actual - expected) <= tolerance, "%s (expected %.3f, got %.3f)" % [message, expected, actual])
