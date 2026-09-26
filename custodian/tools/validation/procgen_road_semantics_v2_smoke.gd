extends SceneTree

const ROAD_RESOLVER := preload("res://game/world/procgen/surfaces/road_semantics_resolver.gd")
const MATERIAL_RESOLVER := preload("res://game/world/procgen/surfaces/surface_material_resolver.gd")
const IDS := preload("res://game/world/procgen/surfaces/surface_material_ids.gd")
const MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const MAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_pure_resolver()
	_test_material_authority()
	_test_macro_claims()
	await _test_production_integration()
	if _failed:
		quit(1)
	else:
		print("procgen_road_semantics_v2_smoke: PASS")
		quit(0)


func _test_pure_resolver() -> void:
	var floor_cells: Dictionary = {}
	var route_cells: Dictionary = {}
	var centerline: Array[Vector2i] = []
	var distance: Dictionary = {}
	for y in range(14, 27):
		for x in range(0, 128):
			floor_cells[Vector2i(x, y)] = true
	for x in range(4, 124):
		var cell := Vector2i(x, 20)
		centerline.append(cell)
		for y in range(18, 23):
			route_cells[Vector2i(x, y)] = true
	for cell: Vector2i in centerline:
		distance[cell] = 0
	for x in range(128):
		for y in range(14, 27):
			distance[Vector2i(x, y)] = absi(y - 20)
	centerline.reverse()
	var context := {
		"seed": 824790,
		"floor_cells": floor_cells,
		"wall_cells": {Vector2i(40, 20): true},
		"chasm_cells": {Vector2i(50, 20): true},
		"ocean_cells": {Vector2i(60, 20): true},
		"route_cells": route_cells,
		"route_centerline_cells": centerline,
		"centerline_distance": distance,
		"spawn_cell": Vector2i(4, 20),
		"compound_rect": Rect2i(90, 16, 12, 10),
		"compound_ingress_cells": [Vector2i(90, 20)],
		"region_kind_by_cell": {Vector2i(70, 20): "story_room_floor"},
		"reserved_cells": {Vector2i(30, 20): true},
	}
	var floor_before: Dictionary = floor_cells.duplicate(true)
	var wall_before: Dictionary = context.wall_cells.duplicate(true)
	var context_before: Dictionary = context.duplicate(true)
	var resolver := ROAD_RESOLVER.new()
	var first: Dictionary = resolver.resolve(context)
	var second: Dictionary = resolver.resolve(context)
	_require(first.fingerprint == second.fingerprint, "same road input changed fingerprint")
	_require(first.ruined_road_cells == second.ruined_road_cells, "same road input changed classifications")
	_require(floor_cells == floor_before and context.wall_cells == wall_before, "road resolver mutated authority input")
	_require(context == context_before, "road resolver mutated resolver input dictionary")
	var roads: Dictionary = first.ruined_road_cells
	_require(not roads.is_empty(), "long eligible route received no ruined-road fragments")
	_require(roads.size() < route_cells.size(), "ruined roads converted the complete route")
	var natural_gap := false
	for cell: Vector2i in centerline:
		var arc := cell.x - 4
		if arc < 12:
			_require(not roads.has(cell), "spawn clearance contains ruined road")
		if arc >= 12 and arc < 116 and route_cells.has(cell) and not roads.has(cell):
			natural_gap = true
	_require(natural_gap, "intermittent road fragments have no natural gap")
	var fallback_seed := -1
	for candidate_seed in range(4096):
		var no_selected_segment := true
		for segment in range(5):
			if resolver._stable_hash(candidate_seed, segment, 0x524F4144) % 100 < 45:
				no_selected_segment = false
				break
		if no_selected_segment:
			fallback_seed = candidate_seed
			break
	_require(fallback_seed >= 0, "could not form deterministic all-segments-rejected fallback fixture")
	if fallback_seed >= 0:
		var fallback_context: Dictionary = context.duplicate(true)
		fallback_context["seed"] = fallback_seed
		var fallback_result: Dictionary = resolver.resolve(fallback_context)
		_require(not fallback_result.ruined_road_cells.is_empty(), "48+ usable centerline cells did not activate fallback road fragment")
	for cell: Vector2i in roads:
		_require(floor_cells.has(cell) and route_cells.has(cell), "road cell is not existing route floor")
		_require(not context.wall_cells.has(cell) and not context.chasm_cells.has(cell) and not context.ocean_cells.has(cell), "road overlaps wall/chasm/ocean")
		_require(not context.reserved_cells.has(cell), "road overlaps reserved cell")
		_require(String(context.region_kind_by_cell.get(cell, "")).findn("story_room") < 0, "road overlaps excluded story region")
		_require(int(distance.get(cell, 999)) <= 2, "road exceeds centerline distance two")
	var apron: Dictionary = first.service_hardstand_cells
	_require(apron.size() <= 63, "apron exceeds 9x7 envelope")
	_require(apron.size() >= 30, "valid service apron was unexpectedly rejected")
	_require(apron == first.parking_cells, "parking/staging does not match service apron")
	for cell: Vector2i in apron:
		_require(floor_cells.has(cell) and not context.wall_cells.has(cell) and not context.chasm_cells.has(cell) and not context.ocean_cells.has(cell), "apron includes invalid terrain")
		_require(not context.reserved_cells.has(cell), "apron overlaps reserved cell")
	var sparse_context: Dictionary = context.duplicate(true)
	var sparse_reserved: Dictionary = sparse_context["reserved_cells"]
	var apron_cells := _sorted_cells(apron.keys())
	for index in range(mini(34, apron_cells.size())):
		sparse_reserved[apron_cells[index]] = true
	var sparse_result: Dictionary = resolver.resolve(sparse_context)
	_require(sparse_result.service_hardstand_cells.is_empty(), "apron with fewer than thirty viable cells was retained")


