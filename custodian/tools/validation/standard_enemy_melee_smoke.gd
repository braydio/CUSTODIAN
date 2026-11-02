extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const SAVAGE_SCENE := preload("res://game/actors/enemies/enemy_savage.tscn")
const PURSUIT_SCENE := preload("res://game/actors/enemies/pursuit_frame.tscn")
const AMBIENT_SHRUMB_SCENE := preload("res://game/actors/enemies/ambient_shrumb.tscn")
const VARIANT_PROFILE := preload("res://game/enemies/procgen/enemy_variant_profile.gd")

var _failed := false


class MeleeTarget:

	extends CharacterBody2D

	var result_mode: StringName = &"damaged"
	var received: Array[Dictionary] = []
	var dead := false

	func take_damage(_amount: float) -> void:
		pass

	func is_dead() -> bool:
		return dead

	func receive_enemy_hit(
		amount: float,
		hit_kind: StringName = &"melee",
		_team: String = "enemy",
		_attacker: Node2D = null,
		_direction: Vector2 = Vector2.ZERO,
		_guard_cost: float = -1.0,
		attack_context: Dictionary = {}
	) -> Dictionary:
		received.append({"amount": amount, "kind": hit_kind, "result": result_mode, "context": attack_context.duplicate(true)})
		return {
			"result": result_mode,
			"hit_kind": hit_kind,
			"dodged": result_mode == &"dodged",
			"blocked": result_mode == &"blocked",
			"parried": result_mode == &"parried",
			"applied_damage": amount if result_mode == &"damaged" else 0.0,
		}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	_check_config_bindings()
	await _check_transactions(fixture)
	await _check_contact_sources(fixture)
	fixture.queue_free()
	await process_frame
	if _failed:
		push_error("StandardEnemyMelee smoke failed")
		quit(1)
		return
	print("[StandardEnemyMeleeSmoke] PASS")
	quit(0)


func _check_config_bindings() -> void:
	var default_config := load("res://game/actors/enemies/combat/configs/standard_enemy_melee_default.tres") as StandardEnemyMeleeConfig
	_expect(default_config != null, "base enemy must have typed standard melee defaults")
	if default_config == null:
		return
	_expect(is_equal_approx(default_config.strong_opening_multiplier, 3.0), "opening strong multiplier default")
	_expect(is_equal_approx(default_config.player_contact_range_px, 40.0), "normal player range default")
	_expect(is_equal_approx(default_config.windup_duration, 0.10), "normal windup default")
	_expect(is_equal_approx(default_config.recovery_duration, 0.40), "normal recovery default")
	_expect(is_equal_approx(default_config.redecision_delay_sec, 0.28), "normal redecision default")
	_expect(is_equal_approx(default_config.tracking_lock_sec, 0.12), "normal tracking lock default")
	_expect(is_equal_approx(default_config.range_grace_multiplier, 1.15), "normal grace multiplier default")
	_expect(is_equal_approx(default_config.range_grace_px, 10.0), "normal grace pixels default")
	_expect(is_equal_approx(default_config.contact_arc_degrees, 95.0), "normal contact arc default")
	_expect_config(MARINE_SCENE, 0.45, 0.40, 0.28, 95.0, "Marine")
	_expect_config(SAVAGE_SCENE, 0.26, 0.40, 0.28, 115.0, "Savage")
	_expect_config(PURSUIT_SCENE, 0.46, 0.48, 0.28, 95.0, "Pursuit Frame")
	_expect_config(GRUNT_SCENE, 0.42, 0.40, 0.28, 95.0, "Grunt")
	var ambient := AMBIENT_SHRUMB_SCENE.instantiate() as Enemy
	_expect(ambient.standard_enemy_melee_config != null, "ambient enemy inherited scene must load the base melee config")
	ambient.free()


func _expect_config(scene: PackedScene, windup: float, recovery: float, redecision: float, arc: float, label: String) -> void:
	var enemy := scene.instantiate() as Enemy
	var config := enemy.standard_enemy_melee_config
	_expect(is_equal_approx(config.windup_duration, windup), "%s scene windup override" % label)
	_expect(is_equal_approx(config.recovery_duration, recovery), "%s scene recovery override" % label)
	_expect(is_equal_approx(config.redecision_delay_sec, redecision), "%s scene redecision override" % label)
	_expect(is_equal_approx(config.contact_arc_degrees, arc), "%s scene arc override" % label)
	enemy.free()


