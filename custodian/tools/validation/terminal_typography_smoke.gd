extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const MONO_PATH := "res://content/ui/fonts/terminal_mono_regular.ttf"
const MONO_BOLD_PATH := "res://content/ui/fonts/terminal_mono_bold.ttf"
const DISPLAY_PATH := "res://content/ui/fonts/terminal_display_regular.ttf"

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_require(_is_font(MONO_PATH), "terminal mono font should import as Font")
	_require(_is_font(MONO_BOLD_PATH), "terminal mono bold font should import as Font")
	_require(_is_font(DISPLAY_PATH), "terminal display font should import as Font")

	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var ui := game.get_node_or_null("UI")
	_require(ui != null, "main game scene should expose UI")
	if ui == null:
		game.queue_free()
		_finish()
		return

	_check_label(ui.get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/Title"), DISPLAY_PATH, 22, "terminal title")
	_check_label(ui.get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/Eyebrow"), MONO_PATH, 11, "header eyebrow")
	for chip_name in ["TimeChip", "ThreatChip", "PhaseChip", "GridChip"]:
		_check_label(ui.get_node_or_null("TerminalPanel/Header/Margin/HeaderRow/StatusChips/" + chip_name), MONO_PATH, 11, "header %s" % chip_name)
	_check_button(ui.find_child("OverviewButton", true, false), DISPLAY_PATH, 12, "navigation button")
	_check_line_edit(ui.get_node_or_null("TerminalPanel/Body/CommandColumn/InputRow/TerminalInput"), MONO_PATH, 16, "command input")
	_check_rich_text(ui.find_child("TerminalOutput", true, false), MONO_PATH, 12, "command log")

	ui.call("_set_terminal_page", "FABRICATION")
	ui.call("_set_terminal_widget_mode", "FABRICATION")
	ui.call("_render_terminal_fabrication_widgets")
	await process_frame
	await process_frame
	_check_label(_panel_title(ui, "FabStatusPanel"), DISPLAY_PATH, 11, "widget section header")
	var selected_body := _panel_body(ui, "FabSelectedRecipePanel")
	_check_rich_text(selected_body, MONO_PATH, 12, "selected work-order detail")
	var filter_body := _panel_body(ui, "FabCategoryPanel")
	_check_rich_text(filter_body, MONO_PATH, 11, "fabrication filter")
	_require(filter_body != null and filter_body.autowrap_mode == TextServer.AUTOWRAP_OFF, "fabrication filter labels should not wrap")
	var rows := ui.find_child("Rows", true, false)
	if rows != null and rows.get_child_count() > 0:
		var row_button := rows.get_child(0)
		_check_button(row_button, MONO_BOLD_PATH, 12, "work-order row")
		_require(row_button is Button and (row_button as Button).clip_text, "work-order row should clip overflow")
		_require(int(row_button.get("text_overrun_behavior")) == TextServer.OVERRUN_TRIM_ELLIPSIS, "work-order row should use ellipsis")
		_require(row_button.get_theme_stylebox("normal") is StyleBoxFlat, "work-order row should use a flat style")
		_check_label(row_button.find_child("StateLabel", true, false), MONO_BOLD_PATH, 12, "work-order state")
		_check_label(row_button.find_child("NameLabel", true, false), MONO_BOLD_PATH, 12, "work-order name")
		_check_label(row_button.find_child("CategoryLabel", true, false), MONO_PATH, 12, "work-order category")
		_check_label(row_button.find_child("CostLabel", true, false), MONO_PATH, 12, "work-order cost")
	else:
		_require(false, "Fabrication should render at least one work-order row")
	for scroll in ui.find_children("*", "ScrollContainer", true, false):
		if scroll is ScrollContainer and (scroll.name == "MainContentScroll" or scroll.name == "RecipeScroll"):
			_require((scroll as ScrollContainer).horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s should disable horizontal scrolling" % scroll.name)

	game.queue_free()
	await process_frame
	_finish()


func _panel_body(ui: Node, panel_name: String) -> RichTextLabel:
	var panel := ui.find_child(panel_name, true, false)
	return panel.find_child("Body", true, false) as RichTextLabel if panel != null else null


func _panel_title(ui: Node, panel_name: String) -> Label:
	var panel := ui.find_child(panel_name, true, false)
	return panel.find_child("Title", true, false) as Label if panel != null else null


func _check_label(node: Node, expected_path: String, size: int, label: String) -> void:
	_require(node is Label, "%s should be a Label" % label)
	if node is Label:
		var control := node as Label
		_require(control.get_theme_font("font").resource_path == expected_path, "%s should use %s" % [label, expected_path])
		_require(control.get_theme_font_size("font_size") == size, "%s should use %dpx" % [label, size])


func _check_button(node: Node, expected_path: String, size: int, label: String) -> void:
	_require(node is BaseButton, "%s should be a button" % label)
	if node is BaseButton:
		var control := node as BaseButton
		_require(control.get_theme_font("font").resource_path == expected_path, "%s should use %s" % [label, expected_path])
		_require(control.get_theme_font_size("font_size") == size, "%s should use %dpx" % [label, size])


func _check_line_edit(node: Node, expected_path: String, size: int, label: String) -> void:
	_require(node is LineEdit, "%s should be a LineEdit" % label)
	if node is LineEdit:
		var control := node as LineEdit
		_require(control.get_theme_font("font").resource_path == expected_path, "%s should use %s" % [label, expected_path])
		_require(control.get_theme_font_size("font_size") == size, "%s should use %dpx" % [label, size])


func _check_rich_text(node: Node, expected_path: String, size: int, label: String) -> void:
	_require(node is RichTextLabel, "%s should be RichTextLabel" % label)
	if node is RichTextLabel:
		var control := node as RichTextLabel
		_require(control.get_theme_font("normal_font").resource_path == expected_path, "%s should use %s" % [label, expected_path])
		_require(control.get_theme_font_size("normal_font_size") == size, "%s should use %dpx" % [label, size])


func _is_font(path: String) -> bool:
	return ResourceLoader.exists(path, "Font") and load(path) is Font


func _finish() -> void:
	if _failed:
		push_error("terminal_typography_smoke failed")
		quit(1)
		return
	print("[TerminalTypographySmoke] fonts, hierarchy, Fabrication density, ellipsis, and scroll policy resolved.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerminalTypographySmoke] " + message)
