extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "OperatorPrimaryRangedModularFireSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root

	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child.call_deferred(operator)
	await process_frame
	await process_frame

	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set_process_input(false)
	operator.set_process_unhandled_input(false)

	operator.set("combat_loadout_mode", &"ranged")
	operator.set("using_unarmed", false)
	operator.set("primary_weapon_equipped", true)
	operator.set("sidearm_slot_equipped", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("modular_locomotion_layers_enabled", true)
	operator.call("_enter_ranged_ready")

	var lower := operator.get_node_or_null("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node_or_null("ModularUpperBodySprite") as AnimatedSprite2D
	var weapon := operator.get_node_or_null("ModularSidearmSprite") as AnimatedSprite2D
	var fx := operator.get_node_or_null("ModularUpperFxSprite") as AnimatedSprite2D

	var failures: Array[String] = []

	_install_test_frames(lower, [
		&"unarmed_idle_right",
		&"ranged_2h_fire_lower_right",
	])
	_install_test_frames(upper, [
		&"ranged_2h_stance_modular_right",
		&"ranged_2h_stance_modular_up",
		&"ranged_2h_stance_modular_left",
		&"ranged_2h_stance_modular_down",
		&"ranged_2h_fire_upper_right",
	])
	_install_test_frames(weapon, [
		&"ranged_2h_stance_modular_right",
		&"ranged_2h_stance_modular_up",
		&"ranged_2h_stance_modular_left",
		&"ranged_2h_stance_modular_down",
		&"ranged_2h_fire_weapon_right",
	])
	_install_test_frames(fx, [
		&"ranged_2h_fire_fx_right",
	])

	if not bool(operator.call("_begin_modular_primary_ranged_fire_presentation")):
		failures.append("primary ranged modular fire presentation did not start")

	_check_layer(lower, &"unarmed_idle_right", "lower", failures)
	_check_layer(upper, &"ranged_2h_fire_upper_right", "upper", failures)
	_check_layer(weapon, &"ranged_2h_fire_weapon_right", "weapon", failures)
	_check_layer(fx, &"ranged_2h_fire_fx_right", "fx", failures)

	if weapon != null:
		var muzzle_position: Vector2 = operator.call("_get_ranged_muzzle_position", Vector2.RIGHT)
		var expected_muzzle := weapon.global_position + Vector2(32.0, -10.0)
		if muzzle_position.distance_to(expected_muzzle) > 0.01:
			failures.append("primary modular muzzle is %s, expected %s" % [
				str(muzzle_position),
				str(expected_muzzle),
			])

	var legacy_body := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if legacy_body != null and legacy_body.visible:
		failures.append("legacy body sprite should be hidden during modular primary ranged fire")

	var primary_weapon := operator.get_node_or_null("PrimaryWeaponSocket/PrimaryWeaponSprite") as AnimatedSprite2D
	if primary_weapon != null and primary_weapon.visible:
		failures.append("legacy primary weapon sprite should be hidden during modular primary ranged fire")

	operator.call("_tick_primary_ranged_fire_presentation", 10.0)
	if bool(operator.call("_is_primary_ranged_fire_presentation_active")):
		failures.append("primary ranged modular fire presentation did not end after timer tick")

	operator.call("_end_modular_primary_ranged_fire_presentation")
	operator.set("sidearm_slot_equipped", true)
	operator.set("_ranged_ready_active", true)
	operator.set("_ranged_ready_weapon_definition", operator.get("sidearm_weapon_definition"))
	operator.set("_sidearm_action_phase", &"firing")
	var sidearm_muzzle_position: Vector2 = operator.call("_get_ranged_muzzle_position", Vector2(1.0, 1.0).normalized())
	var expected_sidearm_muzzle := weapon.global_position + Vector2(35.0, -13.0) if weapon != null else Vector2.INF
	if weapon != null and sidearm_muzzle_position.distance_to(expected_sidearm_muzzle) > 0.01:
		failures.append("sidearm modular muzzle is %s, expected %s" % [
			str(sidearm_muzzle_position),
			str(expected_sidearm_muzzle),
		])

	scene_root.queue_free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("operator_primary_ranged_modular_fire_smoke ok")
	quit()


func _install_test_frames(sprite: AnimatedSprite2D, animation_names: Array[StringName]) -> void:
	if sprite == null:
		return

	var frames := SpriteFrames.new()
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)

	for animation_name in animation_names:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 12.0)
		frames.set_animation_loop(animation_name, false)
		for i in range(3):
			frames.add_frame(animation_name, texture)

	sprite.sprite_frames = frames


func _check_layer(
	sprite: AnimatedSprite2D,
	expected_animation: StringName,
	label: String,
	failures: Array[String]
) -> void:
	if sprite == null:
		failures.append("missing %s sprite" % label)
		return
	if not sprite.visible:
		failures.append("%s sprite hidden" % label)
	if sprite.animation != expected_animation:
		failures.append("%s animation is %s, expected %s" % [
			label,
			String(sprite.animation),
			String(expected_animation),
		])
	if not sprite.is_playing():
		failures.append("%s sprite is not playing" % label)
