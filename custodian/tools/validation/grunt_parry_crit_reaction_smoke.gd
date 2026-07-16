extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const PARRY_CONTACT_SPARK_SCENE := preload("res://game/vfx/combat/parry_contact_spark_vfx.tscn")
const REQUIRED_ASSETS := [
	"res://content/sprites/effects/combat/critical/combat_fx__parry_success_hit_spark_01__6f__128.png",
	"res://content/sprites/effects/combat/critical/combat_fx__breach_alert__8f__96-48.png",
	"res://content/sprites/effects/combat/critical/combat_fx__breach_timer_reticle__12f__128.png",
	"res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_enter_01__s__5f__96.png",
	"res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_open_hold_01__s__4f__96.png",
	"res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__parry_critical_recover_01__s__5f__96.png",
	"res://content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__s__8f__96.png",
	"res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__s__8f__96.png",
	"res://content/sprites/operator/runtime/fx/unarmed/operator__fx__unarmed__critical_execution_01__s__8f__96.png",
]

const PHASE_NONE := 0
const PHASE_ENTER := 1
const PHASE_HOLD := 2
const PHASE_RECOVER := 3
const PHASE_EXECUTING := 4
const DAMAGE_TIME := 3.0 / 12.0

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for asset_path in REQUIRED_ASSETS:
		_assert_true(ResourceLoader.exists(asset_path), "Required asset missing: %s" % asset_path)
	var enter_final_bounds := _frame_alpha_bounds(REQUIRED_ASSETS[3], 4)
	var hold_final_bounds := _frame_alpha_bounds(REQUIRED_ASSETS[4], 3)
	var recover_first_bounds := _frame_alpha_bounds(REQUIRED_ASSETS[5], 0)
	_assert_true(abs(enter_final_bounds.position.x - hold_final_bounds.position.x) <= 2, "enter-final and hold-final artwork should share the standalone enemy root")
	_assert_true(abs(hold_final_bounds.position.x - recover_first_bounds.position.x) <= 2, "hold-final and recover-first artwork should not pop laterally")
	_assert_true(abs(hold_final_bounds.end.y - recover_first_bounds.end.y) <= 2, "hold-final and recover-first planted-foot height should remain continuous")

	var root := Node2D.new()
	root.name = "GruntParryCritReactionSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	var contact_spark := PARRY_CONTACT_SPARK_SCENE.instantiate()
	root.add_child(contact_spark)
	var contact_sprite := contact_spark.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(contact_sprite != null and contact_sprite.sprite_frames.get_frame_count("contact") == 6, "parry contact spark should use six frames")
	await create_timer(0.35).timeout
	_assert_true(not is_instance_valid(contact_spark), "parry contact spark should auto-free")

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	var grunt := GRUNT_SCENE.instantiate()
	grunt.global_position = Vector2(40.0, 0.0)
	root.add_child(grunt)
	await process_frame

	var body_sprite := grunt.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var fx_sprite := grunt.get_node("CustomEnemyFxSprite") as AnimatedSprite2D
	fx_sprite.visible = true
	fx_sprite.play("flinch_fx_s")
	grunt.call("apply_parry_stagger", Vector2.RIGHT, 0.55, 0.0)
	var standalone_grunt_root: Vector2 = grunt.global_position
	var independent_operator_root: Vector2 = operator.global_position
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_ENTER, "parry should enter critical-open enter")
	_assert_true(String(body_sprite.animation) == "critical_open_enter_s", "enter should play critical_open_enter_s")
	_assert_animation(body_sprite.sprite_frames, "critical_open_enter_s", 5, 12.0, false)
	_assert_true(float(grunt.get("_parry_critical_window_timer")) > 0.0, "parry should open enemy-owned opportunity time")
	_assert_true(not fx_sprite.visible, "opening should clear ordinary flinch FX")
	var marker := grunt.get("_critical_breach_marker_vfx") as Node2D
	var ring := grunt.get("_critical_window_ring_vfx") as Node2D
	_assert_true(marker != null and is_instance_valid(marker), "BREACH marker should persist during enter")
	_assert_true(ring != null and is_instance_valid(ring), "countdown ring should persist during enter")
	_assert_true(bool(grunt.call("suppresses_normal_targeting_presentation")), "enter should suppress the normal target ring")

	var enter_duration := body_sprite.sprite_frames.get_frame_count("critical_open_enter_s") / body_sprite.sprite_frames.get_animation_speed("critical_open_enter_s")
	grunt.call("_update_reaction_timers", enter_duration + 0.001)
	_assert_true(grunt.global_position.is_equal_approx(standalone_grunt_root), "enter-to-hold should preserve the enemy standalone root")
	_assert_true(operator.global_position.is_equal_approx(independent_operator_root), "critical-open phases must not snap the Operator to the enemy")
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_HOLD, "enter completion should transition to hold")
	_assert_true(String(body_sprite.animation) == "critical_open_hold_s", "hold should play critical_open_hold_s")
	_assert_animation(body_sprite.sprite_frames, "critical_open_hold_s", 4, 6.0, true)
	_assert_true(is_instance_valid(marker) and is_instance_valid(ring), "indicators should persist through hold")
	_assert_true(bool(grunt.call("can_receive_parry_critical_from", operator)), "enter/hold opportunity should validate its nearby attacker")

	var execution_anchor := grunt.get_node("CriticalExecutionAnchor") as Marker2D
	var operator_body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var operator_fx := operator.get_node("ModularUpperFxSprite") as AnimatedSprite2D
	var operator_body_original_position := operator_body.position
	var operator_fx_original_position := operator_fx.position
	var grunt_body_original_position := body_sprite.position
	var shared_root_offset: Vector2 = grunt.call("get_parry_critical_operator_offset")
	_assert_true(execution_anchor.position.is_zero_approx(), "CriticalExecutionAnchor should be local zero")
	_assert_true(shared_root_offset.is_zero_approx(), "shared-root execution offset should be zero")
	operator.call("_start_critical_attack", grunt)
	_assert_true(bool(operator.get("_paired_execution_active")), "valid input should start paired execution")
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_EXECUTING, "reservation should atomically enter executing")
	_assert_true(String(operator_body.animation) == "operator_critical_execution_s", "Operator should use semantic execution body")
	_assert_true(String(operator_fx.animation) == "operator_critical_execution_fx_s", "Operator should use semantic execution FX")
	_assert_true(String(body_sprite.animation) == "critical_execution_victim_s", "enemy victim should start on the reservation tick")
	_assert_animation(operator_body.sprite_frames, "operator_critical_execution_s", 8, 12.0, false)
	_assert_animation(operator_fx.sprite_frames, "operator_critical_execution_fx_s", 8, 12.0, false)
	_assert_animation(body_sprite.sprite_frames, "critical_execution_victim_s", 8, 12.0, false)
	_assert_true(operator.global_position.is_equal_approx(grunt.global_position), "Operator and victim should start on one shared world root")
	_assert_true(operator.global_position.is_equal_approx(execution_anchor.global_position), "shared world root should equal execution anchor")
	_assert_true(operator_body.position.is_zero_approx() and body_sprite.position.is_zero_approx() and operator_fx.position.is_zero_approx(), "paired body/victim/FX layers should use local zero during execution")
	_assert_true(grunt.get("_critical_breach_marker_vfx") == null and grunt.get("_critical_window_ring_vfx") == null, "reservation should clear both indicators")
	_assert_true((grunt.call("reserve_parry_critical", operator) as Dictionary).is_empty(), "a second reservation should be rejected")

	grunt.health = 999.0
	grunt.max_health = 999.0
	var health_before := float(grunt.health)
	operator.call("_update_paired_execution", DAMAGE_TIME - 0.01)
	_assert_true(is_equal_approx(float(grunt.health), health_before), "damage must remain zero before frame 3")
	_assert_true(operator.global_position.is_equal_approx(grunt.global_position), "shared execution roots should remain equal during playback")
	_assert_true(operator_body.frame == operator_fx.frame and operator_body.frame == body_sprite.frame, "body, FX, and victim should share one frame index")
	operator.call("_update_paired_execution", 0.02)
	var health_after_impact := float(grunt.health)
	_assert_true(health_after_impact < health_before, "crossing frame 3 should apply damage")
	operator.call("_update_paired_execution", 0.02)
	_assert_true(is_equal_approx(float(grunt.health), health_after_impact), "damage should apply exactly once")
	_assert_true(operator_body.frame == operator_fx.frame and operator_body.frame == body_sprite.frame, "all paired sprites should remain synchronized after impact")
	operator.call("_update_paired_execution", 1.0)
	_assert_true(not bool(operator.get("_paired_execution_active")), "normal completion should unlock Operator")
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_NONE, "normal completion should release enemy execution ownership")
	_assert_true(float(grunt.get("_crit_recovery_timer")) > 0.0, "nonlethal completion should enter crit recovery")
	_assert_true(String(body_sprite.animation) == "crit_recovery_s", "nonlethal completion should play crit_recovery_s")
	_assert_true(not operator_fx.visible, "cleanup should hide execution FX")
	_assert_true(operator_body.position.is_equal_approx(operator_body_original_position), "cleanup should restore Operator body local position")
	_assert_true(operator_fx.position.is_equal_approx(operator_fx_original_position), "cleanup should restore execution FX local position")
	_assert_true(body_sprite.position.is_equal_approx(grunt_body_original_position), "cleanup should restore victim body local position")

	var expiry_grunt := GRUNT_SCENE.instantiate()
	expiry_grunt.global_position = Vector2(120.0, 0.0)
	root.add_child(expiry_grunt)
	await process_frame
	var expiry_body := expiry_grunt.get_node("AnimatedSprite2D") as AnimatedSprite2D
	expiry_grunt.call("apply_parry_stagger", Vector2.LEFT, 0.55, 8.0)
	var expiry_standalone_root: Vector2 = expiry_grunt.global_position
	var expiry_marker := expiry_grunt.get("_critical_breach_marker_vfx") as Node2D
	var expiry_ring := expiry_grunt.get("_critical_window_ring_vfx") as Node2D
	var expiry_duration := float(expiry_grunt.get("_parry_critical_window_timer"))
	expiry_grunt.call("_update_reaction_timers", expiry_duration + 0.01)
	await process_frame
	_assert_true(int(expiry_grunt.get("_parry_critical_phase")) == PHASE_RECOVER, "unused expiry should enter recover")
	_assert_true(String(expiry_body.animation) == "critical_open_recover_s", "expiry should play critical_open_recover_s")
	_assert_animation(expiry_body.sprite_frames, "critical_open_recover_s", 5, 10.0, false)
	_assert_true(not is_instance_valid(expiry_marker) and not is_instance_valid(expiry_ring), "expiry should free both indicators")
	_assert_true(expiry_grunt.global_position.is_equal_approx(expiry_standalone_root), "expiry should not move the standalone enemy root")
	_assert_true(bool(expiry_grunt.call("suppresses_normal_targeting_presentation")), "recover should keep the normal target ring suppressed")
	operator.set("_combat_target", expiry_grunt)
	operator.call("_update_target_ring")
	var normal_target_ring := operator.get("_target_ring") as Node2D
	_assert_true(normal_target_ring == null or not normal_target_ring.visible, "Operator target ring should remain hidden during critical-open recover")
	var recover_duration := expiry_body.sprite_frames.get_frame_count("critical_open_recover_s") / expiry_body.sprite_frames.get_animation_speed("critical_open_recover_s")
	expiry_grunt.call("_update_reaction_timers", recover_duration + 0.01)
	_assert_true(int(expiry_grunt.get("_parry_critical_phase")) == PHASE_NONE, "recover completion should return to normal behavior")
	_assert_true(expiry_grunt.global_position.is_equal_approx(expiry_standalone_root), "recover completion should not introduce a lateral root snap")
	_assert_true(not bool(expiry_grunt.call("suppresses_normal_targeting_presentation")), "normal targeting should resume after recover completes")

	var cancel_operator := OPERATOR_SCENE.instantiate()
	cancel_operator.global_position = Vector2(220.0, 0.0)
	root.add_child(cancel_operator)
	var cancel_grunt := GRUNT_SCENE.instantiate()
	cancel_grunt.global_position = Vector2(250.0, 0.0)
	root.add_child(cancel_grunt)
	await process_frame
	cancel_grunt.call("apply_parry_stagger", Vector2.LEFT, 0.55, 0.0)
	var original_layer: int = int(cancel_operator.collision_layer)
	var original_mask: int = int(cancel_operator.collision_mask)
	cancel_operator.call("_start_critical_attack", cancel_grunt)
	cancel_operator.call("_cleanup_paired_execution", false, &"smoke_interrupt")
	_assert_true(not bool(cancel_operator.get("_paired_execution_active")), "interruption should clear Operator execution state")
	_assert_true(cancel_operator.collision_layer == original_layer and cancel_operator.collision_mask == original_mask, "cleanup should restore exact collision values")
	_assert_true(int(cancel_grunt.get("_parry_critical_phase")) == PHASE_NONE and float(cancel_grunt.get("_crit_recovery_timer")) > 0.0, "interruption should release a live enemy into recovery")

	var lethal_operator := OPERATOR_SCENE.instantiate()
	lethal_operator.global_position = Vector2(340.0, 0.0)
	root.add_child(lethal_operator)
	var lethal_grunt := GRUNT_SCENE.instantiate()
	lethal_grunt.global_position = Vector2(370.0, 0.0)
	lethal_grunt.health = 1.0
	lethal_grunt.max_health = 1.0
	root.add_child(lethal_grunt)
	await process_frame
	lethal_grunt.call("apply_parry_stagger", Vector2.LEFT, 0.55, 0.0)
	lethal_operator.call("_start_critical_attack", lethal_grunt)
	lethal_operator.call("_update_paired_execution", DAMAGE_TIME + 0.01)
	_assert_true(bool(lethal_grunt.dead), "lethal frame-3 damage should route to death")
	lethal_operator.call("_update_paired_execution", 1.0)
	_assert_true(not bool(lethal_operator.get("_paired_execution_active")), "lethal completion should still clean Operator state")

	if _failed:
		push_error("grunt_parry_crit_reaction_smoke failed")
		quit(1)
		return
	print("[GruntParryCritReactionSmoke] authored open phases and frame-3 paired execution passed.")
	quit(0)


func _assert_animation(frames: SpriteFrames, animation_name: StringName, frame_count: int, fps: float, loop: bool) -> void:
	_assert_true(frames != null and frames.has_animation(animation_name), "%s should be registered" % animation_name)
	if frames == null or not frames.has_animation(animation_name):
		return
	_assert_true(frames.get_frame_count(animation_name) == frame_count, "%s should expose %d frames" % [animation_name, frame_count])
	_assert_true(is_equal_approx(frames.get_animation_speed(animation_name), fps), "%s should run at %.1f FPS" % [animation_name, fps])
	_assert_true(frames.get_animation_loop(animation_name) == loop, "%s loop contract should match" % animation_name)


func _frame_alpha_bounds(resource_path: String, frame_index: int) -> Rect2i:
	var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		return Rect2i()
	var minimum := Vector2i(96, 96)
	var maximum := Vector2i(-1, -1)
	var frame_x := frame_index * 96
	for y in range(96):
		for x in range(96):
			if image.get_pixel(frame_x + x, y).a <= 0.0:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
