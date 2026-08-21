extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const FRAME_COUNT := 8
const FRAME_SIZE := Vector2i(156, 156)
const DAMAGE_TIME := 0.10 + 0.10 + 0.12 + 0.16 + 0.10
const HIT_STOP := 0.13
const ASSET_TRIPLETS := {
	"e": [
		"res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__full_body__unarmed__cosmetic__falcon_reversal_01__e__8f__156.png",
		"res://content/sprites/enemies/enemy_grunt/runtime/body/melee/enemy_grunt__body__melee__falcon_reversal_victim_01__e__8f__156.png",
		"res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__fx__unarmed__cosmetic__falcon_reversal_01__e__8f__156.png",
	],
	"w": [
		"res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__full_body__unarmed__cosmetic__falcon_reversal_01__w__8f__156.png",
		"res://content/sprites/enemies/enemy_grunt/runtime/body/melee/enemy_grunt__body__melee__falcon_reversal_victim_01__w__8f__156.png",
		"res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__fx__unarmed__cosmetic__falcon_reversal_01__w__8f__156.png",
	],
}

const PHASE_NONE := 0
const PHASE_ENTER := 1
const PHASE_EXECUTING := 4

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_source_geometry()
	var root := Node2D.new()
	root.name = "GruntFalconReversalSmokeRoot"
	get_root().add_child(root)
	current_scene = root

	await _run_reversal_case(root, &"w", Vector2.RIGHT, Vector2.ZERO)
	await _run_reversal_case(root, &"e", Vector2.LEFT, Vector2(400.0, 0.0))
	await _validate_ordinary_parry_fallback(root)

	root.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _run_reversal_case(
	root: Node2D,
	expected_direction: StringName,
	falcon_direction: Vector2,
	origin: Vector2
) -> void:
	var grunt := GRUNT_SCENE.instantiate()
	grunt.global_position = origin
	root.add_child(grunt)
	var operator := OPERATOR_SCENE.instantiate()
	operator.global_position = origin + falcon_direction * 24.0
	root.add_child(operator)
	await process_frame
	grunt.set_process(false)
	grunt.set_physics_process(false)
	operator.set_process(false)
	operator.set_physics_process(false)
	grunt.target = operator
	operator.aim_direction = -falcon_direction
	operator.visual_idle_direction = -falcon_direction
	operator.set("_parry_phase", &"active")
	operator.set("_parry_active", true)
	grunt.call("_start_grunt_falcon_punch_windup", falcon_direction)
	grunt.call("_start_grunt_falcon_punch_leap")
	var falcon := grunt.get_grunt_falcon_punch_ability() as GruntFalconPunch
	_assert_true(falcon.get_phase_name() == &"leap", "%s Falcon should enter committed leap" % expected_direction)

	grunt.call("_try_apply_grunt_falcon_punch_hit", true)
	_assert_true(bool(operator.get("_paired_execution_active")), "%s Falcon parry should automatically start reversal" % expected_direction)
	_assert_true(String(operator.get("_paired_execution_kind")) == "falcon_reversal", "paired execution should identify Falcon Reversal")
	_assert_true(String(operator.get("_paired_execution_direction")) == String(expected_direction), "Falcon travel should select the authored %s triplet" % expected_direction)
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_EXECUTING, "Falcon Reversal should enter EXECUTING directly")
	_assert_true(not falcon.is_active(), "execution ownership should fully cancel Falcon movement")
	_assert_true(grunt.get("_critical_breach_marker_vfx") == null and grunt.get("_critical_window_ring_vfx") == null, "automatic reversal should not create BREACH/countdown presentation")

	var operator_body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var operator_fx := operator.get_node("ModularUpperFxSprite") as AnimatedSprite2D
	var victim_body := grunt.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert_animation_geometry(operator_body, StringName("operator_falcon_reversal_%s" % expected_direction))
	_assert_animation_geometry(operator_fx, StringName("operator_falcon_reversal_fx_%s" % expected_direction))
	_assert_animation_geometry(victim_body, StringName("falcon_reversal_victim_%s" % expected_direction))
	var ordinary_profile: Dictionary = operator.call(
		"_get_paired_execution_profile",
		&"ordinary_critical",
		&"s"
	)
	_assert_true(ordinary_profile.get("frame_size") == Vector2i(96, 96), "ordinary paired critical must remain 96x96")
	var execution_anchor := grunt.get_node("CriticalExecutionAnchor") as Marker2D
	_assert_true(operator.global_position.is_equal_approx(grunt.global_position), "Operator and victim should share one world root")
	_assert_true(operator.global_position.is_equal_approx(execution_anchor.global_position), "shared root should equal CriticalExecutionAnchor")
	_assert_true(operator_body.position.is_zero_approx() and victim_body.position.is_zero_approx() and operator_fx.position.is_zero_approx(), "156px authored canvases must use zero runtime offsets")

	grunt.health = 999.0
	grunt.max_health = 999.0
	var health_before := float(grunt.health)
	operator.call("_update_paired_execution", DAMAGE_TIME - 0.001)
	_assert_true(is_equal_approx(float(grunt.health), health_before), "damage must not occur before runtime index 5")
	operator.call("_update_paired_execution", 0.002)
	var health_after := float(grunt.health)
	_assert_true(health_after < health_before, "entering runtime index 5/source frame 6 should damage once")
	_assert_true(operator_body.frame == 5 and operator_fx.frame == 5 and victim_body.frame == 5, "body/victim/FX should enter contact frame on the same tick")
	_assert_true(float(operator.get("_paired_execution_hit_stop_remaining")) >= 0.128, "contact should begin 130ms paired hit-stop")
	operator.call("_update_paired_execution", HIT_STOP - 0.002)
	_assert_true(is_equal_approx(float(grunt.health), health_after), "hit-stop must not duplicate damage")
	_assert_true(operator_body.frame == 5 and operator_fx.frame == 5 and victim_body.frame == 5, "all three layers should freeze together on contact")
	operator.call("_update_paired_execution", 2.0)
	_assert_true(not bool(operator.get("_paired_execution_active")), "completion should restore Operator ownership")
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_NONE, "completion should release enemy execution ownership")
	_assert_true(falcon.recent_parry_timer > 0.0, "Falcon parry lockout should survive reversal")

	operator.queue_free()
	grunt.queue_free()
	await process_frame


