extends SceneTree

const MAIN_SCENE := preload("res://scenes/game.tscn")
const EXPECTED_DROID_SCENE := "res://game/actors/allies/allied_infantry_droid.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MAIN_SCENE.instantiate()
	assert(scene != null, "Expected main scene to instantiate.")

	var drone_manager := scene.get_node_or_null("World/DroneManager")
	assert(drone_manager != null, "Expected main scene to include World/DroneManager.")

	var drone_scene: PackedScene = drone_manager.get("drone_scene")
	assert(drone_scene != null, "Expected DroneManager.drone_scene to be assigned.")
	assert(drone_scene.resource_path == EXPECTED_DROID_SCENE, "Expected main DroneManager to spawn %s, got %s." % [EXPECTED_DROID_SCENE, drone_scene.resource_path])
	assert(drone_manager.get("toggle_fire_action") == &"drone_toggle_fire", "Expected DroneManager to own fire command input.")
	assert(drone_manager.get("cycle_follow_distance_action") == &"drone_cycle_follow_distance", "Expected DroneManager to own follow-distance input.")
	assert(drone_manager.get("issue_guard_order_action") == &"drone_issue_guard_order", "Expected DroneManager to own guard-order input.")
	assert(drone_manager.get("recall_guard_order_action") == &"drone_recall_order", "Expected DroneManager to own guard recall input.")
	assert(InputMap.has_action(&"drone_issue_guard_order"), "Expected drone_issue_guard_order InputMap action.")
	assert(InputMap.has_action(&"drone_recall_order"), "Expected drone_recall_order InputMap action.")

	var droid := drone_scene.instantiate()
	assert(droid != null, "Expected allied droid scene to instantiate.")
	assert(droid is CombatDrone, "Expected allied droid to inherit CombatDrone behavior.")
	assert(not droid.has_method("_toggle_combat_mode"), "Expected allied droid to have no local fire-at-will toggle method.")
	assert(droid.get_node_or_null("AnimatedSprite2D") != null, "Expected allied droid animated sprite presentation.")
	assert(droid.get_node_or_null("StatusLabel") != null, "Expected allied droid status label presentation.")

	droid.free()
	scene.free()
	print("[MainSceneAlliedDroidSmoke] ok scene=%s manager_commands=T/G/J+click/K" % EXPECTED_DROID_SCENE)
	quit(0)
