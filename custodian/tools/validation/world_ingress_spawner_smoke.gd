extends SceneTree

const LEVEL_DEFINITION_SCRIPT := preload("res://game/world/levels/level_definition.gd")
const SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	world.name = "World"
	root.add_child(world)
	var map := Node2D.new()
	map.name = "ProcGenRuntime"
	world.add_child(map)
	var spawner := SPAWNER_SCRIPT.new()
	world.add_child(spawner)
	var definitions := [
		_definition("alpha_level", "alpha_ingress", [[4, 0]], 100),
		_definition("beta_level", "beta_ingress", [[4, 0], [-8, 0]], 90),
	]
	var level_data := {
		"compound_ingress": [Vector2i(20, 20)],
		"player_spawn": Vector2i(4, 4),
	}
	var placed: Array = spawner.call("place_all", level_data, map, world, null, definitions)
	var errors: Array[String] = []
	if placed.size() != 2: errors.append("expected two generated ingresses, got %d" % placed.size())
	var placements := spawner.call("get_last_placements") as Dictionary
	if not placements.has("alpha_level") or not placements.has("beta_level"):
		errors.append("placement diagnostics omitted a level")
	else:
		var alpha := placements.alpha_level as Vector2i
		var beta := placements.beta_level as Vector2i
		if alpha.distance_squared_to(beta) < 100: errors.append("minimum spacing was not honored")
	for ingress in placed:
		if not ingress.is_in_group("generated_world_ingress"): errors.append("generated ingress group missing")
		if String(ingress.get("level_id")).is_empty(): errors.append("generated ingress has no level ID")
	var first_snapshot := placements.duplicate(true)
	for ingress in placed: ingress.queue_free()
	await process_frame
	var repeated: Array = spawner.call("place_all", level_data, map, world, null, definitions)
	if spawner.call("get_last_placements") != first_snapshot: errors.append("placement is not deterministic")
	if repeated.size() != 2: errors.append("repeat placement count changed")
	_finish(errors)


func _definition(level_id: String, ingress_id: String, offsets: Array, priority: int) -> RefCounted:
	var definition: RefCounted = LEVEL_DEFINITION_SCRIPT.new()
	definition.call("configure_from_dictionary", {
		"level_id": level_id,
		"display_name": level_id.to_pascal_case(),
		"target_scene_path": "res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn",
		"tags": ["world_ingress"],
		"ingress": {
			"ingress_id": ingress_id,
			"prompt_text": "ENTER",
			"target_spawn_id": "EntrySpawn",
			"interaction_distance": 92.0,
			"placement": {
				"priority": priority,
				"minimum_spacing_tiles": 10,
				"search_radius_tiles": 14,
				"offset_candidates_tiles": offsets,
			},
		},
	})
	return definition


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[WorldIngressSpawnerSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[WorldIngressSpawnerSmoke] %s" % error)
	quit(1)
