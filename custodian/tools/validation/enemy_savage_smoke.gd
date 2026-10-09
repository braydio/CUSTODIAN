extends SceneTree

const SAVAGE_SCENE := preload("res://game/actors/enemies/enemy_savage.tscn")
const SavageChain = preload("res://game/actors/enemies/abilities/savage_chain.gd")
const SavageChainConfig = preload("res://game/actors/enemies/abilities/savage_chain_config.gd")
const BEHAVIOR_PROFILE_SCRIPT := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")
const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")

var _failed := false


class SavageTarget:
	extends CharacterBody2D
	var received_hits: Array[Dictionary] = []
	var impacts: Array[Dictionary] = []
	var parry_next := false
	var block_next := false

	func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy", _attacker: Node2D = null, _hit_direction: Vector2 = Vector2.ZERO, guard_stamina_cost_override: float = -1.0) -> Dictionary:
		received_hits.append({
			"amount": amount,
			"hit_kind": hit_kind,
			"guard_cost": guard_stamina_cost_override,
		})
		if parry_next:
			parry_next = false
			return {"result": &"parried", "hit_kind": hit_kind, "dodged": false, "blocked": false, "parried": true, "applied_damage": 0.0}
		if block_next:
			block_next = false
			return {"result": &"blocked", "hit_kind": hit_kind, "dodged": false, "blocked": true, "parried": false, "applied_damage": 0.0}
		return {
			"result": &"damaged",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": false,
			"applied_damage": amount,
		}

	func apply_enemy_dash_impact(direction: Vector2, knockback: float, hitstop: float) -> void:
		impacts.append({"direction": direction, "knockback": knockback, "hitstop": hitstop})


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "EnemySavageSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var savage := SAVAGE_SCENE.instantiate()
	root.add_child(savage)
	savage.set_physics_process(false)
	savage.set("behavior_state_machine_enabled", false)
	savage.collision_layer = 0
	savage.collision_mask = 0
	if savage.get_node_or_null("EnemyBehaviorStateMachine") != null:
		savage.get_node("EnemyBehaviorStateMachine").set_physics_process(false)
	await process_frame

	_assert_true(savage is Enemy, "enemy_savage root should be Enemy")
	_assert_true(savage.get("enemy_name") == "SAVAGE", "enemy name should be SAVAGE")
	_assert_approx(float(savage.get("speed")), 104.0, "speed")
	_assert_approx(float(savage.get("health")), 64.0, "health")
	_assert_approx(float(savage.get("max_health")), 64.0, "max_health")
	_assert_approx(float(savage.get("damage")), 10.0, "damage")
	_assert_approx(float(savage.get_standard_enemy_melee_windup_duration()), 0.26, "attack windup")
	_assert_approx(float(savage.get("stagger_damage_threshold")), 16.0, "stagger threshold")
	_assert_true(savage.get("behavior_profile_id") == &"raider_savage", "scene should use raider_savage")
	_assert_true(savage.get("custom_enemy_animation_set") == "enemy_savage", "scene should use enemy_savage animation set")
	_assert_true(bool(savage.get("savage_chain_enabled")), "two-hit chain should be enabled")
	_assert_true(bool(savage.get("savage_pounce_enabled")), "pounce should be enabled")
	var chain: SavageChain = savage.get_savage_chain_ability()
	var chain_config: SavageChainConfig = savage.get("savage_chain_config")
	_assert_approx(chain_config.gap_time, 0.10, "chain gap")
	_assert_approx(chain_config.second_windup_time, 0.16, "chain second windup")
	_assert_approx(chain_config.second_damage, 12.0, "chain second damage")
	_assert_approx(chain_config.recovery_time, 0.55, "chain recovery")
	_assert_approx(chain_config.first_guard_stamina_damage, 10.0, "chain first guard cost")
	_assert_approx(chain_config.second_guard_stamina_damage, 22.0, "chain second guard cost")
	var pounce_config: SavagePounceConfig = savage.get("savage_pounce_config")
	_assert_approx(pounce_config.windup_time, 0.28, "pounce windup")
	_assert_approx(pounce_config.leap_time, 0.18, "pounce leap")
	_assert_approx(pounce_config.recovery_time, 0.55, "pounce recovery")
	_assert_approx(pounce_config.distance_px, 64.0, "pounce distance")
	_assert_approx(pounce_config.damage, 18.0, "pounce damage")
	_assert_approx(pounce_config.knockback_px, 52.0, "pounce knockback")
	_assert_approx(pounce_config.cooldown, 1.8, "pounce cooldown")
	_assert_approx(pounce_config.launch_band_min, 44.0, "pounce launch minimum")
	_assert_approx(pounce_config.launch_band_max, 132.0, "pounce launch maximum")
	_assert_approx(pounce_config.hit_active_start_ratio, 0.20, "pounce active start")
	_assert_approx(pounce_config.hit_active_end_ratio, 0.86, "pounce active end")
	_assert_approx(pounce_config.hit_forward_reach_px, 30.0, "pounce forward reach")
	_assert_approx(pounce_config.hit_lateral_reach_px, 22.0, "pounce lateral reach")

	var savage_profile: Resource = BEHAVIOR_PROFILE_SCRIPT.create_profile(&"raider_savage")
	var grunt_profile: Resource = BEHAVIOR_PROFILE_SCRIPT.create_profile(&"raider_grunt")
	_assert_true(savage_profile.get("profile_id") == &"raider_savage", "raider_savage profile should exist")
	_assert_true(not bool(savage_profile.get("can_steal_resources")), "Savage should not steal resources")
	_assert_true(bool(savage_profile.get("can_sabotage_storage")), "Savage should retain crude sabotage")
	_assert_true(float(savage_profile.get("aggression_weight")) > float(grunt_profile.get("aggression_weight")), "Savage aggression should exceed grunt")
	_assert_true(float(savage_profile.get("self_preservation_weight")) < float(grunt_profile.get("self_preservation_weight")), "Savage self-preservation should be below grunt")
	_assert_approx(float(savage_profile.get("engage_speed")), 104.0, "profile engage speed")

	var target := SavageTarget.new()
	target.name = "SavageTarget"
	target.add_to_group("player")
	target.collision_layer = 0
	target.collision_mask = 0
	root.add_child(target)
	target.global_position = savage.global_position + Vector2(70.0, 0.0)
	savage.set("target", target)
	_assert_true(chain.start(), "typed chain ability should start when enabled")
	_assert_true(StringName(chain.get_debug_state().get("phase", "")) == &"windup_1", "chain should begin in the first windup")
	_assert_approx(float(chain.get_debug_state().get("timer", -1.0)), 0.26, "chain should use the shared first-windup duration")
	target.global_position = savage.global_position + Vector2(24.0, 0.0)
	chain.tick(0.25)
	_assert_true(target.received_hits.is_empty(), "first hit should wait for the full first windup")
	chain.tick(0.02)
	_assert_true(StringName(chain.get_debug_state().get("phase", "")) == &"gap", "first hit should transition into the configured gap")
	chain.tick(0.11)
	_assert_true(StringName(chain.get_debug_state().get("phase", "")) == &"windup_2", "gap should transition into second windup")
	chain.tick(0.17)
	_assert_true(target.received_hits.size() == 2, "Savage chain should resolve two hits")
	if target.received_hits.size() >= 2:
		_assert_true(target.received_hits[0].get("hit_kind") == &"savage_chain_1", "chain hit one should use its own hit kind")
		_assert_approx(float(target.received_hits[0].get("amount")), 10.0, "chain first hit damage")
		_assert_approx(float(target.received_hits[0].get("guard_cost")), 10.0, "chain hit one guard cost")
		_assert_true(target.received_hits[1].get("hit_kind") == &"savage_chain_2", "chain hit two should use its own hit kind")
		_assert_approx(float(target.received_hits[1].get("amount")), 12.0, "chain hit two damage")
		_assert_approx(float(target.received_hits[1].get("guard_cost")), 22.0, "chain hit two guard cost")
	_assert_true(StringName(chain.get_debug_state().get("phase", "")) == &"recovery", "second hit should transition to recovery")
	chain.tick(0.56)
	_assert_true(not chain.is_active(), "chain should finish after recovery")

	# Facing is committed at start while target qualification/contact is evaluated
	# again at hit time. Moving behind the committed facing must produce a whiff.
	target.received_hits.clear()
	target.global_position = savage.global_position + Vector2(24.0, 0.0)
	_assert_true(chain.start(), "chain should restart for its spatial negative control")
	target.global_position = savage.global_position + Vector2(-24.0, 0.0)
	chain.tick(0.27)
	_assert_true(target.received_hits.is_empty(), "target moved outside the committed melee arc should whiff")
	chain.cancel()

	target.received_hits.clear()
	target.impacts.clear()
	savage.global_position = Vector2.ZERO
	target.global_position = Vector2(43.0, 0.0)
	var pounce: SavagePounce = savage.get_savage_pounce_ability()
	_assert_true(not pounce.try_start(), "pounce must reject targets below its launch band")
	target.global_position = Vector2(133.0, 0.0)
	_assert_true(not pounce.try_start(), "pounce must reject targets beyond its launch band")
	target.global_position = Vector2(43.0, 0.0)
	savage.set("damage_timer", savage.get("damage_interval"))
	savage.call("_attack_target", 0.01)
	_assert_true(chain.is_active(), "declined pounce should preserve generic cadence fallback into chain start")
	chain.cancel()
	target.global_position = Vector2(50.0, 0.0)
	savage.call("_attack_target", 1.0)
	_assert_true(not chain.is_active(), "pounce launch should retain priority over the two-hit chain")
	_assert_true(StringName(pounce.get_debug_state().get("phase", "")) == &"windup", "pounce launch selection should accept an in-band target")
	_assert_true(not pounce.try_start(), "active pounce/cooldown must reject a duplicate start")
	var debug_state := pounce.get_debug_state()
	_assert_true(StringName(debug_state.get("phase", "")) == &"windup", "typed pounce diagnostics should report windup")
	_assert_approx(float(debug_state.get("cooldown_timer", -1.0)), 1.8, "pounce debug cooldown")
	savage.set_physics_process(true)
	_assert_true(await _wait_for_pounce_phase(pounce, &"leap"), "windup should advance into leap at the original boundary")
	_assert_true(not pounce.is_hit_window_active(), "contact must remain closed before the 0.20 active ratio")
	target.global_position = savage.global_position + Vector2(0.0, 40.0)
	for _frame in range(3):
		await physics_frame
	_assert_true(pounce.is_hit_window_active(), "contact should open inside the authored 0.20..0.86 window")
	_assert_true(target.received_hits.is_empty(), "lateral miss should keep the active window from resolving contact")
	target.global_position = savage.global_position + Vector2(20.0, 0.0)
	for _frame in range(8):
		if not target.received_hits.is_empty():
			break
		await physics_frame
	_assert_true(target.received_hits.size() == 1, "Savage pounce should resolve once during its active window")
	if not target.received_hits.is_empty():
		_assert_true(target.received_hits[0].get("hit_kind") == &"savage_pounce", "pounce should use its distinct hit kind")
		_assert_approx(float(target.received_hits[0].get("amount")), 18.0, "pounce damage")
	_assert_true(target.impacts.size() == 1, "successful pounce should apply one impact")
	if not target.impacts.is_empty():
		_assert_approx(float(target.impacts[0].get("knockback")), 52.0, "pounce impact knockback")
		_assert_approx(float(target.impacts[0].get("hitstop")), 0.04, "pounce victim hitstop")
	_assert_true(StringName(pounce.get_debug_state().get("phase", "")) == &"recovery", "successful contact should enter recovery")
	_assert_true(await _wait_for_pounce_inactive(pounce), "pounce should finish after its 0.55 recovery")
	_assert_true(not pounce.is_active(), "pounce should finish after its 0.55 recovery")
	_assert_true(not pounce.try_start(), "cooldown should remain after recovery")
	savage.set_physics_process(false)
	pounce.tick(3.0)

	# A directional miss must not resolve damage; the ability still travels the
	# original 64 px and ends its leap on the same timer boundary.
	target.received_hits.clear()
	target.impacts.clear()
	savage.global_position = Vector2.ZERO
	var travel_start: Vector2 = savage.global_position
	target.global_position = savage.global_position + Vector2(50.0, 0.0)
	_assert_true(pounce.try_start(), "pounce should start after cooldown")
	savage.set_physics_process(true)
	_assert_true(await _wait_for_pounce_phase(pounce, &"leap"), "second pounce should reach leap")
	target.global_position = savage.global_position + Vector2(0.0, 40.0)
	_assert_true(await _wait_for_pounce_phase(pounce, &"recovery"), "leap should end at its distance/time boundary")
	_assert_true(target.received_hits.is_empty(), "lateral spatial miss should not hit")
	_assert_true(absf(savage.global_position.distance_to(travel_start) - 64.0) <= 6.0, "pounce travel distance should remain within one physics step of 64 px")
	_assert_true(await _wait_for_pounce_inactive(pounce), "second pounce should finish recovery")
	savage.set_physics_process(false)
	pounce.tick(3.0)

	# Parried contact consumes its one-hit attempt but does not force recovery;
	# blocked contact does recover and never applies dash impact.
	target.parry_next = true
	savage.global_position = Vector2.ZERO
	target.global_position = savage.global_position + Vector2(50.0, 0.0)
	_assert_true(pounce.try_start(), "pounce should restart after cooldown")
	savage.set_physics_process(true)
	_assert_true(await _wait_for_pounce_phase(pounce, &"leap"), "parry-control pounce should reach leap")
	for _frame in range(8):
		if not target.received_hits.is_empty():
			break
		target.global_position = savage.global_position + Vector2(20.0, 0.0)
		await physics_frame
	_assert_true(StringName(pounce.get_debug_state().get("phase", "")) == &"leap", "parried contact should preserve the committed leap")
	var parried_hit_count := target.received_hits.size()
	await physics_frame
	_assert_true(target.received_hits.size() == parried_hit_count, "parried target should not be hit twice")
	_assert_true(await _wait_for_pounce_phase(pounce, &"recovery"), "parried leap should recover at its normal travel boundary")
	_assert_true(await _wait_for_pounce_inactive(pounce), "parried pounce should finish recovery")
	savage.set_physics_process(false)
	pounce.tick(3.0)
	target.block_next = true
	savage.global_position = Vector2.ZERO
	target.global_position = savage.global_position + Vector2(50.0, 0.0)
	_assert_true(pounce.try_start(), "pounce should start for blocked-contact control")
	savage.set_physics_process(true)
	_assert_true(await _wait_for_pounce_phase(pounce, &"leap"), "blocked-contact pounce should reach leap")
	for _frame in range(8):
		if target.received_hits.size() > parried_hit_count:
			break
		target.global_position = savage.global_position + Vector2(20.0, 0.0)
		await physics_frame
	_assert_true(StringName(pounce.get_debug_state().get("phase", "")) == &"recovery", "blocked contact should enter recovery")
	_assert_true(target.impacts.is_empty(), "blocked contact must not apply impact knockback")
	_assert_true(await _wait_for_pounce_inactive(pounce), "blocked pounce should finish recovery")
	savage.set_physics_process(false)
	pounce.tick(3.0)

	savage.global_position = Vector2.ZERO
	target.global_position = savage.global_position + Vector2(50.0, 0.0)
	_assert_true(pounce.try_start(), "pounce should start for light-damage preservation control")
	savage.take_damage(1.0, CombatConstants.HitStrength.LIGHT)
	_assert_true(pounce.is_active(), "ordinary LIGHT damage must not cancel a committed pounce")
	savage.call("apply_parry_stagger", Vector2.LEFT, 0.3, 0.0)
	_assert_true(not pounce.is_active(), "parry stagger must cancel an active pounce")
	pounce.tick(3.0)
	savage.global_position = Vector2.ZERO
	_assert_true(pounce.try_start(), "pounce should restart for stagger-cancellation control")
	savage.call("_start_stagger_reaction")
	_assert_true(not pounce.is_active(), "stagger reaction must cancel an active pounce")
	_assert_true(chain.start(), "chain should start for stagger-cancellation control")
	savage.take_damage(1.0, CombatConstants.HitStrength.LIGHT)
	_assert_true(chain.is_active(), "ordinary LIGHT damage must not cancel a committed chain")
	savage.call("apply_parry_stagger", Vector2.LEFT, 0.3, 0.0)
	_assert_true(not chain.is_active(), "parry stagger should interrupt an active Savage chain")

	root.queue_free()
	await process_frame
	if _failed:
		push_error("enemy_savage_smoke failed")
		quit(1)
		return
	print("[EnemySavageSmoke] scene, rushdown stats, combat flags, and behavior profile resolved.")
	quit(0)


func _assert_approx(actual: float, expected: float, label: String) -> void:
	_assert_true(is_equal_approx(actual, expected), "%s should be %.2f, got %.2f" % [label, expected, actual])


func _wait_for_pounce_phase(pounce: SavagePounce, expected: StringName, max_frames := 120) -> bool:
	for _frame in range(max_frames):
		if StringName(pounce.get_debug_state().get("phase", "")) == expected:
			return true
		await physics_frame
	return StringName(pounce.get_debug_state().get("phase", "")) == expected


func _wait_for_pounce_inactive(pounce: SavagePounce, max_frames := 120) -> bool:
	for _frame in range(max_frames):
		if not pounce.is_active():
			return true
		await physics_frame
	return not pounce.is_active()


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
