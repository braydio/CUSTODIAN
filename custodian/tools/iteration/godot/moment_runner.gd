extends SceneTree

const DRIVER := preload("res://tools/iteration/godot/moment_action_driver.gd")
const CAPTURE := preload("res://tools/iteration/godot/moment_capture.gd")
const PROBES := preload("res://tools/iteration/godot/moment_probe_collector.gd")
const ASSERTIONS := preload("res://tools/iteration/godot/moment_assertion_evidence.gd")
const ALLOWED_OUTPUT_ROOT := "res://../reports/moment_forge"

var scenario: Dictionary = {}
var scenario_path := ""
var output_dir := ""
var capture_mode := "evidence"
var failures: Array[String] = []
var roles: Dictionary = {}
var spawned: Dictionary = {}
var scene_root: Node
var observatory: Node
var current_tick := 0
var timeline: Array[Dictionary] = []
var warnings: Array[Dictionary] = []
var driver: RefCounted
var capture: RefCounted
var probes: RefCounted


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _parse_args() or not _load_scenario() or not _prepare_output():
		_finish(false)
		return
	var simulation := scenario.get("simulation", {}) as Dictionary
	Engine.physics_ticks_per_second = int(simulation.get("physics_hz", 60))
	seed(int(scenario.get("seed", 0)))
	if not await _load_and_configure_scene():
		_finish(false)
		return
	observatory = root.get_node_or_null("/root/DevObservatory")
	if observatory != null:
		observatory.call("clear")
		observatory.event_logged.connect(_on_event_logged)
		observatory.warning_logged.connect(_on_warning_logged)
	driver = DRIVER.new()
	driver.configure({
		"roles": roles,
		"fixture": (scenario.setup as Dictionary).fixture,
		"scene_root": scene_root,
		"observatory": observatory,
	})
	probes = PROBES.new()
	probes.configure(scenario.get("probes", []), roles)
	capture = CAPTURE.new()
	if not capture.configure(root, output_dir, scenario.capture, capture_mode):
		failures.append_array(capture.failures)
		_finish(false)
		return
	for _warmup in range(int(simulation.get("warmup_ticks", 0))):
		await physics_frame
	var completed := await _run_ticks()
	var held_before_cleanup: bool = bool(driver.has_unreleased_inputs())
	var metrics := _build_metrics(completed)
	_write_json(output_dir.path_join("timeline.json"), timeline)
	_write_json(output_dir.path_join("probes.json"), {
		"records": probes.records,
		"failures": probes.failures,
	})
	_write_json(output_dir.path_join("metrics.json"), metrics)
	if observatory != null:
		var telemetry_path := output_dir.path_join("telemetry.json")
		if str(observatory.call("export_session_json", telemetry_path)).is_empty():
			failures.append("Developer Observatory export failed")
	else:
		_write_json(output_dir.path_join("telemetry.json"), {
			"events": timeline, "warnings": warnings, "counters": {},
		})
	var assertion_context := {
		"roles": roles,
		"driver": driver,
		"warnings": warnings,
		"timeline": timeline,
		"counters": observatory.counters if observatory != null else {},
		"probes": probes.records,
		"metrics": metrics,
		"output_dir": output_dir,
	}
	var assertion_results: Array[Dictionary] = ASSERTIONS.evaluate(
		scenario.get("assertions", []), assertion_context
	)
	if held_before_cleanup:
		# The authored assertion still sees the held state. Cleanup protects later runs.
		timeline.append({"tick": current_tick, "kind": "unreleased_input_cleanup"})
	driver.release_all()
	var passed: bool = completed and failures.is_empty() and probes.failures.is_empty()
	for item: Dictionary in assertion_results:
		if not bool(item.passed) and str(item.severity) == "error":
			passed = false
	_write_json(output_dir.path_join("assertions.json"), assertion_results)
	_write_json(output_dir.path_join("run_result.json"), {
		"schema": "custodian.moment_forge.run_result.v1",
		"scenario_id": str(scenario.get("id", "")),
		"scenario_path": scenario_path,
		"seed": int(scenario.get("seed", 0)),
		"completed": completed,
		"completed_tick": current_tick,
		"capture_mode": capture_mode,
		"keyframes": capture.records,
		"capture_failures": capture.failures,
		"actions": driver.results,
		"markers": driver.markers,
		"probe_failures": probes.failures,
		"assertions": assertion_results,
		"failures": failures,
		"passed": passed,
		"runtime": {
			"godot": Engine.get_version_info(),
			"physics_hz": Engine.physics_ticks_per_second,
			"renderer": RenderingServer.get_current_rendering_driver_name(),
		},
	})
	_finish(passed)


