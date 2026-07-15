extends SceneTree

const DevObservatoryScript := preload("res://game/systems/debug/dev_observatory.gd")
const SectorHeatmapScript := preload("res://game/systems/world/sector_heatmap.gd")
const OVERLAY_SCENE_PATH := "res://scenes/debug/dev_observatory_overlay.tscn"
const SMOKE_EXPORT_PATH := "user://dev_observatory/smoke_session.json"
const LATEST_EXPORT_PATH := "user://dev_observatory/latest_session.json"
const BLOCKER_PATH := "user://dev_observatory_export_blocker"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var observatory := DevObservatoryScript.new()
	observatory.name = "DevObservatory"
	root.add_child(observatory)
	await process_frame

	var heatmap := SectorHeatmapScript.new()
	heatmap.name = "SectorHeatmap"
	root.add_child(heatmap)

	observatory.log_event("smoke", {"ok": true})
	observatory.increment("shots_fired", 2)
	observatory.accumulate("stamina_spent_test", 1.25)
	observatory.accumulate("stamina_spent_test", 0.75)
	observatory.set_gauge("active_enemies", 4)
	observatory.set_gauge("json_safe_types", {
		"vector2": Vector2(12.5, -3.0),
		"vector2i": Vector2i(7, 9),
		"color": Color(0.2, 0.4, 0.6, 0.8),
		"string_name": &"observed",
		"node_path": NodePath("World/Operator"),
		"array": [true, 3, 4.5, "ok"],
		"node": observatory,
	})
	heatmap.add(Vector2(64, 64), "player_presence", 1.0)
	heatmap.add(Vector2(64, 64), "player_presence", 0.5)

	var failures: Array[String] = []
	if observatory.get_recent_events(1).is_empty():
		failures.append("observatory did not retain recent event")
	if int(observatory.counters.get("shots_fired", 0)) != 2:
		failures.append("observatory counter incorrect")
	if not is_equal_approx(float(observatory.counters.get("stamina_spent_test", 0.0)), 2.0):
		failures.append("observatory numeric accumulation incorrect")
	if int(observatory.gauges.get("active_enemies", 0)) != 4:
		failures.append("observatory gauge incorrect")
	if heatmap.get_value(Vector2(64, 64), "player_presence") < 1.49:
		failures.append("heatmap accumulation incorrect")
	if observatory.process_mode != Node.PROCESS_MODE_ALWAYS:
		failures.append("observatory must process while the tree is paused")
	if not InputMap.has_action("debug_observatory"):
		failures.append("debug_observatory input action missing")
	if not _action_contains_key("debug_observatory", KEY_F9):
		failures.append("debug_observatory must be bound to F9")
	if not InputMap.has_action("debug_observatory_export"):
		failures.append("debug_observatory_export input action missing")
	if not _action_contains_key("debug_observatory_export", KEY_F10):
		failures.append("debug_observatory_export must be bound to F10")
	if _action_contains_key("pause", KEY_F9):
		failures.append("pause must not be bound to F9")
	if not ResourceLoader.exists(OVERLAY_SCENE_PATH):
		failures.append("canonical observatory overlay scene missing")

	_remove_file_if_present(SMOKE_EXPORT_PATH)
	var had_latest_export := FileAccess.file_exists(LATEST_EXPORT_PATH)
	var previous_latest_export := _read_text(LATEST_EXPORT_PATH) if had_latest_export else ""
	var event_count_before_export := observatory.events.size()
	var exported_path: String = observatory.export_session_json(SMOKE_EXPORT_PATH)
	if exported_path != SMOKE_EXPORT_PATH or not FileAccess.file_exists(SMOKE_EXPORT_PATH):
		failures.append("observatory stable export was not written")
	if observatory.last_export_path != SMOKE_EXPORT_PATH or observatory.last_export_absolute_path.is_empty():
		failures.append("observatory did not expose the last export path for runtime confirmation")
	if observatory.events.size() != event_count_before_export + 1:
		failures.append("export must retain the event buffer and append one success event")
	elif StringName(observatory.events[-1].get("kind", &"")) != &"observatory_session_exported":
		failures.append("export must emit observatory_session_exported")

	var payload := _read_json(SMOKE_EXPORT_PATH)
	for required_key in ["schema", "metadata", "engine", "session", "scene", "counters", "gauges", "warnings", "events"]:
		if not payload.has(required_key):
			failures.append("export payload missing %s" % required_key)
	if String(payload.get("schema", "")) != "custodian.dev_observatory.session.v1":
		failures.append("export schema mismatch")
	var safe_values: Dictionary = (payload.get("gauges", {}) as Dictionary).get("json_safe_types", {})
	if not safe_values.get("vector2", {}) is Dictionary or float(safe_values.get("vector2", {}).get("x", 0.0)) != 12.5:
		failures.append("Vector2 was not converted safely")
	if String(safe_values.get("string_name", "")) != "observed" or String(safe_values.get("node_path", "")) != "World/Operator":
		failures.append("StringName or NodePath was not converted safely")
	if not safe_values.get("color", {}) is Dictionary or String(safe_values.get("color", {}).get("html", "")).is_empty():
		failures.append("Color was not converted safely")
	if String((safe_values.get("node", {}) as Dictionary).get("node_name", "")) != String(observatory.name):
		failures.append("Node metadata was not converted safely")

	var timestamped_path: String = observatory.export_timestamped_session_json()
	var timestamped_name := timestamped_path.get_file()
	var timestamp_regex := RegEx.create_from_string("^session_[0-9]{8}_[0-9]{6}\\.json$")
	if timestamped_path.is_empty() or timestamp_regex.search(timestamped_name) == null or not FileAccess.file_exists(timestamped_path):
		failures.append("timestamped observatory export path is invalid")
	if observatory.last_export_path != timestamped_path:
		failures.append("timestamped export should remain the visible last-export path")
	if not FileAccess.file_exists(LATEST_EXPORT_PATH):
		failures.append("timestamped export must refresh latest_session.json")

	_remove_file_if_present(BLOCKER_PATH)
	var blocker := FileAccess.open(BLOCKER_PATH, FileAccess.WRITE)
	if blocker == null:
		failures.append("could not create export failure fixture")
	else:
		blocker.store_string("block directory creation")
		blocker.close()
		var warnings_before_failure := observatory.warnings.size()
		var failed_path: String = observatory.export_session_json("%s/session.json" % BLOCKER_PATH)
		if not failed_path.is_empty() or observatory.warnings.size() != warnings_before_failure + 1:
			failures.append("export failure must return empty and emit an observatory warning")

	_remove_file_if_present(SMOKE_EXPORT_PATH)
	_remove_file_if_present(timestamped_path)
	if had_latest_export:
		_write_text(LATEST_EXPORT_PATH, previous_latest_export)
	else:
		_remove_file_if_present(LATEST_EXPORT_PATH)
	_remove_file_if_present(BLOCKER_PATH)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("dev_observatory_smoke ok")
	quit(0)


func _action_contains_key(action: StringName, keycode: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event == null:
			continue
		if key_event.keycode == keycode or key_event.physical_keycode == keycode or key_event.key_label == keycode:
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}


func _remove_file_if_present(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()
