extends SceneTree

## Drives the real ContractWorldLoader install path with production authored
## Operator coordinates. A real registered ingress blocks the compound and
## exported spawn candidates; placement must fall back within the accepted
## main component. A second install with no safe cell must hide and disable the
## stale Operator without snapping the camera or marking the contract ready.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload(
	"res://game/systems/core/systems/contract_world_loader.gd"
)
const PLAYER_CONTROLLER_SCRIPT := preload("res://game/systems/core/player_controller.gd")
const LEGACY_OPERATOR_POSITION := Vector2(717.45905, -485.33954)
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
	operator.position = LEGACY_OPERATOR_POSITION
	operator.visible = true
	operator.process_mode = Node.PROCESS_MODE_INHERIT
	game_root.add_child(operator)
	var player_controller := PLAYER_CONTROLLER_SCRIPT.new()
	player_controller.name = "PlayerController"
	player_controller.operator_path = NodePath("../Operator")
	game_root.add_child(player_controller)
	var loader := WORLD_LOADER_SCRIPT.new()
	loader.name = "ContractWorldLoader"
	loader.set("world_path", NodePath("../World"))
	loader.set("operator_path", NodePath("../Operator"))
	loader.set("camera_path", NodePath("../World/Camera2D"))
	loader.set("contract_map_path", NodePath("../World/ContractMap"))
	game_root.add_child(loader)
	var zero_candidates: Array[Vector2i] = [Vector2i.ZERO]
	var zero_selection: Dictionary = loader.call(
		"_closest_spawn_selection", zero_candidates, Vector2i.ZERO
	)
	_expect(
		zero_selection.get("tile") == Vector2i.ZERO,
		"candidate result representation must preserve tile (0,0)"
	)

	var map := await _generate_map()
	var level_data: Dictionary = (map.get_level_data() as Dictionary).duplicate(true)
	var initial_component := map.get_main_playable_component()
	_expect(not initial_component.is_empty(), "generated fixture needs a main playable component")
	if initial_component.is_empty():
		_finish(game_root, map)
		return

	# Preflight the real registered ingress so the one-cell compound and exported
	# player spawn can target its authored clearance while retaining valid floor.
	_expect(
		loader.call("_place_registered_world_ingresses", level_data, map),
		"real registered ingress preflight must succeed"
	)
	var blocked_tile: Variant = _pick_safe_ingress_clearance_tile(map, initial_component)
	_expect(blocked_tile != null, "real ingress clearance must overlap a safe accepted-component tile")
	if blocked_tile == null:
		_finish(game_root, map)
		return

	var forced_tile: Vector2i = blocked_tile as Vector2i
	level_data["compound_rect"] = Rect2i(forced_tile, Vector2i.ONE)
	level_data["compound_ingress"] = []
	level_data["player_spawn"] = forced_tile
	# Reinstall the registered ingress after changing the anchor. If its stable
	# deterministic placement shifts the clearance, converge on a tile in the new
	# claim before driving the actual ContractWorldLoader callback.
	var clearance_stable := false
	for _attempt in range(4):
		_expect(
			loader.call("_place_registered_world_ingresses", level_data, map),
			"registered ingress placement must survive forced fallback setup"
		)
		if map.is_inside_world_ingress_dressing_clearance(forced_tile):
			clearance_stable = true
			break
		var replacement: Variant = _pick_safe_ingress_clearance_tile(map, initial_component)
		if replacement == null:
			break
		forced_tile = replacement as Vector2i
		level_data["compound_rect"] = Rect2i(forced_tile, Vector2i.ONE)
		level_data["player_spawn"] = forced_tile
	_expect(clearance_stable, "the real registered ingress must block both final preferred candidates")
	if not clearance_stable:
		_finish(game_root, map)
		return
	_expect(
		loader.call("_is_walkable_floor_tile", map, forced_tile)
			and map.is_valid_spawn_cell(forced_tile)
			and map.is_runtime_navigation_walkable(forced_tile)
			and initial_component.has(forced_tile),
		"forced compound/player spawn must be painted, canonically valid, walkable, and in the main component"
	)
	_expect(
		not loader.call("_is_safe_operator_spawn_tile", map, forced_tile, initial_component),
		"real ingress clearance must make both preferred candidates fail the final safe predicate"
	)
	var safe_elsewhere := 0
	for key: Variant in initial_component.keys():
		if key is Vector2i and loader.call(
			"_is_safe_operator_spawn_tile", map, key as Vector2i, initial_component
		):
			safe_elsewhere += 1
	_expect(safe_elsewhere > 0, "fixture must retain a safe accepted-component fallback tile outside ingress clearance")

	var component_queries_before := map.main_playable_component_query_count
	loader.call("_on_contract_generated", {
		"map": {"instance": map, "level_data": level_data},
		"world_profile": {},
	})
	var trace: Array[Dictionary] = loader.call("get_install_trace")
	if loader.is_contract_activation_aborted():
		push_error("[ContractWorldOperatorVoidSpawnFailsafeSmoke] fallback install trace=%s" % [trace])
	var spawn_detail := _trace_detail(trace, &"operator_spawn_selected")
	var operator_detail := _trace_detail(trace, &"operator_placed")
	var selected_tile: Vector2i = spawn_detail.get("tile", Vector2i(-9999, -9999))
	var world_position: Vector2 = spawn_detail.get("world_position", Vector2.ZERO)
	var landed_tile := map.global_to_minimap_tile(operator.global_position)
	_expect(not loader.is_contract_activation_aborted(), "forced fallback install must reach ready")
	_expect(spawn_detail.get("source") == "main_component_fallback", "install trace must identify main_component_fallback")
	_expect(map.debug_get_spawn_presentation_ready_count() == 1, "production install must use the narrow spawn readiness seam")
	_expect(_trace_has_phase(trace, &"spawn_presentation_ready"), "install trace must prove selected spawn presentation became ready")
	_expect(selected_tile == landed_tile, "Operator round-trip tile must equal selected tile")
	_expect(world_position.is_equal_approx(operator.global_position), "trace world position must equal final Operator position")
	_expect(
		operator.global_position.is_equal_approx(map.tile_to_global_position(selected_tile)),
		"fallback Operator world position must be the canonical tile center"
	)
	_expect(
		map.floor_tilemap.get_cell_source_id(landed_tile) >= 0
			and map.is_valid_spawn_cell(landed_tile)
			and map.is_runtime_navigation_walkable(landed_tile)
			and not map.is_inside_world_ingress_dressing_clearance(landed_tile)
			and initial_component.has(landed_tile),
		"landed fallback tile must satisfy the full canonical safe spawn contract"
	)
	_expect(camera.snap_count == 1 and camera.last_snap.is_equal_approx(operator.global_position), "camera must snap once to the final fallback position")
	_expect(operator.visible and operator.process_mode != Node.PROCESS_MODE_DISABLED, "successful placement must leave Operator visible and controllable")
	_expect(
		int(operator_detail.get("component_queries", -1)) == component_queries_before + 1,
		"one accepted component snapshot must serve final Operator selection"
	)
	_expect(_trace_has_phase(trace, &"contract_ready"), "successful fallback must mark the contract ready")
	_expect(
		_trace_index(trace, &"spawn_presentation_ready") < _trace_index(trace, &"archive_resolve_ingress")
			and _trace_index(trace, &"spawn_presentation_ready") < _trace_index(trace, &"camera_refresh"),
		"camera and Archive Resolve ingress must follow successful spawn realization"
	)
	var actual_ingress := world.get_node_or_null("WorldIngressSpawner")
	var placements: Dictionary = actual_ingress.call("get_last_placements") if actual_ingress != null else {}
	_expect(placements.has("forlorn_ritualant_underground"), "real registered Ritualant ingress must be installed")
	var success_query_count := map.main_playable_component_query_count
	var accepted_component := map.get_main_playable_component()
	_expect(accepted_component.has(landed_tile), "final tile must remain in the accepted component")
	_expect(map.main_playable_component_query_count == success_query_count + 1, "test verification is the only post-install component query")

	# Catastrophic path: a covering ingress-clearance claim leaves the canonical
	# component intact but offers no safe candidate anywhere. No camera success
	# or ready phase may happen, and the authored Operator cannot remain playable.
	loader.place_registered_level_connections = false
	loader.place_sundered_keep_connection = false
	loader.place_gothic_compound_connection = false
	map.claim_world_ingress_dressing_clearance(Rect2(-100000.0, -100000.0, 200000.0, 200000.0))
	var failed_component := map.get_main_playable_component()
	var safe_failed_component_tiles := 0
	for key: Variant in failed_component.keys():
		if key is Vector2i and loader.call(
			"_is_safe_operator_spawn_tile", map, key as Vector2i, failed_component
		):
			safe_failed_component_tiles += 1
	_expect(not failed_component.is_empty(), "catastrophic fixture must retain the canonical component")
	_expect(safe_failed_component_tiles == 0, "catastrophic fixture must leave no safe accepted-component tile")
	var failed_data := level_data.duplicate(true)
	failed_data["compound_rect"] = Rect2i(landed_tile, Vector2i.ONE)
	failed_data["player_spawn"] = landed_tile
	var ready_camera_snaps := camera.snap_count
	operator.global_position = LEGACY_OPERATOR_POSITION
	loader.call("_on_contract_generated", {
		"map": {"instance": map, "level_data": failed_data},
		"world_profile": {},
	})
	var failure_trace: Array[Dictionary] = loader.call("get_install_trace")
	_expect(loader.is_contract_activation_aborted(), "no-safe-cell install must fail activation")
	_expect(not operator.visible, "catastrophic failure must hide authored Operator")
	_expect(operator.process_mode == Node.PROCESS_MODE_DISABLED, "catastrophic failure must disable Operator processing")
	_expect(operator.global_position == LEGACY_OPERATOR_POSITION, "failed placement must not move the stale authored Operator")
	_expect(camera.snap_count == ready_camera_snaps, "catastrophic failure must not run a successful camera snap")
	_expect(not _trace_has_phase(failure_trace, &"contract_ready"), "catastrophic failure must not mark contract ready")
	_expect(not _trace_has_phase(failure_trace, &"operator_placed"), "catastrophic failure must not trace successful placement")
	_expect(_trace_detail(failure_trace, &"operator_spawn_unavailable").get("reason") == "no_canonical_safe_spawn", "catastrophic failure must diagnose no_canonical_safe_spawn")
	_expect(player_controller.current_vehicle == null, "catastrophic contract failure must not report vehicle possession")
	_expect(
		loader.get_last_failure_result().get("failure_reason") == "no_canonical_safe_spawn",
		"catastrophic failure must retain the canonical spawn diagnostic"
	)

	# Visibility and processing return only after a later safe placement.
	map.clear_world_ingress_dressing_clearances()
	var recovered_data := level_data.duplicate(true)
	recovered_data["compound_rect"] = Rect2i(landed_tile, Vector2i.ONE)
	recovered_data["player_spawn"] = landed_tile
	loader.call("_on_contract_generated", {
		"map": {"instance": map, "level_data": recovered_data},
		"world_profile": {},
	})
	_expect(not loader.is_contract_activation_aborted(), "later valid placement must recover activation")
	_expect(operator.visible and operator.process_mode == Node.PROCESS_MODE_INHERIT, "later valid placement must restore prior Operator state")

	_finish(game_root, map)


