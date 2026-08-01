extends SceneTree

const OPERATOR_SCENE := preload(
	"res://game/actors/operator/operator.tscn"
)
const DAGGER_DEFINITION := preload(
	"res://game/actors/operator/vigil_pattern_dagger_definition.tres"
)
const DAGGER_PROFILE := preload(
	"res://game/actors/operator/attacks/"
	+ "vigil_pattern_dagger_fast_01.tres"
)

const BODY_ANIMATIONS := [
	&"vigil_dagger_fast_01_right",
	&"vigil_dagger_fast_01_left",
	&"vigil_dagger_fast_02_right",
	&"vigil_dagger_fast_02_left",
	&"vigil_dagger_fast_03_right",
	&"vigil_dagger_fast_03_left",
]
const OVERLAY_ANIMATIONS := [
	&"vigil_dagger_fast_01_weapon_right",
	&"vigil_dagger_fast_01_weapon_left",
	&"vigil_dagger_fast_02_weapon_right",
	&"vigil_dagger_fast_02_weapon_left",
	&"vigil_dagger_fast_03_weapon_right",
	&"vigil_dagger_fast_03_weapon_left",
]
const FX_ANIMATIONS := [
	&"vigil_dagger_fast_01_fx_right",
	&"vigil_dagger_fast_01_fx_left",
	&"vigil_dagger_fast_02_fx_right",
	&"vigil_dagger_fast_02_fx_left",
	&"vigil_dagger_fast_03_fx_right",
	&"vigil_dagger_fast_03_fx_left",
]

var _errors: Array[String] = []
var _fixture_root: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_fixture_root = Node2D.new()
	_fixture_root.name = "OperatorVigilDaggerSmokeRoot"
	root.add_child(_fixture_root)
	current_scene = _fixture_root

	_validate_definition()
	var operator := await _create_operator()
	_validate_default_scene(operator)
	_validate_frame_resources(operator)
	_validate_attack_playback(operator)
	await _validate_open_space_drive(operator)
	await _validate_wall_truncation(operator)
	await _validate_cancellation_paths()

	operator.queue_free()
	_fixture_root.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[OperatorVigilDaggerSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[OperatorVigilDaggerSmoke] %s" % error)
	quit(1)


func _create_operator() -> CharacterBody2D:
	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	_fixture_root.add_child(operator)
	await process_frame
	operator.set_physics_process(false)
	operator.set_process(false)
	operator.set("unstuck_enabled", false)
	_select_dagger(operator)
	return operator


func _select_dagger(operator: Node) -> void:
	operator.call("_rebuild_armed_weapon_list")
	var weapons := operator.get("armed_weapons") as Array
	var index := weapons.find(DAGGER_DEFINITION)
	_assert(index >= 0, "dagger is not in the armed weapon list")
	if index >= 0:
		operator.call("_apply_armed_selection", index)
		operator.call("_refresh_primary_weapon_state")
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)


func _validate_definition() -> void:
	_assert(DAGGER_DEFINITION != null, "dagger definition did not load")
	_assert(
		DAGGER_DEFINITION.weapon_id == &"vigil_pattern_dagger",
		"dagger weapon_id is wrong"
	)
	_assert(
		DAGGER_DEFINITION.primary_intent == "melee_fast",
		"dagger primary intent is not melee_fast"
	)
	_assert(
		DAGGER_DEFINITION.secondary_intent.is_empty(),
		"dagger secondary intent must remain disabled"
	)
	_assert(
		DAGGER_DEFINITION.heavy_attack_profile == null,
		"dagger heavy attack must remain unconfigured"
	)
	_assert(
		DAGGER_DEFINITION.fast_chain_keys
		== PackedStringArray([
			"vigil_dagger_fast_01",
			"vigil_dagger_fast_02",
			"vigil_dagger_fast_03",
		]),
		"dagger chain keys are not Fast 01/02/03"
	)
	_assert(
		DAGGER_DEFINITION.fast_chain_commit_frames
		== PackedInt32Array([6, 6, 6]),
		"dagger provisional commit frames are not 6, 6, 6"
	)
	_assert(
		DAGGER_DEFINITION.fast_chain_attack_profiles.size() == 3,
		"dagger does not expose three per-link profiles"
	)
	_assert(
		DAGGER_PROFILE != null,
		"dagger fast profile did not load"
	)
	_assert_close(
		DAGGER_PROFILE.drive_distance_px,
		7.0,
		"dagger Fast 01 drive distance is not 7 px"
	)
	_assert_close(
		DAGGER_PROFILE.drive_duration_sec,
		0.16,
		"dagger drive duration is not 0.16 s"
	)
	_assert_close(
		DAGGER_PROFILE.drive_input_influence,
		0.20,
		"dagger input influence is not 20%"
	)


