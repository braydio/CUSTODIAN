extends SceneTree

const OPERATOR_SCENE := preload(
	"res://game/actors/operator/operator.tscn"
)
const KATANA_DEFINITION := preload(
	"res://game/actors/operator/fallen_star_katana_definition.tres"
)

const BODY_PATHS := [
	"res://content/sprites/operator/runtime/body/melee_1h/operator__body__melee__fast_01__e__7f__156x96.png",
	"res://content/sprites/operator/runtime/body/melee_1h/operator__body__melee__fast_02__e__7f__156x96.png",
	"res://content/sprites/operator/runtime/body/melee_1h/operator__body__melee__fast_03__e__8f__156x96.png",
]
const ANIMATIONS := [
	&"melee_2h_fast_1_right",
	&"melee_2h_fast_2_right",
	&"melee_2h_fast_3_right",
]
const FRAME_COUNTS := [7, 7, 8]
const FX_FRAME_COUNTS := [10, 7, 8]
const COMMIT_FRAMES := [5, 5, 6]
const FX_ANIMATION_BASES := [
	"melee_2h_fast_1_fx",
	"melee_2h_fast_2_fx",
	"melee_2h_fast_3_fx",
]

var _errors: Array[String] = []
var _fixture_root: Node2D


class ChainTarget:
	extends CharacterBody2D

	var hit_count := 0
	var last_strength := -1

	func _ready() -> void:
		add_to_group("enemy")

	func take_damage(
		amount: float,
		hit_strength: int = 0
	) -> Dictionary:
		hit_count += 1
		last_strength = hit_strength
		return {
			"applied_damage": amount,
			"eligible_hostile": true,
			"target_was_alive": true,
			"target_health_before": 100.0,
			"target_health_after": 100.0 - amount,
		}

	func apply_melee_impact(
		_kind: String,
		_direction: Vector2,
		_force: float
	) -> void:
		pass


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_fixture_root = Node2D.new()
	_fixture_root.name = "OperatorMeleeFastChainSmokeRoot"
	root.add_child(_fixture_root)
	current_scene = _fixture_root
	var operator := OPERATOR_SCENE.instantiate()
	_fixture_root.add_child(operator)
	await process_frame
	_select_katana(operator)

	_validate_source_and_definition()
	_validate_runtime_registration(operator)
	_validate_single_press_settle(operator)
	_validate_directional_fx(operator)
	_validate_chain_order_and_stamina(operator)
	_validate_first_input_wins(operator)
	_validate_heavy_branch(operator)
	_validate_dodge_branch(operator)
	await _validate_exactly_once_damage(operator)
	_validate_resets_and_retargeting(operator)

	operator.queue_free()
	_fixture_root.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[OperatorMeleeFastChainSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[OperatorMeleeFastChainSmoke] %s" % error)
	quit(1)


func _select_katana(operator: Node) -> void:
	operator.set("melee_weapon_definition", KATANA_DEFINITION)
	operator.call("_rebuild_armed_weapon_list")
	var weapons := operator.get("armed_weapons") as Array
	var index: int = weapons.find(KATANA_DEFINITION)
	_assert(index >= 0, "Katana is not in the armed weapon list")
	if index >= 0:
		operator.call("_apply_armed_selection", index)
	operator.set("stamina", 100.0)
	operator.set("melee_cooldown_remaining", 0.0)


func _validate_source_and_definition() -> void:
	var source := load(
		"res://content/sprites/operator/new_operator/modular/chain_attack/"
		+ "operator__full_body_source__melee_1h__chain_attack_01__e__22f__156x96.png"
	) as Texture2D
	_assert(source != null, "22-frame source master is missing")
	if source != null:
		_assert(
			source.get_size() == Vector2(3432, 96),
			"source master is not 3432x96"
		)
	for index in range(BODY_PATHS.size()):
		var texture := load(BODY_PATHS[index]) as Texture2D
		_assert(texture != null, "runtime chain strip is missing")
		if texture != null:
			_assert(
				texture.get_size()
				== Vector2(FRAME_COUNTS[index] * 156, 96),
				"runtime chain strip has wrong dimensions"
			)
	var first := (load(BODY_PATHS[0]) as Texture2D).get_image()
	var second := (load(BODY_PATHS[1]) as Texture2D).get_image()
	_assert(
		hash(first.get_data()) != hash(second.get_data()),
		"Fast 01 and Fast 02 runtime strips are identical"
	)

	_assert(
		KATANA_DEFINITION.fast_chain_keys
		== PackedStringArray([
			"melee_fast_1",
			"melee_fast_2",
			"melee_fast_3",
		]),
		"Katana chain keys are not 1 -> 2 -> 3"
	)
	_assert(
		KATANA_DEFINITION.fast_chain_commit_frames
		== PackedInt32Array(COMMIT_FRAMES),
		"Katana commit frames are not 5, 5, 6"
	)
	_assert(
		KATANA_DEFINITION.fast_chain_stamina_costs
		== PackedFloat32Array([7.0, 8.0, 10.0]),
		"Katana stamina progression is wrong"
	)


func _validate_runtime_registration(operator: Node) -> void:
	var sprite := operator.get("animated_sprite") as AnimatedSprite2D
	_assert(sprite != null, "Operator body sprite is missing")
	if sprite == null or sprite.sprite_frames == null:
		return
	for index in range(ANIMATIONS.size()):
		var animation: StringName = ANIMATIONS[index]
		_assert(
			sprite.sprite_frames.has_animation(animation),
			"missing runtime animation %s" % animation
		)
		if not sprite.sprite_frames.has_animation(animation):
			continue
		_assert(
			sprite.sprite_frames.get_frame_count(animation)
			== FRAME_COUNTS[index],
			"%s has wrong frame count" % animation
		)
		_assert_close(
			sprite.sprite_frames.get_animation_speed(animation),
			18.0,
			"%s is not registered at 18 FPS" % animation
		)
		_assert(
			not sprite.sprite_frames.get_animation_loop(animation),
			"%s must not loop internally" % animation
		)
	var fx_sprite := operator.get(
		"melee_fx_overlay_sprite"
	) as AnimatedSprite2D
	_assert(fx_sprite != null, "Operator fast-chain FX sprite is missing")
	if fx_sprite == null or fx_sprite.sprite_frames == null:
		return
	for index in range(FX_ANIMATION_BASES.size()):
		for suffix in ["right", "left"]:
			var animation := StringName(
				"%s_%s" % [FX_ANIMATION_BASES[index], suffix]
			)
			_assert(
				fx_sprite.sprite_frames.has_animation(animation),
				"missing runtime FX animation %s" % animation
			)
			if not fx_sprite.sprite_frames.has_animation(animation):
				continue
			_assert(
				fx_sprite.sprite_frames.get_frame_count(animation)
				== FX_FRAME_COUNTS[index],
				"%s has wrong frame count" % animation
			)
			_assert_close(
				fx_sprite.sprite_frames.get_animation_speed(animation),
				18.0,
				"%s is not registered at 18 FPS" % animation
			)
			_assert(
				not fx_sprite.sprite_frames.get_animation_loop(animation),
				"%s must not loop internally" % animation
			)


func _validate_single_press_settle(operator: Node) -> void:
	_reset_attack(operator)
	operator.call("_request_attack_state", "fast")
	_assert_step(operator, 0, "melee_fast_1")
	var sprite := operator.get("animated_sprite") as AnimatedSprite2D
	_assert_close(
		sprite.speed_scale,
		1.0,
		"authored chain retained the legacy 1.35x multiplier"
	)
	sprite.set_frame_and_progress(6, 0.0)
	operator.set(
		"_melee_elapsed",
		float(operator.get("_melee_duration"))
	)
	operator.call("_update_melee_attack", 0.0)
	_assert(
		not bool(operator.get("_melee_active")),
		"single press did not end after Fast 01"
	)
	_assert(
		not bool(operator.get("_melee_recovery_active")),
		"integrated stance incorrectly started external recovery"
	)
	_assert(
		int(operator.get("_melee_fast_combo_step")) == 0,
		"stopped attack did not reset to Fast 01"
	)


func _validate_directional_fx(operator: Node) -> void:
	_reset_attack(operator)
	operator.set("aim_direction", Vector2.LEFT)
	operator.set("arrow_aim_enabled", false)
	operator.call("_request_attack_state", "fast")
	var fx_sprite := operator.get(
		"melee_fx_overlay_sprite"
	) as AnimatedSprite2D
	_assert(
		fx_sprite != null
		and fx_sprite.animation == &"melee_2h_fast_1_fx_left",
		"west-facing Fast 01 did not select the west pipeline FX"
	)
	if fx_sprite != null:
		_assert(
			not fx_sprite.flip_h,
			"authored west pipeline FX was mirrored a second time"
		)


func _validate_chain_order_and_stamina(operator: Node) -> void:
	_reset_attack(operator)
	operator.set("stamina", 100.0)
	operator.call("_request_attack_state", "fast")
	_assert_step(operator, 0, "melee_fast_1")
	_commit_buffered(operator, "fast")
	_assert_step(operator, 1, "melee_fast_2")
	_commit_buffered(operator, "fast")
	_assert_step(operator, 2, "melee_fast_3")
	_assert(
		String(operator.get("_melee_attack_kind")) == "fast",
		"Fast 03 was promoted to a heavy attack"
	)
	_assert(
		float(operator.call(
			"_get_fast_chain_hit_stop_duration",
			0.028
		)) > 0.030,
		"Fast 03 has no stronger finish timing"
	)
	_assert(
		float(operator.call(
			"_get_fast_chain_knockback_multiplier"
		)) > 1.0,
		"Fast 03 has no stronger finish knockback"
	)
	_assert(
		float(operator.call(
			"_get_fast_chain_camera_shake_multiplier"
		)) > 1.0,
		"Fast 03 has no stronger finish camera cue"
	)
	_commit_buffered(operator, "fast")
	_assert_step(operator, 0, "melee_fast_1")
	_assert_close(
		float(operator.get("stamina")),
		68.0,
		"four presses did not spend 7 + 8 + 10 + 7 stamina"
	)


func _validate_first_input_wins(operator: Node) -> void:
	_reset_attack(operator)
	operator.call("_request_attack_state", "fast")
	operator.call("_buffer_attack", "fast")
	operator.call("_buffer_attack", "heavy")
	_assert(
		String(operator.get("_buffered_attack_kind")) == "fast",
		"later input overwrote the queued command"
	)
	_commit_current_frame(operator)
	_assert_step(operator, 1, "melee_fast_2")


func _validate_heavy_branch(operator: Node) -> void:
	_reset_attack(operator)
	operator.call("_request_attack_state", "fast")
	_commit_buffered(operator, "heavy")
	_assert(
		String(operator.get("_melee_attack_kind")) == "heavy",
		"heavy input did not branch at the authored marker"
	)
	_assert(
		int(operator.get("_melee_fast_combo_step")) == 0,
		"heavy branch did not reset the fast chain"
	)


func _validate_dodge_branch(operator: Node) -> void:
	_reset_attack(operator)
	operator.call("_request_attack_state", "fast")
	operator.set("_buffered_dodge_direction", Vector2.DOWN)
	operator.call("_buffer_attack", "dodge")
	_commit_current_frame(operator)
	_assert(
		not bool(operator.get("_dodge_active")),
		"dodge erased the strike at its contact frame"
	)
	var sprite := operator.get("animated_sprite") as AnimatedSprite2D
	sprite.set_frame_and_progress(6, 0.0)
	operator.call("_update_melee_attack", 0.0)
	_assert(
		bool(operator.get("_dodge_active")),
		"buffered dodge did not begin on the final stance frame"
	)
	_assert_chain_reset(operator, "dodge")
	operator.call("_cancel_dodge", &"smoke_reset")


func _validate_exactly_once_damage(operator: Node) -> void:
	_reset_attack(operator)
	(operator as Node2D).global_position = Vector2.ZERO
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("arrow_aim_enabled", false)
	var target := ChainTarget.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	target.add_child(shape)
	target.global_position = Vector2(45.0, 0.0)
	_fixture_root.add_child(target)
	operator.call("_request_attack_state", "fast")
	var sprite := operator.get("animated_sprite") as AnimatedSprite2D
	sprite.pause()
	sprite.set_frame_and_progress(5, 0.0)
	operator.call("_sync_melee_hitbox_window_from_animation")
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.call("enable_hitbox")
	await physics_frame
	await physics_frame
	operator.call("_apply_melee_hitbox_tick")
	operator.call("_apply_melee_hitbox_tick")
	_assert(
		target.hit_count == 1,
		"one chain step damaged the same target more than once"
	)
	_assert(
		target.last_strength == 0,
		"Fast 01 did not remain a light hit"
	)
	operator.set_process(true)
	operator.set_physics_process(true)
	target.queue_free()
	await process_frame


func _validate_resets_and_retargeting(operator: Node) -> void:
	_reset_attack(operator)
	operator.set("_melee_fast_combo_step", 2)
	operator.set("_melee_fast_chain_direction_active", true)
	operator.call("_buffer_attack", "fast")
	operator.call("_interrupt_active_combat_for_damage_reaction")
	_assert_chain_reset(operator, "damage reaction")

	operator.set("_melee_fast_combo_step", 2)
	operator.set("_melee_fast_chain_direction_active", true)
	operator.call("start_block")
	_assert_chain_reset(operator, "block")

	operator.set("_melee_fast_combo_step", 2)
	operator.call("_buffer_attack", "fast")
	operator.call("_apply_unarmed_selection")
	_assert_chain_reset(operator, "weapon swap")
	_select_katana(operator)

	_reset_attack(operator)
	operator.set("_melee_fast_combo_step", 1)
	operator.set("_melee_fast_chain_direction_active", true)
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.LEFT)
	var retarget := (
		operator.call("_get_fast_chain_forward_direction")
		as Vector2
	)
	var turn := absf(
		rad_to_deg(Vector2.RIGHT.angle_to(retarget))
	)
	_assert(
		turn <= 75.001,
		"one chain link retargeted more than 75 degrees"
	)


