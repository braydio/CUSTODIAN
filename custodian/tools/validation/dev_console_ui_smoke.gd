extends SceneTree
## Visual structure, focus, responsive layout, and input-interception coverage
## for the native Developer Shell panel. Complements
## `dev_console_contract_smoke.gd`, which covers the command registry itself.

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var console := root.get_node_or_null("DevConsole")
	var dev_mode := root.get_node_or_null("DevMode")
	_assert_true(console != null, "DevConsole autoload should exist at /root/DevConsole")
	_assert_true(dev_mode != null, "DevMode autoload should exist at /root/DevMode")
	if console == null or dev_mode == null:
		_finish()
		return
	dev_mode.set("debug_ui_enabled", true)

	var host := Control.new()
	host.focus_mode = Control.FOCUS_ALL
	root.add_child(host)
	await process_frame
	host.grab_focus()
	await process_frame
	_assert_true(host.has_focus(), "test setup: host control should hold focus before the console opens")

	console.call("open_console")
	await process_frame
	await process_frame
	_assert_true(bool(console.call("is_open")), "console should report open")

	var panel := console.get_node_or_null("ConsoleView")
	_assert_true(panel != null, "DevConsoleService should instantiate the panel scene on first open")
	if panel == null:
		host.queue_free()
		_finish()
		return

	_check_structure(panel)
	_check_no_passive_update_loop(panel)
	_check_focus_capture(panel)
	_check_responsive_layout(panel)
	_check_suggestions(panel)
	_check_escape_two_stage(console, panel)

	# Escape just closed it above; reopen for the focus-restore check below.
	console.call("open_console")
	await process_frame
	console.call("close_console")
	await process_frame
	_assert_true(not bool(console.call("is_open")), "console should report closed")
	_assert_true(host.has_focus(), "closing should restore the control that held focus before the console opened")

	await _check_reopen_does_not_leak_connections(console, panel)

	host.queue_free()
	_finish()


func _check_structure(panel: Node) -> void:
	var paths := [
		"Backdrop", "ConsoleFrame", "ConsoleFrame/Margin/Layout",
		"ConsoleFrame/Margin/Layout/Header",
		"ConsoleFrame/Margin/Layout/Header/Identity",
		"ConsoleFrame/Margin/Layout/Header/Spacer",
		"ConsoleFrame/Margin/Layout/Header/ModeIndicator",
		"ConsoleFrame/Margin/Layout/Separator",
		"ConsoleFrame/Margin/Layout/Output",
		"ConsoleFrame/Margin/Layout/Suggestions",
		"ConsoleFrame/Margin/Layout/InputFrame",
		"ConsoleFrame/Margin/Layout/InputFrame/InputRow/Prompt",
		"ConsoleFrame/Margin/Layout/InputFrame/InputRow/CommandInput",
		"ConsoleFrame/Margin/Layout/Footer/Shortcuts",
		"ConsoleFrame/Margin/Layout/Footer/Status",
	]
	for path in paths:
		_assert_true(panel.get_node_or_null(path) != null, "canonical console node missing: %s" % path)

	var identity := panel.get_node_or_null("ConsoleFrame/Margin/Layout/Header/Identity") as Label
	if identity != null:
		_assert_true(
			identity.get_theme_color("font_color") == Color("#d4b56a"),
			"header identity should use the Black Reliquary gold text color"
		)

	var backdrop := panel.get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		_assert_true(
			backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"backdrop must not block gameplay interactions, even while the console is visible"
		)


func _check_no_passive_update_loop(panel: Node) -> void:
	_assert_true(not panel.is_processing(), "console panel must not run a per-frame update loop")
	_assert_true(not panel.is_physics_processing(), "console panel must not run a per-physics-frame update loop")


func _check_focus_capture(panel: Node) -> void:
	var command_input := panel.get_node_or_null("ConsoleFrame/Margin/Layout/InputFrame/InputRow/CommandInput") as LineEdit
	_assert_true(command_input != null, "command input must exist")
	if command_input != null:
		_assert_true(command_input.has_focus(), "opening the console should capture keyboard focus into the command field")