func _validate_default_scene(operator: Node) -> void:
	_assert(
		operator.get("melee_weapon_definition") == DAGGER_DEFINITION,
		"operator.tscn does not default its melee slot to the dagger"
	)
	var active_definition = operator.call(
		"_get_equipped_primary_weapon_definition"
	)
	_assert(
		active_definition == DAGGER_DEFINITION,
		"dagger could not become the equipped melee definition"
	)
	_assert(
		DAGGER_DEFINITION.weapon_id != &"fallen_star_katana",
		"dagger bootstrap mutated or aliased the Katana definition"
	)


func _validate_frame_resources(operator: Node) -> void:
	var held := DAGGER_DEFINITION.frames_resource
	var body := DAGGER_DEFINITION.body_frames_resource
	var overlay := DAGGER_DEFINITION.melee_overlay_frames_resource
	var fx := DAGGER_DEFINITION.melee_fx_frames_resource
	_assert(
		held != null and held.has_animation(&"vigil_dagger_stance"),
		"held dagger stance is missing"
	)
	if held != null and held.has_animation(&"vigil_dagger_stance"):
		_assert(
			held.get_frame_count(&"vigil_dagger_stance") == 1,
			"held dagger stance must contain one frame"
		)
		_assert_atlas_region(
			held.get_frame_texture(&"vigil_dagger_stance", 0),
			Vector2(24, 24),
			"held dagger stance"
		)
	_validate_animation_set(body, BODY_ANIMATIONS, "body")
	_validate_animation_set(
		overlay,
		OVERLAY_ANIMATIONS,
		"weapon overlay"
	)
	_validate_animation_set(fx, FX_ANIMATIONS, "FX overlay")

	var runtime_body := operator.get("animated_sprite") as AnimatedSprite2D
	var runtime_overlay := operator.get(
		"melee_weapon_overlay_sprite"
	) as AnimatedSprite2D
	var runtime_fx := operator.get(
		"melee_fx_overlay_sprite"
	) as AnimatedSprite2D
	for animation: StringName in BODY_ANIMATIONS:
		_assert(
			runtime_body.sprite_frames.has_animation(animation),
			"equipped dagger did not install body animation %s"
			% animation
		)
	_assert(
		runtime_overlay.sprite_frames == overlay,
		"equipped dagger did not install its overlay resource"
	)
	_assert(
		runtime_fx.sprite_frames == fx,
		"equipped dagger did not install its FX resource"
	)


