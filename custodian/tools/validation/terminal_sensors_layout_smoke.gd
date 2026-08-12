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
