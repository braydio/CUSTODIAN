extends SceneTree

const MAP_SCENE := preload("res://game/world/hub/first_set/hub_first_set_map.tscn")
const PLAYTEST_SCENE := preload("res://scenes/hub_first_set_blockout_playtest.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const EXPECTED_ENVELOPES := {
	"north_processional": Rect2i(72, 97, 32, 36),
	"ashen_forum": Rect2i(48, 46, 80, 56),
	"sepulcher_gardens": Rect2i(8, 50, 36, 44),
	"sepulcher_north_connector": Rect2i(44, 68, 4, 8),
	"sepulcher_south_connector": Rect2i(44, 85, 4, 8),
	"lower_archive_rise": Rect2i(66, 9, 44, 40),
	"crown_transfer_court": Rect2i(110, 14, 24, 24),
	"muster_court": Rect2i(132, 56, 34, 44),
	"muster_connector": Rect2i(128, 70, 4, 10),
	"continuity_port_chamber": Rect2i(166, 64, 22, 28),
}
const TARGET_MARKERS := [
	"ForumSouth", "AdjudicationDais", "ForumNorth", "WestGardenThreshold",
	"EastMusterThreshold", "SepulcherInteriorSample", "CrownTransfer",
	"MusterCenter", "ContinuityPort", "CampaignExitThreshold",
]
const EXPECTED_ROAD_MODULES := [
	{"id": &"south_reach_civic_axis", "position": Vector2(0, 34), "size": Vector2(768, 896)},
	{"id": &"witness_plaza", "position": Vector2(0, -862), "size": Vector2(896, 896)},
	{"id": &"collapsed_chapel_court", "position": Vector2(-832, -862), "size": Vector2(768, 896)},
	{"id": &"archive_ruin_west", "position": Vector2(-832, -1820), "size": Vector2(896, 896)},
	{"id": &"overgrown_reliquary_east", "position": Vector2(832, -862), "size": Vector2(896, 896)},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var map := MAP_SCENE.instantiate() as HubFirstSetMap
	root.add_child(map)
	await process_frame
	_check_layout_and_map(map, failures)
	_check_raw_navigation(map, failures)
	var clearance_metrics := await _check_operator_clearance(map, failures)
	_check_road_ownership(map, failures)
	_check_lifecycle_is_inert(map, failures)
	var walkable_cell_count: int = map.blockout_grid.get_walkable_cells().size()
	var boundary_segment_count: int = map.get_boundary_segments().size()
	map.free()
	await process_frame
	await _check_playtest(failures)
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "hub_first_set_blockout",
		"passed": failures.is_empty(),
		"failure_count": failures.size(),
		"failures": failures,
		"walkable_cells": walkable_cell_count,
		"merged_boundary_segments": boundary_segment_count,
		"marker_count": LAYOUT.MARKERS.size(),
		"operator_clearance": clearance_metrics,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("hub_first_set_blockout_smoke: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_layout_and_map(map: HubFirstSetMap, failures: Array[String]) -> void:
	_expect(map.camera_bounds == LAYOUT.WORLD_BOUNDS, "world bounds mismatch", failures)
	_expect(LAYOUT.GRID_SIZE * LAYOUT.CELL_SIZE == LAYOUT.WORLD_BOUNDS.size, "grid does not span bounds", failures)
	_expect(LAYOUT.GRID_ORIGIN == Vector2(-2816, -5504), "grid origin mismatch", failures)
	_expect(LAYOUT.THRESHOLD_VOLUME == Rect2(3104, -3072, 96, 128), "campaign threshold volume mismatch", failures)
	_expect(map.blockout_grid.authored_cell_size == 32.0, "cell size mismatch", failures)
	_expect(map.blockout_grid.map_size_cells == Vector2i(188, 190), "grid dimensions mismatch", failures)
	_expect(map.blockout_grid.position == LAYOUT.GRID_ORIGIN, "grid position mismatch", failures)
	_expect(map.has_spawn(&"Spawn_SouthReach"), "South Reach spawn missing", failures)
	_expect(map.get_spawn_position(&"Spawn_SouthReach") == Vector2(-6, 162), "South Reach spawn mismatch", failures)
	_expect(map.get_node("Markers").get_child_count() == LAYOUT.MARKERS.size(), "marker count mismatch", failures)
	for marker_variant: Variant in LAYOUT.MARKERS:
		var marker_name := str(marker_variant)
		var marker := map.get_named_marker(StringName(marker_name))
		_expect(marker != null, "missing marker node: %s" % marker_name, failures)
		if marker == null:
			continue
		_expect(marker.position == LAYOUT.MARKERS[marker_variant], "marker position mismatch: %s" % marker_name, failures)
		_expect(map.blockout_grid.is_walkable_cell(LAYOUT.marker_cell(StringName(marker_name))), "marker outside walkable grid: %s" % marker_name, failures)
		var marker_data: Dictionary = map.get_authoring_markers().get(marker_name.to_snake_case(), {})
		_expect(not marker_data.is_empty(), "marker missing from authored-level API: %s" % marker_name, failures)
	for envelope_name: Variant in EXPECTED_ENVELOPES:
		var rect: Rect2i = LAYOUT.ENVELOPES.get(envelope_name, Rect2i())
		_expect(rect == EXPECTED_ENVELOPES[envelope_name], "spatial authority drift: %s" % envelope_name, failures)
		_expect(rect.size.x >= 4 and rect.size.y >= 4, "authored route narrower than four cells: %s" % envelope_name, failures)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_expect(map.blockout_grid.is_walkable_cell(Vector2i(x, y)), "envelope cell missing from walkability: %s at (%d,%d)" % [envelope_name, x, y], failures)
	_expect(LAYOUT.ENVELOPES["sepulcher_north_connector"].size == Vector2i(4, 8), "north garden connector is not 4x8", failures)
	_expect(LAYOUT.ENVELOPES["sepulcher_south_connector"].size == Vector2i(4, 8), "south garden connector is not 4x8", failures)
	_expect(LAYOUT.MARKERS["Spawn_CampaignReturn"] == Vector2(2592, -3008), "campaign return is not the Port west bay", failures)
	_expect(LAYOUT.MARKERS["ContinuityPort"] == Vector2(2944, -3008), "Continuity Port marker mismatch", failures)
	_expect(LAYOUT.MARKERS["CampaignExitThreshold"] == Vector2(3136, -3008), "campaign exit marker mismatch", failures)
	_expect(LAYOUT.ENVELOPES["continuity_port_chamber"].has_point(LAYOUT.marker_cell(&"Spawn_CampaignReturn")), "campaign return spawn is outside the Port chamber", failures)
	_expect(LAYOUT.MARKERS["Spawn_CampaignReturn"].x < LAYOUT.MARKERS["ContinuityPort"].x, "campaign return spawn is not west of the Continuity Port", failures)
	_expect(LAYOUT.THRESHOLD_VOLUME.has_point(LAYOUT.MARKERS["CampaignExitThreshold"]), "campaign exit marker is outside its threshold volume", failures)


func _check_raw_navigation(map: HubFirstSetMap, failures: Array[String]) -> void:
	var walkable: Dictionary = map.blockout_grid.get_walkable_cells()
	var spawn := LAYOUT.marker_cell(&"Spawn_SouthReach")
	for marker_name in TARGET_MARKERS:
		var target := LAYOUT.marker_cell(StringName(marker_name))
		_expect(_can_reach(walkable, spawn, target), "raw walkability disconnected at %s" % marker_name, failures)
		_expect(not map.authored_navigation.compute_path(LAYOUT.MARKERS["Spawn_SouthReach"], LAYOUT.MARKERS[marker_name]).is_empty(), "navigation provider disconnected at %s" % marker_name, failures)
	_expect(_all_connected(walkable), "raw walkability contains an isolated component", failures)
	var garden_cycle := _garden_cycle_cells(walkable)
	var north_mouth := Vector2i(48, 72)
	var south_mouth := Vector2i(48, 89)
	_expect(_can_reach(garden_cycle, north_mouth, south_mouth), "Sepulcher loop does not enter one connector and leave the other", failures)
	for route_name in ["north connector", "south connector"]:
		var connector_name := "sepulcher_north_connector" if route_name == "north connector" else "sepulcher_south_connector"
		var connector: Rect2i = LAYOUT.ENVELOPES[connector_name]
		_expect(_has_connected_rectangle(walkable, connector), "%s is not fully walkable" % route_name, failures)


func _check_operator_clearance(map: HubFirstSetMap, failures: Array[String]) -> Dictionary:
	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	root.add_child(operator)
	await process_frame
	var shape_node := operator.get_node("CollisionShape2D") as CollisionShape2D
	_expect(shape_node != null and shape_node.shape is CapsuleShape2D, "real Operator collision capsule unavailable", failures)
	if shape_node == null or not shape_node.shape is CapsuleShape2D:
		operator.free()
		return {}
	var capsule := shape_node.shape as CapsuleShape2D
	var shape_scale := shape_node.global_transform.get_scale().abs()
	var operator_clearance := maxf(capsule.radius * maxf(shape_scale.x, shape_scale.y), capsule.height * 0.5 * maxf(shape_scale.x, shape_scale.y))
	var rail_clearance := map.boundary_rail_radius
	var clearance_radius := operator_clearance + rail_clearance
	var shape_offset := shape_node.global_position - operator.global_position
	var rails: Array = map.get_boundary_segments()
	var safe_cells: Dictionary = {}
	for cell_variant: Variant in map.blockout_grid.get_walkable_cells().keys():
		var cell := cell_variant as Vector2i
		var center := map.blockout_grid.to_global(map.blockout_grid.cell_center(cell)) + shape_offset
		var blocked := false
		for rail_variant: Variant in rails:
			var rail := rail_variant as Array
			if _distance_to_segment(center, rail[0] as Vector2, rail[1] as Vector2) < clearance_radius:
				blocked = true
				break
		if not blocked:
			safe_cells[cell] = true
	var spawn_cell := _nearest_clear_cell(safe_cells, LAYOUT.marker_cell(&"Spawn_SouthReach"))
	_expect(not safe_cells.is_empty(), "Operator clearance removed all walkable cells", failures)
	for marker_name in TARGET_MARKERS:
		var target_cell := _nearest_clear_cell(safe_cells, LAYOUT.marker_cell(StringName(marker_name)))
		_expect(spawn_cell != Vector2i(-1, -1) and target_cell != Vector2i(-1, -1), "no Operator-clearance cell near mandatory route marker %s" % marker_name, failures)
		if spawn_cell != Vector2i(-1, -1) and target_cell != Vector2i(-1, -1):
			_expect(_can_reach(safe_cells, spawn_cell, target_cell), "Operator-clearance route disconnected at %s (capsule=%0.1f, rail=%0.1f)" % [marker_name, operator_clearance, rail_clearance], failures)
	var garden_cycle := _garden_cycle_cells(safe_cells)
	_expect(_can_reach(garden_cycle, Vector2i(48, 72), Vector2i(48, 89)), "Operator clearance breaks the two-connector Sepulcher loop", failures)
	for connector_name in ["sepulcher_north_connector", "sepulcher_south_connector"]:
		var connector: Rect2i = LAYOUT.ENVELOPES[connector_name]
		_expect(_has_any_cell(safe_cells, connector), "Operator clearance closes %s" % connector_name, failures)
	_expect(_all_connected(map.blockout_grid.get_walkable_cells()), "raw occupancy changed while deriving clearance", failures)
	operator.free()
	return {
		"safe_cells": safe_cells.size(),
		"operator_shape_clearance_px": operator_clearance,
		"boundary_rail_clearance_px": rail_clearance,
		"effective_clearance_px": clearance_radius,
	}


func _garden_cycle_cells(walkable: Dictionary) -> Dictionary:
	var allowed: Dictionary = {}
	for cell_variant: Variant in walkable:
		var cell := cell_variant as Vector2i
		if LAYOUT.ENVELOPES["sepulcher_gardens"].has_point(cell) \
		or LAYOUT.ENVELOPES["sepulcher_north_connector"].has_point(cell) \
		or LAYOUT.ENVELOPES["sepulcher_south_connector"].has_point(cell):
			allowed[cell] = true
	allowed[Vector2i(48, 72)] = true
	allowed[Vector2i(48, 89)] = true
	return allowed


func _check_road_ownership(map: HubFirstSetMap, failures: Array[String]) -> void:
	var road := map.get_node("RoadPresentationRoot") as RoadOfWitnessesPrototype
	_expect(road != null, "Road presentation missing", failures)
	if road == null:
		return
	_expect(road.environment_root.get_child_count() == road.MODULES.size(), "Road module count changed", failures)
	_expect(road.collision_root.get_child_count() == 0, "legacy Road collision competes with first-set boundary", failures)
	for index in road.MODULES.size():
		var spec: Dictionary = road.MODULES[index]
		var expected: Dictionary = EXPECTED_ROAD_MODULES[index]
		var module := road.environment_root.get_child(index) as Node2D
		_expect(spec.id == expected.id and spec.position == expected.position and spec.size == expected.size, "Road module authority changed: %s" % spec.id, failures)
		_expect(module.position == expected.position, "Road module registration changed: %s" % spec.id, failures)
		for layer in ["Underlay", "Foreground"]:
			var sprite := module.get_node_or_null(layer) as Sprite2D
			_expect(sprite != null and sprite.texture != null, "Road art missing: %s/%s" % [spec.id, layer], failures)
			if sprite != null and sprite.texture != null:
				_expect(sprite.texture.get_size() == expected.size, "Road plate size changed: %s/%s" % [spec.id, layer], failures)
				_expect(sprite.centered and sprite.scale == Vector2.ONE, "Road plate registration changed: %s/%s" % [spec.id, layer], failures)
	_expect(map.boundary_collision.get_child_count() > 0, "first-set grid boundary collision missing", failures)


func _check_lifecycle_is_inert(map: HubFirstSetMap, failures: Array[String]) -> void:
	_expect(map.get_node("Interactables").get_child_count() == 0, "H1 added active interactables", failures)
	_expect(map.get_node("TransitionMarkers").get_child_count() == 0, "H1 added active transition handlers", failures)
	_expect(map.find_child("WorldContractBootstrap", true, false) == null, "H1 unexpectedly bootstraps a Contract", failures)
	_expect(map.find_child("WorldTransitionManager", true, false) == null, "H1 unexpectedly implements world transitions", failures)
	_expect(map.find_child("Operator", true, false) == null, "production map owns an Operator", failures)
	_expect(map.find_child("Camera2D", true, false) == null, "production map owns a camera", failures)


func _check_playtest(failures: Array[String]) -> void:
	var playtest := PLAYTEST_SCENE.instantiate()
	root.add_child(playtest)
	await process_frame
	var map := playtest.get_node_or_null("World/Level") as HubFirstSetMap
	var operator := playtest.get_node_or_null("World/Operator") as Node2D
	var camera := playtest.get_node_or_null("World/Camera2D") as Camera2D
	_expect(map != null and operator != null and camera != null, "standalone playtest wiring incomplete", failures)
	if map != null and operator != null and camera != null:
		_expect(operator.global_position == LAYOUT.MARKERS["Spawn_SouthReach"], "real Operator missed South Reach spawn", failures)
		var camera_bounds: Rect2 = camera.get("map_bounds")
		_expect(camera_bounds == LAYOUT.WORLD_BOUNDS.grow(float(camera.get("map_padding"))), "camera bounds are not derived from first-set bounds", failures)
	playtest.free()


func _can_reach(walkable: Dictionary, start: Vector2i, target: Vector2i) -> bool:
	if not walkable.has(start) or not walkable.has(target):
		return false
	var pending: Array[Vector2i] = [start]
	var cursor := 0
	var seen: Dictionary = {}
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		if cell == target:
			return true
		if seen.has(cell):
			continue
		seen[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if walkable.has(neighbor) and not seen.has(neighbor):
				pending.append(neighbor)
	return false


func _all_connected(walkable: Dictionary) -> bool:
	if walkable.is_empty():
		return false
	var first := walkable.keys()[0] as Vector2i
	var pending: Array[Vector2i] = [first]
	var cursor := 0
	var seen: Dictionary = {}
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		if seen.has(cell):
			continue
		seen[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if walkable.has(neighbor) and not seen.has(neighbor):
				pending.append(neighbor)
	return seen.size() == walkable.size()


func _has_connected_rectangle(walkable: Dictionary, rect: Rect2i) -> bool:
	var first := rect.position
	var last := rect.end - Vector2i.ONE
	var rectangle_cells: Dictionary = {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if not walkable.has(cell):
				return false
			rectangle_cells[cell] = true
	return _can_reach(rectangle_cells, first, last)


func _has_any_cell(walkable: Dictionary, rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if walkable.has(Vector2i(x, y)):
				return true
	return false


func _nearest_clear_cell(walkable: Dictionary, origin: Vector2i) -> Vector2i:
	if walkable.has(origin):
		return origin
	var best := Vector2i(-1, -1)
	var best_distance := 1 << 30
	for cell_variant: Variant in walkable:
		var cell := cell_variant as Vector2i
		var distance: int = absi(cell.x - origin.x) + absi(cell.y - origin.y)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best if best_distance <= 2 else Vector2i(-1, -1)


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