func _test_material_authority() -> void:
	var floor_cells := {Vector2i(0, 0): true, Vector2i(1, 0): true, Vector2i(2, 0): true, Vector2i(3, 0): true, Vector2i(4, 0): true, Vector2i(5, 0): true, Vector2i(6, 0): true}
	var base := {
		"floor_cells": floor_cells,
		"wall_cells": {},
		"chasm_cells": {},
		"biome_by_cell": {Vector2i(0, 0): &"scrubland", Vector2i(1, 0): &"rocky_upland", Vector2i(2, 0): &"wetland", Vector2i(3, 0): &"scrubland"},
		"region_kind_by_cell": {Vector2i(0, 0): "soft_path", Vector2i(1, 0): "soft_path", Vector2i(2, 0): "soft_path"},
		"path_cells": {Vector2i(0, 0): true, Vector2i(1, 0): true, Vector2i(2, 0): true},
		"road_cells": {Vector2i(3, 0): true},
		"industrial_hardstand_cells": {Vector2i(4, 0): true},
		"parking_cells": {Vector2i(4, 0): true, Vector2i(5, 0): true},
		"reserved_cells": {},
		"authored_cells": {},
	}
	var result: Dictionary = MATERIAL_RESOLVER.new().resolve(base)
	_require(result.material_by_cell[Vector2i(0, 0)] == IDS.NATURAL_SOFT, "scrubland soft_path became ruined_road")
	_require(result.material_by_cell[Vector2i(1, 0)] == IDS.NATURAL_ROCK, "rocky soft_path became ruined_road")
	_require(result.material_by_cell[Vector2i(2, 0)] == IDS.WET_GROUND, "wetland soft_path became ruined_road")
	_require(result.material_by_cell[Vector2i(3, 0)] == IDS.RUINED_ROAD, "explicit road cell did not become ruined_road")
	_require(result.material_by_cell[Vector2i(4, 0)] == IDS.HARDENED_INDUSTRIAL, "service hardstand did not outrank parking/civic")
	_require(result.material_by_cell[Vector2i(5, 0)] == IDS.HARDENED_CIVIC, "parking did not resolve civic hardstand")
	_require(result.material_by_cell[Vector2i(6, 0)] == IDS.NATURAL_SOFT, "ordinary floor did not fall back to natural_soft")
	var explicit_region: Dictionary = MATERIAL_RESOLVER.new().resolve({
		"floor_cells": {Vector2i(0, 0): true}, "wall_cells": {}, "chasm_cells": {},
		"region_kind_by_cell": {Vector2i(0, 0): "ruined_road_connector"},
	})
	_require(explicit_region.material_by_cell[Vector2i(0, 0)] == IDS.RUINED_ROAD, "explicit road/connector region did not classify as ruined road")
	var tilemap_source := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	for constructed_id in ["HARDENED_CIVIC", "HARDENED_INDUSTRIAL", "RUINED_ROAD", "BRIDGE", "AUTHORED_LANDMARK"]:
		_require(tilemap_source.contains("SURFACE_MATERIAL_IDS." + constructed_id), "cluster skip policy omits constructed material " + constructed_id)


func _test_macro_claims() -> void:
	var host := MAP_SCRIPT.new() as ProcGenTilemap
	var main_road := Vector2i(1, 1)
	var parking := Vector2i(2, 1)
	var ruined := Vector2i(3, 1)
	var apron := Vector2i(4, 1)
	host._main_road_tiles[main_road] = true
	host._parking_zone_tiles[parking] = true
	host._ruined_road_cells[ruined] = true
	host._service_hardstand_cells[apron] = true
	var claims: Dictionary = host.call("_macro_presentation_surface_claims")
	_require(claims.size() == 4 and claims.has(main_road) and claims.has(parking) and claims.has(ruined) and claims.has(apron), "constructed road/apron cells are missing from macro claims")
	_require(host.is_road_surface_tile(main_road) and host.is_road_surface_tile(ruined), "road query omits archived or V2 road cells")
	host._set_region_tile(Vector2i(5, 1), "soft_path", "natural")
	_require(host.is_road_surface_tile(Vector2i(5, 1)), "foliage road query no longer excludes soft_path")
	_require(host.is_parking_zone_tile(parking), "parking query changed")
	host.free()


