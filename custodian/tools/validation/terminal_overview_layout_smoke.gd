extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var _failed := false


func _init() -> void:
	root.size = Vector2i(1366, 768)
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var ui := game.get_node_or_null("UI")
	_require(ui != null, "Main game scene should expose UI.")
	if ui == null:
		_finish(game)
		return
	ui.call("open_command_terminal")
	ui.call("_set_terminal_page", "OVERVIEW")
	await process_frame
	await process_frame

	var panel := ui.get_node_or_null("TerminalPanel") as Control
	var body := ui.get_node_or_null("TerminalPanel/Body") as Control
	var header := ui.get_node_or_null("TerminalPanel/Header") as Control
	var nav := ui.get_node_or_null("TerminalPanel/Body/NavRail") as Control
	var command_column := ui.get_node_or_null("TerminalPanel/Body/CommandColumn") as Control
	var input_row := ui.get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow") as Control
	var background := ui.get_node_or_null("TerminalBackground") as Control
	var map_preview := ui.find_child("MapPreview", true, false) as Control
	var map_slot := ui.find_child("OverviewMapSlot", true, false) as Control
	var top_row := ui.find_child("OverviewTopRow", true, false) as Control
	var bottom_row := ui.find_child("OverviewBottomRow", true, false) as Control
	var planet := ui.find_child("PlanetPreview", true, false) as Control
	var main_scroll := ui.find_child("MainContentScroll", true, false) as ScrollContainer
	var safe_viewport_rect := ui.get_viewport().get_visible_rect()

	_require(panel != null and panel.visible, "Terminal panel should be visible after open.")
	_require(panel == null or _inside(panel.get_global_rect(), safe_viewport_rect), "Terminal panel should remain inside the 1366x768 safe viewport.")
	_require(background != null and background.visible, "Full-viewport terminal scrim should be visible.")
	_require(background == null or background.get_global_rect().size.is_equal_approx(safe_viewport_rect.size), "Terminal scrim should cover the full viewport.")
	_require(background == null or background.mouse_filter == Control.MOUSE_FILTER_STOP, "Terminal scrim should block input behind the modal.")
	_require(panel == null or panel.mouse_filter == Control.MOUSE_FILTER_STOP, "Terminal panel should stop pointer input.")
	_require(background == null or panel == null or background.z_index < panel.z_index, "Scrim should render below the terminal panel.")

	_require(planet != null and not planet.visible, "Overview should not display the large planet preview.")
	_require(map_preview != null and map_preview.visible, "Overview should display the tactical map.")
	_require(map_preview == null or map_preview.get_parent() == map_slot, "Overview tactical map should be mounted between summary and diagnosis rows.")
	_require(map_preview == null or map_preview.size.y >= 200.0, "Overview tactical map should remain the primary visual anchor.")
	_require(top_row != null and top_row.visible, "Overview summary cards should be visible.")
	_require(bottom_row != null and bottom_row.visible, "Overview diagnosis cards should be visible.")
	for panel_name in ["OverviewOperationalPanel", "OverviewPowerPanel", "OverviewAssaultPanel", "OverviewPriorityPanel", "OverviewIncidentPanel", "OverviewContractPanel"]:
		var overview_panel := ui.find_child(panel_name, true, false) as Control
		_require(overview_panel != null and overview_panel.is_visible_in_tree(), "%s should be visible on Overview." % panel_name)
		_require(body == null or overview_panel == null or overview_panel.get_global_rect().end.y <= body.get_global_rect().end.y + 1.0, "%s should fit above the terminal body edge." % panel_name)
		var card_body := overview_panel.find_child("Body", true, false) as RichTextLabel if overview_panel != null else null
		_require(card_body != null and card_body.get_content_height() <= card_body.size.y + 1.0, "%s content should fit without an internal scrollbar." % panel_name)
	_require(main_scroll != null and main_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Overview should not allow horizontal scrolling.")
	_require(main_scroll != null and main_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Overview should fit without page-level scrolling.")

	for required_button in ["OverviewButton", "SectorsButton", "PowerButton", "DefenseButton", "FabricationButton", "SensorsButton", "ArchiveButton", "ReconButton", "MoreButton"]:
		var button := ui.find_child(required_button, true, false) as Control
		_require(button != null and button.visible, "%s should be visible in the primary navigation group." % required_button)
	for secondary_button in ["StatusButton", "IncidentsButton", "ContractsButton", "HistoryButton", "SettingsButton"]:
		var button := ui.find_child(secondary_button, true, false) as Control
		_require(button != null and not button.visible, "%s should begin collapsed behind MORE / SYSTEMS." % secondary_button)
	var more_button := ui.find_child("MoreButton", true, false) as BaseButton
	if more_button != null:
		more_button.pressed.emit()
		await process_frame
		_require((ui.find_child("SettingsButton", true, false) as Control).visible, "MORE / SYSTEMS should expand secondary pages.")
		more_button.pressed.emit()
		await process_frame
		_require(not (ui.find_child("SettingsButton", true, false) as Control).visible, "LESS / PRIMARY should collapse secondary pages.")
	for required_action in ["WaitButton", "FocusButton", "HardenButton", "HelpButton"]:
		var button := ui.find_child(required_action, true, false) as Control
		_require(button != null and button.visible, "%s should remain visible." % required_action)
	for secondary_action in ["Wait10xButton", "ResetButton", "RebootButton"]:
		var button := ui.find_child(secondary_action, true, false) as Control
		_require(button != null and not button.visible, "%s should be command-line/secondary only." % secondary_action)

	_require(body == null or nav == null or nav.get_global_rect().end.y <= body.get_global_rect().end.y + 1.0, "Navigation rail should not clip below the terminal body.")
	_require(body == null or command_column == null or _inside(command_column.get_global_rect(), body.get_global_rect()), "Transcript column should fit inside the terminal body.")
	_require(body == null or input_row == null or _inside(input_row.get_global_rect(), body.get_global_rect()), "Command input should remain fully visible.")
	_require(header == null or _header_fits(header), "Header chips should fit without overlap or truncation.")
	var output := ui.find_child("TerminalOutput", true, false) as RichTextLabel
	var output_text := output.get_parsed_text() if output != null else ""
	_require(output_text.contains("SYSTEM") and output_text.contains("POWER") and output_text.contains("ACTION"), "Overview transcript should begin with an actionable attention feed.")

	ui.call("close_command_terminal")
	_finish(game)


func _header_fits(header: Control) -> bool:
	var previous_end := header.get_global_rect().position.x
	for node_name in ["Eyebrow", "Title", "TimeChip", "ThreatChip", "PhaseChip", "GridChip"]:
		var label := header.find_child(node_name, true, false) as Label
		if label == null or label.get_minimum_size().x > label.size.x + 1.0:
			return false
		if label.get_global_rect().position.x < previous_end - 1.0:
			return false
		previous_end = label.get_global_rect().end.x
	return previous_end <= header.get_global_rect().end.x + 1.0


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 1.0 and inner.position.y >= outer.position.y - 1.0 and inner.end.x <= outer.end.x + 1.0 and inner.end.y <= outer.end.y + 1.0


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	if _failed:
		push_error("terminal_overview_layout_smoke failed")
		quit(1)
		return
	print("[TerminalOverviewLayoutSmoke] PASS")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerminalOverviewLayoutSmoke] " + message)
