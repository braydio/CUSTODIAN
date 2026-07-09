extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const PARRY_CONTACT_SPARK_SCENE := preload("res://game/vfx/combat/parry_contact_spark_vfx.tscn")
const REQUIRED_VFX_ASSETS := [
	"res://content/sprites/effects/combat/critical/combat_fx__parry_success_hit_spark_01__6f__128.png",
	"res://content/sprites/effects/combat/critical/combat_fx__breach_alert__8f__96-48.png",
	"res://content/sprites/effects/combat/critical/combat_fx__breach_timer_reticle__12f__128.png",
]

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for asset_path in REQUIRED_VFX_ASSETS:
		_assert_true(ResourceLoader.exists(asset_path), "[CombatVfx] Required asset missing: %s" % asset_path)
	var root := Node2D.new()
	root.name = "GruntParryCritReactionSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	await process_frame

	var body_sprite := grunt.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var fx_sprite := grunt.get_node_or_null("CustomEnemyFxSprite") as AnimatedSprite2D
	var contact_spark := PARRY_CONTACT_SPARK_SCENE.instantiate()
	root.add_child(contact_spark)
	var contact_sprite := contact_spark.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(contact_sprite != null and contact_sprite.sprite_frames.get_frame_count("contact") == 6, "parry contact spark should use the required 6-frame strip")
	await create_timer(0.35).timeout
	_assert_true(not is_instance_valid(contact_spark), "parry contact spark should auto-free after its non-looping animation")
	fx_sprite.visible = true
	fx_sprite.play("flinch_fx_s")
	grunt.call("apply_parry_stagger", Vector2.RIGHT, 0.55, 44.0)
	await process_frame
	_assert_true(float(grunt.get("_stagger_timer")) > 0.0, "parried grunt should enter stagger timer first")
	_assert_true(float(grunt.get("_parry_critical_window_timer")) > 0.0, "parried grunt should open a critical-hit window")
	_assert_true(is_equal_approx(float(grunt.get("_crit_timer")), 0.0), "parry alone should not start crit_01")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "stagger_s", "parried grunt should play stagger_s before critical hit")
	_assert_true(fx_sprite == null or not fx_sprite.visible, "parry stagger should clear standard flinch FX and wait for the special critical FX")
	var breach_marker := grunt.get("_critical_breach_marker_vfx") as Node2D
	var countdown_ring := grunt.get("_critical_window_ring_vfx") as Node2D
	_assert_true(breach_marker != null and is_instance_valid(breach_marker), "critical-open should attach the BREACH marker")
	_assert_true(countdown_ring != null and is_instance_valid(countdown_ring), "critical-open should attach the countdown ring")
	var breach_sprite := breach_marker.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var ring_sprite := countdown_ring.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(breach_sprite != null and breach_sprite.sprite_frames.get_frame_count("breach") == 8, "BREACH marker should use the required 8-frame strip")
	_assert_true(ring_sprite != null and ring_sprite.sprite_frames.get_frame_count("countdown") == 12, "countdown ring should use the required 12-frame strip")

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
	_assert_true(grunt.get("_critical_breach_marker_vfx") == null, "critical hit should clear BREACH marker ownership")
	_assert_true(grunt.get("_critical_window_ring_vfx") == null, "critical hit should clear countdown ring ownership")
	_assert_true(not is_instance_valid(breach_marker), "consumed BREACH marker should be freed")
	_assert_true(not is_instance_valid(countdown_ring), "consumed countdown ring should be freed")
	var visual := grunt.get_node_or_null("Visual") as ColorRect
	_assert_true(visual == null or visual.modulate != Color.WHITE, "critical follow-up should not apply the standard white body hit flash")

	grunt.call("_update_reaction_timers", float(grunt.get("crit_hit_duration")) + 0.01)
	_assert_true(is_equal_approx(float(grunt.get("_crit_timer")), 0.0), "crit timer should clear after crit hit duration")
	_assert_true(float(grunt.get("_crit_recovery_timer")) > 0.0, "crit_01 should enter crit recovery")
	_assert_true(body_sprite != null and String(body_sprite.animation) == "crit_recovery_s", "crit recovery should play crit_recovery_s")

	var expiry_grunt := GRUNT_SCENE.instantiate()
	root.add_child(expiry_grunt)
	await process_frame
	expiry_grunt.call("apply_parry_stagger", Vector2.LEFT, 0.55, 0.0)
	var expiry_marker := expiry_grunt.get("_critical_breach_marker_vfx") as Node2D
	var expiry_ring := expiry_grunt.get("_critical_window_ring_vfx") as Node2D
	var expiry_duration := float(expiry_grunt.get("_parry_critical_window_timer"))
	expiry_grunt.call("_update_reaction_timers", expiry_duration + 0.01)
	await process_frame
	_assert_true(is_equal_approx(float(expiry_grunt.get("_parry_critical_window_timer")), 0.0), "unconsumed critical window should expire")
	_assert_true(expiry_grunt.get("_critical_breach_marker_vfx") == null, "expired critical window should clear BREACH marker ownership")
	_assert_true(expiry_grunt.get("_critical_window_ring_vfx") == null, "expired critical window should clear countdown ring ownership")
	_assert_true(not is_instance_valid(expiry_marker), "expired BREACH marker should be freed")
	_assert_true(not is_instance_valid(expiry_ring), "expired countdown ring should be freed")

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
