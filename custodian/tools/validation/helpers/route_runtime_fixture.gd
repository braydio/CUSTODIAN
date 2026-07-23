class_name RouteRuntimeFixture
extends RefCounted

const LEVEL_SCRIPT := preload("res://tools/validation/fixtures/route_test_level.gd")
const EXIT_SCRIPT := preload("res://game/world/levels/level_exit_2d.gd")
const LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
const MANAGER_SCRIPT := preload("res://game/world/routes/route_traversal_manager.gd")
const INGRESS_SCRIPT := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const CAMERA_SCRIPT := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")


func create(tree: SceneTree, suffix: String, options: Dictionary = {}) -> Dictionary:
	var paths := _write_resources(suffix, options)
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	tree.root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var procgen := Node2D.new()
	procgen.name = "ProcGenRuntime"
	procgen.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(procgen)
	var connected := Node2D.new()
	connected.name = "ConnectedMaps"
	world.add_child(connected)
	var camera := CAMERA_SCRIPT.new()
	camera.name = "Camera2D"
	camera.runtime_map = procgen
	world.add_child(camera)
	var actor := CharacterBody2D.new()
	actor.name = "Operator"
	actor.add_to_group("player")
	actor.global_position = Vector2(17.0, 29.0)
	if bool(options.get("trigger_exits", false)):
		var actor_shape := CollisionShape2D.new()
		actor_shape.name = "CollisionShape2D"
		actor_shape.shape = CircleShape2D.new()
		actor.add_child(actor_shape)
	world.add_child(actor)
	var loader := LOADER_SCRIPT.new()
	loader.name = "LevelLoader"
	loader.registry_index_path = paths.level_index
	world.add_child(loader)
	var manager := MANAGER_SCRIPT.new()
	manager.name = "RouteTraversalManager"
	manager.route_registry_index_path = paths.route_index
	world.add_child(manager)
	var ingress := INGRESS_SCRIPT.new()
	ingress.name = "RouteIngress"
	ingress.ingress_id = &"fixture"
	ingress.configure_route(&"fixture_route", StringName(str(options.get("profile", "production"))), procgen)
	world.add_child(ingress)
	return {
		"game_root": game_root, "world": world, "procgen": procgen,
		"connected": connected, "camera": camera, "actor": actor, "loader": loader,
		"manager": manager, "ingress": ingress, "paths": paths,
	}


func enter(fixture: Dictionary) -> bool:
	var ingress: Node = fixture.ingress
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", fixture.actor)
	return bool(fixture.manager.call("has_active_route"))


func _write_resources(suffix: String, options: Dictionary) -> Dictionary:
	var safe := suffix.validate_filename().to_snake_case()
	var root := "user://route_fixture_%s" % safe
	var level_a_scene := "%s_a.tscn" % root
	var level_a_retry_scene := "%s_a_retry.tscn" % root
	var level_b_scene := "%s_b.tscn" % root
	var level_a_definition := "%s_a.json" % root
	var level_b_definition := "%s_b.json" % root
	var level_index := "%s_levels.json" % root
	var route_definition := "%s_route.json" % root
	var route_index := "%s_routes.json" % root
	var a_flags: Dictionary = (options.get("a_flags", {}) as Dictionary).duplicate()
	var b_flags: Dictionary = (options.get("b_flags", {}) as Dictionary).duplicate()
	a_flags["trigger_exits"] = bool(options.get("trigger_exits", false))
	b_flags["trigger_exits"] = bool(options.get("trigger_exits", false))
	var a_exit_ids: Array[String] = ["continue", "return_world"]
	if bool(a_flags.get("duplicate_exit_id", false)):
		a_exit_ids.append("continue")
	if bool(a_flags.get("empty_exit_id", false)):
		a_exit_ids.append("")
	_write_level_scene(level_a_scene, a_exit_ids, Vector2(100.0, 10.0), a_flags)
	_write_level_scene(level_a_retry_scene, ["continue", "return_world"], Vector2(100.0, 10.0), {})
	_write_level_scene(level_b_scene, ["backtrack", "return_world"], Vector2(300.0, 20.0), b_flags, "OtherSpawn" if bool(options.get("b_missing_actual_spawn", false)) else "EntrySpawn")
	_write_json(level_a_definition, _level_definition("fixture_a", level_a_scene, str(options.get("a_cache", "keep_during_route")), str(options.get("a_state", "session"))))
	_write_json(level_b_definition, _level_definition("fixture_b", level_b_scene, str(options.get("b_cache", "keep_during_route")), str(options.get("b_state", "session"))))
	_write_json(level_index, {"schema": "custodian.level_registry.v1", "definitions": [level_a_definition, level_b_definition]})
	var route := _route_dictionary()
	if bool(options.get("missing_target_scene", false)):
		var broken := _read_json(level_b_definition)
		broken.target_scene_path = "user://missing_route_fixture_scene.tscn"
		_write_json(level_b_definition, broken)
	if bool(options.get("missing_target_spawn", false)):
		for edge: Dictionary in route.edges:
			if edge.edge_id == "a_to_b": edge.target_spawn_id = "MissingSpawn"
	_write_json(route_definition, route)
	_write_json(route_index, {"schema": "custodian.route_registry.v1", "definitions": [route_definition]})
	return {
		"level_index": level_index,
		"route_index": route_index,
		"route_definition": route_definition,
		"level_a_scene": level_a_scene,
		"level_a_retry_scene": level_a_retry_scene,
		"level_b_scene": level_b_scene,
	}


