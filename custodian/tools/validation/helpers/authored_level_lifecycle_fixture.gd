class_name AuthoredLevelLifecycleFixture
extends RefCounted

const AUTHORED_LEVEL_SCRIPT := preload("res://game/world/levels/authored_level_2d.gd")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
const INGRESS_SCRIPT := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const TEST_UI_SCRIPT := preload("res://tools/validation/fixtures/level_lifecycle_test_ui.gd")
const TEST_ACTOR_SCRIPT := preload("res://tools/validation/fixtures/level_lifecycle_test_actor.gd")
const TEST_CAMERA_SCRIPT := preload("res://tools/validation/fixtures/level_lifecycle_test_camera.gd")


func create(tree: SceneTree, suffix: String, profile: StringName, target_spawn_id: StringName) -> Dictionary:
	var paths := _write_resources(suffix, profile, target_spawn_id)
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	tree.root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var ui := TEST_UI_SCRIPT.new()
	ui.name = "UI"
	game_root.add_child(ui)
	var procgen := Node2D.new()
	procgen.name = "ProcGenRuntime"
	procgen.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(procgen)
	var connected := Node2D.new()
	connected.name = "ConnectedMaps"
	world.add_child(connected)
	var camera := TEST_CAMERA_SCRIPT.new()
	camera.name = "Camera2D"
	camera.global_position = Vector2(18.0, 26.0)
	camera.zoom = Vector2(0.9, 0.9)
	camera.target_zoom = camera.zoom
	world.add_child(camera)
	var actor := TEST_ACTOR_SCRIPT.new()
	actor.name = "Operator"
	actor.add_to_group("player")
	actor.global_position = Vector2(32.0, 48.0)
	world.add_child(actor)
	var loader := LEVEL_LOADER_SCRIPT.new()
	loader.name = "LevelLoader"
	loader.registry_index_path = paths.index
	world.add_child(loader)
	var ingress := INGRESS_SCRIPT.new()
	ingress.name = "FixtureIngress"
	world.add_child(ingress)
	ingress.global_position = actor.global_position
	ingress.configure_level(StringName(paths.level_id), procgen)
	ingress.target_spawn_id = target_spawn_id
	return {
		"game_root": game_root,
		"world": world,
		"ui": ui,
		"procgen": procgen,
		"connected": connected,
		"camera": camera,
		"actor": actor,
		"loader": loader,
		"ingress": ingress,
		"level_id": StringName(paths.level_id),
	}


func _write_resources(suffix: String, profile: StringName, target_spawn_id: StringName) -> Dictionary:
	var safe_suffix := suffix.validate_filename().to_snake_case()
	var scene_path := "user://authored_level_lifecycle_%s.tscn" % safe_suffix
	var definition_path := "user://authored_level_lifecycle_%s.json" % safe_suffix
	var index_path := "user://authored_level_lifecycle_%s_index.json" % safe_suffix
	var level_id := "lifecycle_%s" % safe_suffix
	var level := AUTHORED_LEVEL_SCRIPT.new()
	level.name = "LifecycleFixtureLevel"
	level.draw_placeholder_grid = false
	var collision_root := Node2D.new()
	collision_root.name = "Collision"
	level.add_child(collision_root)
	collision_root.owner = level
	var boundary := StaticBody2D.new()
	boundary.name = "PathBoundaryCollision"
	collision_root.add_child(boundary)
	boundary.owner = level
	var markers := Node2D.new()
	markers.name = "Markers"
	level.add_child(markers)
	markers.owner = level
	var spawn := Marker2D.new()
	spawn.name = "Spawn_Main"
	spawn.position = Vector2(240.0, 80.0)
	markers.add_child(spawn)
	spawn.owner = level
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, scene_path) == OK)
	level.free()
	_write_json(definition_path, {
		"schema": "custodian.level_definition.v1",
		"level_id": level_id,
		"display_name": "Lifecycle Fixture",
		"target_scene_path": scene_path,
		"world_context": "campaign_region",
		"presentation_profile": String(profile),
		"lifecycle": {
			"cache_policy": "keep_during_route",
			"state_policy": "session",
		},
		"tags": ["authored", "world_ingress"],
		"ingress": {
			"ingress_id": level_id,
			"prompt_text": "ENTER FIXTURE",
			"target_spawn_id": String(target_spawn_id),
			"interaction_distance": 92.0,
		},
	})
	_write_json(index_path, {
		"schema": "custodian.level_registry.v1",
		"definitions": [definition_path],
	})
	return {
		"scene": scene_path,
		"definition": definition_path,
		"index": index_path,
		"level_id": level_id,
	}


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(value, "  ") + "\n")
