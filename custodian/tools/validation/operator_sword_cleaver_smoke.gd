extends SceneTree

const OPERATOR_SCENE := preload(
	"res://game/actors/operator/operator.tscn"
)
const DAGGER_DEFINITION := preload(
	"res://game/actors/operator/vigil_pattern_dagger_definition.tres"
)
const CLEAVER_DEFINITION := preload(
	"res://game/actors/operator/sword_cleaver_definition.tres"
)
const KATANA_DEFINITION := preload(
	"res://game/actors/operator/fallen_star_katana_definition.tres"
)

const CHAIN_KEYS := [
	"sword_cleaver_fast_01",
	"sword_cleaver_fast_02",
	"sword_cleaver_fast_03",
]

var _errors: Array[String] = []
var _fixture_root: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_fixture_root = Node2D.new()
	_fixture_root.name = "OperatorSwordCleaverSmokeRoot"
	root.add_child(_fixture_root)
	current_scene = _fixture_root

	_validate_definition()
	var operator := await _create_operator()
	_validate_canonical_default(operator)
	_equip_cleaver(operator)
	_validate_installed_resources(operator)
	_validate_all_chain_links(operator)
	await _validate_finisher_drive(operator)

	operator.queue_free()
	_fixture_root.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[OperatorSwordCleaverSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[OperatorSwordCleaverSmoke] %s" % error)
	quit(1)


func _create_operator() -> CharacterBody2D:
	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	_fixture_root.add_child(operator)
	await process_frame
	operator.set_physics_process(false)
	operator.set_process(false)
	operator.set("unstuck_enabled", false)
	operator.set("stamina", 100.0)
	return operator


func _equip_cleaver(operator: Node) -> void:
	operator.set("melee_weapon_definition", CLEAVER_DEFINITION)
	operator.call("_rebuild_armed_weapon_list")
	var weapons := operator.get("armed_weapons") as Array
	var index := weapons.find(CLEAVER_DEFINITION)
	_assert(index >= 0, "cleaver was not registered by the loadout override")
	if index >= 0:
		operator.call("_apply_armed_selection", index)
		operator.call("_refresh_primary_weapon_state")
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)


func _validate_definition() -> void:
	_assert(CLEAVER_DEFINITION != null, "cleaver definition did not load")
	_assert(
		CLEAVER_DEFINITION.weapon_id == &"sword_cleaver",
		"cleaver weapon_id is wrong"
	)
	_assert(
		CLEAVER_DEFINITION.weapon_type == &"melee_1h_heavy",
		"cleaver weapon_type is wrong"
	)
	_assert(
		CLEAVER_DEFINITION.primary_intent == "melee_fast",
		"cleaver primary intent is not melee_fast"
	)
	_assert(
		CLEAVER_DEFINITION.secondary_intent.is_empty(),
		"cleaver heavy input must remain disabled until art exists"
	)
	_assert(
		CLEAVER_DEFINITION.heavy_attack_profile == null,
		"cleaver heavy profile must remain deferred"
	)
	_assert(
		CLEAVER_DEFINITION.fast_chain_keys
		== PackedStringArray(CHAIN_KEYS),
		"cleaver chain keys are not ordered Fast 01/02/03"
	)
	_assert(
		CLEAVER_DEFINITION.fast_chain_commit_frames
		== PackedInt32Array([6, 6, 6]),
		"cleaver provisional commit frames are not 6, 6, 6"
	)
	_assert(
		CLEAVER_DEFINITION.fast_chain_attack_profiles.size() == 3,
		"cleaver does not provide three fast profiles"
	)
	var expected_drive := [9.0, 11.0, 14.0]
	for index in range(3):
		var profile = CLEAVER_DEFINITION.fast_chain_attack_profiles[index]
		_assert(
			profile != null,
			"cleaver profile %d is missing" % index
		)
		if profile != null:
			_assert_close(
				profile.drive_distance_px,
				expected_drive[index],
				"cleaver profile %d drive is wrong" % index
			)


func _validate_canonical_default(operator: Node) -> void:
	_assert(
		operator.get("melee_weapon_definition") == DAGGER_DEFINITION,
		"cleaver support changed the canonical dagger default"
	)
	_assert(
		KATANA_DEFINITION.weapon_id == &"fallen_star_katana",
		"Katana definition was mutated"
	)