func _write_level_scene(path: String, exit_ids: Array[String], spawn_position: Vector2, flags: Dictionary, marker_name := "EntrySpawn") -> void:
	var level := LEVEL_SCRIPT.new()
	level.name = "RouteFixtureLevel"
	level.draw_placeholder_grid = false
	level.fail_activation = bool(flags.get("fail_activation", false))
	level.fail_camera = bool(flags.get("fail_camera", false))
	level.fail_state_restore = bool(flags.get("fail_state_restore", false))
	level.fail_completion = bool(flags.get("fail_completion", false))
	var collision_root := Node2D.new()
	collision_root.name = "Collision"
	level.add_child(collision_root)
	collision_root.owner = level
	var boundary := StaticBody2D.new()
	boundary.name = "PathBoundaryCollision"
	collision_root.add_child(boundary)
	boundary.owner = level
	var marker := Marker2D.new()
	marker.name = marker_name
	marker.position = spawn_position
	level.add_child(marker)
	marker.owner = level
	var exits := Node2D.new()
	exits.name = "Exits"
	level.add_child(exits)
	exits.owner = level
	for exit_id: String in exit_ids:
		var exit := EXIT_SCRIPT.new() as LevelExit2D
		exit.name = "Exit_%s" % exit_id.to_pascal_case()
		exit.exit_id = StringName(exit_id)
		exit.trigger_on_body_entered = bool(flags.get("trigger_exits", false))
		exit.position = spawn_position + Vector2(96.0 + exit_ids.find(exit_id) * 96.0, 0.0)
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.shape = RectangleShape2D.new()
		exit.add_child(shape)
		exits.add_child(exit, true)
		exit.owner = level
		shape.owner = level
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	level.free()


func _level_definition(id: String, scene: String, cache_policy: String, state_policy: String) -> Dictionary:
	return {
		"schema": "custodian.level_definition.v1", "level_id": id,
		"display_name": id, "target_scene_path": scene,
		"world_context": "campaign_region", "presentation_profile": "gameplay",
		"spawns": ["EntrySpawn"], "tags": ["authored", "route_node"],
		"lifecycle": {"cache_policy": cache_policy, "state_policy": state_policy},
	}


func _route_dictionary() -> Dictionary:
	return {
		"schema": "custodian.route_definition.v1", "route_id": "fixture_route",
		"display_name": "Fixture Route", "world_context": "campaign_region",
		"default_profile": "production", "tags": ["authored"],
		"nodes": [
			{"node_id": "a", "level_id": "fixture_a"},
			{"node_id": "b", "level_id": "fixture_b"},
		],
		"edges": [
			{"edge_id": "enter_a", "from_node_id": "@world_origin", "exit_id": "enter", "to_node_id": "a", "target_spawn_id": "EntrySpawn", "direction": "forward", "transition_style": "fade"},
			{"edge_id": "a_to_b", "from_node_id": "a", "exit_id": "continue", "to_node_id": "b", "target_spawn_id": "EntrySpawn", "direction": "forward", "transition_style": "fade"},
			{"edge_id": "a_exfil", "from_node_id": "a", "exit_id": "return_world", "to_node_id": "@world_origin", "target_spawn_id": "", "direction": "exfil", "transition_style": "fade"},
			{"edge_id": "b_to_a", "from_node_id": "b", "exit_id": "backtrack", "to_node_id": "a", "target_spawn_id": "EntrySpawn", "direction": "back", "transition_style": "fade"},
			{"edge_id": "b_exfil", "from_node_id": "b", "exit_id": "return_world", "to_node_id": "@world_origin", "target_spawn_id": "", "direction": "exfil", "transition_style": "fade"},
		],
		"profiles": [{"profile_id": "production", "entry_edge_id": "enter_a", "enabled_edge_ids": ["enter_a", "a_to_b", "a_exfil", "b_to_a", "b_exfil"]}],
	}


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(value, "  ") + "\n")


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}