func _validate_animation_set(
	frames: SpriteFrames,
	animations: Array,
	label: String
) -> void:
	_assert(frames != null, "%s SpriteFrames are missing" % label)
	if frames == null:
		return
	for animation: StringName in animations:
		var expected_frames := 8 if "fast_02" in String(animation) else 10
		_assert(
			frames.has_animation(animation),
			"%s animation %s is missing" % [label, animation]
		)
		if not frames.has_animation(animation):
			continue
		_assert(
			frames.get_frame_count(animation) == expected_frames,
			"%s animation %s has %d frames; expected %d"
			% [label, animation, frames.get_frame_count(animation), expected_frames]
		)
		_assert_close(
			frames.get_animation_speed(animation),
			18.0,
			"%s animation %s is not 18 FPS"
			% [label, animation]
		)
		_assert(
			not frames.get_animation_loop(animation),
			"%s animation %s must not loop"
			% [label, animation]
		)
		for frame_index in range(expected_frames):
			_assert_atlas_region(
				frames.get_frame_texture(animation, frame_index),
				Vector2(156, 96),
				"%s %s frame %d"
				% [label, animation, frame_index]
			)
		if "fast_02" in String(animation):
			var atlas := frames.get_frame_texture(animation, 0) as AtlasTexture
			_assert(
				atlas != null and "chain_02" in atlas.atlas.resource_path,
				"%s animation %s is not bound to authored Chain 02"
				% [label, animation]
			)


func _validate_attack_playback(operator: Node) -> void:
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.call("_start_fast_attack")
	var body := operator.get("animated_sprite") as AnimatedSprite2D
	var overlay := operator.get(
		"melee_weapon_overlay_sprite"
	) as AnimatedSprite2D
	var fx := operator.get(
		"melee_fx_overlay_sprite"
	) as AnimatedSprite2D
	_assert(
		body.animation == &"vigil_dagger_fast_01_right",
		"dagger attack did not play its semantic right body action"
	)
	_assert(
		overlay.visible
		and overlay.animation
			== &"vigil_dagger_fast_01_weapon_right",
		"dagger attack did not play its synchronized weapon overlay"
	)
	_assert(
		fx.visible
		and fx.animation == &"vigil_dagger_fast_01_fx_right",
		"dagger attack did not play its synchronized FX overlay"
	)
	var drive_status := operator.call(
		"get_attack_drive_status"
	) as Dictionary
	_assert(
		bool(drive_status.get("active", false)),
		"starting dagger Fast 01 did not begin profile-owned drive"
	)
	body.set_frame_and_progress(5, 0.0)
	operator.call("_on_attack_frame_changed")
	_assert(
		overlay.frame == 5 and fx.frame == 5,
		"dagger overlays did not synchronize to body frame 5"
	)
	var hit_window := (
		DAGGER_DEFINITION.hit_windows.get(
			"vigil_dagger_fast_01",
			{}
		) as Dictionary
	)
	_assert(
		bool(
			operator.call(
				"_is_melee_hit_frame_active",
				5,
				hit_window
			)
		),
		"zero-based body frame 5 is not the dagger contact frame"
	)
	_assert(
		not bool(
			operator.call(
				"_is_melee_hit_frame_active",
				4,
				hit_window
			)
		),
		"dagger contact opened before zero-based frame 5"
	)
	operator.call("_interrupt_active_combat_for_damage_reaction")
	operator.set("_melee_fast_combo_step", 1)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.call("_start_fast_attack")
	_assert(
		body.animation == &"vigil_dagger_fast_02_right",
		"dagger chain step 2 did not play the authored Chain 02 body"
	)
	_assert(
		overlay.animation == &"vigil_dagger_fast_02_weapon_right",
		"dagger chain step 2 did not play the authored Chain 02 dagger"
	)
	_assert(
		fx.animation == &"vigil_dagger_fast_02_fx_right",
		"dagger chain step 2 did not play the authored Chain 02 FX"
	)
	operator.call("_interrupt_active_combat_for_damage_reaction")


