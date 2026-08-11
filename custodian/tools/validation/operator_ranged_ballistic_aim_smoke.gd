extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var failures: Array[String] = []


func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "IntentAuthoritativeRangedAimSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	scene_root.add_child(projectiles)
	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child(operator)
	await process_frame
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set("combat_loadout_mode", &"ranged")
	operator.set("using_unarmed", false)
	operator.set("primary_weapon_equipped", true)
	operator.set("sidearm_slot_equipped", false)
	operator.set("_ranged_ready_active", true)
	operator.set("_ranged_ready_weapon_definition", operator.get("primary_weapon_definition"))
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)

	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var weapon := operator.get_node("ModularSidearmSprite") as AnimatedSprite2D
	upper.visible = true
	weapon.visible = true
	upper.play(&"ranged_2h_stance_modular_right")
	weapon.play(&"ranged_2h_stance_modular_right")
	upper.set_frame_and_progress(0, 0.0)
	operator.call("_begin_modular_primary_ranged_fire_presentation", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.LEFT)
	operator.call("_sync_primary_ranged_weapon_frame_to_upper")
	_expect((operator.get("_primary_ranged_action_direction") as Vector2).x > 0.0, "cursor reversal twisted the committed east fire presentation")
	_expect(String(upper.animation).contains("right"), "cursor reversal switched the committed fire sprite octant")

	var accepted_aim_world_position := Vector2(180.0, 74.0)
	var expected_muzzle: Vector2 = operator.call(
		"_get_ranged_muzzle_position",
		Vector2.RIGHT
	)
	operator.set("current_recoil", 0.0)
	operator.set("_pending_ranged_shot", {
		"timer": 0.0,
		"profile": {
			"spread": 0.0, "speed": 780.0, "damage": 16.0,
			"max_range_px": 320.0, "falloff_start_px": 180.0,
			"falloff_end_px": 320.0, "min_damage_multiplier": 0.5,
			"radius": 3.0, "recoil_kick": 0.0,
		},
		"accepted_aim_direction": Vector2.RIGHT,
		"accepted_aim_world_position": accepted_aim_world_position,
	})
	operator.call("_emit_pending_ranged_shot")
	var emitted_projectiles := get_nodes_in_group("projectiles")
	_expect(emitted_projectiles.size() == 1, "intent-authoritative snap shot did not emit a projectile")
	if emitted_projectiles.size() == 1:
		var bullet := emitted_projectiles[0] as Node2D
		var muzzle := bullet.global_position
		var expected_direction := muzzle.direction_to(accepted_aim_world_position)
		var actual_direction: Vector2 = bullet.get("direction")
		_expect(actual_direction.dot(expected_direction) > 0.99999, "zero-spread projectile did not travel from current muzzle through accepted aim point")
		var physical_axis: Vector2 = operator.call("_get_current_ranged_weapon_axis", Vector2.RIGHT)
		_expect(actual_direction.dot(physical_axis) < 0.9999, "test fixture did not prove sprite/socket axis is non-authoritative")
		_expect(muzzle.distance_to(expected_muzzle) < 0.1, "projectile did not spawn at current frame-aware muzzle")

	scene_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("operator_ranged_ballistic_aim_smoke: PASS (single intent authority)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
