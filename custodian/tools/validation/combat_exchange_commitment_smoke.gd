extends SceneTree

const ENEMY_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const CombatConstants := preload("res://game/systems/combat/combat_constants.gd")

var _enemy: CharacterBody2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	_enemy = ENEMY_SCENE.instantiate() as CharacterBody2D
	fixture.add_child(_enemy)
	await process_frame
	_enemy.set_physics_process(false)
	_enemy.set_process(false)

	_validate_committed_light_survives()
	_validate_light_flinch_gate()
	_validate_posture_break()
	_validate_posture_recovery()
	_validate_heavy_authority()
	_validate_displacement_does_not_cancel()

	fixture.queue_free()
	await process_frame
	print("[CombatExchangeCommitmentSmoke] PASS")
	quit(0)


func _reset_enemy() -> void:
	_enemy.set("dead", false)
	_enemy.set("health", 1000.0)
	_enemy.set("max_health", 1000.0)
	_enemy.set("posture_current", 0.0)
	_enemy.set("_posture_recovery_delay_timer", 0.0)
	_enemy.set("_light_flinch_cooldown_timer", 0.0)
	_enemy.set("_recoil_timer", 0.0)
	_enemy.set("_stagger_timer", 0.0)
	_enemy.set("_pending_attack_id", "")


func _validate_committed_light_survives() -> void:
	_reset_enemy()
	_enemy.set("_pending_attack_id", "committed-fast-01")
	_enemy.set("_attack_windup_timer", 0.25)
	var hp_before := float(_enemy.get("health"))
	_enemy.call("take_damage", 11.0, CombatConstants.HitStrength.LIGHT, 14.0)
	assert(float(_enemy.get("health")) == hp_before - 11.0)
	assert(String(_enemy.get("_pending_attack_id")) == "committed-fast-01")
	assert(is_equal_approx(float(_enemy.get("_attack_windup_timer")), 0.25))
	assert(is_zero_approx(float(_enemy.get("_recoil_timer"))))
	assert(is_zero_approx(float(_enemy.get("_stagger_timer"))))


func _validate_light_flinch_gate() -> void:
	_reset_enemy()
	_enemy.call("take_damage", 4.0, CombatConstants.HitStrength.LIGHT, 14.0)
	assert(float(_enemy.get("_recoil_timer")) > 0.0)
	_enemy.set("_recoil_timer", 0.0)
	_enemy.call("take_damage", 4.0, CombatConstants.HitStrength.LIGHT, 16.0)
	assert(is_zero_approx(float(_enemy.get("_recoil_timer"))))
	_enemy.call("_update_reaction_timers", 0.71)
	_enemy.call("take_damage", 4.0, CombatConstants.HitStrength.LIGHT, 1.0)
	assert(float(_enemy.get("_recoil_timer")) > 0.0)


func _validate_posture_break() -> void:
	_reset_enemy()
	_enemy.set("_pending_attack_id", "committed-posture")
	_enemy.call("take_damage", 1.0, CombatConstants.HitStrength.LIGHT, 60.0)
	assert(String(_enemy.get("_pending_attack_id")) == "committed-posture")
	_enemy.call("take_damage", 1.0, CombatConstants.HitStrength.LIGHT, 40.0)
	assert(String(_enemy.get("_pending_attack_id")).is_empty())
	assert(float(_enemy.get("_stagger_timer")) > 0.0)
	assert(is_zero_approx(float(_enemy.get("posture_current"))))


func _validate_posture_recovery() -> void:
	_reset_enemy()
	_enemy.call("take_damage", 1.0, CombatConstants.HitStrength.LIGHT, 30.0)
	_enemy.set("_recoil_timer", 0.0)
	_enemy.call("_update_reaction_timers", 1.0)
	assert(is_equal_approx(float(_enemy.get("posture_current")), 30.0))
	_enemy.call("_update_reaction_timers", 0.30)
	_enemy.call("_update_reaction_timers", 0.10)
	assert(float(_enemy.get("posture_current")) < 30.0)


func _validate_heavy_authority() -> void:
	_reset_enemy()
	_enemy.set("_pending_attack_id", "committed-heavy")
	_enemy.call("take_damage", 2.0, CombatConstants.HitStrength.HEAVY, 45.0)
	assert(String(_enemy.get("_pending_attack_id")).is_empty())
	assert(float(_enemy.get("_stagger_timer")) > 0.0)
	assert(is_equal_approx(float(_enemy.get("posture_current")), 45.0))


func _validate_displacement_does_not_cancel() -> void:
	_reset_enemy()
	_enemy.set("_pending_attack_id", "committed-displacement")
	var before := _enemy.global_position
	_enemy.call("apply_melee_impact", "vigil_dagger_fast_02:default", Vector2.RIGHT, 180.0)
	assert(_enemy.global_position.distance_to(before) > 0.0)
	assert(String(_enemy.get("_pending_attack_id")) == "committed-displacement")
