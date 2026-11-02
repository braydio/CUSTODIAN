extends SceneTree

const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const ALPINE_FRAME := preload("res://game/world/procgen/presentation/region_frames/alpine_plateau.tres")
const PLANNER := preload("res://game/world/events/abandoned_station/abandoned_station_placement_planner.gd")
const SITE := preload("res://game/world/events/abandoned_station/abandoned_station_site.gd")
const MEMORY := preload("res://game/systems/core/state/world_event_memory.gd")

class PlannerMap extends Node:
	func is_runtime_navigation_walkable(_tile: Vector2i) -> bool:
		return true
	func is_encounter_reserved_cell(_tile: Vector2i) -> bool:
		return false
	func get_runtime_escape_neighbor_count(_tile: Vector2i) -> int:
		return 4
const SEEDS := [913042, 902104, 440183, 773311]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for seed_value in SEEDS:
		var map := MAP_SCENE.instantiate()
		root.add_child(map)
		var legacy_generator := map.get_node_or_null("ProcGen")
		if legacy_generator != null:
			legacy_generator.queue_free()
			await process_frame
		var generator := map.get_node("ProcGen2") as ProcGen
		generator.generate_seed = false
		generator.seed = seed_value
		generator.map_size = Vector2i(96, 80)
		map.enable_streaming_reveal = false
		map.enable_final_foliage = false
		map.enable_ruin_prop_spawning = false
		map.interior_prop_spawning_enabled = false
		map.generate()
		await process_frame
		var level_data: Dictionary = map.get_level_data()
		var synthetic_floor: Array[Vector2i] = []
		for y in range(8, 72):
			for x in range(8, 88):
				synthetic_floor.append(Vector2i(x, y))
		level_data["floor_cells"] = synthetic_floor
		level_data["worldgen_reserved_regions"] = []
		level_data["route_playability"] = {"route_distance": _route_distance_field(synthetic_floor)}
		var planner_map := PlannerMap.new()
		var first: Dictionary = PLANNER.plan(planner_map, level_data, seed_value)
		var second: Dictionary = PLANNER.plan(planner_map, level_data, seed_value)
		_expect(not first.is_empty(), "seed %d must find a station site" % seed_value)
		_expect(first == second, "seed %d placement must be deterministic" % seed_value)
		if not first.is_empty():
			var services: Array = first.get("services", [])
			_expect(services.size() == 3, "seed %d must place three service points" % seed_value)
			_expect(services.size() == 3 and services[0] != services[1] and services[1] != services[2] and services[0] != services[2], "seed %d service points must be distinct" % seed_value)
			for tile in services:
				_expect(synthetic_floor.has(tile), "seed %d service point must be navigable in fixture" % seed_value)
		map.queue_free()
		await process_frame
		planner_map.free()
	_expect(String(ALPINE_FRAME.profile_id) == "alpine_plateau", "smoke must use the authored Alpine region frame")
	var memory := MEMORY.new()
	var site := SITE.new()
	root.add_child(site)
	site.configure(&"station_smoke", [Vector2.ZERO, Vector2(32, 0), Vector2(64, 0)], memory)
	site.service_point(1)
	_expect(site.is_service_complete(1), "service interaction must persist an individual subsystem")
	var restored := SITE.new()
	root.add_child(restored)
	restored.configure(&"station_smoke", [Vector2.ZERO, Vector2(32, 0), Vector2(64, 0)], memory)
	_expect(restored.is_service_complete(1), "service state must restore from WorldEventMemory")
	restored.service_point(0)
	restored.service_point(2)
	_expect(restored.get_stability_phase() == "hazard_revealed", "all three service points before the deadline must reveal the unsafe outward link")
	_expect(not memory.is_completed(&"station_smoke"), "S2 success must preserve the station until S3 resolves the event")
	site.free()
	restored.free()
	memory.free()
	if failures.is_empty():
		print("PASS: abandoned station placement seeds=%d" % SEEDS.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _route_distance_field(floor_cells: Array[Vector2i]) -> Dictionary:
	var distance := {}
	for tile in floor_cells:
		distance[tile] = mini(tile.x, 95 - tile.x)
	return distance
