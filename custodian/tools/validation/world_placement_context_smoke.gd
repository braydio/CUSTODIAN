extends SceneTree

const CONTEXT_SCRIPT := preload("res://game/world/placement/world_placement_context.gd")
const WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")


class FakePlacementMap:
	extends Node

	var walkable_tiles := {Vector2i(4, 5): true}
	var region_types := {Vector2i(4, 5): "compound_approach"}
	var intensities := {Vector2i(4, 5): 0.75}
	var transform_origin := Vector2(128.0, 64.0)


	func is_placement_floor_tile(tile: Vector2i) -> bool:
		return bool(walkable_tiles.get(tile, false))


	func get_region_type_at_tile(tile: Vector2i) -> String:
		return String(region_types.get(tile, "exterior"))


	func get_intensity_at_tile(tile: Vector2i) -> float:
		return float(intensities.get(tile, 0.0))


	func tile_to_global_position(tile: Vector2i) -> Vector2:
		return transform_origin + Vector2(tile * 32)


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := FakePlacementMap.new()
	root.add_child(map)
	var original_walkable := map.walkable_tiles.duplicate(true)
	var original_rooms := [
		{"sector_id": " defense ", "rect": Rect2i(1, 2, 4, 5), "nested": {"label": "kept"}},
		{"sector_id": "DEFENSE", "rect": Rect2i(9, 9, 1, 1)},
		{"sector_id": "", "rect": Rect2i(0, 0, 1, 1)},
	]
	var level_data := {
		"seed": 881,
		"player_spawn": Vector2i(4, 5),
		"compound_rect": Rect2i(1, 2, 8, 6),
		"compound_ingress": [Vector2i(1, 4), "discard", Vector2i(8, 4)],
		"compound_rooms": original_rooms,
		"nested": {"list": [1, 2]},
	}
	var observed: Array[Dictionary] = []
	var observer := func(event_name: StringName, payload: Dictionary) -> void:
		observed.append({"event": event_name, "payload": payload})
	var original_data := level_data.duplicate(true)
	var context := CONTEXT_SCRIPT.new(map, level_data, observer)
	var repeated_context := CONTEXT_SCRIPT.new(map, level_data)

	_expect(context.has_accepted_map(), "context retains the accepted map for narrow read queries")
	_expect(
		context.get_compound_rect() == repeated_context.get_compound_rect()
		and context.get_compound_rooms_by_sector_id() == repeated_context.get_compound_rooms_by_sector_id(),
		"construction returns deterministic snapshots for the same accepted inputs"
	)
	_expect(observed.is_empty(), "context construction emits no observability event")
	_expect(level_data == original_data, "context construction leaves authoritative level data untouched")
	_expect(map.walkable_tiles == original_walkable, "context construction leaves accepted map state untouched")
	_expect(context.get_anchor_tile(&"player_spawn") == Vector2i(4, 5), "spawn anchor query returns the authored tile")
	_expect(not context.has_anchor_tile(&"missing_spawn"), "missing spawn anchor remains distinguishable")
	_expect(context.get_compound_rect() == Rect2i(1, 2, 8, 6), "compound bounds query returns the accepted bounds")
	_expect(
		context.get_compound_ingress_tiles() == [Vector2i(1, 4), Vector2i(8, 4)],
		"compound ingress query filters invalid values into a typed copy"
	)
	var rooms := context.get_compound_rooms_by_sector_id()
	_expect(rooms.size() == 1 and rooms.has("DEFENSE"), "compound room query normalizes IDs and keeps the first stable room")
	rooms["DEFENSE"]["nested"]["label"] = "mutated"
	_expect(level_data["compound_rooms"][0]["nested"]["label"] == "kept", "compound room results are detached copies")
	var snapshot := context.get_level_data_snapshot()
	snapshot["nested"]["list"].append(3)
	_expect(level_data["nested"]["list"] == [1, 2], "level-data snapshots cannot mutate the accepted dictionary")
	var ingress := context.get_compound_ingress_tiles()
	ingress.append(Vector2i(99, 99))
	_expect(context.get_compound_ingress_tiles().size() == 2, "typed query results are detached copies")

	_expect(context.is_walkable_floor_tile(Vector2i(4, 5)), "floor query delegates to the map's narrow read method")
	_expect(not context.is_walkable_floor_tile(Vector2i(5, 5)), "floor query does not infer absent floor")
	_expect(context.get_region_type(Vector2i(4, 5)) == "compound_approach", "region query delegates to the accepted map")
	_expect(is_equal_approx(context.get_intensity(Vector2i(4, 5)), 0.75), "intensity query delegates to the accepted map")
	_expect(
		context.has_canonical_tile_transform()
		and context.tile_to_global_position(Vector2i(4, 5)) == Vector2(256.0, 224.0),
		"tile transform uses the map's canonical world transform"
	)

	var seed_parts: Array[int] = [1, 2, 3, 4, 3]
	_expect(CONTEXT_SCRIPT.stable_seed(seed_parts) == 1172651610, "stable seed primitive preserves the current resource score hash")
	_expect(
		CONTEXT_SCRIPT.stable_seed(seed_parts) == CONTEXT_SCRIPT.stable_seed(seed_parts.duplicate()),
		"stable seed is deterministic for equal input"
	)
	var loader := WORLD_LOADER_SCRIPT.new()
	_expect(
		loader.call("_stable_resource_tile_score", Vector2i(4, 5), Vector2i(8, 9)) == 1444720962,
		"tutorial resource score retains its pre-context output"
	)
	_expect(
		loader.call("_stable_expedition_resource_tile_score", Vector2i(4, 5), Vector2i(8, 9)) == 2101123403,
		"expedition resource score retains its pre-context output"
	)
	loader.free()
	var event_payload := {"anchor": Vector2i(4, 5), "details": ["original"]}
	context.observe(&"placement_context_smoke", event_payload)
	event_payload["details"].append("mutated")
	_expect(observed.size() == 1, "observability is invoked only when requested")
	_expect(
		observed[0]["event"] == &"placement_context_smoke"
		and observed[0]["payload"]["details"] == ["original"],
		"observability receives an isolated payload"
	)
	_expect(map.walkable_tiles == original_walkable, "read queries and observation do not alter map state")
	for property in context.get_property_list():
		_expect(
			String(property.get("name", "")) not in ["accepted_map", "map", "map_instance"],
			"context does not expose a live map property"
		)

	map.queue_free()
	await process_frame
	_expect(not context.has_accepted_map(), "context safely detects an expired accepted map")
	_expect(context.get_region_type(Vector2i.ZERO) == "exterior", "expired map queries use stable fallbacks")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("world_placement_context_smoke: %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("world_placement_context_smoke ok")
	quit(0)
