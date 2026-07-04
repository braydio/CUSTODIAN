extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "GruntParryCritReactionSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	await process_frame

	grunt.call("apply_parry_stagger", Vector2.RIGHT, 0.55, 44.0)
	await process_frame

	var body_sprite := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var fx_sprite := grunt.get_node_or_null("CustomEnemyFxSprite") as AnimatedSprite2D
	_assert_true(float(grunt.get("_stagger_timer")) > 0.0, "parried grunt should enter stagger timer first")
	_assert_true(float(grunt.get("_parry_critical_window_timer")) > 0.0, "parried grunt should open a critical-hit window")
	_assert_true(is_equal_approx(float(grunt.get("_crit_timer")), 0.0), "parry alone should not start crit_01")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "stagger_s", "parried grunt should play stagger_s before critical hit")
	_assert_true(fx_sprite == null or not fx_sprite.visible, "parry stagger should not play critical FX until the follow-up hit")

	grunt.call("_update_reaction_timers", 0.56)
	var stagger_frames := body_sprite.sprite_frames if body_sprite != null else null
	var last_stagger_frame := stagger_frames.get_frame_count("stagger_s") - 1 if stagger_frames != null and stagger_frames.has_animation("stagger_s") else -1
	_assert_true(is_equal_approx(float(grunt.get("_stagger_timer")), 0.0), "stagger timer should clear before the critical window ends")
	_assert_true(float(grunt.get("_parry_critical_window_timer")) > 0.0, "critical window should remain briefly after stagger animation time")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "stagger_s" and body_sprite.frame == last_stagger_frame, "critical window placeholder should freeze the last stagger frame")

	grunt.call("take_damage", 12.0)
	await process_frame
	_assert_true(is_equal_approx(float(grunt.get("_parry_critical_window_timer")), 0.0), "follow-up hit should consume the critical window")
	_assert_true(float(grunt.get("_crit_timer")) > 0.0, "follow-up hit during stagger should start crit_01")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "crit_s", "follow-up hit should play crit_s body animation")
	_assert_true(fx_sprite != null and fx_sprite.visible and String(fx_sprite.animation) == "crit_fx_s", "follow-up hit should play crit_fx_s overlay")

	grunt.call("_update_reaction_timers", float(grunt.get("crit_hit_duration")) + 0.01)
	_assert_true(is_equal_approx(float(grunt.get("_crit_timer")), 0.0), "crit timer should clear after crit hit duration")
	_assert_true(float(grunt.get("_crit_recovery_timer")) > 0.0, "crit_01 should enter crit recovery")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "crit_recovery_s", "crit recovery should play crit_recovery_s")

	if _failed:
		push_error("grunt_parry_crit_reaction_smoke failed")
		quit(1)
		return
	print("[GruntParryCritReactionSmoke] parry stagger opens a critical window, then hit routes to crit/recovery.")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