func _commit_buffered(operator: Node, kind: String) -> void:
	operator.call("_buffer_attack", kind)
	_commit_current_frame(operator)


func _commit_current_frame(operator: Node) -> void:
	var commit_frame := int(
		operator.call("_get_fast_chain_commit_frame")
	)
	var sprite := operator.get("animated_sprite") as AnimatedSprite2D
	sprite.set_frame_and_progress(commit_frame, 0.0)
	operator.call("_update_melee_attack", 0.0)


func _assert_step(
	operator: Node,
	expected_step: int,
	expected_key: String
) -> void:
	_assert(
		int(operator.get("_melee_fast_combo_step"))
		== expected_step,
		"expected chain step %d" % expected_step
	)
	_assert(
		String(operator.get("_melee_attack_key"))
		== expected_key,
		"expected %s, got %s"
		% [expected_key, String(operator.get("_melee_attack_key"))]
	)
	if bool(operator.call("_has_authored_fast_chain")):
		var weapon_overlay := operator.get(
			"melee_weapon_overlay_sprite"
		) as AnimatedSprite2D
		var fx_overlay := operator.get(
			"melee_fx_overlay_sprite"
		) as AnimatedSprite2D
		_assert(
			weapon_overlay == null or not weapon_overlay.visible,
			"Katana chain unexpectedly showed a separate weapon overlay"
		)
		_assert(
			fx_overlay != null and fx_overlay.visible,
			"Katana chain did not show its pipeline FX overlay"
		)
		if fx_overlay != null:
			_assert(
				String(fx_overlay.animation).begins_with(
					FX_ANIMATION_BASES[expected_step]
				),
				"Katana chain played the wrong FX overlay"
			)