func _validate_open_space_drive(operator: Node) -> void:
	operator.global_position = Vector2.ZERO
	operator.set("velocity", Vector2.ZERO)
	await physics_frame
	operator.call(
		"_begin_attack_drive",
		DAGGER_PROFILE,
		Vector2.RIGHT
	)
	var backward := operator.call(
		"_filter_locomotion_for_attack_drive",
		Vector2.LEFT * 100.0
	) as Vector2
	_assert(
		backward.dot(Vector2.RIGHT) >= -0.001,
		"backward input reversed the opening drive"
	)
	var lateral := operator.call(
		"_filter_locomotion_for_attack_drive",
		Vector2.DOWN * 100.0
	) as Vector2
	_assert_close(
		lateral.length(),
		20.0,
		"lateral input did not retain bounded 20% steering",
		0.05
	)
	for _step in range(20):
		operator.call("_physics_process", 1.0 / 60.0)
	var distance: float = operator.global_position.x
	_assert(
		distance >= 5.5 and distance <= 8.0,
		"stationary dagger drive moved %.3f px, expected 5.5-8"
		% distance
	)
	var settled_position: Vector2 = operator.global_position
	for _step in range(8):
		operator.call("_physics_process", 1.0 / 60.0)
	_assert(
		operator.global_position.distance_to(settled_position) <= 0.05,
		"dagger drive snapped or drifted after completion"
	)


func _validate_wall_truncation(operator: Node) -> void:
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4.0, 80.0)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	wall.position = Vector2(15.0, 0.0)
	_fixture_root.add_child(wall)
	operator.global_position = Vector2.ZERO
	operator.set("velocity", Vector2.ZERO)
	operator.call("_cancel_attack_drive", true)
	await physics_frame
	operator.call(
		"_begin_attack_drive",
		DAGGER_PROFILE,
		Vector2.RIGHT
	)
	for _step in range(20):
		operator.call("_physics_process", 1.0 / 60.0)
	var distance: float = operator.global_position.x
	var status := operator.call(
		"get_attack_drive_status"
	) as Dictionary
	_assert(
		distance < 5.5,
		"wall did not truncate dagger drive (%.3f px)" % distance
	)
	_assert(
		operator.global_position.x <= 7.1,
		"dagger drive penetrated the wall"
	)
	_assert(
		not bool(status.get("active", true)),
		"blocking collision did not cancel remaining drive"
	)
	wall.queue_free()
	await physics_frame


func _validate_cancellation_paths() -> void:
	await _validate_cancel_case(&"block")
	await _validate_cancel_case(&"dodge")
	await _validate_cancel_case(&"damage")
	await _validate_cancel_case(&"weapon_switch")
	await _validate_cancel_case(&"portal")
	await _validate_cancel_case(&"death")


func _validate_cancel_case(case_name: StringName) -> void:
	var operator := await _create_operator()
	operator.call(
		"_begin_attack_drive",
		DAGGER_PROFILE,
		Vector2.RIGHT
	)
	match case_name:
		&"block":
			operator.call("_request_block_state")
		&"dodge":
			var started := bool(
				operator.call(
					"_try_start_dodge_with_profile",
					Vector2.UP,
					&"tap"
				)
			)
			_assert(started, "dodge cancellation fixture did not start")
		&"damage":
			operator.call(
				"_interrupt_active_combat_for_damage_reaction"
			)
		&"weapon_switch":
			operator.call("_apply_unarmed_selection")
		&"portal":
			operator.call("set_portal_transition_locked", true)
		&"death":
			operator.call("_handle_death")
	var status := operator.call(
		"get_attack_drive_status"
	) as Dictionary
	_assert(
		not bool(status.get("active", true)),
		"%s did not cancel attack drive" % case_name
	)
	operator.queue_free()
	await process_frame


func _assert_atlas_region(
	texture: Texture2D,
	expected_size: Vector2,
	label: String
) -> void:
	_assert(texture is AtlasTexture, "%s is not an AtlasTexture" % label)
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		_assert(
			atlas.region.size == expected_size,
			"%s region is %s, expected %s"
			% [label, atlas.region.size, expected_size]
		)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _assert_close(
	actual: float,
	expected: float,
	message: String,
	tolerance: float = 0.001
) -> void:
	if absf(actual - expected) > tolerance:
		_errors.append(
			"%s (%.4f != %.4f)"
			% [message, actual, expected]
		)
