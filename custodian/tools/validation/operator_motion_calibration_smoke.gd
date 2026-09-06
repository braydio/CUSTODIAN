extends SceneTree

const HARNESS := preload("res://tools/debug/operator_motion_calibration.gd")


func _init() -> void:
	var fixture_path := "user://operator_motion_calibration_fixture.json"
	var fixture := {
		"schema": "custodian.operator_motion_request.v2",
		"identity": {"profile": "melee_1h", "group": "attack", "action": "fast_01", "direction": "e"},
		"source": "runtime", "fps": 12.0, "travel_px": 128.0,
		"curve": "linear", "ground": "ritualant_cavern", "mode": "treadmill",
		"loop": true, "loop_cycles": 3,
	}
	var file := FileAccess.open(fixture_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture)); file.close()
	var harness = HARNESS.new()
	var error: String = harness.load_request(fixture_path)
	if not error.is_empty() or harness.identity_key != "melee_1h/attack/fast_01/e" or harness.frame_count != 10:
		_fail("identity/runtime animation did not resolve: %s" % error); return
	var first_cycle := harness.sample_motion(harness.cycle_duration())
	if first_cycle.cycle_index != 1 or not is_equal_approx(first_cycle.continuous_position, 128.0):
		_fail("first cycle did not preserve cumulative displacement"); return
	var before_reset := harness.sample_motion(harness.cycle_duration() * 2.999)
	var after_reset := harness.sample_motion(harness.cycle_duration() * 3.0)
	if before_reset.cycle_index != 2 or after_reset.cycle_index != 0 or not is_zero_approx(after_reset.continuous_position):
		_fail("three-cycle reset mismatch"); return
	if not is_equal_approx(harness.sample_motion(harness.cycle_duration() * 0.6).progress, harness.curve_progress(0.6)):
		_fail("modes do not share normalized curve"); return
	var treadmill := harness.presentation_offsets(first_cycle)
	if not is_equal_approx((treadmill.world as Vector2).x, -128.0) or treadmill.actor != Vector2.ZERO:
		_fail("treadmill displacement mismatch"); return
	harness.request["mode"] = "world"
	var world_sample := harness.sample_motion(harness.cycle_duration() * 1.5)
	var world := harness.presentation_offsets(world_sample)
	if not is_equal_approx((world.world as Vector2).x, -96.0) or not is_equal_approx((world.actor as Vector2).x, 192.0):
		_fail("WORLD follow displacement mismatch"); return
	if harness.ground_presets.size() != 7 or harness.ground_texture == null:
		_fail("shared ground registry did not load"); return
	root.add_child(harness)
	harness._build_runtime_view()
	harness.elapsed_sec = harness.cycle_duration() * 0.5
	harness._update_presentation()
	if harness.animation_layers.is_empty() or harness.animation_layers[0].frame != 5:
		_fail("requested review FPS did not drive runtime frame sampling"); return
	if harness.animation_layers[0].is_playing():
		_fail("runtime SpriteFrames retained its independent playback clock"); return
	harness.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("[OperatorMotionCalibrationSmoke] PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("[OperatorMotionCalibrationSmoke] %s" % message)
	quit(1)
