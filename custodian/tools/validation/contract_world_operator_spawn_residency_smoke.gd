extends SceneTree

## Production-shaped regression: a canonical accepted-component spawn whose
## chunk has not been presented must become resident before Operator activation.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
const TEST_SEED := 424242

var _errors: Array[String] = []


class ContractMapFixture:
	extends Node2D

	signal contract_generated(contract: Dictionary)
	signal contract_generation_failed(result: Dictionary)


class CameraProbe:
	extends Node2D

	var snap_count := 0
	var last_snap := Vector2.ZERO

	func set_runtime_map(_map_instance: Node) -> void:
		pass

	func snap_to_player_spawn(position: Vector2) -> void:
		snap_count += 1
		last_snap = position


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
	var camera := CameraProbe.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	operator.position = Vector2(717.45905, -485.33954)
	game_root.add_child(operator)
	var loader := WORLD_LOADER_SCRIPT.new()
	loader.name = "ContractWorldLoader"
	loader.set("world_path", NodePath("../World"))
	loader.set("operator_path", NodePath("../Operator"))
	loader.set("camera_path", NodePath("../World/Camera2D"))
	loader.set("contract_map_path", NodePath("../World/ContractMap"))
	loader.place_registered_level_connections = false
	loader.place_sundered_keep_connection = false
	game_root.add_child(loader)

	var map := await _generate_map()
	var component := map.get_main_playable_component()
	_expect(not component.is_empty(), "generated streaming map must have a non-empty accepted main component")
	var spawn: Variant = _pick_unpainted_canonical_spawn(map, component)
	_expect(spawn != null, "fixture must find an unpainted canonical cell in an unseen or unloaded chunk")
	if spawn == null:
		_finish(game_root, map)
		return
	var spawn_tile := spawn as Vector2i
	var chunk: Vector2i = map.call("_tile_to_chunk", spawn_tile)
	var initial_state := map.debug_get_chunk_lifecycle_state(chunk)
	_expect(map.floor_tilemap.get_cell_source_id(spawn_tile) < 0, "selected spawn must initially be unpainted")
	_expect(
		initial_state == ProcGenChunkLifecycle.State.UNSEEN
			or initial_state == ProcGenChunkLifecycle.State.UNLOADED,
		"selected spawn chunk must retain a valid unrealized lifecycle state"
	)
	_expect(
		map.is_valid_spawn_cell(spawn_tile)
			and map.is_runtime_navigation_walkable(spawn_tile)
			and component.has(spawn_tile),
		"initially unpainted selected spawn must already be canonically safe and accepted"
	)

	var level_data: Dictionary = (map.get_level_data() as Dictionary).duplicate(true)
	var generated_floor_count := (map.get("_generated_floor_cells") as Dictionary).size()
	var generated_wall_count := (map.get("_generated_wall_cells") as Dictionary).size()
	level_data["compound_rect"] = Rect2i()
	level_data["compound_ingress"] = []
	level_data["player_spawn"] = spawn_tile
	loader.call("_on_contract_generated", {
		"map": {"instance": map, "level_data": level_data},
		"world_profile": {},
	})
	var trace: Array[Dictionary] = loader.call("get_install_trace")
	var spawn_detail := _trace_detail(trace, &"operator_spawn_selected")
	_expect(not loader.is_contract_activation_aborted(), "real contract install must become ready from an unpainted spawn")
	_expect(map.debug_get_spawn_presentation_ready_count() == 1, "real install must call the narrow readiness seam")
	_expect(_trace_has_phase(trace, &"spawn_presentation_ready"), "trace must record successful spawn realization")
	_expect(spawn_detail.get("tile") == spawn_tile, "contract must keep the selected canonical tile")
	_expect(
		map.floor_tilemap.get_cell_source_id(spawn_tile) >= 0
			and map.walls_tilemap.get_cell_source_id(spawn_tile) < 0,
		"selected tile must be painted floor and not a painted wall after readiness"
	)
	_expect(
		map.is_valid_spawn_cell(spawn_tile)
			and map.is_runtime_navigation_walkable(spawn_tile)
			and map.get_main_playable_component().has(spawn_tile),
		"realized tile must remain canonically safe and in the accepted component"
	)
	_expect(
		(map.get("_generated_floor_cells") as Dictionary).size() == generated_floor_count
			and (map.get("_generated_wall_cells") as Dictionary).size() == generated_wall_count,
		"spawn presentation readiness must not change canonical generated topology"
	)
	_expect(operator.visible and operator.process_mode != Node.PROCESS_MODE_DISABLED, "Operator must be visible and controllable")
	_expect(camera.snap_count == 1 and camera.last_snap.is_equal_approx(operator.global_position), "camera must snap only after successful placement")
	_expect(_trace_index(trace, &"spawn_presentation_ready") < _trace_index(trace, &"archive_resolve_ingress"), "Archive Resolve ingress must follow realization")
	_expect(_trace_index(trace, &"spawn_presentation_ready") < _trace_index(trace, &"camera_refresh"), "camera refresh must follow realization")
	_expect(_trace_has_phase(trace, &"contract_ready"), "real install must reach contract_ready")

	var resident_state := map.debug_get_chunk_lifecycle_state(chunk)
	var floors_before := map.floor_tilemap.get_used_cells().size()
	_expect(map.ensure_spawn_presentation_ready(spawn_tile), "already-resident spawn readiness must be idempotently successful")
	_expect(map.debug_get_chunk_lifecycle_state(chunk) == resident_state, "idempotent readiness must preserve lifecycle state")
	_expect(map.floor_tilemap.get_used_cells().size() == floors_before, "readiness must not change canonical generated topology")
	_finish(game_root, map)


func _generate_map() -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = "SpawnResidencyMap"
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = TEST_SEED
	generator.map_size = Vector2i(112, 96)
	map.enable_streaming_reveal = true
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = false
	map.generate()
	await process_frame
	return map


func _pick_unpainted_canonical_spawn(map: ProcGenTilemap, component: Dictionary) -> Variant:
	var keys: Array = component.keys()
	keys.sort()
	for value: Variant in keys:
		if not (value is Vector2i):
			continue
		var tile := value as Vector2i
		var chunk: Vector2i = map.call("_tile_to_chunk", tile)
		var state := map.debug_get_chunk_lifecycle_state(chunk)
		if (
			map.floor_tilemap.get_cell_source_id(tile) < 0
			and map.is_valid_spawn_cell(tile)
			and map.is_runtime_navigation_walkable(tile)
			and (state == ProcGenChunkLifecycle.State.UNSEEN or state == ProcGenChunkLifecycle.State.UNLOADED)
		):
			return tile
	return null


func _trace_detail(trace: Array[Dictionary], phase: StringName) -> Dictionary:
	for entry: Dictionary in trace:
		if entry.get("phase") == phase:
			return entry.get("detail", {}) as Dictionary
	return {}


func _trace_has_phase(trace: Array[Dictionary], phase: StringName) -> bool:
	return _trace_index(trace, phase) >= 0


func _trace_index(trace: Array[Dictionary], phase: StringName) -> int:
	for index in range(trace.size()):
		if trace[index].get("phase") == phase:
			return index
	return -1


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("[ContractWorldOperatorSpawnResidencySmoke] " + message)


func _finish(game_root: Node, map: ProcGenTilemap) -> void:
	game_root.queue_free()
	map.queue_free()
	await process_frame
	if not _errors.is_empty():
		push_error("ContractWorldOperatorSpawnResidencySmoke failed (%d errors)" % _errors.size())
		quit(1)
		return
	print("ContractWorldOperatorSpawnResidencySmoke passed")
	quit(0)