func _check_transactions(fixture: Node2D) -> void:
	var enemy := GRUNT_SCENE.instantiate() as Enemy
	fixture.add_child(enemy)
	await process_frame
	enemy.set_physics_process(false)
	enemy.set_process(false)
	var target_a := MeleeTarget.new()
	target_a.name = "TargetA"
	target_a.add_to_group("player")
	fixture.add_child(target_a)
	target_a.global_position = enemy.global_position + Vector2.RIGHT * 24.0
	enemy.target = target_a
	var melee := enemy.get_standard_enemy_melee_ability()
	var config := enemy.standard_enemy_melee_config

	_expect(melee.is_eligible(), "fresh melee should be eligible")
	_expect(melee.try_start(), "first baseline attack should start")
	var first := melee.get_debug_state()
	var first_id := String(first.get("attack_id", ""))
	_expect(bool(first.get("queued_strong", false)), "first swing must be strong")
	_expect(is_equal_approx(float(first.get("queued_damage", 0.0)), enemy.damage * 3.0), "first strong swing must use multiplier 3.0")
	_expect(first_id.split(":").size() == 2, "ordinary attack id must retain <enemy-instance>:<sequence> identity")
	_expect(is_equal_approx(float(first.get("windup_remaining", 0.0)), 0.42), "Grunt windup should begin at the authored scene override")
	var target_b := MeleeTarget.new()
	target_b.name = "TargetB"
	target_b.add_to_group("player")
	fixture.add_child(target_b)
	target_b.global_position = target_a.global_position
	enemy.target = target_b
	melee.tick(config.windup_duration + 0.001)
	_expect(target_a.received.is_empty(), "windup should resolve against the current target, not a captured target")
	_expect(target_b.received.size() == 1, "replacement current target should receive the melee hit")
	if not target_b.received.is_empty():
		_expect(is_equal_approx(float(target_b.received[0].get("amount", 0.0)), enemy.damage * 3.0), "first contact applies the queued strong damage")
		var context: Dictionary = target_b.received[0].get("context", {})
		_expect(String(context.get("attack_id", "")) == first_id, "hit context should carry the committed attack id")
		_expect(String(context.get("contact_range_source", "")) == "standard_melee", "hit context should preserve contact-range provenance")
	_expect(not melee.is_committed(), "resolved hit should clear commitment")
	_expect(not melee.is_eligible(), "recovery should gate immediate restart")

	# The variant's legacy attack_cooldown still maps to host damage_interval;
	# standard melee recovery/redecision remains the baseline cadence.
	var variant = VARIANT_PROFILE.new()
	variant.attack_range = 72.0
	variant.attack_cooldown = 0.05
	enemy.apply_variant(variant)
	_expect(is_equal_approx(enemy.damage_interval, 0.05), "variant cooldown remains the host compatibility value")
	melee.update_recovery(config.recovery_duration + 0.001)
	_expect(melee.get_debug_state().get("redecision_remaining", 0.0) > 0.0, "redecision follows recovery")
	_expect(not melee.is_eligible(), "variant cooldown must not bypass the redecision window")
	melee.update_recovery(config.redecision_delay_sec + 0.001)
	_expect(melee.is_eligible(), "baseline melee becomes eligible after recovery plus redecision")

	# Strong is consumed at commitment even when that first swing whiffs.
	enemy.target = target_a
	target_a.global_position = enemy.global_position + Vector2.RIGHT * 24.0
	_expect(melee.try_start(), "second baseline attack should start")
	_expect(not bool(melee.get_debug_state().get("queued_strong", true)), "only the opening swing receives strong multiplier")
	target_a.global_position = enemy.global_position + Vector2.RIGHT * 400.0
	melee.tick(config.windup_duration + 0.001)
	_expect(target_a.received.is_empty(), "out-of-range first committed swing should whiff")
	_expect(float(melee.get_debug_state().get("recovery_remaining", 0.0)) > 0.0, "whiff should begin recovery")

	# Retargeting follows until the authored lock threshold, then holds facing.
	melee.update_recovery(config.recovery_duration + 0.001)
	melee.update_recovery(config.redecision_delay_sec + 0.01)
	target_a.global_position = enemy.global_position + Vector2.RIGHT * 24.0
	_expect(melee.try_start(), "tracking probe should start")
	target_a.global_position = enemy.global_position + Vector2.UP * 24.0
	melee.tick(0.20)
	var tracked_direction: Vector2 = melee.get_debug_state().get("committed_forward", Vector2.ZERO)
	_expect(tracked_direction.dot(Vector2.UP) > 0.99, "windup should track target before lock")
	melee.tick(0.11)
	var locked_direction: Vector2 = melee.get_debug_state().get("committed_forward", Vector2.ZERO)
	target_a.global_position = enemy.global_position + Vector2.RIGHT * 24.0
	_expect(locked_direction.is_equal_approx(tracked_direction), "windup should stop tracking inside lock window")
	melee.tick(0.12)
	_expect(target_a.received.is_empty(), "target moving outside committed arc should whiff")

	# Shared hit resolution still reports each guarded/dodged result without
	# changing who owns guard or reaction policy.
	for result_mode in [&"blocked", &"parried", &"dodged"]:
		melee.update_recovery(config.recovery_duration + 0.001)
		melee.update_recovery(config.redecision_delay_sec + 0.01)
		target_a.dead = false
		target_a.result_mode = result_mode
		target_a.global_position = enemy.global_position + Vector2.RIGHT * 24.0
		var result_start_count := target_a.received.size()
		_expect(melee.try_start(), "%s result probe should start" % result_mode)
		melee.tick(config.windup_duration + 0.001)
		_expect(target_a.received.size() == result_start_count + 1, "%s must pass through shared hit resolution" % result_mode)
		if target_a.received.size() > result_start_count:
			_expect(target_a.received[-1].get("result") == result_mode, "%s result must be preserved" % result_mode)

	melee.update_recovery(config.recovery_duration + 0.001)
	melee.update_recovery(config.redecision_delay_sec + 0.01)
	target_a.result_mode = &"damaged"

	# A target that becomes dead before contact takes the existing no-target
	# terminal and leaves no stale commitment.
	melee.update_recovery(config.recovery_duration + 0.001)
	melee.update_recovery(config.redecision_delay_sec + 0.01)
	target_a.dead = false
	target_a.global_position = enemy.global_position + Vector2.RIGHT * 24.0
	_expect(melee.try_start(), "no-target terminal probe should start")
	target_a.dead = true
	melee.tick(config.windup_duration + 0.001)
	_expect(not melee.is_committed(), "destroyed target resolution should clear the transaction")

	enemy.queue_free()
	target_a.queue_free()
	target_b.queue_free()
	await process_frame


