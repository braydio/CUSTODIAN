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

	_install_test_frames(lower, &"ranged_2h_fire_lower_right")
	_install_test_frames(upper, &"ranged_2h_fire_upper_right")
	_install_test_frames(weapon, &"ranged_2h_fire_weapon_right")
	_install_test_frames(fx, &"ranged_2h_fire_fx_right")

	if not bool(operator.call("_begin_modular_primary_ranged_fire_presentation")):
		failures.append("primary ranged modular fire presentation did not start")

	_check_layer(lower, &"ranged_2h_fire_lower_right", "lower", failures)
	_check_layer(upper, &"ranged_2h_fire_upper_right", "upper", failures)
	_check_layer(weapon, &"ranged_2h_fire_weapon_right", "weapon", failures)
	_check_layer(fx, &"ranged_2h_fire_fx_right", "fx", failures)

	var legacy_body := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if legacy_body != null and legacy_body.visible:
		failures.append("legacy body sprite should be hidden during modular primary ranged fire")

	var primary_weapon := operator.get_node_or_null("PrimaryWeaponSocket/PrimaryWeaponSprite") as AnimatedSprite2D
	if primary_weapon != null and primary_weapon.visible:
		failures.append("legacy primary weapon sprite should be hidden during modular primary ranged fire")

	operator.call("_tick_primary_ranged_fire_presentation", 10.0)
	if bool(operator.call("_is_primary_ranged_fire_presentation_active")):
		failures.append("primary ranged modular fire presentation did not end after timer tick")

	scene_root.queue_free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("operator_primary_ranged_modular_fire_smoke ok")
	quit()


func _install_test_frames(sprite: AnimatedSprite2D, animation_name: StringName) -> void:
	if sprite == null:
		return

	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, 12.0)
	frames.set_animation_loop(animation_name, false)

	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)

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
