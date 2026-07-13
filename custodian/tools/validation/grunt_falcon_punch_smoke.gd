extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")

class DummyTarget:
	extends CharacterBody2D

	var hits: Array[Dictionary] = []

	func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy", _attacker: Node2D = null, _hit_direction: Vector2 = Vector2.ZERO) -> Dictionary:
		var result := {
			"result": &"damaged",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": false,
			"applied_damage": amount,
		}
		hits.append(result)
		return result


var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "GruntFalconPunchSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	var target := DummyTarget.new()
	target.name = "DummyPlayer"
	target.add_to_group("player")
	target.global_position = Vector2(112.0, 0.0)
	root.add_child(target)
	await process_frame

	grunt.global_position = Vector2.ZERO
	grunt.set("target", target)
	grunt.set("grunt_falcon_punch_enabled", true)
	grunt.set("grunt_falcon_punch_windup_time", 0.02)
	grunt.set("grunt_falcon_punch_leap_time", 0.20)
	grunt.set("grunt_falcon_punch_impact_lock_time", 0.01)
	grunt.set("grunt_falcon_punch_recovery_time", 0.04)
	grunt.set("grunt_falcon_punch_distance_px", 120.0)
	grunt.set("grunt_falcon_punch_cooldown", 0.0)
	grunt.set("damage_timer", 999.0)

	_assert_true(bool(grunt.call("_attack_grunt_falcon_punch_target", 0.016)), "grunt should start falcon-punch attack in launch band")
	var body_sprite := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "windup", "falcon punch should start in windup")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "run_e", "windup should use running east animation")

	grunt.call("_update_grunt_falcon_punch_attack", 0.03)
	await process_frame
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "leap", "falcon punch should advance to leap")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_inflight_e", "leap should use special_inflight_e")

	target.global_position = grunt.global_position + Vector2(24.0, 0.0)
	grunt.call("_update_grunt_falcon_punch_attack", 0.12)
	await process_frame
	_assert_true(target.hits.size() == 1, "falcon punch should resolve one hit")
	_assert_true(String(target.hits[0].get("hit_kind", "")) == "falcon_punch", "falcon punch hit should preserve hit_kind")
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "impact_lock", "resolved hit should enter impact lock")

	grunt.call("_update_grunt_falcon_punch_attack", 0.02)
	await process_frame
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")) == "recovery", "impact lock should enter recovery")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "special_recovery_e", "recovery should use special_recovery_e")

	grunt.call("_update_grunt_falcon_punch_attack", 0.06)
	await process_frame
	_assert_true(String(grunt.get("_grunt_falcon_punch_phase")).is_empty(), "recovery should finish the special attack")

	if _failed:
		push_error("grunt_falcon_punch_smoke failed")
		quit(1)
		return
	print("[GruntFalconPunchSmoke] windup, leap hit, and recovery phases resolved.")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
