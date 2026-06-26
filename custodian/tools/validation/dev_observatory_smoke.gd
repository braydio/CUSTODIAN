extends SceneTree

const DevObservatoryScript := preload("res://game/systems/debug/dev_observatory.gd")
const SectorHeatmapScript := preload("res://game/systems/world/sector_heatmap.gd")


func _init() -> void:
	var observatory := DevObservatoryScript.new()
	observatory.name = "DevObservatory"
	root.add_child(observatory)

	var heatmap := SectorHeatmapScript.new()
	heatmap.name = "SectorHeatmap"
	root.add_child(heatmap)

	observatory.log_event("smoke", {"ok": true})
	observatory.increment("shots_fired", 2)
	observatory.set_gauge("active_enemies", 4)
	heatmap.add(Vector2(64, 64), "player_presence", 1.0)
	heatmap.add(Vector2(64, 64), "player_presence", 0.5)

	var failures: Array[String] = []
	if observatory.get_recent_events("", 1).is_empty():
		failures.append("observatory did not retain recent event")
	if int(observatory.counters.get("shots_fired", 0)) != 2:
		failures.append("observatory counter incorrect")
	if int(observatory.gauges.get("active_enemies", 0)) != 4:
		failures.append("observatory gauge incorrect")
	if heatmap.get_value(Vector2(64, 64), "player_presence") < 1.49:
		failures.append("heatmap accumulation incorrect")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("dev_observatory_smoke ok")
	quit(0)

