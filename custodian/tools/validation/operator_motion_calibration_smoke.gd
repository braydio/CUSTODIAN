extends SceneTree

const HARNESS := preload("res://tools/debug/operator_motion_calibration.gd")


func _init() -> void:
	var fixture_path := "user://operator_motion_calibration_fixture.json"
	var fixture := {
		"schema": "custodian.operator_motion_request.v1",
		"identity": {"profile": "melee_1h", "group": "attack", "action": "fast_01", "direction": "e"},
		"source": "runtime", "fps": 12.0, "travel_px": 128.0,
		"curve": "attack_lunge", "ground": "ritualant_cavern", "mode": "treadmill",
	}
	var file := FileAccess.open(fixture_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture)); file.close()
	var harness = HARNESS.new()
	var error: String = harness.load_request(fixture_path)
	if not error.is_empty() or harness.identity_key != "melee_1h/attack/fast_01/e" or harness.frame_count != 10:
		_fail("identity/runtime animation did not resolve: %s" % error); return
	var treadmill: Vector2 = harness.sample_offsets(1.0).treadmill_ground
	var world: Vector2 = harness.sample_offsets(1.0).world_actor
	if not is_equal_approx(treadmill.x, -128.0) or not is_equal_approx(world.x, 128.0):
		_fail("terminal displacement mismatch"); return
	if not is_equal_approx(harness.sample_offsets(0.6).progress, harness.curve_progress(0.6)):
		_fail("modes do not share normalized curve"); return
	harness.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("[OperatorMotionCalibrationSmoke] PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("[OperatorMotionCalibrationSmoke] %s" % message)
	quit(1)
