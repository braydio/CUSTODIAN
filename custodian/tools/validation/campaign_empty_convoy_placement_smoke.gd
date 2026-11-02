extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const INSERTER := preload("res://game/world/procgen/special_rooms/special_room_runtime_inserter.gd")
const EVENT_ID := "campaign_empty_convoy_v1"
const SCENE_PATH := "res://game/world/events/campaign/empty_convoy_site.tscn"
const SEEDS := [420777, 420779, 771923, 392011]
const MAP_SIZE := Vector2i(160, 128)
const CONVOY_SIZE := Vector2i(12, 10)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var inserter: Variant = INSERTER.new()
	var placed_seed_count := 0
	for seed_value in SEEDS:
		var map: ProcGenTilemap = await _generate_map(seed_value)
		if map == null:
			_continue("seed=%d generated map missing" % seed_value)
			continue
		var level_data := map.get_level_data()
		var definition := {
			"id": EVENT_ID,
			"scene_path": SCENE_PATH,
			"size_tiles": [CONVOY_SIZE.x, CONVOY_SIZE.y],
			"require_main_playable_component": true,
			"clearance_tiles": 2,
		}
		var floor_cells: Array[Vector2i] = []
		for floor_cell in level_data.get("floor_cells", []):
			if floor_cell is Vector2i:
				floor_cells.append(floor_cell)
		var occupied_rects: Array[Rect2i] = []
		var blocked: Dictionary = inserter.call("_build_blocked_lookup", level_data)
		var main_component: Dictionary = map.get_main_playable_component()
		var first_center: Vector2i = inserter.call(
			"_pick_room_center", map, definition, floor_cells, blocked, occupied_rects,
			MAP_SIZE, seed_value, main_component, 2
		)
		var repeated_center: Vector2i = inserter.call(
			"_pick_room_center", map, definition, floor_cells, blocked, occupied_rects,
			MAP_SIZE, seed_value, main_component, 2
		)
		print("[EmptyConvoySmoke] seed=%d planned_center=%s" % [seed_value, str(first_center)])
		_expect(first_center == repeated_center, "seed=%d placement planning changed on repeat" % seed_value)
		var sites: Array[Dictionary] = inserter.call("insert_special_rooms", {
			"map_instance": map,
			"parent": map,
			"level_data": level_data,
			"seed": seed_value,
			"definitions_path": "res://content/procgen/special_rooms",
			"max_rooms": 1,
		})
		var convoy_sites := _convoy_sites(sites)
		if first_center == Vector2i(-999999, -999999):
			_expect(convoy_sites.is_empty(), "seed=%d unsafe/no-site plan must skip" % seed_value)
		else:
			_expect(convoy_sites.size() == 1, "seed=%d valid placement must realize exactly once" % seed_value)
		if convoy_sites.size() == 1:
			placed_seed_count += 1
			var site := convoy_sites[0]
			var center: Vector2i = site.get("center_tile", Vector2i.ZERO)
			var footprint: Rect2i = site.get("claimed_rect", Rect2i())
			_expect(center == first_center, "seed=%d realized site differs from planned center" % seed_value)
			_expect(site.get("size_tiles", Vector2i.ZERO) == CONVOY_SIZE, "seed=%d convoy footprint is not 12x10" % seed_value)
			_expect(site.get("scene_path", "") == SCENE_PATH, "seed=%d convoy scene path is incorrect" % seed_value)
			_expect(_rect_is_in_component(map, center, footprint.size), "seed=%d pocket footprint is not reachable" % seed_value)
			_expect(_rect_clears_semantics(footprint, level_data), "seed=%d pocket overlaps route, ingress, objective, or escape semantics" % seed_value)
			var instance := map.get_node_or_null(String(site.get("instance_path", "")))
			_expect(instance != null, "seed=%d realized convoy scene is missing" % seed_value)
			if instance != null:
				var original_position: Vector2 = instance.global_position
				var original_fingerprint := _site_fingerprint(site)
				var chunk_size := int(map.get("streaming_chunk_size_tiles"))
				var chunk := Vector2i(center.x / chunk_size, center.y / chunk_size)
				map.call("_reveal_chunk_immediately", chunk)
				map.call("debug_force_unload_chunk", chunk)
				map.call("_reveal_chunk_immediately", chunk)
				var reread_sites := _convoy_sites(map.call("get_special_room_sites"))
				_expect(is_instance_valid(instance), "seed=%d streaming unload destroyed the authored scene" % seed_value)
				_expect(instance.global_position == original_position, "seed=%d reveal moved the convoy scene" % seed_value)
				_expect(reread_sites.size() == 1, "seed=%d reveal duplicated or lost convoy metadata" % seed_value)
				if reread_sites.size() == 1:
					_expect(_site_fingerprint(reread_sites[0]) == original_fingerprint, "seed=%d reveal changed the placement fingerprint" % seed_value)
				if instance.has_method("interact"):
					instance.call("interact", null)
					_expect(int(instance.get("inspect_count")) == 1, "seed=%d manifest inspection did not register" % seed_value)
				else:
					_expect(false, "seed=%d convoy scene lacks the manifest inspection contract" % seed_value)
		map.queue_free()
		await process_frame

	_expect(placed_seed_count > 0, "at least one generated seed must produce an eligible convoy pocket")
	var skip_map := Node2D.new()
	root.add_child(skip_map)
	var skipped: Array[Dictionary] = inserter.call("insert_special_rooms", {
		"map_instance": skip_map,
		"parent": skip_map,
		"level_data": {"map_size": Vector2i(8, 8), "floor_cells": [Vector2i(4, 4)]},
		"seed": 1,
		"definitions_path": "res://content/procgen/special_rooms",
		"max_rooms": 1,
	})
	_expect(skipped.is_empty(), "no-valid-pocket input must deterministically skip without realizing a scene")
	skip_map.free()
	if _errors.is_empty():
		print("PASS: empty convoy placement seeds=%d placed=%d" % [SEEDS.size(), placed_seed_count])
		quit(0)
	else:
		for message in _errors:
			push_error(message)
		quit(1)