func _pick_safe_ingress_clearance_tile(
	map: ProcGenTilemap,
	component: Dictionary
) -> Variant:
	var keys: Array = component.keys()
	keys.sort()
	for key: Variant in keys:
		if not (key is Vector2i):
			continue
		var tile := key as Vector2i
		if (
			map.floor_tilemap.get_cell_source_id(tile) >= 0
			and map.is_valid_spawn_cell(tile)
			and map.is_runtime_navigation_walkable(tile)
			and map.is_inside_world_ingress_dressing_clearance(tile)
		):
			return tile
	return null


func _trace_detail(trace: Array[Dictionary], phase: StringName) -> Dictionary:
	for entry: Dictionary in trace:
		if entry.get("phase") == phase:
			return entry.get("detail", {}) as Dictionary
	return {}


func _trace_has_phase(trace: Array[Dictionary], phase: StringName) -> bool:
	for entry: Dictionary in trace:
		if entry.get("phase") == phase:
			return true
	return false


func _trace_index(trace: Array[Dictionary], phase: StringName) -> int:
	for index in range(trace.size()):
		if trace[index].get("phase") == phase:
			return index
	return -1


func _generate_map() -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = "VoidSpawnFailsafeMap"
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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("[ContractWorldOperatorVoidSpawnFailsafeSmoke] " + message)


func _finish(game_root: Node, map: ProcGenTilemap) -> void:
	map.clear_world_ingress_dressing_clearances()
	game_root.queue_free()
	map.queue_free()
	await process_frame
	if not _errors.is_empty():
		push_error("ContractWorldOperatorVoidSpawnFailsafeSmoke failed (%d errors)" % _errors.size())
		quit(1)
		return
	print("[ContractWorldOperatorVoidSpawnFailsafeSmoke] PASS")
	quit(0)
