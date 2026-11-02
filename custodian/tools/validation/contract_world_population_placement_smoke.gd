extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
const FIELD_FABRICATOR_SCENE := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")
const CONSTRUCTION_ZONE_SCRIPT := preload("res://game/infrastructure/construction_zone_2d.gd")
const TEST_SEED := 424242

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)

	var fabricator := FIELD_FABRICATOR_SCENE.instantiate() as Node2D
	fabricator.name = "FieldFabricatorMk1"
	world.add_child(fabricator)
	var zone := Node2D.new()
	zone.name = "FabricationConstructionZone"
	zone.set_script(CONSTRUCTION_ZONE_SCRIPT)
	world.add_child(zone)

	var map := await _generate_map("PrimaryMap")
	var level_data := map.get_level_data()
	var loader := WORLD_LOADER_SCRIPT.new()
	loader.hide_static_sectors = false
	loader.reposition_operator_from_contract = false
	loader.reposition_spawn_nodes_from_contract = false
	loader.reposition_terminal_from_contract = false
	loader.reposition_vehicles_from_contract = false
	loader.reposition_items_from_contract = false
	loader.reposition_camera_from_contract = false
	loader.place_arrn_relays_from_contract = false
	loader.place_tutorial_resource_nodes_from_contract = false
	loader.place_expedition_resource_nodes_from_contract = false
	loader.place_gothic_compound_connection = false
	loader.place_registered_level_connections = false
	loader.place_sundered_keep_connection = false
	loader.place_ambient_enemy_camps_from_contract = false
	game_root.add_child(loader)
	loader.call("_on_contract_generated", {
		"map": {"instance": map, "level_data": level_data},
		"world_profile": {},
	})
	await process_frame

	_validate_population_anchor(map, level_data, &"compound_fabricator_anchor", fabricator)
	_validate_population_anchor(map, level_data, &"compound_construction_zone_anchor", zone)
	var placed_position := fabricator.global_position
	loader.call(
		"_place_population_node",
		fabricator,
		{},
		&"compound_fabricator_anchor",
		&"field_fabricator",
		map
	)
	_expect(
		fabricator.global_position.is_equal_approx(placed_position),
		"missing population anchors must preserve the existing node transform"
	)

	var second_map := await _generate_map("DeterminismMap")
	var second_data := second_map.get_level_data()
	_expect(
		level_data.get("compound_fabricator_anchor") == second_data.get("compound_fabricator_anchor"),
		"same seed must reproduce the fabricator anchor"
	)
	_expect(
		level_data.get("compound_construction_zone_anchor") == second_data.get("compound_construction_zone_anchor"),
		"same seed must reproduce the construction-zone anchor"
	)

	game_root.queue_free()
	second_map.queue_free()
	_finish()


func _generate_map(node_name: String) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = node_name
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = TEST_SEED
	generator.map_size = Vector2i(112, 96)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = false
	map.generate()
	await process_frame
	return map


func _validate_population_anchor(
	map: ProcGenTilemap,
	level_data: Dictionary,
	anchor_key: StringName,
	node: Node2D
) -> void:
	_expect(level_data.has(anchor_key), "%s must exist" % anchor_key)
	var anchor: Variant = level_data.get(anchor_key)
	_expect(anchor is Vector2i, "%s must use Vector2i tile semantics" % anchor_key)
	if not (anchor is Vector2i):
		return
	var tile := anchor as Vector2i
	var floors := map.debug_get_generated_floor_cells()
	var walls := map.debug_get_generated_wall_cells()
	_expect(floors.has(tile), "%s must belong to authoritative generated floor" % anchor_key)
	_expect(not walls.has(tile), "%s must not belong to generated walls" % anchor_key)
	_expect(not (level_data.get("ocean_cells", []) as Array).has(tile), "%s must not be ocean" % anchor_key)
	_expect(not (level_data.get("chasm_cells", []) as Array).has(tile), "%s must not be chasm" % anchor_key)
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	_expect(Rect2i(Vector2i.ZERO, map_size).has_point(tile), "%s must be inside the generated map" % anchor_key)
	_expect(
		node.global_position.is_equal_approx(map.tile_to_global_position(tile)),
		"%s node position must equal the canonical semantic-anchor transform" % anchor_key
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		push_error("contract_world_population_placement_smoke failed")
		quit(1)
		return
	print("contract_world_population_placement_smoke passed")
	quit()
