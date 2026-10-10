extends SceneTree

const ENEMY_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const CombatConstants := preload("res://game/systems/combat/combat_constants.gd")

var _enemy: CharacterBody2D
var _target: Node2D


class DummyTarget:
	extends CharacterBody2D

	func take_damage(_amount: float) -> void:
		pass


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	_enemy = ENEMY_SCENE.instantiate() as CharacterBody2D
	fixture.add_child(_enemy)
	_target = DummyTarget.new()
	_target.add_to_group("player")
	fixture.add_child(_target)
	await process_frame
	_enemy.set_physics_process(false)
	_target.global_position = _enemy.global_position + Vector2.RIGHT * 20.0
	_enemy.set("target", _target)
	_enemy.set_process(false)

	_validate_committed_light_survives()
	_validate_light_flinch_gate()
	_validate_posture_break()
	_validate_posture_recovery()
	_validate_heavy_authority()
	_validate_displacement_does_not_cancel()
	_validate_knockback_multi_tick_displacement()
	await _validate_knockback_wall_blocking(fixture)

	fixture.queue_free()
	await process_frame
	print("[CombatExchangeCommitmentSmoke] PASS")
	quit(0)


func _reset_enemy() -> void:
	_enemy.set("dead", false)
	_enemy.set("health", 1000.0)
	_enemy.set("max_health", 1000.0)
	_enemy.call("reset_reaction_state")
	(_enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee).cancel(&"interrupted", &"test_reset")
	_enemy.set("target", _target)


func _start_melee_commitment() -> void:
	_target.global_position = _enemy.global_position + Vector2.RIGHT * 20.0
	var melee := _enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee
	assert(melee.try_start(), "test must create commitment through the public melee start API")


func _validate_committed_light_survives() -> void:
	_reset_enemy()
	_start_melee_commitment()
	var melee := _enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee
	var attack_id := String(melee.get_debug_state().get("attack_id", ""))
	var windup := float(melee.get_debug_state().get("windup_remaining", 0.0))
	var hp_before := float(_enemy.get("health"))
	_enemy.call("take_damage", 11.0, CombatConstants.HitStrength.LIGHT, 14.0)
	assert(float(_enemy.get("health")) == hp_before - 11.0)
	assert(melee.is_committed() and String(melee.get_debug_state().get("attack_id", "")) == attack_id)
	assert(is_equal_approx(float(melee.get_debug_state().get("windup_remaining", 0.0)), windup))
	var reaction_state: Dictionary = _enemy.call("get_reaction_debug_state")
	assert(is_zero_approx(float(reaction_state.get("recoil_remaining", -1.0))))
	assert(is_zero_approx(float(reaction_state.get("stagger_remaining", -1.0))))
	# Gameplay recoil stays suppressed, but the cosmetic presentation-only
	# kick must still fire (Combat tempo + impact feedback pass).
	assert(_enemy.get("_light_contact_visual_tween") != null)


func _validate_light_flinch_gate() -> void:
	_reset_enemy()
	_enemy.call("take_damage", 4.0, CombatConstants.HitStrength.LIGHT, 14.0)
	assert(float((_enemy.call("get_reaction_debug_state") as Dictionary).get("recoil_remaining", 0.0)) > 0.0)
	_enemy.call("_update_reaction_timers", 0.13)
	_enemy.set("_light_contact_visual_tween", null)
	_enemy.call("take_damage", 4.0, CombatConstants.HitStrength.LIGHT, 16.0)
	assert(is_zero_approx(float((_enemy.call("get_reaction_debug_state") as Dictionary).get("recoil_remaining", -1.0))))
	# Cooldown-suppressed LIGHT hits still get the cosmetic-only kick.
	assert(_enemy.get("_light_contact_visual_tween") != null)
	_enemy.call("_update_reaction_timers", 0.71)
	_enemy.call("take_damage", 4.0, CombatConstants.HitStrength.LIGHT, 1.0)
	assert(float((_enemy.call("get_reaction_debug_state") as Dictionary).get("recoil_remaining", 0.0)) > 0.0)


func _validate_posture_break() -> void:
	_reset_enemy()
	_start_melee_commitment()
	var melee := _enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee
	_enemy.call("take_damage", 1.0, CombatConstants.HitStrength.LIGHT, 60.0)
	assert(melee.is_committed())
	_enemy.call("take_damage", 1.0, CombatConstants.HitStrength.LIGHT, 40.0)
	assert(not melee.is_committed())
	var reaction_state: Dictionary = _enemy.call("get_reaction_debug_state")
	assert(float(reaction_state.get("stagger_remaining", 0.0)) > 0.0)
	assert(is_zero_approx(float((_enemy.call("get_posture_status") as Dictionary).get("current", -1.0))))


