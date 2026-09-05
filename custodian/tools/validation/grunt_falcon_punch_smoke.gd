extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")

class DummyTarget:
	extends CharacterBody2D

	var hits: Array[Dictionary] = []
	var attack_contexts: Array[Dictionary] = []
	var result_mode: StringName = &"damaged"
	var falcon_impacts: int = 0

	func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy", _attacker: Node2D = null, _hit_direction: Vector2 = Vector2.ZERO, _guard_cost: float = -1.0, attack_context: Dictionary = {}) -> Dictionary:
		var result := {
			"result": result_mode,
			"hit_kind": hit_kind,
			"dodged": result_mode == &"dodged",
			"blocked": result_mode == &"blocked",
			"parried": result_mode == &"parried",
			"applied_damage": amount if result_mode == &"damaged" else 0.0,
		}
		hits.append(result)
		attack_contexts.append(attack_context.duplicate(true))
		return result

	func apply_enemy_falcon_punch_impact(_direction: Vector2, _knockback_px: float, _victim_hitstop_sec: float) -> void:
		falcon_impacts += 1


class RejectingEngagementCoordinator:
	extends Node

	func reject(_target: Node2D, _hold_sec: float) -> bool:
		return false

	func release_committed_attack(_enemy: Node) -> void:
		pass


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
	var ability := grunt.get_grunt_falcon_punch_ability() as GruntFalconPunch
	var config := grunt.grunt_falcon_punch_config as GruntFalconPunchConfig
	_assert_true(ability != null, "grunt should expose its owned Falcon ability")
	_assert_true(config != null, "grunt should use typed Falcon configuration")
	var body_sprite := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_near(float(grunt.get("grunt_falcon_punch_windup_time")), 0.75, 0.001, "live grunt should use the longer Falcon tell")
	_assert_near(float(grunt.get("grunt_falcon_punch_tracking_lock_sec")), 0.25, 0.001, "live grunt should lock Falcon tracking for the final quarter-second")
	_assert_near(float(grunt.get("grunt_falcon_punch_recovery_time")), 0.70, 0.001, "live grunt should use the longer punish recovery")
	_assert_near(config.blocked_recovery_time, 0.75, 0.001, "blocked Falcon recovery")
	_assert_near(config.whiff_recovery_time, 0.85, 0.001, "dodged/whiffed Falcon recovery")
	_assert_near(config.collision_recovery_time, 0.95, 0.001, "collision Falcon recovery")
	_assert_near(config.committed_reach_buffer_px, 10.0, 0.001, "committed reach cushion")
	_assert_near(config.commitment_cue_time, 0.10, 0.001, "commitment cue duration")
	_assert_near(float(grunt.get("grunt_falcon_punch_recovery_speed")), 0.0, 0.001, "live grunt recovery should have zero forward drift")
	_assert_near(float(grunt.get("grunt_falcon_punch_stop_short_px")), 28.0, 0.001, "live grunt should target a stop-short contact point")
	_assert_near(float(grunt.get("grunt_falcon_punch_hit_forward_reach_px")), 42.0, 0.001, "live grunt should have practical forward contact grace")
	_assert_near(float(grunt.get("grunt_falcon_punch_hit_lateral_reach_px")), 30.0, 0.001, "live grunt should have practical lateral contact grace")
	for animation_name in [&"special_windup_e", &"special_windup_w"]:
		_assert_true(body_sprite.sprite_frames.get_frame_count(animation_name) == 6, "%s should retain six frames" % animation_name)
		_assert_near(body_sprite.sprite_frames.get_animation_speed(animation_name), 8.0, 0.0001, "%s should span the 0.75s windup" % animation_name)
	for animation_name in [&"special_inflight_e", &"special_inflight_w"]:
		_assert_true(body_sprite.sprite_frames.get_frame_count(animation_name) == 6, "%s should retain six frames" % animation_name)
		_assert_near(body_sprite.sprite_frames.get_animation_speed(animation_name), 21.428571, 0.0001, "%s should span the 0.28s leap" % animation_name)
	for animation_name in [&"special_recovery_e", &"special_recovery_w"]:
		_assert_true(body_sprite.sprite_frames.get_frame_count(animation_name) == 6, "%s should retain six frames" % animation_name)
		_assert_near(body_sprite.sprite_frames.get_animation_speed(animation_name), 8.571429, 0.0001, "%s should span the 0.70s recovery" % animation_name)
	for animation_name in [&"falcon_collision_e", &"falcon_collision_w"]:
		_assert_true(body_sprite.sprite_frames.get_frame_count(animation_name) == 4, "%s should retain four frames" % animation_name)
	for animation_name in [&"falcon_collision_knockdown_e", &"falcon_collision_knockdown_w"]:
		_assert_true(body_sprite.sprite_frames.get_frame_count(animation_name) == 8, "%s should retain eight frames" % animation_name)
	var fx_sprite := grunt.get_node_or_null("CustomEnemyFxSprite") as AnimatedSprite2D
	_assert_true(fx_sprite != null, "grunt should expose synchronized Falcon FX")
	if fx_sprite != null:
		_assert_true(fx_sprite.sprite_frames.get_frame_count(&"combat_falcon_inflight_fx_e") == 6, "Falcon inflight FX should retain six frames")

	grunt.global_position = Vector2.ZERO
	grunt.set("target", target)
	grunt.set("grunt_falcon_punch_enabled", true)
	grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
	target.global_position = Vector2(80.0, 80.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.20)
	var early_direction := ability.direction
	_assert_true(early_direction.y > 0.5, "early Falcon windup should still track target movement")
	target.global_position = Vector2(112.0, 0.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.31)
	_assert_true(ability.phase >= GruntFalconPunch.Phase.COMMITTED, "Falcon should lock when the final 0.25s commitment window begins")
	_assert_true(ability.commitment_cue_count == 1, "commitment cue should fire exactly once")
	_assert_near(ability.phase_timer, config.committed_time, 0.02, "presentation cue must not alter committed timing")
	var locked_direction := ability.committed_direction
	_assert_true(locked_direction.x > 0.9, "Falcon should capture its eastward direction at commitment")
	if observatory != null:
		_assert_true(int(observatory.get("counters").get("falcon_punch_tracking_locks", 0)) == 1, "Falcon tracking lock counter should increment exactly once")
	target.global_position = Vector2(-112.0, 0.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.10)
	_assert_true(ability.direction.is_equal_approx(locked_direction), "moving behind Falcon after commitment must not retarget it")
	_assert_true(String(body_sprite.animation) == "special_windup_e", "locked windup presentation should retain its committed direction")
	grunt.call("_update_grunt_falcon_punch_attack", 0.20)
	_assert_true(ability.get_phase_name() == &"leap", "committed Falcon should enter leap")
	_assert_true(ability.direction.is_equal_approx(locked_direction), "leap must use the locked direction")
	_assert_true(String(body_sprite.animation) == "special_inflight_e", "leap transition should atomically select its inflight presentation")
	if observatory != null:
		var leap_events := observatory.call("get_recent_events", 20, &"grunt_falcon_punch_leap") as Array
		var leap_data := (leap_events.back() as Dictionary).get("data", {}) as Dictionary if not leap_events.is_empty() else {}
		_assert_true(String(leap_data.get("presentation_animation", "")) == "special_inflight_e", "leap telemetry should report active inflight presentation")
		_assert_true(String(leap_data.get("expected_animation", "")) == "special_inflight_e", "leap telemetry should report expected inflight presentation")
		_assert_true(bool(leap_data.get("presentation_matches_phase", false)), "leap telemetry should confirm phase/presentation agreement")
		_assert_true(bool(leap_data.get("tracking_locked", false)), "leap telemetry should retain commitment state")
	grunt.call("_finish_grunt_falcon_punch_attack", &"debug_lock_test_complete")

	# Captured identity remains authoritative even when Enemy.target is replaced.
	var decoy := DummyTarget.new()
	decoy.name = "DecoyPlayer"
	decoy.add_to_group("player")
	decoy.global_position = Vector2(-160.0, 0.0)
	scene_root.add_child(decoy)
	grunt.target = target
	target.global_position = Vector2(112.0, 0.0)
	ability.start_debug(target, Vector2.RIGHT)
	ability.phase_timer = 0.0
	ability.tick(0.0)
	_assert_true(ability.get_phase_name() == &"committed", "successful token claim should enter explicit committed phase")
	grunt.target = decoy
	ability.tick(config.committed_time + 0.01)
	_assert_true(ability.get_phase_name() == &"leap", "committed Falcon should launch")
	_assert_true(ability.target_id == target.get_instance_id(), "Falcon target identity must not follow Enemy.target replacement")
	_assert_true(ability.direction.x > 0.9, "captured Falcon must retain its original eastward commitment")
	ability.finish(&"captured_target_test")
	decoy.queue_free()

	# A denied token cannot leave Falcon sitting forever at a zero timer.
	var coordinator := RejectingEngagementCoordinator.new()
	root.add_child(coordinator)
	ability.engagement_token_request = Callable(coordinator, "reject")
	grunt.target = target
	ability.start_debug(target, Vector2.RIGHT)
	ability.phase_timer = 0.0
	ability.tick(0.0)
	_assert_true(ability.get_phase_name() == &"recovery", "token denial should abort into recovery")
	_assert_true(ability.result == &"token_unavailable", "token denial should expose a terminal reason")
	ability.finish(&"token_denial_test")
	ability.engagement_token_request = Callable(grunt, "try_claim_ability_engagement_token")
	coordinator.queue_free()
	await process_frame
	grunt.target = target
	grunt.global_position = Vector2.ZERO
	target.global_position = Vector2(112.0, 0.0)
	grunt.set("grunt_falcon_punch_windup_time", 0.02)
	grunt.set("grunt_falcon_punch_tracking_lock_sec", 0.005)
	grunt.set("grunt_falcon_punch_leap_time", 0.20)
	grunt.set("grunt_falcon_punch_impact_lock_time", 0.01)
	grunt.set("grunt_falcon_punch_recovery_time", 0.04)
	grunt.set("grunt_falcon_punch_cooldown", 0.0)
	ability.cooldown_timer = 0.0
	grunt.set("grunt_falcon_punch_chance", 1.0)
	grunt.set("grunt_falcon_punch_after_normal_attacks_min", 0)
	grunt.set("grunt_falcon_punch_victim_hitstop", 0.0)
	grunt.set("grunt_falcon_punch_attacker_hitstop", 0.0)
	ability.cadence_credit = 1.0

	_assert_true(bool(grunt.call("_attack_grunt_falcon_punch_target", 0.016)), "grunt should start falcon-punch attack in launch band")
	_assert_true(ability.debug_get_presentation_phase_name() == &"windup", "falcon punch should start in windup")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_windup_e", "windup should use special_windup_e")
	target.global_position = Vector2(80.0, 80.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.005)
	var tracked_direction := ability.direction
	_assert_true(tracked_direction.y > 0.5, "windup should visibly track target movement before leap commitment")
	target.global_position = Vector2(112.0, 0.0)

	grunt.call("_update_grunt_falcon_punch_attack", 0.03)
	await process_frame
	_assert_true(ability.get_phase_name() == &"leap", "falcon punch should advance to leap")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_inflight_e", "leap should use special_inflight_e")
	_assert_true(ability.current_distance < 120.0, "falcon punch should stop short of the target center")

	target.global_position = grunt.global_position + Vector2(24.0, 0.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.12)
	await process_frame
	_assert_true(target.hits.size() == 1, "falcon punch should resolve one hit")
	_assert_true(String(target.hits[0].get("hit_kind", "")) == "falcon_punch", "falcon punch hit should preserve hit_kind")
	_assert_true(target.attack_contexts.size() == 1, "falcon punch should pass one authoritative attack context")
	if not target.attack_contexts.is_empty():
		var spatial := target.attack_contexts[0]
		_assert_true(String(spatial.get("contact_model", "")) == "directional_lane", "falcon punch should use normalized directional-lane geometry")
		_assert_true(bool(spatial.get("spatial_valid", false)), "falcon punch accepted contact should carry spatial_valid=true")
		_assert_true(not String(spatial.get("attack_id", "")).is_empty(), "falcon punch contact should retain stable attack ID")
	_assert_true(ability.get_phase_name() == &"impact_lock", "resolved hit should enter impact lock")
	_assert_true(target.falcon_impacts == 1, "damaging falcon punch should trigger dedicated Operator impact")
	_assert_true(grunt.global_position.distance_to(target.global_position) >= 27.9, "falcon contact should preserve minimum body separation")

	grunt.call("_update_grunt_falcon_punch_attack", 0.02)
	await process_frame
	_assert_true(ability.get_phase_name() == &"recovery", "impact lock should enter recovery")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_recovery_e", "recovery should use special_recovery_e")
	_assert_true((grunt.get("velocity") as Vector2).is_zero_approx(), "falcon recovery must not drift forward")

	grunt.call("_update_grunt_falcon_punch_attack", 0.06)
	await process_frame
	_assert_true(not ability.is_active(), "recovery should finish the special attack")

	# A stationary target in the normal launch band should be contacted without test-side repositioning.
	config.recovery_time = 0.70
	target.hits.clear()
	target.falcon_impacts = 0
	target.result_mode = &"damaged"
	grunt.global_position = Vector2.ZERO
	target.global_position = Vector2(112.0, 0.0)
	grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
	grunt.call("_start_grunt_falcon_punch_leap")
	for _step in range(24):
		if ability.get_phase_name() != &"leap":
			break
		await physics_frame
		grunt.call("_update_grunt_falcon_punch_attack", 1.0 / 60.0)
	_assert_true(target.hits.size() == 1, "stationary target in the natural launch band should be hit")
	_assert_true(ability.get_phase_name() == &"impact_lock", "natural contact should enter impact lock")
	ability.tick(config.impact_lock_time + 0.01)
	_assert_true(ability.get_phase_name() == &"recovery", "damaging Falcon should enter recovery after impact lock")
	_assert_near(ability.phase_timer, config.recovery_time, 0.02, "damaging Falcon should retain 0.70s recovery")
	grunt.call("_finish_grunt_falcon_punch_attack", &"debug_test_complete")

	# Prove the actual live launch contract, without an artificial travel override.
	var band_hits := {88: 0, 96: 0, 112: 0, 136: 0, 160: 0, 176: 0, 184: 0}
	for launch_distance in [88, 96, 112, 136, 160, 176, 184]:
		for _attempt in range(7):
			target.hits.clear()
			target.result_mode = &"damaged"
			grunt.global_position = Vector2.ZERO
			target.global_position = Vector2(float(launch_distance), 0.0)
			grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
			var attack_id := ability.attack_id
			grunt.call("_start_grunt_falcon_punch_leap")
			for _step in range(30):
				if ability.get_phase_name() != &"leap":
					break
				grunt.call("_update_grunt_falcon_punch_attack", 1.0 / 60.0)
			if target.hits.size() == 1:
				band_hits[launch_distance] = int(band_hits[launch_distance]) + 1
			_assert_true(target.hits.size() == 1, "Falcon sample at %d px should resolve exactly one hit" % launch_distance)
			if observatory != null:
				var resolved_events := observatory.call("get_recent_events", 100, &"grunt_falcon_punch_hit_resolved") as Array
				var matching: Dictionary = {}
				for event in resolved_events:
					var data := (event as Dictionary).get("data", {}) as Dictionary
					if String(data.get("attack_id", "")) == attack_id:
						matching = data
						break
				_assert_true(not matching.is_empty(), "Falcon sample should emit a terminal event with its attack_id")
				for field in ["launch_distance", "target_distance_at_active_start", "closest_approach", "lateral_error", "player_dodge_phase", "collision_obstructed", "stop_short_distance", "committed_target_distance", "planned_travel_distance", "actual_travel_distance", "selected_recovery_duration"]:
					_assert_true(matching.has(field), "Falcon terminal telemetry missing %s" % field)
			grunt.call("_finish_grunt_falcon_punch_attack", &"debug_sample_complete")
	for launch_distance in band_hits:
		_assert_true(int(band_hits[launch_distance]) == 7, "Falcon %d px band did not connect on all seven stationary samples" % launch_distance)
	# The 10px commitment cushion covers modest straight-away movement without homing.
	target.hits.clear()
	grunt.global_position = Vector2.ZERO
	target.global_position = Vector2(176.0, 0.0)
	ability.start_debug(target, Vector2.RIGHT)
	ability.phase_timer = 0.0
	ability.tick(0.0)
	target.global_position += Vector2(10.0, 0.0)
	ability.tick(config.committed_time + 0.01)
	for _step in range(30):
		if ability.phase != GruntFalconPunch.Phase.LEAP:
			break
		ability.tick(1.0 / 60.0)
	_assert_true(target.hits.size() == 1, "modest straight-away movement should not expose fixed-distance shortfall")
	ability.finish(&"straight_away_reach_test")
	ability.cooldown_timer = 0.0
	ability.recent_parry_timer = 0.0
	ability.normal_attacks_since_special = 1
	ability.cadence_credit = 1.0
	target.global_position = Vector2(config.launch_band.y + 1.0, 0.0)
	grunt.global_position = Vector2.ZERO
	_assert_true(not ability.can_start(target), "Falcon must reject targets beyond launch_band_max")

	# A parried result must cancel the entire attack even when the target stub does not call back into Enemy.
	var impact_events_before_parry := 0
	if observatory != null:
		impact_events_before_parry = (observatory.call("get_recent_events", 100, &"grunt_falcon_punch_impact_lock") as Array).size()
	target.result_mode = &"parried"
	target.global_position = Vector2(100.0, 0.0)
	grunt.global_position = Vector2.ZERO
	ability.cadence_credit = 1.0
	_assert_true(bool(grunt.call("_attack_grunt_falcon_punch_target", 0.016)), "parry scenario should start falcon punch")
	grunt.call("_start_grunt_falcon_punch_leap")
	target.global_position = grunt.global_position + Vector2(20.0, 0.0)
	ability.phase_timer = 0.10
	grunt.call("_try_apply_grunt_falcon_punch_hit")
	_assert_true(not ability.is_active(), "parry should hard-cancel falcon punch")
	_assert_true(ability.recent_parry_timer > 0.0, "parry should start the special lockout")
	if observatory != null:
		var impact_events_after_parry := (observatory.call("get_recent_events", 100, &"grunt_falcon_punch_impact_lock") as Array).size()
		_assert_true(impact_events_after_parry == impact_events_before_parry, "parried Falcon Punch must not emit normal impact lock")
		_assert_true(int(observatory.get("counters").get("falcon_punch_parried", 0)) == 1, "Falcon parry counter should increment once")
	ability.cadence_credit = 1.0
	target.global_position = grunt.global_position + Vector2(100.0, 0.0)
	_assert_true(not bool(grunt.call("_should_start_grunt_falcon_punch_now", target)), "recent parry should block immediate re-falcon")

	for terminal_result in [&"blocked", &"dodged"]:
		target.result_mode = terminal_result
		grunt.global_position = Vector2.ZERO
		target.global_position = Vector2(100.0, 0.0)
		grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
		grunt.call("_start_grunt_falcon_punch_leap")
		target.global_position = grunt.global_position + Vector2(20.0, 0.0)
		grunt.call("_try_apply_grunt_falcon_punch_hit", true)
		_assert_true(ability.get_phase_name() == &"recovery", "Falcon %s result should enter recovery" % terminal_result)
		var expected_recovery := config.blocked_recovery_time if terminal_result == &"blocked" else config.whiff_recovery_time
		_assert_near(ability.phase_timer, expected_recovery, 0.001, "Falcon %s recovery duration" % terminal_result)
		grunt.call("_finish_grunt_falcon_punch_attack", &"debug_terminal_detail")

	# An ally occupying the forward corridor blocks the special, without blocking ordinary pathing.
	ability.recent_parry_timer = 0.0
	ability.cooldown_timer = 0.0
	ability.normal_attacks_since_special = 1
	ability.cadence_credit = 1.0
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
	ability.normal_attacks_since_special = 0
	ability.cadence_credit = 0.0
	_assert_true(not bool(grunt.call("_should_start_grunt_falcon_punch_now", target)), "falcon punch should require normal melee pressure first")
	grunt.call("_start_attack_windup", 13.0, false)
	_assert_true(bool(grunt.call("_should_start_grunt_falcon_punch_now", target)), "normal melee pressure should advance deterministic Falcon eligibility")

	# A terminal leap without a hit goes directly to recovery and records why.
	grunt.call("_clear_pending_attack_context")
	ability.recent_parry_timer = 0.0
	grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
	grunt.call("_start_grunt_falcon_punch_leap")
	grunt.call("_resolve_grunt_falcon_punch_whiff", &"target_out_of_range")
	_assert_true(ability.get_phase_name() == &"recovery", "Falcon whiff should skip successful impact lock")
	_assert_near(ability.phase_timer, config.whiff_recovery_time, 0.001, "ordinary Falcon whiff should use extended recovery")
	grunt.call("_finish_grunt_falcon_punch_attack", &"debug_whiff_complete")
	grunt.call("_start_grunt_falcon_punch_windup", Vector2.RIGHT)
	grunt.call("_start_grunt_falcon_punch_leap")
	grunt.call("_resolve_grunt_falcon_punch_whiff", &"blocked_by_collision")
	_assert_near(ability.phase_timer, config.collision_recovery_time, 0.001, "collision obstruction should use longest recovery")
	grunt.call("_finish_grunt_falcon_punch_attack", &"debug_collision_complete")

	# A meaningful head-on StaticBody collision owns the crash/stand-up sequence.
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(12.0, 120.0)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall.global_position = Vector2(58.0, 0.0)
	scene_root.add_child(wall)
	grunt.global_position = Vector2.ZERO
	target.global_position = Vector2(150.0, 0.0)
	ability.start_debug(target, Vector2.RIGHT)
	ability.start_leap()
	for step in 12:
		ability.tick(0.03)
		if ability.get_phase_name() == &"collision_knockdown":
			break
	_assert_true(ability.get_phase_name() == &"collision_knockdown", "head-on world collision after meaningful travel should hard-knockdown")
	_assert_true(ability.result == &"blocked_by_collision_hard", "hard collision should retain distinct terminal result")
	_assert_true(ability.collision_opposition >= config.hard_collision_opposition_threshold, "hard collision should record opposing normal")
	ability.tick(config.hard_collision_knockdown_time + 0.01)
	_assert_true(ability.get_phase_name() == &"stand_up", "hard collision should transition to stand-up exactly once")
	ability.tick(config.stand_up_time + 0.01)
	_assert_true(not ability.is_active(), "stand-up completion should return Falcon to idle")
	wall.queue_free()

	# Grunt expression is presentation-only and follows BSM transitions.
	grunt._grunt_weapon_posture = Enemy.GruntWeaponPosture.RELAXED
	grunt.on_behavior_presentation_state_changed(&"idle", &"notice")
	_assert_true(grunt.get_enemy_presentation_action() == &"posture.draw", "relaxed grunt should draw on first notice")
	grunt.on_behavior_presentation_state_changed(&"search", &"notice")
	_assert_true(grunt.get_enemy_presentation_action() == &"posture.alert", "ready grunt should alert on later notice")
	grunt._pending_attack_id = ""
	grunt._attack_windup_timer = 0.0
	grunt._grunt_expression_action = &""
	grunt._grunt_expression_timer = 0.0
	grunt._grunt_flavor_cooldown = 0.0
	grunt.velocity = Vector2.ZERO
	grunt.behavior_state_machine.current_state = &"idle"
	grunt._update_grunt_expression(0.01)
	_assert_true(String(grunt.get_enemy_presentation_action()).begins_with("flavor."), "safe stationary idle should admit deterministic flavor")
	grunt.on_behavior_presentation_state_changed(&"idle", &"engage_operator")
	_assert_true(grunt._grunt_expression_action.is_empty(), "combat escalation should cancel flavor immediately")

	# Locomotion presentation follows, but never owns, BSM movement speed.
	grunt._grunt_weapon_posture = Enemy.GruntWeaponPosture.RELAXED
	grunt.behavior_state_machine.current_state = &"patrol"
	grunt.velocity = Vector2(58.0, 0.0)
	_assert_true(grunt._get_grunt_locomotion_action() == &"locomotion.relaxed_walk", "calm patrol speed should use relaxed walk")
	grunt.behavior_state_machine.current_state = &"investigate"
	grunt.velocity = Vector2(72.0, 0.0)
	_assert_true(grunt._get_grunt_locomotion_action() == &"locomotion.relaxed_run", "faster non-aggro investigation should use relaxed run")
	grunt.behavior_state_machine.current_state = &"engage_operator"
	grunt.velocity = Vector2(88.0, 0.0)
	_assert_true(grunt._get_grunt_locomotion_action() == &"locomotion.run", "aggro movement should retain armed run")
	if observatory != null:
		_assert_true(int(observatory.get("counters").get("falcon_punch_whiffed", 0)) == 3, "Falcon whiff counter should identify range and collision misses")
		_assert_true(int(observatory.get("counters").get("enemy_attack_whiffed_out_of_range", 0)) >= 1, "Falcon range whiff should expose reason counter")
		var falcon_counters: Dictionary = observatory.get("counters")
		_assert_true(int(falcon_counters.get("falcon_punch_result_damaged", 0)) >= 1, "Falcon damaged terminal detail should be counted")
		_assert_true(int(falcon_counters.get("falcon_punch_result_parried", 0)) == 1, "Falcon parried terminal detail should be counted")
		_assert_true(int(falcon_counters.get("falcon_punch_result_blocked", 0)) == 1, "Falcon blocked terminal detail should be counted")
		_assert_true(int(falcon_counters.get("falcon_punch_result_iframe_dodged", 0)) == 1, "Falcon iframe-dodged terminal detail should be counted")
		_assert_true(int(falcon_counters.get("falcon_punch_result_whiffed", 0)) == 3, "Falcon whiff terminal detail should count range, generic collision, and hard collision")

	if _failed:
		push_error("grunt_falcon_punch_smoke failed")
		quit(1)
		return
	print("[GruntFalconPunchSmoke] tracking tell, natural contact, stop-short, separation, impact, parry lockout, lane gate, and zero-drift recovery resolved.")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)


func _assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	_assert_true(absf(actual - expected) <= tolerance, "%s (expected %.3f, got %.3f)" % [message, expected, actual])
