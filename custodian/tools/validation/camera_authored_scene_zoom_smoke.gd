extends SceneTree

const CAMERA_SCRIPT := preload("res://game/world/camera.gd")
const SCALE := 2.25
const PROFILES := [
	"base_zoom", "move_zoom", "interaction_zoom", "melee_zoom",
	"melee_move_zoom", "ranged_zoom", "ranged_move_zoom",
	"hitstun_zoom", "sector_entry_zoom", "heavy_zoom",
]

var _failures: Array[String] = []


func _initialize() -> void:
	var camera := CAMERA_SCRIPT.new() as Camera2D
	root.add_child(camera)
	await process_frame
	var baselines := {}
	for property_name in PROFILES:
		baselines[property_name] = camera.get(property_name) as Vector2
	camera.call("apply_authored_scene_zoom_scale", SCALE, Vector2(2.5, 2.5))
	camera.call("apply_authored_scene_zoom_scale", SCALE, Vector2(2.5, 2.5))
	for property_name in PROFILES:
		var expected: Vector2 = baselines[property_name] * SCALE
		if not (camera.get(property_name) as Vector2).is_equal_approx(expected):
			_fail("authored zoom profile mismatch after repeated apply: %s" % property_name)
	var base_zoom: Vector2 = camera.get("base_zoom")
	if camera.zoom != base_zoom or camera.get("target_zoom") != base_zoom or camera.get("_locked_zoom") != base_zoom:
		_fail("locked, current, and target zoom are incoherent")
	if camera.get("max_zoom") != Vector2(2.5, 2.5):
		_fail("authored max zoom override was not applied")
	if float(camera.call("get_authored_scene_zoom_scale")) != SCALE:
		_fail("authored zoom scale did not remain idempotent")
	if _failures.is_empty():
		print("Camera authored-scene zoom smoke: PASS")
	else:
		for failure in _failures:
			push_error("Camera authored-scene zoom smoke: %s" % failure)
	camera.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)
