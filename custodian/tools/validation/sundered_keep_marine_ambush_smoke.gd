extends SceneTree

const KEEP_SCENE := preload("res://game/world/sundered_keep/sundered_keep_map.tscn")

var failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene_root := Node2D.new()
	root.add_child(scene_root)
	current_scene = scene_root
	var target := CharacterBody2D.new()
	target.name = "AmbushValidationTarget"
	target.position = Vector2(-10000.0, -10000.0)
	target.add_to_group("player")
	scene_root.add_child(target)
	var map := KEEP_SCENE.instantiate()
	scene_root.add_child(map)
	await process_frame
	var ambush := map.get_node_or_null("GreatHallMarineAmbush") as SunderedKeepMarineAmbush
	var marine := map.get_node_or_null("GreatHallDashMarine") as Enemy
	_check(ambush != null and marine != null, "production map must stage the authored Marine encounter")
	if ambush == null or marine == null:
		quit(1)
		return
	var dash := marine.get_marine_dash_ability()
	var idle := ambush.capture_route_state()
	_check(idle.state == "idle" and not marine.is_physics_processing(), "staged Marine must wait for approach")
	_check(is_equal_approx(dash.cadence_timer, 1.4), "authored cadence must retain its 1.4 second initial credit")
	_check(is_equal_approx(dash.config.damage, 32.0) and is_equal_approx(dash.config.cooldown, 1.1), "ambush must retain scene dash tuning")
	ambush.target = target
	ambush.force_dash_for_validation()
	marine.set_physics_process(false)
	_check(ambush.capture_route_state().state == "active", "force dash must wake the shared actor")
	_check(marine.target == target and not marine.behavior_state_machine_enabled, "ambush must retain the authored target and shared legacy-AI handoff")
	_check(dash.phase == &"windup" and not dash.attack_id.is_empty(), "explicit request seam must start one complete ability")
	_check(marine.get_enemy_presentation_animation() == "marine_dash_charge_e", "authored dash must request the original charge animation")
	_check(dash.warning_line != null and dash.warning_line.visible, "authored dash must display its telegraph")
	dash.finish()
	_check(ambush.restore_route_state(idle), "idle route state must remain restorable")
	_check(not marine.is_physics_processing() and ambush.capture_route_state().state == "idle", "idle restore must suspend the shared actor")
	var active := idle.duplicate(true)
	active["state"] = "active"
	_check(ambush.restore_route_state(active), "active route state must remain restorable")
	_check(marine.is_physics_processing() and marine.target == target, "active restore must resume shared AI against the same target")
	marine.set_physics_process(false)
	var complete := active.duplicate(true)
	complete["state"] = "complete"
	complete["marine_alive"] = false
	_check(ambush.restore_route_state(complete), "completed encounter must remain restorable")
	_check(ambush.capture_route_state().state == "complete" and ambush.marine == null, "complete restore must not replay the encounter")
	scene_root.queue_free()
	await process_frame
	if not failed:
		print("SUNDERED_KEEP_MARINE_AMBUSH_SMOKE: PASS")
	quit(1 if failed else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("[MarineAmbushSmoke] %s" % message)