func _test_production_integration() -> void:
	var map := MAP_SCENE.instantiate()
	root.add_child(map)
	var tilemap := map as ProcGenTilemap
	_require(tilemap != null, "procgen map is not ProcGenTilemap")
	if tilemap == null:
		quit(1)
		return
	var procgen := map.get_node("ProcGen2") as ProcGen
	procgen.generate_seed = false
	procgen.seed = 824790
	procgen.map_size = Vector2i(128, 104)
	tilemap.enable_streaming_reveal = false
	tilemap.generate()
	for _frame in range(360):
		if not tilemap.debug_get_generated_floor_cells().is_empty():
			break
		await process_frame
	_require(not tilemap.intent_main_roads_enabled, "production wide-road flag is enabled")
	_require(tilemap._main_road_tiles.is_empty(), "archived wide-road tiles were generated in production")
	var floor_before := tilemap.debug_get_generated_floor_cells()
	var walls_before := tilemap.debug_get_generated_wall_cells()
	var route_before := tilemap.debug_get_route_playability()
	var elevation_before: Variant = tilemap.get_elevation_map().get_serialized_cells()
	tilemap.call("_resolve_road_semantics", procgen.map_size)
	_require(tilemap.debug_get_generated_floor_cells() == floor_before, "integration changed floor authority")
	_require(tilemap.debug_get_generated_wall_cells() == walls_before, "integration changed wall authority")
	_require(tilemap.debug_get_route_playability() == route_before, "integration changed traversal/route authority")
	_require(tilemap.get_elevation_map().get_serialized_cells() == elevation_before, "integration changed elevation")
	_require(tilemap.get_surface_material_at_tile(Vector2i(-1, -1)) == &"", "outside-map cell received floor material")
	var summary := tilemap.debug_get_road_semantics_summary()
	_require(summary.has("fingerprint"), "production road summary omitted fingerprint")
	_require(int(summary.get("ruined_road_cell_count", 0)) > 0, "fixed production route did not independently produce ruined-road semantics")
	_require(bool(tilemap.debug_run_route_playability_audit().get("ok", false)), "road semantics caused route playability audit failure")
	_require(tilemap.get_level_data().has("ruined_road_tiles"), "level data omitted ruined road export")
	_require(tilemap.get_level_data().has("service_hardstand_tiles"), "level data omitted service apron export")
	_require(tilemap.get_level_data().has("parking_zone_tiles"), "level data omitted parking export")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(Vector2i(-1, -1)), 1.0), "natural non-path movement changed")
	var civic_probe := Vector2i(-10, -10)
	var industrial_probe := Vector2i(-11, -10)
	var road_probe := Vector2i(-13, -10)
	var soft_path_probe := Vector2i(-12, -10)
	tilemap._surface_material_by_cell[civic_probe] = IDS.HARDENED_CIVIC
	tilemap._surface_material_by_cell[industrial_probe] = IDS.HARDENED_INDUSTRIAL
	tilemap._surface_material_by_cell[road_probe] = IDS.RUINED_ROAD
	tilemap._surface_material_by_cell[soft_path_probe] = IDS.NATURAL_SOFT
	tilemap._set_region_tile(soft_path_probe, "soft_path", "natural")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(civic_probe), 1.12), "civic hardstand lost operator multiplier")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(civic_probe, "vehicle"), 1.35), "civic hardstand lost vehicle multiplier")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(industrial_probe), 1.12), "industrial hardstand lost operator multiplier")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(industrial_probe, "vehicle"), 1.35), "industrial hardstand lost vehicle multiplier")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(road_probe), 1.12), "ruined road lost operator multiplier")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(road_probe, "vehicle"), 1.35), "ruined road lost vehicle multiplier")
	_require(is_equal_approx(tilemap.get_movement_surface_multiplier_at_tile(soft_path_probe), 1.12), "soft_path compatibility multiplier changed")
	tilemap._surface_material_by_cell.erase(civic_probe)
	tilemap._surface_material_by_cell.erase(industrial_probe)
	tilemap._surface_material_by_cell.erase(road_probe)
	tilemap._surface_material_by_cell.erase(soft_path_probe)
	tilemap._region_tiles.erase(soft_path_probe)
	var materials := tilemap.debug_get_surface_material_map()
	var ocean := tilemap.debug_get_ocean_cells()
	for cell: Vector2i in materials:
		_require(floor_before.has(cell), "surface material exists without floor authority")
		_require(not walls_before.has(cell) and not tilemap.is_chasm_tile(cell) and not ocean.has(cell), "wall/chasm/ocean received floor material")
	print("road_semantics_fixed_seed: fragments=%d road_cells=%d service_apron=%d parking=%d fingerprint=%s" % [int(summary.get("ruined_road_fragment_count", 0)), int(summary.get("ruined_road_cell_count", 0)), int(summary.get("service_hardstand_cell_count", 0)), int(summary.get("parking_cell_count", 0)), String(summary.get("fingerprint", ""))])
	map.queue_free()
	await process_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("procgen_road_semantics_v2_smoke: " + message)


func _sorted_cells(values: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value: Variant in values:
		if value is Vector2i:
			result.append(value)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return result
