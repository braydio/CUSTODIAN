extends SceneTree

## Exercises the live Operator collision, zone regions, console activation and
## gameplay camera across the Crèche's north passage and back.

const Scene := preload("res://scenes/awakening_first_return.tscn")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const OUTPUT := "res://../reports/awakening_creche_gameplay_review"
const NORTH_TARGET := Vector2(0, -640)
const RETURN_TARGET := Vector2(0, 160)
const MAX_TICKS_PER_LEG := 420

var _failures: Array[String] = []
var _viewport: SubViewport
var _scene: Node2D
var _operator: CharacterBody2D
var _camera: Camera2D
var _transition_log: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_scene = Scene.instantiate() as Node2D
	_viewport.add_child(_scene)
	_operator = _scene.get_node("World/Operator") as CharacterBody2D
	_camera = _scene.get_node("World/Camera2D") as Camera2D
	_camera.operator_ref = _operator
	_camera.follow_target = _operator
	var output := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	await _settle(20)
	await _capture(output, "10_actual_operator_wake")

	var console := _scene.get_node("World/AwakeningZones/Zone01_Creche/Interactables/CrecheConsole")
	var fx := _scene.get_node("World/AwakeningZones/Zone01_Creche/SetPieces/CrecheConsoleBody/ScreenAnchor/CrecheConsoleActivation") as AnimatedSprite2D
	console.call("interact", _operator)
	var frame_zero := await _wait_for_fx_frame(fx, 0, 90)
	await _capture(output, "11_actual_console_fx_frame_0")
	var frame_three := await _wait_for_fx_frame(fx, 3, 90)
	await _capture(output, "12_actual_console_fx_frame_3")
	var frame_seven := await _wait_for_fx_frame(fx, 7, 90)
	await _capture(output, "13_actual_console_fx_frame_7")
	if not frame_zero or not frame_three or not frame_seven:
		_fail("actual console interaction did not expose frames 0, 3, and 7")
	if not _scene.opening_console_acknowledged:
		_fail("actual console interaction did not acknowledge the readout")
	await _settle(70)
	if fx.visible or fx.is_playing():
		_fail("actual screen FX did not finish and hide")

	var start := _operator.global_position
	var north_ok := await _drive_to(NORTH_TARGET, &"zone02_ambulatory", 2, output, "14_north")
	if not north_ok:
		_fail("live Operator did not cross into Zone02 through the north passage")
	var north_end := _operator.global_position
	var return_ok := await _drive_to(RETURN_TARGET, &"zone01_creche", 1, output, "15_return")
	if not return_ok:
		_fail("live Operator did not return through the north passage into Zone01")
	await _capture(output, "16_actual_operator_returned")
	if _operator.global_position.distance_to(start) > 12.0:
		_fail("live Operator did not return near the wake anchor")
	if north_end.y >= -448.0 or not Layout.is_point_walkable(north_end):
		_fail("north-passage capture point is outside the visible walkable destination")
	_write_report(output, start, north_end)
	if _failures.is_empty():
		print("awakening_creche_live_traversal_smoke: PASS north_zone=2 return_zone=1 transitions=", _transition_log)
		quit(0)
	else:
		for failure in _failures:
			push_error("awakening_creche_live_traversal_smoke: " + failure)
		quit(1)


func _drive_to(target: Vector2, expected_zone: StringName, expected_index: int,
		output: String, stem: String) -> bool:
	var transitioned := false
	var connector_capture := false
	var previous_position := _operator.global_position
	for tick in MAX_TICKS_PER_LEG:
		var offset := target - _operator.global_position
		if offset.length() <= 6.0:
			break
		_operator.call("process_input", offset.normalized(), Vector2.ZERO, false)
		await physics_frame
		var position := _operator.global_position
		if position.distance_to(previous_position) > 8.0:
			_fail("Operator teleported during %s movement: %s to %s" % [stem, str(previous_position), str(position)])
		previous_position = position
		if not connector_capture and ((stem == "14_north" and position.y <= -352.0) or (stem == "15_return" and position.y >= -352.0)):
			connector_capture = true
			await _capture(output, stem + "_operator_in_connector")
		if int(_scene.current_zone_index) == expected_index and not transitioned:
			transitioned = true
			var zone_id := expected_zone
			_transition_log.append({"phase": stem + "_crossing", "zone": String(zone_id), "position": [position.x, position.y], "tick": tick})
			print(stem, " crossing zone=", zone_id, " position=", position, " tick=", tick)
	_operator.call("process_input", Vector2.ZERO, Vector2.ZERO, false)
	await _settle(6)
	var reached := _operator.global_position.distance_to(target) <= 12.0
	if reached:
		await _capture(output, stem + "_destination")
	return transitioned and reached and int(_scene.current_zone_index) == expected_index


func _wait_for_fx_frame(fx: AnimatedSprite2D, target: int, max_frames: int) -> bool:
	for _tick in max_frames:
		if fx.visible and fx.is_playing() and fx.frame == target:
			await process_frame
			return true
		await physics_frame
	return false


func _capture(output: String, name: String) -> void:
	for _frame in 2:
		RenderingServer.force_draw(false)
		await process_frame
	var image := _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("capture has no rendered pixels: " + name)
		return
	var path := output.path_join(name + ".png")
	if image.save_png(path) != OK:
		_fail("could not save runtime capture: " + path)


func _settle(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _write_report(output: String, start: Vector2, north_end: Vector2) -> void:
	var report := {
		"schema": "custodian.awakening_creche_live_traversal.v1",
		"passed": _failures.is_empty(),
		"failures": _failures,
		"start_position": [start.x, start.y],
		"north_position": [north_end.x, north_end.y],
		"return_position": [_operator.global_position.x, _operator.global_position.y],
		"return_zone_index": _scene.current_zone_index,
		"transitions": _transition_log,
		"console_fx_frames": [0, 3, 7],
		"screenshots": ["10_actual_operator_wake.png", "11_actual_console_fx_frame_0.png", "12_actual_console_fx_frame_3.png", "13_actual_console_fx_frame_7.png", "14_north_destination.png", "15_return_destination.png", "16_actual_operator_returned.png"],
	}
	var file := FileAccess.open(output.path_join("live_traversal_result.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