func _generate_map(seed_value: int) -> ProcGenTilemap:
	var map := MAP_SCENE.instantiate() as ProcGenTilemap
	if map == null:
		return null
	root.add_child(map)
	var legacy_generator := map.get_node_or_null("ProcGen")
	if legacy_generator != null:
		legacy_generator.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = seed_value
	generator.map_size = MAP_SIZE
	map.enable_streaming_reveal = true
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.generate()
	await process_frame
	return map


func _convoy_sites(sites: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in sites:
		if item is Dictionary and String(item.get("id", "")) == EVENT_ID:
			result.append(item)
	return result


func _rect_is_in_component(map: ProcGenTilemap, center: Vector2i, size: Vector2i) -> bool:
	var component: Dictionary = map.get_main_playable_component()
	var half := Vector2i(int(floor(float(size.x) * 0.5)), int(floor(float(size.y) * 0.5)))
	var rect := Rect2i(center - half, size)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			if not component.has(Vector2i(x, y)):
				return false
	return true


func _rect_clears_semantics(rect: Rect2i, level_data: Dictionary) -> bool:
	for key in ["main_route_cells", "compound_ingress", "objective_cells", "required_objective_cells", "escape_cells"]:
		for cell in level_data.get(key, []):
			if cell is Vector2i and rect.has_point(cell):
				return false
	return true


func _site_fingerprint(site: Dictionary) -> String:
	return "%s|%s|%s|%s" % [
		String(site.get("id", "")),
		str(site.get("center_tile", Vector2i.ZERO)),
		str(site.get("size_tiles", Vector2i.ZERO)),
		str(site.get("global_position", Vector2.ZERO)),
	]


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _continue(message: String) -> void:
	_errors.append(message)
