extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const SOCKET_LIBRARY := preload("res://game/actors/operator/animations/operator_weapon_socket_library.gd")
const CAMERA_SCRIPT := preload("res://game/world/camera.gd")

var _failures: Array[String] = []


func _init() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.set_script(CAMERA_SCRIPT)
	world.add_child(camera)
	camera.set_process(false)
	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	await process_frame
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)

	var library := SOCKET_LIBRARY.new()
	_expect(library.load_generated(), "generated Carbine socket JSON did not load")
	for sample in [
		[Vector2.RIGHT, &"e"], [Vector2.LEFT, &"w"],
		[Vector2(1, 1), &"se"], [Vector2(-1, 1), &"sw"],
		[Vector2.UP, &"n"], [Vector2(1, -1), &"ne"],
		[Vector2.DOWN, &"s"], [Vector2(-1, -1), &"nw"],
	]:
		_expect(library.resolve_aim_sector(sample[0]) == sample[1], "aim sector failed for %s" % sample[0])

	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var weapon := operator.get_node("ModularSidearmSprite") as AnimatedSprite2D
	for suffix in ["right", "left", "down_right", "down_left"]:
		for phase in ["stance", "aim", "fire"]:
			var animation := StringName("ranged_2h_%s_modular_%s" % [phase, suffix])
			_expect(upper.sprite_frames.has_animation(animation), "missing upper animation %s" % animation)
			_expect(weapon.sprite_frames.has_animation(animation), "missing directional weapon art %s" % animation)
			if upper.sprite_frames.has_animation(animation):
				var errors: PackedStringArray = library.validate_track(animation, upper.sprite_frames.get_frame_count(animation))
				_expect(errors.is_empty(), "socket coverage errors: %s" % ", ".join(errors))

	var definition = operator.get("primary_weapon_definition")
	_expect(definition.production_socket_data_required, "Carbine must require production socket data")
	_expect(not String(definition.socket_data_path).is_empty(), "Carbine socket_data_path is empty")
	for sector in [&"e", &"w", &"se", &"sw"]:
		_expect(definition.directional_weapon_textures.get(String(sector)) is Texture2D, "missing Carbine directional texture %s" % sector)
	_expect(operator.get_node_or_null("PrimaryWeaponSocket/Barrel") != null, "MuzzleSocket/Barrel missing")
	_expect(operator.get_node_or_null("PrimaryWeaponSocket/EjectionSocket") != null, "EjectionSocket missing")
	_expect(operator.get_node_or_null("PrimaryWeaponSocket/SupportGripDebug") != null, "SupportGripDebug missing")
	_expect(operator.get_node_or_null("PrimaryWeaponSocket/MagazineSocket") != null, "MagazineSocket missing")
	_expect(operator.get_node_or_null("PrimaryWeaponSocket/OffhandPropSprite") != null, "OffhandPropSprite missing")
	_expect(operator.get("operator_weapon_socket_debug_enabled") != null, "weapon socket debug toggle missing")

	operator.set("combat_loadout_mode", &"ranged")
	operator.set("using_unarmed", false)
	operator.set("primary_weapon_equipped", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("_ranged_ready_active", true)
	operator.set("_ranged_ready_weapon_definition", definition)
	upper.visible = true
	weapon.visible = true
	upper.play(&"ranged_2h_stance_modular_right")
	weapon.play(&"ranged_2h_stance_modular_right")
	upper.set_frame_and_progress(0, 0.0)
	operator.call("_sync_primary_ranged_weapon_frame_to_upper")
	var barrel := operator.get_node("PrimaryWeaponSocket/Barrel") as Node2D
	var resolved_muzzle: Vector2 = operator.call("_get_ranged_muzzle_position", Vector2.RIGHT)
	_expect(resolved_muzzle.distance_to(barrel.global_position) < 0.01, "projectile origin did not match frame-aware muzzle")
	var ejection := operator.get_node("PrimaryWeaponSocket/EjectionSocket") as Node2D
	var resolved_ejection: Vector2 = operator.call("get_ranged_ejection_position")
	_expect(resolved_ejection.distance_to(ejection.global_position) < 0.01, "ejection origin did not match frame-aware socket")
	_expect(weapon.z_index == 3, "east draw order did not come from socket metadata")

	upper.play(&"ranged_2h_stance_modular_down_right")
	weapon.play(&"ranged_2h_stance_modular_down_right")
	operator.set("aim_direction", Vector2(1, 1).normalized())
	operator.call("_sync_primary_ranged_weapon_frame_to_upper")
	_expect(weapon.z_index == 4, "southeast draw order did not change")

	_expect(float(operator.get("ranged_lower_duration")) < float(operator.get("ranged_raise_duration")), "ranged lower duration must be faster than raise")
	_expect(is_equal_approx(float(operator.get("ranged_aim_ready_ratio")), 0.70), "aim-ready threshold drifted")
	operator.set("_ranged_ready_active", true)
	operator.set("_ranged_ready_weapon_definition", definition)
	operator.set("aim_direction", Vector2.RIGHT)
	_expect(bool(operator.call("_begin_modular_primary_ranged_aim_presentation")), "raise transition did not start")
	operator.call("_tick_primary_ranged_action_presentation", float(operator.get("ranged_raise_duration")) * 0.5)
	var partial_raise_frame := upper.frame
	operator.call("_exit_ranged_ready")
	_expect(bool(operator.call("_is_primary_ranged_lower_presentation_active")), "raise release did not enter lowering")
	_expect(upper.frame <= partial_raise_frame + 1, "partial raise snapped to full pose before lowering")
	operator.set("stamina", 100.0)
	operator.set("_dodge_cooldown_remaining", 0.0)
	_expect(bool(operator.call("_try_start_dodge")), "dodge could not interrupt lowering")
	_expect(not bool(operator.call("_is_primary_ranged_transition_presentation_active")), "dodge left ranged transition active")
	operator.call("_cancel_dodge")

	camera.call("set_ranged_aim_camera_active", true, Vector2.RIGHT)
	camera.call("_update_ranged_aim_camera", 0.22)
	var camera_snapshot: Dictionary = camera.call("get_ranged_aim_camera_snapshot")
	_expect(bool(camera_snapshot.active), "aim camera did not activate")
	_expect((camera_snapshot.lead as Vector2).x > 0.0, "aim camera did not lead toward aim")
	_expect(float(camera.get("ranged_aim_camera_exit_sec")) < float(camera.get("ranged_aim_camera_enter_sec")), "aim camera exit must be faster than entry")
	var prior_lead: Vector2 = camera_snapshot.lead
	camera.call("set_ranged_aim_camera_active", true, Vector2.LEFT)
	camera.call("_update_ranged_aim_camera", 1.0 / 60.0)
	camera_snapshot = camera.call("get_ranged_aim_camera_snapshot")
	_expect((camera_snapshot.direction as Vector2).is_equal_approx(Vector2.LEFT), "aim camera direction did not retarget")
	_expect((camera_snapshot.lead as Vector2).distance_to(Vector2.LEFT * 32.0) > 0.1, "aim camera lead snapped instead of smoothing")
	_expect((camera_snapshot.lead as Vector2) != prior_lead, "aim camera lead did not respond to direction change")
	var shake_before: Vector2 = camera.get("_shake_offset")
	camera.call("apply_shake", 2.0, 0.1)
	camera.call("_update_shake", 0.01)
	_expect((camera.get("_shake_offset") as Vector2) != shake_before, "camera shake was not additive during aim")
	camera.call("set_ranged_aim_camera_active", false, Vector2.LEFT)
	for index in range(120):
		camera.call("_update_ranged_aim_camera", 1.0 / 60.0)
	camera_snapshot = camera.call("get_ranged_aim_camera_snapshot")
	_expect(absf(float(camera_snapshot.zoom_multiplier) - 1.0) < 0.001, "aim zoom did not return to baseline")
	_expect((camera_snapshot.lead as Vector2).length() < 0.01, "aim lead did not return to baseline")

	game_root.queue_free()
	await process_frame
	if _failures.is_empty():
		print("operator_weapon_socket_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
