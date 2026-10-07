extends SceneTree

## Covers PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO acceptance 3/4/5/12 and closes
## spawn-review R0-03: drives the REAL `ContractWorldLoader._on_contract_generated()`
## with a real generated ProcGenTilemap, a real registered world ingress, and the
## real Gothic compound connection/gate, then proves ordering, that the one-time
## Archive Resolve ingress trigger receives the exact final Operator tile, that
## tile is canonically valid and in the accepted main playable component, that
## AR3 adds zero component queries and never moves the Operator, and that the
## pocket is settled while the ring is veiled and resolves outward.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
const SECTOR_SCENE := preload("res://game/actors/sector/sector.tscn")
const TEST_SEED := 424242

var _errors: Array[String] = []


class ContractMapFixture:
	extends Node2D

	signal contract_generated(contract: Dictionary)
	signal contract_generation_failed(result: Dictionary)


## Records what the Archive Resolve owner looked like at the instant the loader
## snaps the camera, plus the Operator position it was given.
class CameraProbe:
	extends Node2D

	var map_ref: ProcGenTilemap
	var snap_count := 0
	var ingress_begin_at_snap := -1
	var operator_at_snap := Vector2.ZERO

	func set_runtime_map(map_instance: Node) -> void:
		map_ref = map_instance as ProcGenTilemap

	func snap_to_player_spawn(position: Vector2) -> void:
		snap_count += 1
		operator_at_snap = position
		if map_ref != null and map_ref.debug_get_reveal_presentation() != null:
			ingress_begin_at_snap = map_ref.debug_get_reveal_presentation().ingress_begin_count


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
	var sectors := Node2D.new()
	sectors.name = "Sectors"
	world.add_child(sectors)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	operator.add_to_group("player")
	game_root.add_child(operator)
	var loader := WORLD_LOADER_SCRIPT.new()
	loader.name = "ContractWorldLoader"
	loader.set("world_path", NodePath("../World"))
	loader.set("operator_path", NodePath("../Operator"))
	loader.set("camera_path", NodePath("../World/Camera2D"))
	loader.set("contract_map_path", NodePath("../World/ContractMap"))
	game_root.add_child(loader)
	_expect(loader.place_registered_level_connections and loader.place_gothic_compound_connection and loader.reposition_operator_from_contract, "fixture must exercise the real registered-ingress + Gothic + Operator path")

	var map := await _generate_map()
	var level_data := map.get_level_data() as Dictionary
	_expect(not level_data.is_empty(), "fixture needs real generated level data")
	_expect((level_data.get("compound_rect", Rect2i()) as Rect2i).has_area(), "fixture needs a real compound")
	var queries_before := map.main_playable_component_query_count
	operator.global_position = Vector2(-9999.0, -9999.0)

	loader.call("_on_contract_generated", {
		"map": {"instance": map, "level_data": level_data},
		"world_profile": {},
	})
	# Presentation state is read synchronously, before any further process frame
	# can advance it: this is what the trigger itself produced.
	var presentation := map.debug_get_reveal_presentation()
	var snap := presentation.get_snapshot()
	var pocket_state := _pocket_veil_violations(presentation, map)
	await process_frame

	var failed: bool = loader.get("_contract_generation_failed")
	_expect(not failed, "contract installation failed: %s" % [loader.get("_last_failure_result")])
	var trace: Array[Dictionary] = loader.call("get_install_trace")
	var phases: Array[StringName] = []
	for entry: Dictionary in trace:
		phases.append(entry["phase"])
	var expected: Array[StringName] = [
		&"registered_ingress_placed",
		&"spawn_presentation_ready",
		&"operator_spawn_selected",
		&"operator_placed",
		&"compound_connection_placed",
		&"archive_resolve_ingress",
		&"camera_refresh",
		&"contract_ready",
	]
	_expect(phases == expected, "install phase order %s != %s" % [phases, expected])
	if failed or phases != expected:
		_finish(game_root, map)
		return

	# Real registered ingress + real Gothic connection/gate were actually placed.
	var spawner := world.get_node_or_null("WorldIngressSpawner")
	_expect(spawner != null, "registered world ingress spawner was not created")
	var placements: Dictionary = spawner.call("get_last_placements") if spawner != null else {}
	_expect(placements.has("forlorn_ritualant_underground"), "required registered ingress was not placed")
	var gate := world.get_node_or_null("GothicCompoundTravelGate")
	_expect(gate != null and gate.is_in_group("generated_gothic_compound_connection"), "real Gothic compound gate was not placed before the AR3 trigger")
	_expect(world.get_node_or_null("ConnectedMaps/GothicCompoundMap") != null, "real Gothic compound map was not attached")

	# The trigger received the exact final Operator tile.
	var ingress: Dictionary = loader.call("get_last_archive_resolve_ingress")
	var final_tile: Vector2i = map.floor_tilemap.local_to_map(map.floor_tilemap.to_local(operator.global_position))
	_expect(bool(ingress.get("triggered", false)), "ingress presentation did not trigger")
	_expect(ingress.get("center_tile", Vector2i.ZERO) == final_tile, "ingress centre %s is not the final Operator tile %s" % [ingress.get("center_tile"), final_tile])
	_expect((ingress.get("operator_global_position", Vector2.ZERO) as Vector2).is_equal_approx(operator.global_position), "Operator moved after the ingress trigger")
	_expect(camera.snap_count == 1 and camera.operator_at_snap.is_equal_approx(operator.global_position), "camera was not snapped once to the final Operator position")
	_expect(camera.ingress_begin_at_snap == 1, "ingress must begin before the camera refresh (saw %d)" % camera.ingress_begin_at_snap)

	# R0-03: final Operator tile is canonically valid and in the main component;
	# no underlevel / exterior / disconnected tile became the arrival centre.
	var component := map.get_main_playable_component()
	_expect(not component.is_empty(), "main playable component must exist")
	_expect(map.floor_tilemap.get_cell_source_id(final_tile) >= 0, "arrival centre must be authoritative painted floor")
	_expect(map.is_valid_spawn_cell(final_tile), "arrival centre must pass canonical spawn validity")
	_expect(map.is_runtime_navigation_walkable(final_tile), "arrival centre must be runtime-navigation walkable")
	_expect(component.has(final_tile), "arrival centre must belong to the accepted main playable component")
	_expect(not map.is_inside_world_ingress_dressing_clearance(final_tile), "arrival centre must be outside ingress clearance")
	_expect((map.get("_generated_floor_cells") as Dictionary).has(final_tile), "arrival centre must be canonical generated floor (not exterior/underlevel)")

	# R0-01 observability: AR3 adds zero main-component queries.
	var at_operator: int = int((trace[3]["detail"] as Dictionary).get("component_queries", -1))
	var at_compound: int = int((trace[4]["detail"] as Dictionary).get("component_queries", -1))
	var at_ingress: int = int(ingress.get("component_queries", -2))
	_expect(at_operator - queries_before >= 1, "the existing reviewed spawn selection must still query the component")
	_expect(at_ingress == at_compound, "AR3 added main-component queries (%d -> %d)" % [at_compound, at_ingress])
	_expect(map.main_playable_component_query_count - at_ingress == 1, "only this smoke's own validation may query after the trigger")

	# Presentation state: pocket settled, ring veiled and resolving outward, control not gated.
	_expect(int(snap["ingress_begin_count"]) == 1, "ingress must begin exactly once")
	_expect(int(snap["ingress_pending_count"]) > 0, "ingress ring was not re-veiled")
	_expect(int(ingress.get("owned_cells", 0)) == int(snap["ingress_pending_count"]), "ingress telemetry disagrees with the owner")
	_expect(pocket_state.is_empty(), "committed safety-pocket cells were veiled at the trigger: %s" % [pocket_state])
	_expect(_pocket_veil_violations(presentation, map).is_empty(), "committed safety-pocket cells were veiled after a process frame")
	_expect(operator.process_mode != Node.PROCESS_MODE_DISABLED, "ingress presentation gated Operator processing")

	# Outward resolution settles inside ~1.0-1.5 s of presentation time and leaves no veil.
	var start_time := float(presentation.get_snapshot()["presentation_time"])
	var guard := 0
	while guard < 400:
		presentation.advance(0.016, final_tile, map.streaming_chunk_size_tiles)
		guard += 1
		var s := presentation.get_snapshot()
		if int(s["resolving_count"]) == 0 and _eligible_unresolved(presentation, map, final_tile).is_empty():
			break
	var settled := presentation.get_snapshot()
	# Real frames between the trigger and this manual stepping already advanced the
	# clock by an unknowable headless delta; the wave budget is judged on the whole
	# span from the trigger (deterministic wave timing is covered by the owner smoke).
	var elapsed := float(settled["presentation_time"]) - float(snap["presentation_time"])
	var drift := start_time - float(snap["presentation_time"])
	_expect(elapsed - drift <= 1.6 and elapsed <= 1.6 + maxf(0.0, drift), "ingress took %.2f s to resolve" % elapsed)
	# AR4: the wave only resolves cells the visual frontier admits (distance cap,
	# Operator line of sight, camera). Cells it does not admit stay veiled until the
	# Operator approaches; no admitted cell may be left behind.
	var stuck := _eligible_unresolved(presentation, map, final_tile)
	_expect(stuck.is_empty() and int(settled["resolving_count"]) == 0, "ingress left frontier-eligible cells unresolved: %s" % [stuck.slice(0, 5)])

	_finish(game_root, map)


