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

	var droid := drone_scene.instantiate()
	assert(droid != null, "Expected allied droid scene to instantiate.")
	assert(droid is CombatDrone, "Expected allied droid to inherit CombatDrone behavior.")
	assert(droid.has_method("_toggle_combat_mode"), "Expected allied droid fire-at-will toggle method.")
	assert(droid.get("toggle_key") == KEY_T, "Expected allied droid fire-at-will toggle key to be T.")
	assert(droid.get_node_or_null("AnimatedSprite2D") != null, "Expected allied droid animated sprite presentation.")

	droid.free()
	scene.free()
	print("[MainSceneAlliedDroidSmoke] ok scene=%s toggle_key=T" % EXPECTED_DROID_SCENE)
	quit(0)