func _validate_posture_recovery() -> void:
	_reset_enemy()
	_enemy.call("take_damage", 1.0, CombatConstants.HitStrength.LIGHT, 30.0)
	_enemy.call("_update_reaction_timers", 0.13)
	_enemy.call("_update_reaction_timers", 1.0)
	assert(is_equal_approx(float((_enemy.call("get_posture_status") as Dictionary).get("current", -1.0)), 30.0))
	_enemy.call("_update_reaction_timers", 0.30)
	_enemy.call("_update_reaction_timers", 0.10)
	assert(float((_enemy.call("get_posture_status") as Dictionary).get("current", 100.0)) < 30.0)


func _validate_heavy_authority() -> void:
	_reset_enemy()
	_start_melee_commitment()
	var melee := _enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee
	_enemy.call("take_damage", 2.0, CombatConstants.HitStrength.HEAVY, 45.0)
	assert(not melee.is_committed())
	var reaction_state: Dictionary = _enemy.call("get_reaction_debug_state")
	assert(float(reaction_state.get("stagger_remaining", 0.0)) > 0.0)
	assert(is_equal_approx(float((_enemy.call("get_posture_status") as Dictionary).get("current", -1.0)), 45.0))


func _validate_displacement_does_not_cancel() -> void:
	_reset_enemy()
	_start_melee_commitment()
	var melee := _enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee
	var before := _enemy.global_position
	# Knockback is a queued, collision-resolved impulse (resolved across
	# _physics_process ticks), not an instantaneous position change -- with
	# physics processing disabled for this fixture, global_position must not
	# move synchronously inside apply_melee_impact() itself.
	_enemy.call("apply_melee_impact", "vigil_dagger_fast_02:default", Vector2.RIGHT, 360.0)
	assert(is_zero_approx(_enemy.global_position.distance_to(before)))
	assert(float(_enemy.get("_knockback_remaining")) > 0.0)
	assert((_enemy.get("_knockback_velocity") as Vector2).length() > 0.0)
	assert(melee.is_committed())
	_enemy.call("_update_knockback_impulse", 0.5)
	assert(_enemy.global_position.distance_to(before) > 0.0)
	assert(melee.is_committed())
	assert(is_zero_approx(float(_enemy.get("_knockback_remaining"))))


func _validate_knockback_multi_tick_displacement() -> void:
	_reset_enemy()
	_enemy.global_position = Vector2(2000.0, 2000.0)
	_target.global_position = _enemy.global_position + Vector2.RIGHT * 20.0
	_start_melee_commitment()
	var melee := _enemy.call("get_standard_enemy_melee_ability") as StandardEnemyMelee
	var before := _enemy.global_position
	# Fast 02 target: ~5-7px over ~0.09-0.11s.
	_enemy.call("apply_melee_impact", "vigil_dagger_fast_02:default", Vector2.RIGHT, 360.0)
	var duration := float(_enemy.get("_knockback_remaining"))
	assert(duration >= 0.09 and duration <= 0.11)
	var step := duration / 4.0
	var midpoint_distance := 0.0
	for tick_index in range(3):
		_enemy.call("_update_knockback_impulse", step)
		if tick_index == 1:
			midpoint_distance = _enemy.global_position.distance_to(before)
	# Displacement must accumulate gradually across ticks, not resolve in one.
	assert(midpoint_distance > 0.0)
	assert(midpoint_distance < _enemy.global_position.distance_to(before))
	_enemy.call("_update_knockback_impulse", step)
	var total_distance := _enemy.global_position.distance_to(before)
	assert(total_distance >= 4.5 and total_distance <= 7.5)
	assert(is_zero_approx(float(_enemy.get("_knockback_remaining"))))


func _validate_knockback_wall_blocking(fixture: Node2D) -> void:
	_reset_enemy()
	_enemy.global_position = Vector2(2500.0, 2000.0)
	var wall := StaticBody2D.new()
	wall.position = _enemy.global_position + Vector2(24.0, 0.0)
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(20.0, 200.0)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	fixture.add_child(wall)
	# A newly added collider is not queryable by move_and_collide until the
	# physics server has processed at least one frame.
	await process_frame
	await physics_frame
	var before := _enemy.global_position
	_enemy.call("apply_melee_impact", "vigil_dagger_fast_03:cut_02", Vector2.RIGHT, 960.0)
	for _tick_index in range(6):
		_enemy.call("_update_knockback_impulse", 0.03)
	var travelled := _enemy.global_position.distance_to(before)
	# The wall must stop the impulse well short of the full ~16px target
	# (no tunneling through the collider) and cleanly zero the remaining
	# impulse rather than leaving it to fire later.
	assert(travelled < 16.0)
	assert(is_zero_approx(float(_enemy.get("_knockback_remaining"))))
	wall.queue_free()