## Ingress/ready cells the AR4 frontier currently admits (should drain to none).
func _eligible_unresolved(presentation: ProcGenRevealPresentation, map: ProcGenTilemap, operator_tile: Vector2i) -> Array[Vector2i]:
	var frontier := presentation.get_frontier()
	var out: Array[Vector2i] = []
	var r := presentation.visual_resolve_radius_tiles + presentation.visual_resolve_fringe_tiles + 1
	for x in range(operator_tile.x - r, operator_tile.x + r + 1):
		for y in range(operator_tile.y - r, operator_tile.y + r + 1):
			var tile := Vector2i(x, y)
			var state := presentation.get_tile_state(tile)
			if state != ProcGenRevealPresentation.TileState.INGRESS and state != ProcGenRevealPresentation.TileState.READY:
				continue
			if Vector2(tile - operator_tile).length() <= frontier.distance_limit(tile) and frontier.is_visible_from_center(tile):
				out.append(tile)
	return out


## Committed (non-REQUESTED) cells inside the pocket that still carry a veil.
func _pocket_veil_violations(presentation: ProcGenRevealPresentation, map: ProcGenTilemap) -> Array[Vector2i]:
	var center := presentation._ingress_center
	var pocket := maxi(presentation.ingress_pocket_tiles, presentation.safety_halo_tiles)
	var bad: Array[Vector2i] = []
	for x in range(center.x - pocket, center.x + pocket + 1):
		for y in range(center.y - pocket, center.y + pocket + 1):
			var tile := Vector2i(x, y)
			if presentation.has_veil(tile) and presentation.get_tile_state(tile) != ProcGenRevealPresentation.TileState.REQUESTED:
				bad.append(tile)
	return bad


func _generate_map() -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	map.name = "ArchiveResolveIngressMap"
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
	map.archive_resolve_enabled = true
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
	push_error("[ContractWorldArchiveResolveIngressSmoke] " + message)


func _finish(game_root: Node, map: Node) -> void:
	game_root.queue_free()
	map.queue_free()
	await process_frame
	if not _errors.is_empty():
		push_error("ContractWorldArchiveResolveIngressSmoke failed (%d errors)" % _errors.size())
		quit(1)
		return
	print("[ContractWorldArchiveResolveIngressSmoke] PASS")
	quit(0)
