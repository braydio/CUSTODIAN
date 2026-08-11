extends SceneTree

const PROCGEN_MAP := preload("res://game/world/procgen/proc_gen_map.tscn")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture := Node2D.new()
	fixture.name = "ProcgenRenderIsolationSmokeRoot"
	root.add_child(fixture)
	current_scene = fixture
	var map := PROCGEN_MAP.instantiate()
	fixture.add_child(map)
	await process_frame

	var controller := map
	var nav := map.get_node_or_null("NavigationRegion2D") as NavigationRegion2D
	var depth := map.get_node_or_null("DepthBackdrop") as CanvasItem
	var floor := map.get_node_or_null("NavigationRegion2D/Floor") as CanvasItem
	var walls := map.get_node_or_null("NavigationRegion2D/Walls") as CanvasItem
	var base := map.get_node_or_null("NavigationRegion2D/NonWalkableSurfaceBase") as CanvasItem
	var overlay := map.get_node_or_null("NavigationRegion2D/NonWalkableSurfaceOverlay") as CanvasItem
	var foliage := map.get_node_or_null("NavigationRegion2D/FoliageLayer") as CanvasItem
	var props := map.get_node_or_null("NavigationRegion2D/PropLayer") as CanvasItem
	_assert_true(controller != null and controller.is_in_group("procgen_render_isolation"), "ProcGen controller must register for render isolation")
	_assert_true(nav != null and nav.enabled, "navigation must begin enabled")

	var collision_body := StaticBody2D.new()
	collision_body.name = "DiagnosticRuntimeWallBody"
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	collision_body.add_child(collision_shape)
	nav.add_child(collision_body)

	controller.call("set_procgen_major_visuals_visible", false)
	for item in [depth, floor, walls, base, overlay]:
		_assert_true(item != null and not item.visible, "major procgen CanvasItems must hide")
	_assert_true(nav.enabled and nav.process_mode != Node.PROCESS_MODE_DISABLED, "navigation must remain enabled while visuals are hidden")
	_assert_true(collision_body.process_mode != Node.PROCESS_MODE_DISABLED and not collision_shape.disabled, "runtime collision must remain enabled while visuals are hidden")
	_assert_true(foliage != null and foliage.visible, "P1 isolation must not hide foliage")
	_assert_true(props != null and props.visible, "P1 isolation must not hide props")
	var direct_status := controller.call("get_procgen_render_isolation_status") as Dictionary
	_assert_true(not bool(direct_status.get("major_visuals_enabled", true)), "controller status should report major visuals disabled")

	var observatory := root.get_node_or_null("DevObservatory")
	if observatory != null:
		observatory.call("_sample_render_state_gauges")
		var gauges := observatory.get("gauges") as Dictionary
		_assert_true(not bool(gauges.get("render_procgen_major_visuals_enabled", true)), "Observatory should report major visuals disabled")
		_assert_true(not bool(gauges.get("render_procgen_floor_enabled", true)), "Observatory should report floor disabled")
		_assert_true(not bool(gauges.get("render_procgen_walls_enabled", true)), "Observatory should report walls disabled")
		_assert_true(not bool(gauges.get("render_procgen_depth_backdrop_enabled", true)), "Observatory should report backdrop disabled")

	controller.call("set_procgen_major_visuals_visible", true)
	for item in [depth, floor, walls, base, overlay]:
		_assert_true(item != null and item.visible, "major procgen CanvasItems must restore")
	_assert_true(nav.enabled and not collision_shape.disabled, "navigation/collision must remain enabled after restore")

	fixture.queue_free()
	await process_frame
	if _failed:
		push_error("procgen_render_isolation_smoke failed")
		quit(1)
		return
	print("PROCGEN_RENDER_ISOLATION_SMOKE: PASS")
	quit(0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