func _check_contact_sources(fixture: Node2D) -> void:
	var enemy := GRUNT_SCENE.instantiate() as Enemy
	fixture.add_child(enemy)
	await process_frame
	enemy.set_physics_process(false)
	var target := MeleeTarget.new()
	fixture.add_child(target)
	enemy.target = target
	enemy.structure_attack_range = 77.0
	var melee := enemy.get_standard_enemy_melee_ability()
	target.add_to_group("player")
	var player_context := melee.get_contact_context(target, Vector2.RIGHT)
	_expect(is_equal_approx(float(player_context.get("base_contact_range_px", 0.0)), 40.0), "player contact range should default to 40px")
	_expect(String(player_context.get("contact_range_source", "")) == "standard_melee", "player range source should be standard melee")
	_expect(is_equal_approx(float(player_context.get("allowed_range_px", 0.0)), 56.0), "range grace should remain 1.15x + 10px")
	target.remove_from_group("player")
	var structure_context := melee.get_contact_context(target, Vector2.RIGHT)
	_expect(is_equal_approx(float(structure_context.get("base_contact_range_px", 0.0)), 77.0), "structure contact range remains host-owned")
	_expect(String(structure_context.get("contact_range_source", "")) == "structure_melee", "structure range source should be preserved")
	var variant = VARIANT_PROFILE.new()
	variant.attack_range = 83.0
	enemy.apply_variant(variant)
	var variant_context := melee.get_contact_context(target, Vector2.RIGHT)
	_expect(is_equal_approx(float(variant_context.get("base_contact_range_px", 0.0)), 83.0), "variant profile range should continue to override standard contact range")
	_expect(String(variant_context.get("contact_range_source", "")) == "variant_profile", "variant range provenance should remain explicit")
	enemy.queue_free()
	target.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
