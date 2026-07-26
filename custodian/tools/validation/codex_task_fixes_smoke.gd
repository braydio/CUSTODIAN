extends SceneTree

const SCRAP_SCENE := preload("res://game/actors/items/scrap_pickup.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const CAMERA_SCRIPT := preload("res://game/world/camera.gd")
const COMBAT_CONSTANTS := preload("res://game/systems/combat/combat_constants.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture := Node2D.new()
	fixture.name = "CodexTaskFixesFixture"
	root.add_child(fixture)
	await process_frame

	var scrap := SCRAP_SCENE.instantiate() as Area2D
	fixture.add_child(scrap)
	scrap.call("_play_pickup_tone")
	var scrap_audio := fixture.get_node_or_null("ScrapPickupAudio") as AudioStreamPlayer2D
	_assert(scrap_audio != null, "scrap pickup did not create its collection cue")
	if scrap_audio != null:
		_assert(
			scrap_audio.stream.resource_path.ends_with("pickup_collect_01.wav"),
			"scrap pickup uses the wrong collection cue"
		)

	var operator := OPERATOR_SCENE.instantiate()
	fixture.add_child(operator)
	var warning_audio := operator.call("_play_low_health_warning") as AudioStreamPlayer2D
	_assert(warning_audio != null, "low-health warning did not create audio")
	if warning_audio != null:
		_assert(
			is_equal_approx(warning_audio.volume_db, -1.0),
			"low-health warning was not raised to the louder -1 dB level"
		)

	var grunt := GRUNT_SCENE.instantiate()
	fixture.add_child(grunt)
	grunt.set("crit_damage_threshold", 9999.0)
	grunt.set("stagger_damage_threshold", 9999.0)
	grunt.call(
		"_apply_reaction",
		1.0,
		COMBAT_CONSTANTS.HitStrength.HEAVY
	)
	_assert(
		float(grunt.get("_stagger_timer")) > 0.0,
		"a low-damage heavy hit did not guarantee enemy stagger"
	)
	_assert(
		is_zero_approx(float(grunt.get("_recoil_timer"))),
		"a guaranteed heavy stagger incorrectly fell back to light recoil"
	)

	var camera := CAMERA_SCRIPT.new() as Camera2D
	fixture.add_child(camera)
	camera.call("on_critical_hit", Vector2.RIGHT)
	_assert(
		is_equal_approx(
			float(camera.get("_shake_power")),
			float(camera.get("critical_hit_shake_power"))
		),
		"critical hit did not apply its dedicated screen shake"
	)

	fixture.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[CodexTaskFixesSmoke] PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("[CodexTaskFixesSmoke] %s" % failure)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
