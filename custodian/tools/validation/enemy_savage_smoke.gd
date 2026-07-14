extends SceneTree

const SAVAGE_SCENE := preload("res://game/actors/enemies/enemy_savage.tscn")
const BEHAVIOR_PROFILE_SCRIPT := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")

var _failed := false


class SavageTarget:
	extends Node2D
	var received_hits: Array[Dictionary] = []

	func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy", _attacker: Node2D = null, _hit_direction: Vector2 = Vector2.ZERO, guard_stamina_cost_override: float = -1.0) -> Dictionary:
		received_hits.append({
			"amount": amount,
			"hit_kind": hit_kind,
			"guard_cost": guard_stamina_cost_override,
		})
		return {
			"result": &"damaged",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": false,
			"applied_damage": amount,
		}


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
	await process_frame

	_assert_true(savage is Enemy, "enemy_savage root should be Enemy")
	_assert_true(savage.get("enemy_name") == "SAVAGE", "enemy name should be SAVAGE")
	_assert_approx(float(savage.get("speed")), 104.0, "speed")
	_assert_approx(float(savage.get("health")), 64.0, "health")
	_assert_approx(float(savage.get("max_health")), 64.0, "max_health")
	_assert_approx(float(savage.get("damage")), 10.0, "damage")
	_assert_approx(float(savage.get("attack_windup_duration")), 0.26, "attack windup")
	_assert_approx(float(savage.get("stagger_damage_threshold")), 16.0, "stagger threshold")
	_assert_approx(float(savage.get("crit_damage_threshold")), 38.0, "crit threshold")
	_assert_true(savage.get("behavior_profile_id") == &"raider_savage", "scene should use raider_savage")
	_assert_true(savage.get("custom_enemy_animation_set") == "enemy_savage", "scene should use enemy_savage animation set")
	_assert_true(bool(savage.get("savage_chain_enabled")), "two-hit chain should be enabled")
	_assert_true(bool(savage.get("savage_pounce_enabled")), "pounce should be enabled")

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
	root.add_child(target)
	target.global_position = savage.global_position + Vector2(24.0, 0.0)
	savage.set("target", target)
	savage.call("_start_savage_chain")
	savage.call("_update_savage_attack", 0.27)
	savage.call("_update_savage_attack", 0.11)
	savage.call("_update_savage_attack", 0.17)
	_assert_true(target.received_hits.size() == 2, "Savage chain should resolve two hits")
	if target.received_hits.size() >= 2:
		_assert_true(target.received_hits[0].get("hit_kind") == &"savage_chain_1", "chain hit one should use its own hit kind")
		_assert_approx(float(target.received_hits[0].get("guard_cost")), 10.0, "chain hit one guard cost")
		_assert_true(target.received_hits[1].get("hit_kind") == &"savage_chain_2", "chain hit two should use its own hit kind")
		_assert_approx(float(target.received_hits[1].get("amount")), 12.0, "chain hit two damage")
		_assert_approx(float(target.received_hits[1].get("guard_cost")), 22.0, "chain hit two guard cost")
	savage.call("_update_savage_attack", 0.56)

	target.received_hits.clear()
	savage.global_position = Vector2.ZERO
	target.global_position = Vector2(50.0, 0.0)
	_assert_true(bool(savage.call("_attack_savage_pounce_target")), "Savage should start pounce inside its launch band")
	savage.call("_update_savage_attack", 0.29)
	savage.call("_update_savage_attack", 0.08)
	_assert_true(target.received_hits.size() == 1, "Savage pounce should resolve once during its active window")
	if not target.received_hits.is_empty():
		_assert_true(target.received_hits[0].get("hit_kind") == &"savage_pounce", "pounce should use its distinct hit kind")
		_assert_approx(float(target.received_hits[0].get("amount")), 18.0, "pounce damage")
	savage.call("_start_savage_chain")
	savage.call("apply_parry_stagger", Vector2.LEFT, 0.3, 0.0)
	_assert_true(StringName(savage.get("_savage_chain_phase")) == &"", "parry stagger should interrupt an active Savage commitment")

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


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
