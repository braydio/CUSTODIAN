extends SceneTree

const LOWER := preload("res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := LOWER.instantiate() as AshBellLowerQuarter
	root.add_child(level)
	await process_frame
	var provider := level.get_node("NavigationRoot/AuthoredNavigationProvider") as AuthoredNavigationProvider2D
	assert(provider != null)
	var revision := provider.get_navigation_revision()
	var start := level.cell_center(Vector2i(64, 87))
	var detour := level.cell_center(Vector2i(39, 58))
	var path := provider.compute_path(start, detour)
	assert(path.size() > 2, "authored route should produce a nontrivial path")
	for point in path:
		assert(provider.is_world_position_walkable(point))
	var collapse_center := level.cell_center(Vector2i(63, 72))
	assert(not provider.is_world_position_walkable(collapse_center))
	(level.get_node("POIRoot/EvacAnnunciator") as CivicRelay2D).set_repaired(true)
	assert(provider.get_navigation_revision() > revision)
	assert(provider.is_world_position_walkable(level.cell_center(Vector2i(39, 55))))
	var station_revision := provider.get_navigation_revision()
	(level.get_node("POIRoot/StationIXTransitInterlock") as CivicRelay2D).set_repaired(true)
	assert(provider.get_navigation_revision() > station_revision)
	print("ash_bell_authored_navigation_smoke: PASS path_points=%d revision=%d" % [path.size(), provider.get_navigation_revision()])
	quit(0)
