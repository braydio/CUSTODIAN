extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SITE_SCRIPT := preload(
	"res://game/world/approaches/ash_bell/ash_bell_lift_ingress_site.gd"
)
const EVENT_ID := &"ash_bell_threadway_unlocked"
const RESOURCE_ID := "white_thread_knot"


class MockThreadwayMap:
	extends Node2D

	var resolve_count := 0
	var result := {
		"ok": true,
		"cells": [Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7)],
		"new_cells": [Vector2i(5, 6), Vector2i(5, 7)],
		"centerline_cells": [Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7)],
		"tile_variants": {
			Vector2i(5, 5): 0,
			Vector2i(5, 6): 1,
			Vector2i(5, 7): 2,
		},
		"already_connected": false,
		"reason": "",
	}

	func evaluate_runtime_walkable_connector(
		_start_global_position: Vector2,
		_preferred_direction: Vector2i,
		_width_tiles: int,
		_max_length_tiles: int,
		_region_type: String,
		_region_zone: String,
		_lateral_allowance_tiles: int = -1
	) -> Dictionary:
		return result.duplicate(true)

	func commit_runtime_walkable_connector_plan(
		plan: Dictionary,
		_region_type: String,
		_region_zone: String
	) -> Dictionary:
		resolve_count += 1
		return plan.duplicate(true)

	func get_runtime_tile_size() -> Vector2:
		return Vector2(32.0, 32.0)

	func tile_to_global_position(cell: Vector2i) -> Vector2:
		return Vector2(cell) * 32.0 + Vector2(16.0, 16.0)


class MockFallbackThreadwayMap:
	extends MockThreadwayMap

	var evaluated_lengths: Array[int] = []
	var committed_length := 0
	var committed_lateral := -1

	func evaluate_runtime_walkable_connector(
		_start_global_position: Vector2, _preferred_direction: Vector2i,
		_width_tiles: int, max_length_tiles: int, _region_type: String,
		_region_zone: String, _lateral_allowance_tiles: int = -1
	) -> Dictionary:
		evaluated_lengths.append(max_length_tiles)
		if max_length_tiles <= 18:
			return {"ok": false, "reason": "no mainland endpoint within connector budget"}
		return result.duplicate(true)

	func commit_runtime_walkable_connector_plan(
		plan: Dictionary, _region_type: String, _region_zone: String
	) -> Dictionary:
		resolve_count += 1
		committed_length = int(plan.get("selected_max_length_tiles", 0))
		committed_lateral = int(plan.get("selected_lateral_allowance_tiles", -1))
		return plan.duplicate(true)


var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_authoritative_connector()
	await _validate_resource_lifecycle()
	await _validate_bounded_fallback()
	if _errors.is_empty():
		print("[AshBellThreadwayCausewaySmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[AshBellThreadwayCausewaySmoke] %s" % error)
	quit(1)


func _validate_authoritative_connector() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	_check(map != null, "procgen map did not instantiate")
	if map == null:
		return
	root.add_child(map)
	await process_frame
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	_check(procgen != null, "procgen authority is missing")
	if procgen == null:
		map.queue_free()
		return
	map.procgen_node = procgen
	procgen.map_size = Vector2i(40, 30)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = true
	map.claim_procgen_floor_rect_for_authored_scene_tiles(
		Vector2i(20, 20),
		Vector2i(22, 8),
		"test_mainland",
		"test",
		0
	)
	var island := map.claim_world_overlook_pocket(
		Vector2i(20, 6),
		Vector2i(9, 10),
		{
			"initially_isolated": true,
			"gap_depth_tiles": 2,
		}
	)
	_check(island.has_area(), "isolated Ash-Bell pocket was not authored")
	var before := map.debug_get_generated_floor_cells()
	_check(
		not _component_from(Vector2i(20, 18), before).has(Vector2i(20, 5)),
		"pre-Knot ingress island is connected to mainland"
	)
	_check(
		not get_nodes_in_group("runtime_walkable_boundary").is_empty(),
		"pre-Knot island has no physical walkable frontier"
	)
	var start_tile := Vector2i(20, 10)
	var start_global := map.tile_to_global_position(start_tile)
	var minimap_updates: Array[Vector2i] = []
	map.minimap_tile_changed.connect(
		func(cell: Vector2i, terrain_kind: String) -> void:
			if terrain_kind == "floor":
				minimap_updates.append(cell)
	)
	var first: Dictionary = map.resolve_runtime_walkable_connector(
		start_global,
		Vector2i.DOWN,
		3,
		18,
		"ash_bell_threadway",
		"white_thread"
	)
	_check(bool(first.get("ok", false)), "authoritative connector failed: %s" % first.get("reason", ""))
	var cells: Array = first.get("cells", [])
	_check(not cells.is_empty(), "connector returned no cells")
	_check(minimap_updates.size() == cells.size(), "connector did not emit one canonical floor minimap update per cell")
	var floor := map.debug_get_generated_floor_cells()
	var walls := map.debug_get_generated_wall_cells()
	for cell_variant in cells:
		var cell := cell_variant as Vector2i
		_check(floor.has(cell), "connector cell is not authoritative floor: %s" % cell)
		_check(not walls.has(cell), "connector retained a generated wall: %s" % cell)
		_check(not map.is_ocean_tile(cell), "connector retained ocean semantics: %s" % cell)
		_check(not map.is_chasm_tile(cell), "connector retained chasm semantics: %s" % cell)
	_check(
		_component_from(Vector2i(20, 18), floor).has(Vector2i(20, 5)),
		"resolved connector did not join mainland to ingress island"
	)
	var repeat: Dictionary = map.resolve_runtime_walkable_connector(
		start_global,
		Vector2i.DOWN,
		3,
		18,
		"ash_bell_threadway",
		"white_thread"
	)
	_check(bool(repeat.get("already_connected", false)), "repeat connector did not become a no-op")
	_check((repeat.get("new_cells", []) as Array).is_empty(), "repeat connector added floor")
	var variants: Dictionary = first.get("tile_variants", {})
	for value in variants.values():
		_check(int(value) >= 0 and int(value) < 6, "tile variant left the six-tile contract")
	map.queue_free()
	await process_frame


