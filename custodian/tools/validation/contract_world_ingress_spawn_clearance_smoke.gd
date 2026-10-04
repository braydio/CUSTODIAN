extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload(
	"res://game/systems/core/systems/contract_world_loader.gd"
)
const ASH_BELL_PRESENTATION_SCENE := preload(
	"res://game/world/approaches/ash_bell/ash_bell_lift_ingress_presentation.tscn"
)
const TEST_SEED := 424242

var _errors: Array[String] = []


class ContractMapFixture:
	extends Node2D

	signal contract_generated(contract: Dictionary)
	signal contract_generation_failed(result: Dictionary)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var contract_map := ContractMapFixture.new()
	contract_map.name = "ContractMap"
	world.add_child(contract_map)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	game_root.add_child(operator)
	var loader := WORLD_LOADER_SCRIPT.new()
	loader.set("world_path", NodePath("../World"))
	loader.set("operator_path", NodePath("../Operator"))
	game_root.add_child(loader)

	var map := await _generate_map()
	var level_data := (map.get_level_data() as Dictionary).duplicate(true)
	var preferred_before_clearance: Vector2i = loader.call(
		"_pick_compound_spawn_tile", level_data, map
	)
	_expect(
		preferred_before_clearance != Vector2i.ZERO,
		"fixture must have a preferred walkable compound spawn"
	)
	if preferred_before_clearance == Vector2i.ZERO:
		_finish()
		return

	var target_world := map.tile_to_global_position(preferred_before_clearance)
	var presentation := ASH_BELL_PRESENTATION_SCENE.instantiate() as Node2D
	world.add_child(presentation)
	await process_frame
	var collision_body := presentation.get_node(
		"SpatialFacingRoot/Collision"
	) as StaticBody2D
	var clearance_claimed := false
	var safe_spawn := Vector2i.ZERO
	var offsets := [
		Vector2(150.0, 300.0),
		Vector2(150.0, 240.0),
		Vector2(150.0, 360.0),
		Vector2(-150.0, 300.0),
		Vector2(-150.0, 240.0),
		Vector2(-150.0, 360.0),
		Vector2(0.0, 300.0),
	]
	for offset: Vector2 in offsets:
		map.clear_world_ingress_dressing_clearances()
		presentation.global_position = target_world + offset
		presentation.call("configure_outward_direction", Vector2i.UP)
		await physics_frame
		var authored_clearance: Rect2 = presentation.call(
			"get_procgen_dressing_clearance_world_rect"
		)
		map.claim_world_ingress_dressing_clearance(authored_clearance)
		if not map.is_inside_world_ingress_dressing_clearance(
			preferred_before_clearance
		):
			continue
		if not _has_authored_collision_at(collision_body, target_world):
			continue
		safe_spawn = loader.call(
			"_pick_compound_spawn_tile", level_data, map
		) as Vector2i
		if safe_spawn != Vector2i.ZERO and safe_spawn != preferred_before_clearance:
			clearance_claimed = true
			break

	_expect(
		clearance_claimed,
		"fixture must overlap the old preferred spawn with the authored Ash Bell clearance and leave a safe compound candidate"
	)
	if not clearance_claimed:
		_finish()
		return
	_expect(
		map.is_inside_world_ingress_dressing_clearance(preferred_before_clearance),
		"the old preferred spawn must be covered by the real Ash Bell clearance claim"
	)
	_expect(
		map.is_inside_world_ingress_dressing_clearance(safe_spawn) == false,
		"the selected replacement compound spawn must be outside ingress clearance"
	)
	_expect(
		map.floor_tilemap.get_cell_source_id(safe_spawn) >= 0,
		"the replacement spawn must remain on authoritative walkable floor"
	)

	var source_file := FileAccess.open(
		"res://game/systems/core/systems/contract_world_loader.gd",
		FileAccess.READ
	)
	var source := source_file.get_as_text() if source_file != null else ""
	var install_start := source.find("func _on_contract_generated(")
	var ingress_call := source.find("if place_registered_level_connections:", install_start)
	var sectors_call := source.find("var sectors_positioned :=", install_start)
	var operator_call := source.find("if reposition_operator_from_contract:", install_start)
	_expect(
		install_start >= 0
			and ingress_call > install_start
			and sectors_call > ingress_call
			and operator_call > sectors_call,
		"registered ingress placement must remain before sector and Operator placement in contract installation"
	)

	var initial_operator_position := operator.global_position
	_expect(
		loader.call("_position_operator", level_data, map),
		"safe replacement spawn must position the Operator"
	)
	var first_position := operator.global_position
	_expect(
		first_position.is_equal_approx(map.tile_to_global_position(safe_spawn)),
		"Operator must land on the deterministic safe compound tile"
	)
	_expect(
		not _has_authored_collision_at(collision_body, first_position),
		"96px-class Operator capsule must not overlap Ash Bell authored collision"
	)
	operator.global_position = initial_operator_position
	_expect(
		loader.call("_position_operator", level_data, map),
		"repeated safe spawn resolution must succeed"
	)
	_expect(
		operator.global_position.is_equal_approx(first_position),
		"safe compound spawn selection must be deterministic"
	)

	var fallback_data := level_data.duplicate(true)
	fallback_data["compound_rect"] = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	fallback_data["player_spawn"] = preferred_before_clearance
	operator.global_position = Vector2(-9999.0, -9999.0)
	var fallback_result: bool = loader.call(
		"_position_operator", fallback_data, map
	)
	_expect(not fallback_result, "unsafe player_spawn fallback must fail closed")
	_expect(
		operator.global_position == Vector2(-9999.0, -9999.0),
		"failed unsafe fallback must not move the Operator into authored collision"
	)

	map.clear_world_ingress_dressing_clearances()
	game_root.queue_free()
	map.queue_free()
	await process_frame
	_finish()


func _generate_map() -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = "IngressSpawnClearanceMap"
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


func _has_authored_collision_at(
	collision_body: StaticBody2D,
	position: Vector2
) -> bool:
	var capsule := CapsuleShape2D.new()
	capsule.radius = 32.0
	capsule.height = 96.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = capsule
	query.transform = Transform2D(0.0, position)
	query.collision_mask = collision_body.collision_layer
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hits := root.get_world_2d().direct_space_state.intersect_shape(query, 32)
	for hit: Dictionary in hits:
		if hit.get("collider") == collision_body:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("[ContractWorldIngressSpawnClearanceSmoke] " + message)


func _finish() -> void:
	if not _errors.is_empty():
		push_error(
			"ContractWorldIngressSpawnClearanceSmoke failed (%d errors)"
			% _errors.size()
		)
		quit(1)
		return
	print("ContractWorldIngressSpawnClearanceSmoke passed")
	quit(0)
