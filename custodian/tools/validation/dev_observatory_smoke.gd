extends SceneTree

const DevObservatoryScript := preload("res://game/systems/debug/dev_observatory.gd")
const SectorHeatmapScript := preload("res://game/systems/world/sector_heatmap.gd")
const OVERLAY_SCENE_PATH := "res://scenes/debug/dev_observatory_overlay.tscn"


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
	observatory.set_gauge("active_enemies", 4)
	heatmap.add(Vector2(64, 64), "player_presence", 1.0)
	heatmap.add(Vector2(64, 64), "player_presence", 0.5)

	var failures: Array[String] = []
	if observatory.get_recent_events(1).is_empty():
		failures.append("observatory did not retain recent event")
	if int(observatory.counters.get("shots_fired", 0)) != 2:
		failures.append("observatory counter incorrect")
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
	if _action_contains_key("pause", KEY_F9):
		failures.append("pause must not be bound to F9")
	if not ResourceLoader.exists(OVERLAY_SCENE_PATH):
		failures.append("canonical observatory overlay scene missing")

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
