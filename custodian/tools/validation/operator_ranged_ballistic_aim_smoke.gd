extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const RESOLVER := preload("res://game/systems/combat/ranged_ballistic_aim_resolver.gd")

var failures: Array[String] = []


func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "BallisticAimSmokeRoot"
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
	var axis: Vector2 = operator.call("_get_current_ranged_weapon_axis", Vector2.RIGHT)
	_expect(axis.x > 0.0, "cursor reversal twisted the committed east weapon axis")
	_expect((operator.get("_primary_ranged_action_direction") as Vector2).x > 0.0, "fire presentation lost accepted east commitment")

	# Unsupported production octants must use the explicit accepted-direction
	# fallback. A previously resolved east socket must never remain authority.
	operator.set("_primary_ranged_action_phase", &"")
	operator.set("aim_direction", Vector2.UP)
	upper.play(&"ranged_2h_stance_modular_up")
	weapon.play(&"ranged_2h_stance_modular_up")
	var unresolved_axis: Vector2 = operator.call("_get_current_ranged_weapon_axis", Vector2.UP)
	_expect(unresolved_axis.dot(Vector2.UP) > 0.999, "unresolved north sector consumed stale east barrel authority")
	operator.set("aim_direction", Vector2.RIGHT)
	upper.play(&"ranged_2h_stance_modular_right")
	weapon.play(&"ranged_2h_stance_modular_right")
	operator.call("_sync_primary_ranged_weapon_frame_to_upper")

	var muzzle: Vector2 = operator.call("_get_ranged_muzzle_position", Vector2.RIGHT)
	var barrel := operator.get_node("PrimaryWeaponSocket/Barrel") as Node2D
	_expect(muzzle.distance_to(barrel.global_position) < 0.01, "release muzzle is not frame-aware Barrel")

	var correction := RESOLVER.resolve_fine_correction(Vector2.RIGHT, Vector2.RIGHT.rotated(deg_to_rad(35.0)), 24.0)
	_expect(absf(rad_to_deg(correction)) <= 24.001, "fine correction exceeded ±24 degrees")
	_expect(is_equal_approx(absf(rad_to_deg(correction)), 24.0), "fine correction did not cover the full configured sector envelope")
	var repeated := correction
	for index in range(500):
		repeated = RESOLVER.resolve_fine_correction(Vector2.RIGHT, Vector2.RIGHT.rotated(deg_to_rad(35.0)), 24.0)
	_expect(is_equal_approx(repeated, correction), "fine correction accumulated across repeated updates")
	var pursuit_60hz := 0.0
	for index in range(60):
		pursuit_60hz = RESOLVER.pursue_correction(pursuit_60hz, deg_to_rad(20.0), 20.0, 1.0 / 60.0)
	var pursuit_120hz := 0.0
	for index in range(120):
		pursuit_120hz = RESOLVER.pursue_correction(pursuit_120hz, deg_to_rad(20.0), 20.0, 1.0 / 120.0)
	_expect(absf(pursuit_60hz - pursuit_120hz) < 0.0001, "weapon pursuit changed with presentation frame rate")
	_expect(absf(pursuit_60hz - deg_to_rad(20.0)) < 0.0001, "weapon pursuit did not converge toward desired correction")

	var clear_solution := RESOLVER.solve(
		root.world_2d.direct_space_state,
		Vector2(160.0, 0.0),
		Vector2.ZERO,
		Vector2.RIGHT,
		320.0,
		[]
	)
	_expect((clear_solution.predicted_world_position as Vector2).distance_to(Vector2(160.0, 0.0)) < 0.01, "clear prediction did not use desired target depth")
	_expect(not bool(clear_solution.obstructed), "clear prediction reported obstruction")

	var blocker := StaticBody2D.new()
	blocker.position = Vector2(80.0, 0.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(12.0, 64.0)
	shape.shape = rectangle
	blocker.add_child(shape)
	scene_root.add_child(blocker)
	await physics_frame
	var blocked_solution := RESOLVER.solve(
		root.world_2d.direct_space_state,
		Vector2(160.0, 0.0),
		Vector2.ZERO,
		Vector2.RIGHT,
		320.0,
		[]
	)
	_expect(bool(blocked_solution.obstructed), "wall prediction did not report obstruction")
	_expect((blocked_solution.predicted_world_position as Vector2).x < 100.0, "wall prediction did not stop at blocker")

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
	})
	blocker.queue_free()
	await physics_frame
	operator.call("_emit_pending_ranged_shot")
	var bullets := get_nodes_in_group("projectiles")
	_expect(not bullets.is_empty(), "snap-fire emission was alignment-gated")
	if not bullets.is_empty():
		var bullet := bullets.back() as Node2D
		_expect((bullet.get("direction") as Vector2).dot(axis) > 0.999, "zero-spread projectile did not use release-time weapon axis")
		_expect(bullet.global_position.distance_to(barrel.global_position) < 0.1, "projectile did not spawn at release-frame muzzle")

	scene_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("operator_ranged_ballistic_aim_smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