func _validate_resource_lifecycle() -> void:
	var ledger := root.get_node_or_null("ResourceLedger")
	var memory := root.get_node_or_null("WorldEventMemory")
	_check(ledger != null, "ResourceLedger autoload missing")
	_check(memory != null, "WorldEventMemory autoload missing")
	if ledger == null or memory == null:
		return
	ledger.call("clear")
	memory.call("reset_run_events", 1138)
	var live_map := MockThreadwayMap.new()
	root.add_child(live_map)
	var live_site := _make_site(live_map)
	root.add_child(live_site)
	await process_frame
	await process_frame
	_check(live_map.resolve_count == 0, "threadway resolved before Knot acquisition")
	ledger.call("add", RESOURCE_ID, 1)
	await process_frame
	_check(memory.call("is_completed", EVENT_ID), "Knot acquisition did not latch WorldEventMemory")
	_check(live_map.resolve_count == 0, "live Knot committed terrain before visual resolution")
	var live_threadway := live_site.call("debug_get_threadway") as AshBellThreadwayCauseway
	_check(live_threadway != null, "live Knot did not create persistent threadway presentation")
	if live_threadway != null:
		_check(live_threadway.debug_get_persistent_tile_count() == 3, "persistent tile count drifted")
		for child in live_threadway.get_children():
			if String(child.name).begins_with("ThreadwayFloor_"):
				_check((child as Sprite2D).z_index == 0, "persistent Threadway floor is not in ground z=0")
	await create_timer(1.2).timeout
	if live_threadway != null:
		_check(live_threadway.debug_get_reveal_play_count() == 1, "live reveal did not play exactly once")
		_check(not live_threadway.debug_has_temporary_blocker(), "temporary blocker survived reveal")
	_check(live_map.resolve_count == 1, "live Knot did not commit exactly once after reveal")
	ledger.call("add", RESOURCE_ID, 1)
	await process_frame
	_check(live_map.resolve_count == 1, "second Knot duplicated connector resolution")
	live_site.queue_free()
	live_map.queue_free()
	await process_frame

	ledger.call("clear")
	memory.call("reset_run_events", 1138)
	ledger.call("add", RESOURCE_ID, 1)
	var pre_map := MockThreadwayMap.new()
	root.add_child(pre_map)
	var pre_site := _make_site(pre_map)
	root.add_child(pre_site)
	await process_frame
	await process_frame
	_check(memory.call("is_completed", EVENT_ID), "pre-acquired Knot was not latched on site load")
	_check(pre_map.resolve_count == 1, "pre-acquired Knot did not resolve on load")
	var pre_threadway := pre_site.call("debug_get_threadway") as AshBellThreadwayCauseway
	_check(pre_threadway != null, "pre-acquired Knot did not create presentation")
	if pre_threadway != null:
		_check(pre_threadway.debug_get_reveal_play_count() == 0, "pre-acquired Knot replayed live reveal")
	pre_site.queue_free()
	pre_map.queue_free()
	ledger.call("clear")
	memory.call("reset_run_events", 0)
	await process_frame


func _validate_bounded_fallback() -> void:
	var ledger := root.get_node_or_null("ResourceLedger")
	var memory := root.get_node_or_null("WorldEventMemory")
	ledger.call("clear")
	memory.call("reset_run_events", 1138)
	ledger.call("add", RESOURCE_ID, 1)
	var map := MockFallbackThreadwayMap.new()
	root.add_child(map)
	var site := _make_site(map)
	root.add_child(site)
	await process_frame
	await process_frame
	_check(map.evaluated_lengths == [18, 30], "fallback did not evaluate canonical then bounded budgets")
	_check(map.committed_length == 30, "fallback commit did not use bounded 30-tile budget")
	_check(map.committed_lateral == 10, "fallback commit did not retain bounded lateral allowance")
	_check(map.resolve_count == 1, "fallback committed more than once")
	site.queue_free()
	map.queue_free()
	ledger.call("clear")
	memory.call("reset_run_events", 0)
	await process_frame


func _make_site(map_instance: Node) -> Area2D:
	var site := SITE_SCRIPT.new() as Area2D
	site.call("configure_route", &"forlorn_ritualant_underground", &"default", map_instance)
	site.set_meta("world_ingress_outward_direction", Vector2i.UP)
	site.set_meta("world_ingress_unlock_causeway", {
		"resource_id": RESOURCE_ID,
		"event_id": String(EVENT_ID),
		"initially_isolated": true,
		"width_tiles": 3,
		"max_length_tiles": 18,
	})
	return site


func _component_from(origin: Vector2i, floor: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if not floor.has(origin):
		return result
	var pending: Array[Vector2i] = [origin]
	result[origin] = true
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if floor.has(neighbor) and not result.has(neighbor):
				result[neighbor] = true
				pending.append(neighbor)
	return result


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
