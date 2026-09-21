extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const UNARMED := preload("res://game/actors/operator/unarmed_definition.tres")
const EXPECTED_FRAMES := [6, 6, 7, 8]
const EXPECTED_CONTACTS := [3, 3, 3, 4]

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	_assert_true(UNARMED.fast_chain_keys == PackedStringArray([
		"unarmed_fast_01", "unarmed_fast_02", "unarmed_fast_03", "unarmed_fast_04"
	]), "Fists must declare exactly four ordered links")
	_assert_true(not UNARMED.fast_chain_loops, "Fists chain must not loop to Fast 01")
	_assert_true(UNARMED.fast_chain_attack_profiles.size() == 4, "each link needs one attack profile")
	_assert_true(Array(UNARMED.fast_chain_commit_frames) == EXPECTED_CONTACTS, "commit frames must match reviewed zero-based contacts")

	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("_active_attack_profile", UNARMED)
	operator.set("_melee_active", true)
	operator.set("_melee_attack_kind", "fast")
	for direction in [Vector2.RIGHT, Vector2.LEFT]:
		operator.set("_melee_forward", direction)
		var sector := "e" if direction.x > 0.0 else "w"
		for index in range(4):
			var key: String = UNARMED.fast_chain_keys[index]
			var profile = UNARMED.fast_chain_attack_profiles[index]
			operator.set("_melee_fast_combo_step", index)
			operator.set("_melee_attack_key", key)
			operator.set("_active_melee_attack_profile", profile)
			_assert_true(bool(operator.call("_sync_modular_action_domains")), "%s %s must resolve" % [key, sector])
			var lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
			var upper := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
			var expected_lower := StringName("unarmed/attack/fast_%02d/%s/lower_body" % [index + 1, sector])
			var expected_upper := StringName("unarmed/attack/fast_%02d/%s/upper_body" % [index + 1, sector])
			_assert_true(lower.animation == expected_lower, "%s lower identity mismatch" % key)
			_assert_true(upper.animation == expected_upper, "%s upper identity mismatch" % key)
			_assert_true(not lower.flip_h and not upper.flip_h, "%s must not runtime-mirror" % key)
			_assert_true(lower.sprite_frames.get_frame_count(lower.animation) == EXPECTED_FRAMES[index], "%s frame contract mismatch" % key)
			_assert_true(upper.sprite_frames.get_frame_count(upper.animation) == EXPECTED_FRAMES[index], "%s upper clock mismatch" % key)
			_assert_true(is_equal_approx(lower.speed_scale, upper.speed_scale), "%s modular clocks must match" % key)

	operator.set("_melee_fast_combo_step", 0)
	_assert_true(bool(operator.call("_advance_fast_chain_step")), "01 must queue 02")
	_assert_true(bool(operator.call("_advance_fast_chain_step")), "02 must queue 03")
	_assert_true(bool(operator.call("_advance_fast_chain_step")), "03 must queue 04")
	_assert_true(not bool(operator.call("_advance_fast_chain_step")), "04 must terminate without Fast 05")
	_assert_true(int(operator.get("_melee_fast_combo_step")) == 0, "terminal recovery must reset to neutral link")

	for index in range(4):
		var frames: PackedInt32Array = UNARMED.fast_chain_attack_profiles[index].hit_window_frames
		_assert_true(frames == PackedInt32Array([EXPECTED_CONTACTS[index]]), "each link must expose one reviewed contact")

	operator.set("_melee_fast_combo_step", 0)
	operator.set("_melee_attack_key", "unarmed_fast_01")
	operator.set("_active_melee_attack_profile", UNARMED.fast_chain_attack_profiles[0])
	operator.set("_melee_forward", Vector2.RIGHT)
	operator.call("_sync_modular_action_domains")
	await create_timer(0.18).timeout
	var playback_clock := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	_assert_true(playback_clock.frame > 0, "visible modular presentation clock must advance")

	operator.queue_free()
	if _failed:
		push_error("operator_unarmed_fast_chain_smoke failed")
		quit(1)
		return
	print("operator_unarmed_fast_chain_smoke passed")
	quit()


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
