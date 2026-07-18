extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const TERMINAL_MAP_PREVIEW_SCRIPT := preload("res://game/ui/terminal/terminal_map_preview.gd")

var _failed := false


func _init() -> void:
	root.size = Vector2i(1366, 768)
	call_deferred("_run")


func _run() -> void:
	var fallback_preview = TERMINAL_MAP_PREVIEW_SCRIPT.new()
	fallback_preview.set_overview_mode(true)
	var fallback_texture := fallback_preview.build_placeholder("OVERVIEW FALLBACK")
	_require(fallback_texture.get_width() == 448 and fallback_texture.get_height() == 448, "Overview compatibility preview should render at 448x448 rather than the 256px default.")
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var ui := game.get_node_or_null("UI")
	_require(ui != null, "Main game scene should expose UI.")
	if ui == null:
		_finish(game)
		return
	var original_mouse_mode := Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var terminal_entry_mouse_mode := Input.mouse_mode
	ui.call("open_command_terminal")
	ui.call("_set_terminal_page", "OVERVIEW")
	await process_frame
	await process_frame

	var panel := ui.get_node_or_null("TerminalPanel") as Control
	var body := ui.get_node_or_null("TerminalPanel/Body") as Control
	var header := ui.get_node_or_null("TerminalPanel/Header") as Control
	var nav := ui.get_node_or_null("TerminalPanel/Body/NavRail") as Control
	var page_scroll := ui.get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll") as ScrollContainer
	var page_buttons := ui.get_node_or_null("TerminalPanel/Body/NavRail/PageButtonsScroll/PageButtons") as Control
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
	_require(background == null or panel == null or background.get_index() < panel.get_index(), "Terminal scrim should precede the panel in GUI input order.")
	_require(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Opening the terminal should make the pointer visible for mouse interaction.")
	var sectors_click_target := ui.find_child("SectorsButton", true, false) as Control
	if sectors_click_target != null:
		_click_control(sectors_click_target)
		await process_frame
		await process_frame
		_require(str(ui.get("_terminal_current_page")) == "SECTORS", "A real viewport mouse click should reach terminal page buttons through the modal scrim.")
		ui.call("_set_terminal_page", "OVERVIEW")
		await process_frame

	_require(planet != null and not planet.visible, "Overview should not display the large planet preview.")
	_require(map_preview != null and map_preview.visible, "Overview should display the tactical map.")
	_require(map_preview == null or map_preview.get_parent() == map_slot, "Overview tactical map should be mounted between summary and diagnosis rows.")
	_require(map_preview == null or map_preview.size.y >= 200.0, "Overview tactical map should remain the primary visual anchor.")
	_require(map_preview == null or bottom_row == null or map_preview.size.y > bottom_row.size.y, "Overview tactical map should remain taller than the diagnosis-card row.")
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

	_require(page_scroll != null, "PageButtonsScroll should be authored explicitly in game.tscn.")
	_require(page_scroll == null or page_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "PageButtonsScroll should reject horizontal scrolling.")
	_require(page_scroll == null or page_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "PageButtonsScroll should allow vertical scrolling.")
	_require(page_scroll == null or page_scroll.mouse_filter == Control.MOUSE_FILTER_STOP, "PageButtonsScroll should capture pointer input.")
	_require(page_buttons != null and page_buttons.get_parent() == page_scroll, "PageButtons should be the sole scroll-content container.")
	for required_button in ["OverviewButton", "SectorsButton", "PowerButton", "DefenseButton", "FabricationButton", "SensorsButton", "ArchiveButton", "ReconButton", "MoreButton"]:
		var button := ui.find_child(required_button, true, false) as Control
		_require(button != null and button.visible, "%s should be visible in the primary navigation group." % required_button)
	for secondary_button in ["StatusButton", "IncidentsButton", "ContractsButton", "HistoryButton", "SettingsButton"]:
		var button := ui.find_child(secondary_button, true, false) as BaseButton
		_require(button != null and not button.visible, "%s should begin collapsed behind MORE / SYSTEMS." % secondary_button)
		_require(button == null or button.focus_mode == Control.FOCUS_NONE, "%s should not remain keyboard-focusable while collapsed." % secondary_button)
	var more_button := ui.find_child("MoreButton", true, false) as BaseButton
	if more_button != null:
		_require(more_button.get_parent() == nav, "MoreButton should be pinned as a direct NavRail child.")
		_require(page_scroll == null or not page_scroll.is_ancestor_of(more_button), "MoreButton must remain outside scrollable page content.")
		more_button.pressed.emit()
		await process_frame
		await process_frame
		_require((ui.find_child("SettingsButton", true, false) as Control).visible, "MORE / SYSTEMS should expand secondary pages.")
		if page_scroll != null:
			var scroll_bar := page_scroll.get_v_scroll_bar()
			_require(scroll_bar != null and scroll_bar.max_value > scroll_bar.page, "Expanded secondary pages should overflow into a usable vertical scroll range.")
			page_scroll.scroll_vertical = 0
			var wheel_event := InputEventMouseButton.new()
			wheel_event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			wheel_event.pressed = true
			var nav_button := ui.find_child("SettingsButton", true, false) as Control
			if nav_button != null:
				nav_button.gui_input.emit(wheel_event)
			await process_frame
			_require(page_scroll.scroll_vertical > 0, "Mouse wheel over a nav button should scroll PageButtonsScroll.")
		more_button.pressed.emit()
		await process_frame
		_require(not (ui.find_child("SettingsButton", true, false) as Control).visible, "LESS / PRIMARY should collapse secondary pages.")
	ui.call("_set_terminal_page", "POWER")
	var overview_button := ui.find_child("OverviewButton", true, false) as BaseButton
	var sectors_button := ui.find_child("SectorsButton", true, false) as BaseButton
	if overview_button != null and sectors_button != null:
		overview_button.grab_focus()
		ui.call("_move_terminal_button_focus", 1)
		_require(ui.get_viewport().gui_get_focus_owner() == sectors_button, "Keyboard traversal should skip the hidden Status button.")
	ui.call("_set_terminal_page", "OVERVIEW")
	for required_action in ["WaitButton", "FocusButton", "HardenButton", "HelpButton"]:
		var button := ui.find_child(required_action, true, false) as Control
		_require(button != null and button.visible, "%s should remain visible." % required_action)
		_require(page_scroll == null or button == null or not page_scroll.is_ancestor_of(button), "%s should remain pinned outside page scrolling." % required_action)
	for secondary_action in ["Wait10xButton", "ResetButton", "RebootButton"]:
		var button := ui.find_child(secondary_action, true, false) as Control
		_require(button != null and not button.visible, "%s should be command-line/secondary only." % secondary_action)

	_require(body == null or nav == null or nav.get_global_rect().end.y <= body.get_global_rect().end.y + 1.0, "Navigation rail should not clip below the terminal body.")
	_require(body == null or command_column == null or _inside(command_column.get_global_rect(), body.get_global_rect()), "Transcript column should fit inside the terminal body.")
	_require(body == null or input_row == null or _inside(input_row.get_global_rect(), body.get_global_rect()), "Command input should remain fully visible.")
	_require(header == null or _header_fits(header), "Header chips should fit without overlap or truncation.")
	_require(str(ui.call("_format_terminal_grid_rate", -3538.0)) == "-3.5K/s", "Grid deficit formatter should use compact signed K/s text.")
	var output := ui.find_child("TerminalOutput", true, false) as RichTextLabel
	var output_text := output.get_parsed_text() if output != null else ""
	_require(output_text.contains("SYSTEM") and output_text.contains("POWER") and output_text.contains("ACTION"), "Overview transcript should begin with an actionable attention feed.")
	ui.set("_terminal_boot_complete", true)
	ui.call("_append_terminal_line", "[ SYSTEM POWER: UNSTABLE ]")
	output_text = output.get_parsed_text() if output != null else ""
	_require(output_text.contains("BOOT LOG //") and not output_text.contains("SYSTEM POWER: UNSTABLE"), "Completed Overview boot chatter should collapse into one summary line.")

	var contract_body := ui.find_child("OverviewContractPanel", true, false).find_child("Body", true, false) as RichTextLabel
	var priority_body := ui.find_child("OverviewPriorityPanel", true, false).find_child("Body", true, false) as RichTextLabel
	var incident_body := ui.find_child("OverviewIncidentPanel", true, false).find_child("Body", true, false) as RichTextLabel
	var meta_handler := Callable(ui, "_on_terminal_activity_meta_clicked")
	for card_body in [contract_body, priority_body, incident_body]:
		_require(card_body != null and card_body.meta_clicked.is_connected(meta_handler), "Overview diagnosis cards should route clickable terminal_action links.")
	if contract_body != null:
		contract_body.meta_clicked.emit("terminal_action:open_power")
		await process_frame
		_require(str(ui.get("_terminal_current_page")) == "POWER", "Overview action links should open their target page.")
		ui.call("_set_terminal_page", "OVERVIEW")

	var minimap_view := map_preview.find_child("MinimapView", true, false) if map_preview != null else null
	if minimap_view is Control and minimap_view.has_method("get_map_draw_rect"):
		var map_rect: Rect2 = minimap_view.call("get_map_draw_rect")
		var preview_size := (minimap_view as Control).size
		var horizontal_fill := map_rect.size.x / preview_size.x if preview_size.x > 0.0 else 0.0
		var vertical_fill := map_rect.size.y / preview_size.y if preview_size.y > 0.0 else 0.0
		# Aspect-preserving fit makes one axis authoritative; the other can be
		# smaller on wide/tall generated maps without indicating excess padding.
		var fill_ratio := maxf(horizontal_fill, vertical_fill)
		_require(fill_ratio >= 0.65 and fill_ratio <= 0.80, "Overview map content should occupy 65-80% of its aspect-preserving fit axis.")
		var world_center: Vector2 = minimap_view.call("local_to_world", map_rect.get_center())
		_require(is_finite(world_center.x) and is_finite(world_center.y), "Overview map center should preserve a finite local-to-world mapping.")

	ui.call("close_command_terminal")
	_require(Input.mouse_mode == terminal_entry_mouse_mode, "Closing the terminal should restore the mouse mode active before it opened.")
	Input.mouse_mode = original_mouse_mode
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


func _click_control(control: Control) -> void:
	# Push through the viewport's GUI router in its local canvas coordinates. This
	# exercises hit testing without relying on a window-system mouse in headless CI.
	var position := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = position
		click.global_position = position
		click.pressed = pressed
		root.push_input(click, true)


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