func _assert_chain_reset(operator: Node, cause: String) -> void:
	_assert(
		int(operator.get("_melee_fast_combo_step")) == 0,
		"%s did not reset the chain step" % cause
	)
	_assert(
		String(operator.get("_buffered_attack_kind")).is_empty(),
		"%s did not clear the queued command" % cause
	)


func _reset_attack(operator: Node) -> void:
	operator.call("_reset_fast_chain")
	operator.set("_melee_active", false)
	operator.set("_melee_attack_kind", "")
	operator.set("_melee_attack_key", "")
	operator.set("_melee_elapsed", 0.0)
	operator.set("_melee_duration", 0.0)
	operator.set("_melee_heavy_anticipating", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)
	operator.set("_melee_recovery_timer", 0.0)
	operator.set("_active_attack_profile", null)
	operator.set("_active_melee_attack_profile", null)
	operator.set("melee_cooldown_remaining", 0.0)
	operator.set("fire_cooldown_remaining", 0.0)
	operator.set("stamina", 100.0)
	operator.call("disable_hitbox")
	operator.call("_reset_melee_overlay_visuals")
	var machine = operator.get("_animation_state_machine")
	if machine != null:
		machine.request("idle", 100)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _assert_close(
	actual: float,
	expected: float,
	message: String
) -> void:
	if not is_equal_approx(actual, expected):
		_errors.append(
			"%s (expected %.4f, got %.4f)"
			% [message, expected, actual]
		)