func _check_responsive_layout(panel: Node) -> void:
	var frame := panel.get_node_or_null("ConsoleFrame") as PanelContainer
	if frame == null:
		_assert_true(false, "ConsoleFrame must exist for layout checks")
		return

	# Headless mode does not propagate an assigned `Window.size` back through
	# `get_viewport_rect()` (there is no real display server to resize), so a
	# live resize can't be exercised here. The geometry formula itself --
	# `DevConsoleStyle.frame_size_and_position()` -- is pure and takes a size
	# directly, so it is checked for all four target resolutions; the
	# `size_changed` wiring that feeds it a real size is checked separately
	# in `_check_reopen_does_not_leak_connections`.
	var sizes := [Vector2(960, 540), Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]
	for size in sizes:
		var geometry: Dictionary = DevConsoleStyle.frame_size_and_position(size)
		var frame_size: Vector2 = geometry["size"]
		var frame_pos: Vector2 = geometry["position"]
		_assert_true(
			frame_size.x <= size.x - 32.0 + 0.01,
			"frame width must leave 16px side margins at %s, got width %s" % [size, frame_size.x]
		)
		_assert_true(
			frame_size.x <= 1120.0 + 0.01,
			"frame width must clamp at 1120 and not stretch across the whole viewport at %s, got %s" % [size, frame_size.x]
		)
		_assert_true(
			frame_size.y >= 230.0 - 0.01 and frame_size.y <= 360.0 + 0.01,
			"frame height must stay clamped to 230-360 at %s, got %s" % [size, frame_size.y]
		)
		_assert_true(frame_pos.x >= -0.01, "frame must not be clipped off the left edge at %s" % size)
		_assert_true(
			frame_pos.y + frame_size.y <= size.y + 0.01,
			"frame must not be clipped off the bottom edge at %s" % size
		)

	# The live wiring: `_update_layout()` must actually apply that formula to
	# the real `ConsoleFrame` at the panel's current (real) viewport size.
	var current_size: Vector2 = panel.get_viewport_rect().size
	var expected: Dictionary = DevConsoleStyle.frame_size_and_position(current_size)
	panel.call("_update_layout")
	_assert_true(
		frame.size.is_equal_approx(expected["size"]),
		"_update_layout should apply the formula's size at the current viewport, expected %s got %s" % [expected["size"], frame.size]
	)
	_assert_true(
		frame.position.is_equal_approx(expected["position"]),
		"_update_layout should apply the formula's position at the current viewport, expected %s got %s" % [expected["position"], frame.position]
	)


func _check_suggestions(panel: Node) -> void:
	var suggestions := panel.get_node_or_null("ConsoleFrame/Margin/Layout/Suggestions") as ItemList
	var command_input := panel.get_node_or_null("ConsoleFrame/Margin/Layout/InputFrame/InputRow/CommandInput") as LineEdit
	if suggestions == null or command_input == null:
		_assert_true(false, "Suggestions/CommandInput must exist for autocomplete checks")
		return

	_assert_true(not suggestions.visible, "suggestions must stay hidden until there are multiple candidates")

	# Built-ins "help" and "history" both start with "h"; only autoloads are
	# live in this harness, so no HUD-registered command can collide here.
	command_input.text = "h"
	panel.call("_on_text_changed", "h")
	_assert_true(suggestions.visible, "typing a prefix with multiple matches should show suggestions")
	_assert_true(suggestions.item_count == 2, "expected exactly 2 matches for 'h', got %d" % suggestions.item_count)

	command_input.text = "h "
	panel.call("_on_text_changed", "h ")
	_assert_true(not suggestions.visible, "suggestions must dismiss once the token is followed by a space")

	command_input.text = "h"
	panel.call("_on_text_changed", "h")
	panel.call("_complete_selected_suggestion")
	_assert_true(command_input.text == "help ", "tab-complete should fill the first match, got '%s'" % command_input.text)
	_assert_true(not suggestions.visible, "completing a suggestion must dismiss the list")
	_assert_true(
		command_input.text.strip_edges() != "",
		"tab-complete must never execute a command; the field should hold text, not be cleared by a submission"
	)

	command_input.text = ""
	panel.call("_on_text_changed", "")


func _check_escape_two_stage(console: Node, panel: Node) -> void:
	var suggestions := panel.get_node_or_null("ConsoleFrame/Margin/Layout/Suggestions") as ItemList
	var command_input := panel.get_node_or_null("ConsoleFrame/Margin/Layout/InputFrame/InputRow/CommandInput") as LineEdit
	if suggestions == null or command_input == null:
		_assert_true(false, "Suggestions/CommandInput must exist for the Escape check")
		return

	command_input.grab_focus()
	command_input.text = "h"
	panel.call("_on_text_changed", "h")
	_assert_true(suggestions.visible, "setup: suggestions should be visible before testing Escape")

	var escape_event := InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	panel.call("_input", escape_event)
	_assert_true(not suggestions.visible, "first Escape should dismiss suggestions, not close the console")
	_assert_true(bool(console.call("is_open")), "console should remain open after only dismissing suggestions")

	panel.call("_input", escape_event)
	_assert_true(not bool(console.call("is_open")), "second Escape should close the console")


func _check_reopen_does_not_leak_connections(console: Node, panel: Node) -> void:
	var viewport := panel.get_viewport()
	for _attempt in range(3):
		console.call("open_console")
		await process_frame
		console.call("close_console")
		await process_frame
	# Every Control auto-wires its own internal `_size_changed` notification
	# hook to the viewport -- that one is Godot's, not a leak, and exists even
	# after a single open. Filtering by method name isolates the connection
	# this panel's own `_ready()` makes.
	var panel_connections := 0
	for connection in viewport.size_changed.get_connections():
		var callable: Callable = connection.get("callable")
		if callable != null and callable.is_valid() \
				and callable.get_object() == panel \
				and callable.get_method() == &"_update_layout":
			panel_connections += 1
	_assert_true(
		panel_connections == 1,
		"reopening the console repeatedly must not accumulate size_changed connections, found %d" % panel_connections
	)


func _finish() -> void:
	if _failed:
		push_error("dev_console_ui_smoke failed")
		quit(1)
		return
	print("dev_console_ui_smoke ok")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
