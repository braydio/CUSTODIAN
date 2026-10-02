extends SceneTree

const MAP_SCENE := preload("res://game/world/hub/first_set/hub_first_set_map.tscn")
const PLAYTEST_SCENE := preload("res://scenes/hub_first_set_blockout_playtest.tscn")
const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const EXPECTED_MARKERS := {
	"Spawn_SouthReach": Vector2(-6, 162),
	"AdjudicationDais": Vector2(0, -3136),
	"ForumSouth": Vector2(0, -2464),
	"ForumNorth": Vector2(0, -3904),
	"WestGardenThreshold": Vector2(-1280, -3200),
	"EastMusterThreshold": Vector2(1280, -3104),
	"SepulcherInteriorSample": Vector2(-1984, -3200),
	"CrownTransfer": Vector2(1088, -4672),
	"Spawn_TwinReturn": Vector2(864, -4672),
	"MusterEntry": Vector2(1472, -3008),
	"MusterCenter": Vector2(1952, -3008),
	"Spawn_CampaignReturn": Vector2(2592, -3008),
	"ContinuityPort": Vector2(2944, -3008),
	"CampaignExitThreshold": Vector2(3136, -3008),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := MAP_SCENE.instantiate() as HubFirstSetMap
	root.add_child(map)
	await process_frame
	assert(map.camera_bounds == LAYOUT.WORLD_BOUNDS)
	assert(map.blockout_grid.authored_cell_size == 32.0)
	assert(map.blockout_grid.map_size_cells == Vector2i(188, 190))
	assert(map.blockout_grid.position == LAYOUT.GRID_ORIGIN)
	assert(LAYOUT.GRID_ORIGIN == Vector2(-2816, -5504))
	assert(LAYOUT.GRID_SIZE * LAYOUT.CELL_SIZE == LAYOUT.WORLD_BOUNDS.size)
	assert(LAYOUT.THRESHOLD_VOLUME == Rect2(3104, -3072, 96, 128))
	assert(map.has_spawn(&"Spawn_SouthReach"))
	assert(map.get_spawn_position(&"Spawn_SouthReach") == Vector2(-6.0, 162.0))
	assert(map.get_node("Markers").get_child_count() == LAYOUT.MARKERS.size())
	for marker_name: Variant in LAYOUT.MARKERS:
		assert(LAYOUT.MARKERS[marker_name] == EXPECTED_MARKERS[marker_name], "layout marker drift: %s" % marker_name)
		var marker := map.get_node("Markers/%s" % str(marker_name)) as Marker2D
		assert(marker != null)
		assert(marker.position == LAYOUT.MARKERS[marker_name])
		var map_label := marker.get_node("MapLabel") as Label
		assert(map_label.position == LAYOUT.MARKER_LABEL_OFFSETS.get(str(marker_name), Vector2(24, -30)))
		assert(map.authored_navigation.is_world_position_walkable(marker.position), "marker not walkable: %s" % marker_name)
	for rect_name: Variant in LAYOUT.ENVELOPES:
		var rect: Rect2i = LAYOUT.ENVELOPES[rect_name]
		assert(rect.size.x >= 4 and rect.size.y >= 4, "route envelope below minimum width: %s" % rect_name)
		if str(rect_name).ends_with("connector"):
			assert(rect.size.x == 4, "connector must preserve 128px route width: %s" % rect_name)
		for cell in [rect.position, rect.end - Vector2i.ONE]:
			assert(map.blockout_grid.is_walkable_cell(cell), "missing envelope cell %s / %s" % [rect_name, cell])
	var spawn := LAYOUT.marker_cell(&"Spawn_SouthReach")
	for target_name in ["ForumSouth", "AdjudicationDais", "ForumNorth", "CrownTransfer"]:
		assert(_can_reach(map.blockout_grid, spawn, LAYOUT.marker_cell(StringName(target_name))), "main route disconnected at %s" % target_name)
	for target_name in ["WestGardenThreshold", "SepulcherInteriorSample", "EastMusterThreshold", "MusterCenter", "ContinuityPort", "CampaignExitThreshold"]:
		assert(_can_reach(map.blockout_grid, LAYOUT.marker_cell(&"AdjudicationDais"), LAYOUT.marker_cell(StringName(target_name))), "branch disconnected at %s" % target_name)
	for target_name in ["ForumSouth", "AdjudicationDais", "ForumNorth", "WestGardenThreshold", "SepulcherInteriorSample", "EastMusterThreshold", "MusterCenter", "ContinuityPort", "CampaignExitThreshold"]:
		assert(not map.authored_navigation.compute_path(LAYOUT.MARKERS["Spawn_SouthReach"], LAYOUT.MARKERS[target_name]).is_empty(), "navigation provider has no route to %s" % target_name)
	assert(_all_walkable_connected(map.blockout_grid), "isolated walkable island")
	var road := map.get_node("RoadPresentationRoot") as RoadOfWitnessesPrototype
	assert(road != null and road.environment_root.get_child_count() == road.MODULES.size())
	assert(road.collision_root.get_child_count() == 0, "legacy Road collision remains enabled")
	for index in road.MODULES.size():
		var spec: Dictionary = road.MODULES[index]
		var module := road.environment_root.get_child(index) as Node2D
		assert(module.position == spec.position, "Road module registration changed: %s" % spec.id)
		assert(module.get_node("Underlay").texture != null and module.get_node("Foreground").texture != null)
	assert(map.boundary_collision.get_child_count() > 0)
	assert(map.get_node("Interactables").get_child_count() == 0)
	assert(map.get_node("TransitionMarkers").get_child_count() == 0)
	assert(map.find_child("WorldContractBootstrap", true, false) == null)
	assert(map.find_child("WorldTransitionManager", true, false) == null)
	print("hub_first_set_blockout_smoke: PASS cells=%d boundaries=%d markers=%d" % [map.blockout_grid.get_walkable_cells().size(), map.boundary_collision.get_child_count(), LAYOUT.MARKERS.size()])
	map.free()
	var playtest := PLAYTEST_SCENE.instantiate()
	root.add_child(playtest)
	await process_frame
	var playtest_map := playtest.get_node("World/Level") as HubFirstSetMap
	var operator := playtest.get_node("World/Operator") as Node2D
	var camera := playtest.get_node("World/Camera2D") as Camera2D
	assert(playtest_map != null and operator != null and camera != null)
	assert(operator.global_position == Vector2(-6.0, 162.0), "real Operator did not spawn at South Reach")
	var camera_bounds: Rect2 = camera.get("map_bounds")
	assert(camera_bounds == LAYOUT.WORLD_BOUNDS.grow(float(camera.get("map_padding"))), "playtest camera bounds are not derived from first-set bounds")
	assert(playtest_map.find_child("Operator", true, false) == null, "production map owns an Operator")
	assert(playtest_map.find_child("Camera2D", true, false) == null, "production map owns a camera")
	playtest.free()
	quit(0)


func _can_reach(grid: AuthoredBlockoutGrid2D, start: Vector2i, target: Vector2i) -> bool:
	var pending: Array[Vector2i] = [start]
	var seen: Dictionary = {}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if cell == target:
			return true
		if seen.has(cell) or not grid.is_walkable_cell(cell):
			continue
		seen[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			pending.append(cell + direction)
	return false


func _all_walkable_connected(grid: AuthoredBlockoutGrid2D) -> bool:
	var walkable: Dictionary = grid.get_walkable_cells()
	if walkable.is_empty():
		return false
	var first: Vector2i = walkable.keys()[0]
	var pending: Array[Vector2i] = [first]
	var seen: Dictionary = {}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if seen.has(cell) or not walkable.has(cell):
			continue
		seen[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			pending.append(cell + direction)
	return seen.size() == walkable.size()