func _validate_installed_resources(operator: Node) -> void:
	var body := CLEAVER_DEFINITION.body_frames_resource
	var weapon := CLEAVER_DEFINITION.melee_overlay_frames_resource
	var fx := CLEAVER_DEFINITION.melee_fx_frames_resource
	_assert(body != null, "cleaver body frames are missing")
	_assert(weapon != null, "cleaver weapon frames are missing")
	_assert(fx != null, "cleaver FX frames are missing")
	for link in range(1, 4):
		for suffix in ["right", "left"]:
			_validate_animation(
				body,
				StringName("sword_cleaver_fast_%02d_%s" % [link, suffix]),
				"body"
			)
			_validate_animation(
				weapon,
				StringName(
					"sword_cleaver_fast_%02d_weapon_%s"
					% [link, suffix]
				),
				"weapon"
			)
			_validate_animation(
				fx,
				StringName(
					"sword_cleaver_fast_%02d_fx_%s"
					% [link, suffix]
				),
				"FX"
			)
	var runtime_weapon := operator.get(
		"melee_weapon_overlay_sprite"
	) as AnimatedSprite2D
	var runtime_fx := operator.get(
		"melee_fx_overlay_sprite"
	) as AnimatedSprite2D
	_assert(
		runtime_weapon.sprite_frames == weapon,
		"equipping cleaver did not install its weapon overlay resource"
	)
	_assert(
		runtime_fx.sprite_frames == fx,
		"equipping cleaver did not install its FX resource"
	)


func _validate_animation(
	frames: SpriteFrames,
	animation: StringName,
	label: String
) -> void:
	if frames == null:
		return
	_assert(
		frames.has_animation(animation),
		"cleaver %s animation %s is missing" % [label, animation]
	)
	if not frames.has_animation(animation):
		return
	_assert(
		frames.get_frame_count(animation) == 10,
		"cleaver %s animation %s is not ten frames"
		% [label, animation]
	)
	_assert_close(
		frames.get_animation_speed(animation),
		18.0,
		"cleaver %s animation %s is not 18 FPS"
		% [label, animation]
	)
	for frame_index in range(10):
		var texture := frames.get_frame_texture(animation, frame_index)
		_assert(
			texture is AtlasTexture,
			"cleaver %s %s frame %d is not an AtlasTexture"
			% [label, animation, frame_index]
		)
		if texture is AtlasTexture:
			_assert(
				(texture as AtlasTexture).region.size
				== Vector2(156, 96),
				"cleaver %s %s frame %d is not 156x96"
				% [label, animation, frame_index]
			)


func _validate_all_chain_links(operator: Node) -> void:
	var body := operator.get("animated_sprite") as AnimatedSprite2D
	var weapon := operator.get(
		"melee_weapon_overlay_sprite"
	) as AnimatedSprite2D
	var fx := operator.get(
		"melee_fx_overlay_sprite"
	) as AnimatedSprite2D
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	for index in range(3):
		operator.set("_melee_fast_combo_step", index)
		operator.set("melee_cooldown_remaining", 0.0)
		operator.call("_start_fast_attack")
		var base := "sword_cleaver_fast_%02d" % (index + 1)
		_assert(
			body.animation == StringName("%s_right" % base),
			"cleaver link %d did not play its semantic body animation"
			% (index + 1)
		)
		_assert(
			weapon.visible
			and weapon.animation
				== StringName("%s_weapon_right" % base),
			"cleaver link %d did not play its weapon overlay"
			% (index + 1)
		)
		_assert(
			fx.visible
			and fx.animation == StringName("%s_fx_right" % base),
			"cleaver link %d did not play its FX overlay"
			% (index + 1)
		)
		_assert(
			operator.get("_active_melee_attack_profile")
			== CLEAVER_DEFINITION.fast_chain_attack_profiles[index],
			"cleaver link %d did not select its own attack profile"
			% (index + 1)
		)
		body.set_frame_and_progress(5, 0.0)
		operator.call("_on_attack_frame_changed")
		_assert(
			weapon.frame == 5 and fx.frame == 5,
			"cleaver link %d overlays lost frame synchronization"
			% (index + 1)
		)
		operator.call("_interrupt_active_combat_for_damage_reaction")


func _validate_finisher_drive(operator: Node) -> void:
	operator.global_position = Vector2.ZERO
	operator.set("velocity", Vector2.ZERO)
	await physics_frame
	var finisher = CLEAVER_DEFINITION.fast_chain_attack_profiles[2]
	operator.call("_begin_attack_drive", finisher, Vector2.RIGHT)
	var opposing := operator.call(
		"_filter_locomotion_for_attack_drive",
		Vector2.LEFT * 100.0
	) as Vector2
	_assert(
		opposing.dot(Vector2.RIGHT) >= -0.001,
		"opposing input reversed the cleaver finisher drive"
	)
	for _step in range(30):
		operator.call("_physics_process", 1.0 / 60.0)
	var distance: float = operator.global_position.x
	_assert(
		distance > 10.0 and distance <= 14.1,
		"cleaver finisher moved %.3f px, expected >10 and <=14"
		% distance
	)
	var settled: Vector2 = operator.global_position
	for _step in range(8):
		operator.call("_physics_process", 1.0 / 60.0)
	_assert(
		operator.global_position.distance_to(settled) <= 0.05,
		"cleaver drive snapped back or drifted after completion"
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
