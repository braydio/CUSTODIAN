extends SceneTree

const FAKE_CONTRACT_MAP_SCRIPT := preload(
	"res://tools/validation/fixtures/fake_world_contract_map.gd"
)
const PROXY_SCRIPT := preload(
	"res://game/world/procgen/world_contract_proxy.gd"
)
const LOADER_SCRIPT := preload(
	"res://game/systems/core/systems/contract_world_loader.gd"
)
const CONTRACT_MAP_SCRIPT := preload(
	"res://game/world/procgen/custodian_contract_map.gd"
)
const FAKE_NAVIGATION_SCRIPT := preload(
	"res://tools/validation/fixtures/fake_navigation_system.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_static_wiring()
	_validate_freed_cached_map_guard()
	var bootstrap := root.get_node_or_null("WorldContractBootstrap")
	assert(bootstrap != null, "WorldContractBootstrap autoload missing")
	bootstrap.call("reset")
	await process_frame
	bootstrap.call(
		"set_generator_scene_for_testing",
		_build_fake_generator_scene(false)
	)
	bootstrap.call("ensure_started", 424242)
	assert(int(bootstrap.call("get_state")) == 1, "prewarm must begin generating")
	var generation_metrics := bootstrap.call("get_metrics") as Dictionary
	assert(int(generation_metrics.get("generation_count", 0)) == 1)
	assert(get_current_scene() == null, "operational game scene must not load for prewarm")
	await process_frame
	assert(bool(bootstrap.call("is_ready")), "prewarm did not reach READY")
	var contract := bootstrap.call("get_latest_contract") as Dictionary
	var map_instance := (contract.get("map", {}) as Dictionary).get("instance") as Node
	assert(map_instance != null and is_instance_valid(map_instance))
	var original_map_id := map_instance.get_instance_id()
	assert(map_instance.is_inside_tree(), "prewarmed map must remain alive")

	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var proxy := Node2D.new()
	proxy.name = "ContractMap"
	proxy.set_script(PROXY_SCRIPT)
	world.add_child(proxy)
	var navigation := Node.new()
	navigation.name = "NavigationSystem"
	navigation.set_script(FAKE_NAVIGATION_SCRIPT)
	game_root.add_child(navigation)
	var loader := Node.new()
	loader.name = "ContractWorldLoader"
	loader.set_script(LOADER_SCRIPT)
	_disable_loader_population(loader)
	game_root.add_child(loader)
	await process_frame
	await process_frame
	assert(proxy.get_script() == PROXY_SCRIPT, "game ContractMap must be compatibility proxy")
	assert(proxy.get_script() != CONTRACT_MAP_SCRIPT, "game ContractMap must not generate")
	assert(map_instance.get_instance_id() == original_map_id, "loader replaced prewarmed map")
	assert(map_instance.get_parent() == world.get_node("ProcGenRuntime"))
	assert(int(bootstrap.call("get_state")) == 4, "installed contract must be CLAIMED")
	assert(int((bootstrap.call("get_metrics") as Dictionary).get("generation_count", 0)) == 1)

	game_root.queue_free()
	await process_frame
	assert(not bool(bootstrap.call("is_ready")), "freed claimed map must be stale")
	assert((bootstrap.call("get_latest_contract") as Dictionary).is_empty())
	bootstrap.call("ensure_started", 434343)
	assert(int(bootstrap.call("get_state")) == 1, "stale claim must regenerate")
	await process_frame
	assert(bool(bootstrap.call("is_ready")), "stale claim retry did not reach READY")
	bootstrap.call("reset")
	await process_frame
	assert((bootstrap.call("get_latest_contract") as Dictionary).is_empty())
	assert(int(bootstrap.call("get_state")) == 0)

	bootstrap.call(
		"set_generator_scene_for_testing",
		_build_fake_generator_scene(true)
	)
	bootstrap.call("ensure_started", 515151)
	await process_frame
	assert(int(bootstrap.call("get_state")) == 3, "forced failure must reach FAILED")
	assert(not (bootstrap.call("get_latest_generation_failure") as Dictionary).is_empty())
	bootstrap.call("reset")
	await process_frame
	bootstrap.call(
		"set_generator_scene_for_testing",
		_build_fake_generator_scene(false)
	)
	bootstrap.call("ensure_started", 616161)
	await process_frame
	assert(bool(bootstrap.call("is_ready")), "fresh retry did not reach READY")
	assert(int((bootstrap.call("get_metrics") as Dictionary).get("generation_count", 0)) == 1)
	bootstrap.call("reset")
	await process_frame
	bootstrap.call("restore_generator_scene")
	print("world_contract_prewarm_smoke: PASS")
	quit(0)


func _validate_freed_cached_map_guard() -> void:
	var loader := LOADER_SCRIPT.new()
	var stale_map := Node2D.new()
	var stale_contract := {
		"world_profile": {},
		"map": {
			"instance": stale_map,
			"level_data": {},
		},
	}
	stale_map.free()
	loader.call("_on_contract_generated", stale_contract)
	loader.free()


func _validate_static_wiring() -> void:
	assert(
		ProjectSettings.get_setting("application/run/main_scene")
		== "res://scenes/home_custodian_begin.tscn"
	)
	var game_scene_source := FileAccess.get_file_as_string("res://scenes/game.tscn")
	assert(game_scene_source.contains("world_contract_proxy.gd"))
	assert(not game_scene_source.contains("custodian_contract_map.tscn"))
	var home_source := FileAccess.get_file_as_string(
		"res://game/world/home/custodian_home_begin.gd"
	)
	assert(home_source.contains("await get_tree().process_frame"))
	assert(home_source.contains("FIELD LINK SYNCHRONIZING"))
	assert(not home_source.contains("get_tree().paused = true"))
	var home_scene := load("res://scenes/home_custodian_begin.tscn") as PackedScene
	var home := home_scene.instantiate()
	var operator := home.get_node_or_null("World/Operator")
	var camera := home.get_node_or_null("World/Camera2D")
	assert(operator != null and operator.process_mode != Node.PROCESS_MODE_DISABLED)
	assert(camera != null and camera.process_mode != Node.PROCESS_MODE_DISABLED)
	home.free()


func _build_fake_generator_scene(should_fail: bool) -> PackedScene:
	var generator := Node2D.new()
	generator.set_script(FAKE_CONTRACT_MAP_SCRIPT)
	generator.set("should_fail", should_fail)
	var packed := PackedScene.new()
	assert(packed.pack(generator) == OK)
	generator.free()
	return packed


func _disable_loader_population(loader: Node) -> void:
	for property_name in [
		"hide_static_sectors",
		"reposition_operator_from_contract",
		"reposition_spawn_nodes_from_contract",
		"reposition_terminal_from_contract",
		"reposition_construction_population_from_contract",
		"reposition_vehicles_from_contract",
		"reposition_items_from_contract",
		"reposition_camera_from_contract",
		"place_arrn_relays_from_contract",
		"place_tutorial_resource_nodes_from_contract",
		"place_expedition_resource_nodes_from_contract",
		"place_gothic_compound_connection",
		"place_registered_level_connections",
		"place_sundered_keep_connection",
		"place_ambient_enemy_camps_from_contract",
	]:
		loader.set(property_name, false)