func _validate_ordinary_parry_fallback(root: Node2D) -> void:
	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	await process_frame
	grunt.set_process(false)
	grunt.set_physics_process(false)
	grunt.call("apply_parry_stagger", Vector2.RIGHT, 0.55, 0.0)
	_assert_true(int(grunt.get("_parry_critical_phase")) == PHASE_ENTER, "ordinary non-Falcon parry should retain critical-open flow")
	grunt.queue_free()
	await process_frame


func _validate_source_geometry() -> void:
	for direction in ASSET_TRIPLETS:
		var geometry: Array[Vector2i] = []
		for path in ASSET_TRIPLETS[direction]:
			_assert_true(ResourceLoader.exists(path), "Required Falcon Reversal asset missing: %s" % path)
			var texture := load(path) as Texture2D
			if texture == null:
				continue
			var size := Vector2i(texture.get_width(), texture.get_height())
			geometry.append(Vector2i(size.x / FRAME_COUNT, size.y))
			_assert_true(size.x % FRAME_COUNT == 0, "%s width must divide into eight horizontal frames" % path)
			_assert_true(size.y == FRAME_SIZE.y, "%s must preserve the authored 156px height" % path)
		_assert_true(geometry.size() == 3 and geometry.all(func(value: Vector2i) -> bool: return value == FRAME_SIZE), "%s body/victim/FX must share 156x156 frame geometry" % direction)


func _assert_animation_geometry(sprite: AnimatedSprite2D, animation_name: StringName) -> void:
	var frames := sprite.sprite_frames
	_assert_true(frames != null and frames.has_animation(animation_name), "%s should be registered" % animation_name)
	if frames == null or not frames.has_animation(animation_name):
		return
	_assert_true(frames.get_frame_count(animation_name) == FRAME_COUNT, "%s should expose exactly eight frames" % animation_name)
	_assert_true(is_equal_approx(frames.get_animation_speed(animation_name), 12.0), "%s should expose 12 FPS source metadata" % animation_name)
	var frame := frames.get_frame_texture(animation_name, 0) as AtlasTexture
	_assert_true(frame != null and frame.region.size == Vector2(FRAME_SIZE), "%s should use the 156x156 execution profile" % animation_name)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