func _parse_args() -> bool:
	var args := OS.get_cmdline_user_args()
	if not args.has("--moment-forge"):
		failures.append("runner requires --moment-forge")
		return false
	var scenario_index := args.find("--moment-scenario")
	var output_index := args.find("--moment-output")
	var capture_index := args.find("--moment-capture-mode")
	if scenario_index < 0 or scenario_index + 1 >= args.size():
		failures.append("runner requires --moment-scenario")
		return false
	if output_index < 0 or output_index + 1 >= args.size():
		failures.append("runner requires --moment-output")
		return false
	scenario_path = str(args[scenario_index + 1]).simplify_path()
	output_dir = str(args[output_index + 1]).simplify_path()
	if capture_index >= 0 and capture_index + 1 < args.size():
		capture_mode = str(args[capture_index + 1])
	if capture_mode not in ["none", "evidence", "full"]:
		failures.append("invalid capture mode: %s" % capture_mode)
		return false
	var allowed := ProjectSettings.globalize_path(ALLOWED_OUTPUT_ROOT).simplify_path()
	if output_dir == allowed or not output_dir.begins_with(allowed + "/"):
		failures.append("output must be a child of %s" % allowed)
		return false
	return true


func _load_scenario() -> bool:
	var file := FileAccess.open(scenario_path, FileAccess.READ)
	if file == null:
		failures.append("could not open scenario: %s" % scenario_path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		failures.append("scenario JSON is invalid")
		return false
	scenario = parsed
	return int(scenario.get("schema_version", 0)) == 1


func _prepare_output() -> bool:
	var error := DirAccess.make_dir_recursive_absolute(output_dir)
	if error != OK:
		failures.append("could not create output directory: %s" % error_string(error))
		return false
	return true


func _load_and_configure_scene() -> bool:
	var packed := load(str(scenario.get("scene", ""))) as PackedScene
	if packed == null:
		failures.append("could not load scene: %s" % scenario.get("scene", ""))
		return false
	scene_root = packed.instantiate()
	if scene_root == null:
		failures.append("could not instantiate authored scene")
		return false
	scene_root.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(scene_root)
	current_scene = scene_root
	var setup := scenario.setup as Dictionary
	for path: String in setup.remove_nodes:
		var node := scene_root.get_node_or_null(path)
		if node != null:
			node.free()
	if not _resolve_roles(setup.roles, true):
		return false
	for spawn: Dictionary in setup.spawns:
		if not _spawn(spawn):
			return false
	if not _resolve_roles(setup.roles):
		return false
	for assignment: Dictionary in setup.properties:
		if not _apply_property(assignment):
			return false
	for item: Dictionary in setup.processing:
		var node := roles.get(str(item.get("role", ""))) as Node
		if node == null:
			failures.append("processing role unavailable: %s" % item.get("role", ""))
			return false
		if item.has("physics"):
			node.set_physics_process(bool(item.physics))
		if item.has("process"):
			node.set_process(bool(item.process))
	var viewport_size := Vector2i(int(scenario.capture.width), int(scenario.capture.height))
	root.size = viewport_size
	root.content_scale_size = viewport_size
	scene_root.process_mode = Node.PROCESS_MODE_INHERIT
	await process_frame
	await physics_frame
	return true


func _spawn(definition: Dictionary) -> bool:
	var packed := load(str(definition.get("scene", ""))) as PackedScene
	var parent := roles.get(str(definition.get("parent_role", ""))) as Node
	if packed == null or parent == null:
		failures.append("invalid spawn: %s" % definition)
		return false
	var node := packed.instantiate()
	node.name = str(definition.get("name", definition.get("id", "Spawn")))
	parent.add_child(node)
	spawned[str(definition.get("id", ""))] = node
	roles[str(definition.get("role", ""))] = node
	return true


func _resolve_roles(definitions: Dictionary, skip_spawn_roles := false) -> bool:
	for role_name: String in definitions:
		if roles.has(role_name):
			continue
		var selector := definitions[role_name] as Dictionary
		if skip_spawn_roles and selector.has("spawn_id"):
			continue
		var node: Node
		if selector.has("node_path"):
			node = scene_root.get_node_or_null(str(selector.node_path))
		elif selector.has("spawn_id"):
			node = spawned.get(str(selector.spawn_id))
		elif selector.has("group"):
			var matches := get_nodes_in_group(str(selector.group))
			if matches.size() == 1:
				node = matches[0]
			elif matches.size() > 1 and selector.has("index"):
				node = matches[int(selector.index)]
		if node == null:
			failures.append("role did not resolve uniquely: %s" % role_name)
			return false
		roles[role_name] = node
	return true


func _apply_property(assignment: Dictionary) -> bool:
	var node := roles.get(str(assignment.get("role", ""))) as Node
	var property := str(assignment.get("property", ""))
	var allowed := [
		"position", "global_position", "visible", "health", "current_health",
		"max_health", "field_patch_count", "aim_direction", "facing",
	]
	if node == null or property not in allowed:
		failures.append("unsafe or unresolved setup property: %s" % assignment)
		return false
	var value: Variant = assignment.get("value")
	if value is Array and value.size() == 2:
		value = Vector2(float(value[0]), float(value[1]))
	node.set(property, value)
	return true


func _run_ticks() -> bool:
	var by_tick := {}
	for action: Dictionary in scenario.timeline:
		var tick := int(action.tick)
		if not by_tick.has(tick):
			by_tick[tick] = []
		by_tick[tick].append(action)
	var duration := int(scenario.get("duration_ticks", 0))
	for tick in range(duration + 1):
		current_tick = tick
		driver.begin_tick(tick)
		for action: Dictionary in by_tick.get(tick, []):
			var result: Dictionary = driver.perform(action, tick)
			if not bool(result.ok):
				failures.append("tick %d action failed: %s" % [tick, result.get("error", "")])
			if bool(result.get("finish", false)):
				probes.sample_tick(tick)
				await capture.capture_tick(tick)
				return failures.is_empty()
		await physics_frame
		probes.sample_tick(tick)
		if not await capture.capture_tick(tick):
			if bool(scenario.capture.required_keyframes):
				failures.append("required keyframe capture failed at tick %d" % tick)
	return failures.is_empty()


func _build_metrics(completed: bool) -> Dictionary:
	var metrics := {
		"completed": completed,
		"duration_ticks": current_tick,
		"event_count": timeline.size(),
		"warning_count": warnings.size(),
		"action_count": driver.results.size(),
		"probe_sample_count": probes.records.size(),
	}
	for role_name: String in roles:
		var node := roles[role_name] as Node
		if node is Node2D:
			metrics[role_name] = {"position": [node.global_position.x, node.global_position.y]}
	return metrics


func _on_event_logged(kind: StringName, data: Dictionary) -> void:
	timeline.append({"tick": current_tick, "kind": str(kind), "data": data})


func _on_warning_logged(message: String, data: Dictionary) -> void:
	warnings.append({"tick": current_tick, "message": message, "data": data})


func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write output: %s" % path)
		return
	file.store_string(JSON.stringify(value, "\t") + "\n")


func _finish(success: bool) -> void:
	if not success:
		for failure: String in failures:
			printerr("[MomentForge] ", failure)
	quit(0 if success else 1)
