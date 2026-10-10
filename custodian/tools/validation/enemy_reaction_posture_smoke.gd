extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const SAVAGE_SCENE := preload("res://game/actors/enemies/enemy_savage.tscn")
const HIT := preload("res://game/systems/combat/combat_constants.gd")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	var grunt := GRUNT_SCENE.instantiate() as Enemy
	var marine := MARINE_SCENE.instantiate() as Enemy
	var savage := SAVAGE_SCENE.instantiate() as Enemy
	fixture.add_child(grunt)
	fixture.add_child(marine)
	fixture.add_child(savage)
	await process_frame
	grunt.set_physics_process(false)
	marine.set_physics_process(false)
	savage.set_physics_process(false)

	_check(grunt.reaction_config.hit_recoil_duration == 0.12, "default recoil tuning changed")
	_check(grunt.reaction_config.stagger_duration == 0.35, "default stagger tuning changed")
	_check(grunt.reaction_config.posture_max == 100.0, "default posture maximum changed")
	_check(grunt.reaction_config.posture_recovery_delay == 1.25, "posture recovery delay changed")
	_check(grunt.reaction_config.posture_recovery_rate == 26.0, "posture recovery rate changed")
	_check(grunt.reaction_config.light_flinch_cooldown == 0.70, "light-flinch cooldown changed")
	_check(grunt.reaction_config.crit_hit_duration == 0.8, "ordinary critical-hit duration changed")
	_check(grunt.reaction_config.crit_recovery_duration == 0.625, "ordinary critical recovery changed")
	_check(marine.reaction_config.resists_light_flinch, "Marine lost light-flinch resistance")
	_check(is_equal_approx(savage.reaction_config.stagger_duration, 0.45), "Savage stagger override changed")
	_check(is_equal_approx(grunt.parry_critical_config.minimum_window_sec, 0.8), "critical minimum window changed")
	_check(is_equal_approx(grunt.parry_critical_config.capture_range_px, 72.0), "critical capture range changed")
	_check(grunt.parry_critical_config.operator_offset == Vector2.ZERO, "critical execution offset changed")

	grunt.call("take_damage", 1.0, HIT.HitStrength.LIGHT, 30.0)
	_check(is_equal_approx(float(grunt.get_posture_status().current), 30.0), "posture accumulation changed")
	_check(float(grunt.get_reaction_debug_state().recoil_remaining) > 0.0, "uncommitted LIGHT should recoil")
	grunt.call("_update_reaction_timers", 0.13)
	grunt.call("take_damage", 1.0, HIT.HitStrength.LIGHT, 10.0)
	_check(is_zero_approx(float(grunt.get_reaction_debug_state().recoil_remaining)), "cooldown LIGHT should suppress gameplay recoil")
	_check(is_equal_approx(float(grunt.get_posture_status().current), 40.0), "cooldown suppression must preserve posture damage")
	grunt.call("_update_reaction_timers", 0.71)
	grunt.call("take_damage", 1.0, HIT.HitStrength.LIGHT, 10.0)
	_check(float(grunt.get_reaction_debug_state().recoil_remaining) > 0.0, "LIGHT recoil should return after cooldown")

	grunt.reset_reaction_state()
	grunt.call("take_damage", 1.0, HIT.HitStrength.LIGHT, 60.0)
	grunt.call("take_damage", 1.0, HIT.HitStrength.LIGHT, 40.0)
	_check(float(grunt.get_reaction_debug_state().stagger_remaining) > 0.0, "posture break must stagger")
	_check(is_zero_approx(float(grunt.get_posture_status().current)), "posture break must reset posture")
	grunt.reset_reaction_state()
	grunt.call("take_damage", 1.0, HIT.HitStrength.HEAVY, 10.0)
	_check(float(grunt.get_reaction_debug_state().stagger_remaining) > 0.0, "HEAVY must stagger independently of posture threshold")
	grunt.reset_reaction_state()
	grunt.call("take_damage", 1.0, HIT.HitStrength.INTERRUPT, 0.0)
	_check(float(grunt.get_reaction_debug_state().stagger_remaining) > 0.0, "INTERRUPT must stagger")

	marine.call("take_damage", 1.0, HIT.HitStrength.LIGHT, 8.0)
	_check(is_zero_approx(float(marine.get_reaction_debug_state().recoil_remaining)), "Marine LIGHT hit must be armor-deflected")
	_check(is_equal_approx(float(marine.get_posture_status().current), 8.0), "Marine resistance must not suppress posture accumulation")

	grunt.reset_reaction_state()
	grunt.request_recoil_reaction(0.12)
	_check(is_equal_approx(float(grunt.get_reaction_debug_state().recoil_remaining), 0.12), "semantic recoil request changed duration")
	grunt.reset_reaction_state()
	grunt.request_stagger_reaction(0.35)
	_check(is_equal_approx(float(grunt.get_reaction_debug_state().stagger_remaining), 0.35), "semantic stagger request changed duration")
	grunt.reset_reaction_state()
	grunt.call("_start_crit_reaction")
	_check(is_equal_approx(float(grunt.get_reaction_debug_state().crit_remaining), 0.8), "ordinary critical-hit reaction changed duration")
	grunt.call("_update_reaction_timers", 0.81)
	_check(float(grunt.get_reaction_debug_state().crit_recovery_remaining) > 0.0, "ordinary critical hit must enter recovery")
	_check(is_zero_approx(float(grunt.get_reaction_debug_state().crit_remaining)), "ordinary critical reaction did not finish")

	grunt.reset_reaction_state()
	grunt.call("apply_melee_impact", "vigil_dagger_fast_03:default", Vector2.RIGHT, 0.0)
	_check(is_equal_approx(float(grunt.get_reaction_debug_state().stagger_remaining), 0.33), "Grunt dagger finisher stagger duration changed")
	marine.call("apply_melee_impact", "vigil_dagger_fast_03:default", Vector2.RIGHT, 0.0)
	_check(is_equal_approx(float(marine.get_reaction_debug_state().recoil_remaining), 0.22), "Marine dagger finisher recoil duration changed")
	savage.call("apply_melee_impact", "vigil_dagger_fast_03:default", Vector2.RIGHT, 0.0)
	_check(is_equal_approx(float(savage.get_reaction_debug_state().recoil_remaining), 0.20), "Savage dagger finisher recoil duration changed")

	fixture.queue_free()
	await process_frame
	if not _failed:
		print("[EnemyReactionPostureSmoke] PASS")
		quit(0)
	else:
		quit(1)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[EnemyReactionPostureSmoke] " + message)
