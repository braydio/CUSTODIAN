extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var _failed := false


func _init() -> void:
	root.size = Vector2i(1366, 768)
	_run.call_deferred()


func _run() -> void:
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var ui := game.get_node_or_null("UI")
	ui.call("open_command_terminal")
	ui.call("_set_terminal_page", "SENSORS")
	ui.call("_refresh_snapshot")
	await process_frame
	await process_frame
	var body := ui.get_node("TerminalPanel/Body") as Control
	var preview := ui.find_child("MapPreview", true, false) as Control
	for panel_name in ["SensorsFidelityPanel", "SensorsPredictionPanel", "SensorsActivityPanel"]:
		var panel := ui.find_child(panel_name, true, false) as Control
		_expect(panel != null and panel.is_visible_in_tree(), "%s must be visible" % panel_name)
		_expect(panel == null or body.get_global_rect().encloses(panel.get_global_rect()), "%s must fit terminal body: body=%s panel=%s" % [panel_name, body.get_global_rect(), panel.get_global_rect() if panel != null else Rect2()])
	_expect(preview != null and preview.visible, "Sensors tactical map must be visible")
	var main_scroll := ui.find_child("MainContentScroll", true, false) as ScrollContainer
	_expect(main_scroll != null and main_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Sensors must not scroll horizontally")
	var quality := ui.find_child("SensorsFidelityPanel", true, false).find_child("Body", true, false) as RichTextLabel
	var forecast := ui.find_child("SensorsPredictionPanel", true, false).find_child("Body", true, false) as RichTextLabel
	_expect(quality.get_parsed_text().contains("NETWORK SUPPORT"), "quality panel must explain network support")
	_expect(forecast.get_parsed_text().contains("INGRESS") and forecast.get_parsed_text().contains("OBJECTIVE"), "forecast must separate ingress and objective")
	var minimap_view := preview.find_child("MinimapView", true, false)
	_expect(minimap_view != null and bool(minimap_view.call("is_sensor_intelligence_active")), "Sensors map must consume projected intelligence")
	minimap_view.call("set_sensor_intelligence", {"contacts":[], "sector_activity":[{"sector":"STORAGE", "sector_map_position":Vector2.ZERO}]})
	var fragmented_markers: Dictionary = minimap_view.call("get_sensor_marker_summary")
	_expect(fragmented_markers["contact_markers"] == 0 and fragmented_markers["sector_activity_markers"] == 1, "FRAGMENTED map must render sector activity without enemy pips")
	minimap_view.call("set_sensor_intelligence", {"contacts":[], "sector_activity":[]})
	var lost_markers: Dictionary = minimap_view.call("get_sensor_marker_summary")
	_expect(lost_markers["contact_markers"] == 0 and lost_markers["sector_activity_markers"] == 0, "LOST map must render no hostile or activity markers")
	var selection_snapshot := {
		"fidelity":"FULL", "terminal_mode":&"command", "arrn":{},
		"sensor_intelligence":{"contacts":[
			{"contact_id":"C-001", "sector":"STORAGE", "class_label":"GRUNT", "activity":"STEALING", "confidence":"HIGH", "age_ticks":12, "health_pct":0.72, "velocity":Vector2.RIGHT},
			{"contact_id":"C-002", "sector":"POWER", "class_label":"MARINE", "activity":"ENGAGING", "confidence":"HIGH", "age_ticks":3, "health_pct":1.0, "velocity":Vector2.UP},
		], "tracked_count":2, "current_count":2, "stale_count":0},
		"sensor_forecast":{"ingress":"NORTH", "objective":"HOSTILE PRESSURE", "composition":["GRUNT"]},
	}
	ui.set("_terminal_snapshot", selection_snapshot)
	ui.call("_render_terminal_sensors_widgets", selection_snapshot)
	ui.call("_select_terminal_sensor_contact", "C-002")
	var activity_body := ui.find_child("SensorsActivityPanel", true, false).find_child("Body", true, false) as RichTextLabel
	_expect(String(ui.get("_terminal_sensor_selected_contact_id")) == "C-002", "contact link selection must change selected ID")
	_expect(activity_body.get_parsed_text().contains("SELECTED // C-002") and activity_body.get_parsed_text().contains("HEADING") and activity_body.get_parsed_text().contains("NORTH"), "selected contact must expose FULL detail")
	ui.call("_set_terminal_page", "OVERVIEW")
	ui.call("_refresh_snapshot")
	_expect(not bool(minimap_view.call("is_sensor_intelligence_active")), "leaving Sensors restores ordinary minimap mode")
	await create_timer(0.2).timeout
	game.free()
	await process_frame
	if _failed:
		quit(1)
		return
	print("TERMINAL_SENSORS_LAYOUT_SMOKE: PASS")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
