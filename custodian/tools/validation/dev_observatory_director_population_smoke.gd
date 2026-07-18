extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory == null:
		push_error("[DevObservatoryDirectorPopulationSmoke] DevObservatory autoload missing")
		quit(1)
		return
	observatory.clear()
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	current_scene = game_root
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var entities := Node2D.new()
	entities.name = "Entities"
	world.add_child(entities)

	for index in range(2):
		var agent := GRUNT_SCENE.instantiate()
		agent.name = "DirectorAgent%d" % index
		entities.add_child(agent)
		await process_frame
		agent.set_physics_process(false)
		agent.call("set_behavior_profile", &"raider_grunt")
	var legacy := GRUNT_SCENE.instantiate()
	legacy.name = "LegacyAgent"
	legacy.set("behavior_state_machine_enabled", false)
	entities.add_child(legacy)
	await process_frame
	legacy.set_physics_process(false)

	observatory.call("_sample_runtime_gauges")
	if int(observatory.gauges.get("active_enemies", -1)) != 3:
		failures.append("active enemy gauge did not count all three deliberate fixtures")
	if int(observatory.gauges.get("director_behavior_agents", -1)) != 2:
		failures.append("director population gauge did not count exactly two managed agents")
	if int(observatory.gauges.get("legacy_combat_agents", -1)) != 1:
		failures.append("legacy population gauge did not retain the one unmanaged enemy")
	var sample := observatory.gauges.get("enemy_behavior_sample", {}) as Dictionary
	if not bool(sample.get("enabled", false)) or String(sample.get("profile_id", "")) != "raider_grunt":
		failures.append("director behavior sample did not expose the enabled raider_grunt profile")
	if not failures.is_empty():
		for failure in failures:
			push_error("[DevObservatoryDirectorPopulationSmoke] %s" % failure)
		quit(1)
		return
	print("DEV_OBSERVATORY_DIRECTOR_POPULATION_SMOKE: PASS")
	quit(0)
