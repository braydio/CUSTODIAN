extends SceneTree

const ACTION_DRIVER_SCRIPT := preload(
	"res://tools/iteration/godot/moment_action_driver.gd"
)

class DeterministicProbe:
	extends Node2D

	var current_health := 100.0
	var physics_steps := 0

	func _ready() -> void:
		add_to_group("player")

	func _physics_process(_delta: float) -> void:
		physics_steps += 1
		if Input.is_action_pressed("attack_primary"):
			position.x += 2.0


var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	seed(104729)
	var output_dir := _parse_output_dir(OS.get_cmdline_user_args())
	var error := DirAccess.make_dir_recursive_absolute(output_dir)
	if error != OK:
		_failures.append("could not create output directory")
		_finish()
		return

	var fixture := Node2D.new()
	fixture.name = "MomentForgeRuntimeSmokeRoot"
	root.add_child(fixture)
	current_scene = fixture
	var probe := DeterministicProbe.new()
	probe.name = "Operator"
	fixture.add_child(probe)
	await process_frame

	var observatory := root.get_node_or_null("/root/DevObservatory")
	_assert(observatory != null, "DevObservatory autoload is missing")
	if observatory != null:
		observatory.call("clear")
		observatory.call("log_event", &"moment_forge_smoke_started", {
			"moment_tick": 0,
			"seed": 104729,
		})

	var driver: RefCounted = ACTION_DRIVER_SCRIPT.new()
	driver.call("configure", {
		"operator": probe,
		"world": fixture,
		"observatory": observatory,
	})
	probe.physics_steps = 0
	var action_results: Array[Dictionary] = []
	for tick in range(30):
		if tick == 4:
			action_results.append(
				driver.call("perform", {
					"tick": tick,
					"action": "input_press",
					"name": "attack_primary",
				}, tick) as Dictionary
			)
		elif tick == 5:
			action_results.append(
				driver.call("perform", {
					"tick": tick,
					"action": "input_release",
					"name": "attack_primary",
				}, tick) as Dictionary
			)
		await physics_frame
		await process_frame
	driver.call("release_all")

	var stable := {
		"completed": true,
		"seed": 104729,
		"duration_ticks": 30,
		"action_count": action_results.size(),
		"operator_x": snappedf(probe.position.x, 0.001),
		"physics_steps": probe.physics_steps,
	}
	_assert(stable["action_count"] == 2, "action driver count drifted")
	_assert(stable["operator_x"] == 2.0, "fixed-tick input result drifted")
	_assert(
		stable["physics_steps"] == 30,
		"fixed physics tick count drifted: %s"
		% stable["physics_steps"]
	)
	_assert(
		root.get_node_or_null("/root/MomentForge") == null,
		"Moment Forge must not exist as an autoload"
	)

	if observatory != null:
		observatory.call("log_event", &"moment_forge_smoke_completed", {
			"moment_tick": 30,
			"stable": stable,
		})
		var telemetry_path := output_dir.path_join("telemetry.json")
		var exported := str(
			observatory.call("export_session_json", telemetry_path)
		)
		_assert(not exported.is_empty(), "Observatory export failed")
		_assert(
			FileAccess.file_exists(telemetry_path),
			"Observatory telemetry file is missing"
		)

	_write_json(
		output_dir.path_join("metrics.json"),
		{
			"schema": "custodian.moment_forge.metrics.v1",
			"stable": stable,
		}
	)
	fixture.queue_free()
	await process_frame
	_finish()


func _parse_output_dir(args: PackedStringArray) -> String:
	var index := args.find("--output")
	if index >= 0 and index + 1 < args.size():
		return str(args[index + 1]).simplify_path()
	return ProjectSettings.globalize_path(
		"res://../reports/moment_forge/_validation/"
		+ "runtime_smoke_%d" % OS.get_process_id()
	)


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write metrics JSON")
		return
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MomentForgeRuntimeSmoke] PASS")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[MomentForgeRuntimeSmoke] %s" % failure)
	quit(1)
