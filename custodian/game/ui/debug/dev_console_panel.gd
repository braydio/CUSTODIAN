extends Control
## Presentation only. Owns no gameplay state and calls no gameplay systems --
## it reads command metadata/output from `DevConsoleService` and emits
## command text back to it. See `dev_console_service.gd` for the execution
## authority this panel is a view onto.

const Style := preload("res://game/ui/debug/dev_console_style.gd")

const MAX_SUGGESTIONS := 10
const FADE_SEC := 0.12
const SLIDE_PX := 8.0

## Set true (or via project setting below) to skip the open animation and show
## the shell immediately -- the reduced-motion path required by the design.
var reduced_motion := false

@onready var _backdrop: ColorRect = $Backdrop
@onready var _frame: PanelContainer = $ConsoleFrame
@onready var _layout: VBoxContainer = $ConsoleFrame/Margin/Layout
@onready var _identity_label: Label = $ConsoleFrame/Margin/Layout/Header/Identity
@onready var _mode_label: Label = $ConsoleFrame/Margin/Layout/Header/ModeIndicator
@onready var _separator: HSeparator = $ConsoleFrame/Margin/Layout/Separator
@onready var _output: RichTextLabel = $ConsoleFrame/Margin/Layout/Output
@onready var _suggestions: ItemList = $ConsoleFrame/Margin/Layout/Suggestions
@onready var _input_frame: PanelContainer = $ConsoleFrame/Margin/Layout/InputFrame
@onready var _prompt_label: Label = $ConsoleFrame/Margin/Layout/InputFrame/InputRow/Prompt
@onready var _command_input: LineEdit = $ConsoleFrame/Margin/Layout/InputFrame/InputRow/CommandInput
@onready var _shortcuts_label: Label = $ConsoleFrame/Margin/Layout/Footer/Shortcuts
@onready var _status_label: Label = $ConsoleFrame/Margin/Layout/Footer/Status

var _service: Node = null
var _history_cursor := -1
var _pending_text := ""
var _suggestion_names: PackedStringArray = []
var _open_tween: Tween = null
var _previous_focus_owner: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	reduced_motion = bool(ProjectSettings.get_setting("custodian/ui/reduced_motion", false))
	visible = false
	modulate.a = 0.0

	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP

	_identity_label.text = "CUSTODIAN / DEV SHELL"
	_mode_label.text = "LOCAL · DEVELOPMENT"
	_prompt_label.text = ">"
	_shortcuts_label.text = "↑↓ HISTORY · TAB COMPLETE · ESC CLOSE"

	Style.apply_heading(_identity_label)
	Style.apply_mode_indicator(_mode_label)
	Style.apply_separator(_separator)
	Style.apply_output(_output)
	Style.apply_input_frame(_input_frame)
	Style.apply_prompt(_prompt_label)
	Style.apply_command_input(_command_input)
	Style.apply_footer_label(_shortcuts_label)
	Style.apply_footer_label(_status_label, true)
	Style.apply_suggestions(_suggestions)

	_suggestions.visible = false
	_suggestions.custom_minimum_size = Vector2(0.0, 0.0)

	_command_input.text_submitted.connect(_on_text_submitted)
	_command_input.text_changed.connect(_on_text_changed)
	_command_input.focus_entered.connect(_on_input_focus_changed.bind(true))
	_command_input.focus_exited.connect(_on_input_focus_changed.bind(false))
	_suggestions.item_activated.connect(_on_suggestion_activated)
	get_viewport().size_changed.connect(_update_layout)

	_update_layout()


func bind_service(service: Node) -> void:
	_service = service
	if _service.has_signal("output_appended") \
			and not _service.output_appended.is_connected(_on_output_appended):
		_service.output_appended.connect(_on_output_appended)
	render_output()
	_update_footer_status()


# ---------------------------------------------------------------------------
# Open/close presentation. Visibility and focus are synchronous; only the
# fade/slide is animated. Closing never waits on the tween -- the service has
# already flipped `is_open()` before this runs, so gameplay input suppression
# is released the instant close is requested, not when the animation ends.
# ---------------------------------------------------------------------------

func present_opened() -> void:
	_previous_focus_owner = get_viewport().gui_get_focus_owner()
	visible = true
	_history_cursor = -1
	_pending_text = ""
	_update_layout()
	_update_footer_status()
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	var base_position := _frame.position
	if reduced_motion:
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		_frame.position = base_position + Vector2(0.0, SLIDE_PX)
		_open_tween = create_tween()
		_open_tween.set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(self, "modulate:a", 1.0, FADE_SEC)
		_open_tween.parallel().tween_property(_frame, "position", base_position, FADE_SEC)
	call_deferred("_focus_input")


func present_closed() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_dismiss_suggestions()
	if _command_input.has_focus():
		_command_input.release_focus()
	visible = false
	modulate.a = 0.0
	if _previous_focus_owner != null and is_instance_valid(_previous_focus_owner) and _previous_focus_owner.is_inside_tree():
		_previous_focus_owner.grab_focus()
	_previous_focus_owner = null


func _focus_input() -> void:
	if not visible:
		return
	_command_input.grab_focus()
	_command_input.caret_column = _command_input.text.length()


# ---------------------------------------------------------------------------
# Responsive layout -- recomputed on viewport resize signals, never polled.
# ---------------------------------------------------------------------------

func _update_layout() -> void:
	var geometry := Style.frame_size_and_position(get_viewport_rect().size)
	_frame.custom_minimum_size = geometry["size"]
	_frame.size = geometry["size"]
	_frame.position = geometry["position"]


# ---------------------------------------------------------------------------
# Output rendering
# ---------------------------------------------------------------------------

func render_output() -> void:
	_output.clear()
	if _service == null:
		return
	for entry in _service.call("get_output"):
		_append_line(entry)


func _on_output_appended(entry: Dictionary) -> void:
	_append_line(entry)


func _append_line(entry: Dictionary) -> void:
	_output.append_text(_format_entry(entry) + "\n")


func _format_entry(entry: Dictionary) -> String:
	var level := String(entry.get("level", "RESULT"))
	var message := _escape_bbcode(String(entry.get("message", "")))
	if level == "INPUT":
		return "[color=#%s]%s[/color]" % [Style.level_color(level).to_html(false), message]
	var category := String(entry.get("category", "GENERAL")).to_upper()
	var elapsed := float(entry.get("time", 0.0))
	var timestamp := "[%02d:%02d]" % [int(elapsed) / 60, int(elapsed) % 60]
	var category_color := Style.Palette.BLUE_TECH.to_html(false)
	var message_color := Style.level_color(level).to_html(false)
	return "%s  [color=#%s]%s[/color]  [color=#%s]%s[/color]" % [
		timestamp, category_color, category, message_color, message,
	]


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _update_footer_status() -> void:
	if _service == null:
		return
	var names: PackedStringArray = _service.call("get_command_names")
	_status_label.text = "DEV BUILD · COMMANDS %d" % names.size()


# ---------------------------------------------------------------------------
# Command submission
# ---------------------------------------------------------------------------

## Execution happens exactly once, from this signal alone -- there is no
## parallel Enter-key handler in `_input()`, so `text_submitted` and a
## keyboard callback can never both fire for the same press.
func _on_text_submitted(text: String) -> void:
	if _service == null:
		return
	_dismiss_suggestions()
	_command_input.clear()
	var result := String(_service.call("execute_line", text))
	_history_cursor = -1
	_pending_text = ""
	_update_footer_status()
	if _looks_like_failure(result):
		_command_input.text = text
		_command_input.caret_column = text.length()
	_focus_input()


## Legacy command handlers report failure as plain text (see
## `dev_console_service.gd::_looks_like_failure`); mirroring the same check
## here is what lets a failed, complicated command stay in the field for
## editing instead of forcing a full retype.
func _looks_like_failure(result_text: String) -> bool:
	return result_text.begins_with("Unknown command") \
		or result_text.contains("no longer available") \
		or result_text.contains("Usage:") \
		or result_text.begins_with("Failed") \
		or result_text.contains("not found")


# ---------------------------------------------------------------------------
# Autocomplete
# ---------------------------------------------------------------------------

func _on_text_changed(new_text: String) -> void:
	if _service == null or new_text.find(" ") != -1 or new_text.is_empty():
		_dismiss_suggestions()
		return
	_suggestion_names = _service.call("get_matching_commands", new_text)
	_populate_suggestions()


func _populate_suggestions() -> void:
	_suggestions.clear()
	if _suggestion_names.is_empty() \
			or (_suggestion_names.size() == 1 and _suggestion_names[0] == _command_input.text):
		_suggestions.visible = false
		return
	var shown := mini(_suggestion_names.size(), MAX_SUGGESTIONS)
	for i in range(shown):
		_suggestions.add_item(_suggestion_names[i])
	_suggestions.select(0)
	_suggestions.visible = true


func _dismiss_suggestions() -> void:
	_suggestions.clear()
	_suggestion_names = PackedStringArray()
	_suggestions.visible = false


func _complete_selected_suggestion() -> void:
	if _suggestion_names.is_empty():
		return
	var chosen := _suggestion_names[0]
	var selected := _suggestions.get_selected_items()
	if selected.size() > 0:
		chosen = _suggestion_names[selected[0]]
	_command_input.text = chosen + " "
	_command_input.caret_column = _command_input.text.length()
	_dismiss_suggestions()
	_show_usage_hint(chosen)


func _on_suggestion_activated(index: int) -> void:
	if index < 0 or index >= _suggestion_names.size():
		return
	_command_input.text = _suggestion_names[index] + " "
	_command_input.caret_column = _command_input.text.length()
	_dismiss_suggestions()
	_show_usage_hint(_command_input.text.strip_edges())
	_command_input.grab_focus()


func _move_suggestion_selection(direction: int) -> void:
	if _suggestions.item_count == 0:
		return
	var current := _suggestions.get_selected_items()
	var index := (current[0] if current.size() > 0 else 0) + direction
	index = clampi(index, 0, _suggestions.item_count - 1)
	_suggestions.select(index)


func _show_usage_hint(command_name: String) -> void:
	if _service == null:
		return
	var meta: Dictionary = _service.call("get_command_metadata", command_name)
	if meta.is_empty():
		return
	_status_label.text = "USAGE: %s" % String(meta.get("usage", command_name))


# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

func _navigate_history(direction: int) -> void:
	if _service == null:
		return
	var history: Array = _service.call("get_history")
	if history.is_empty():
		return
	if direction < 0 and _history_cursor == -1:
		return
	if _history_cursor == -1:
		_pending_text = _command_input.text
	_history_cursor += direction
	if _history_cursor >= history.size():
		_history_cursor = history.size() - 1
	if _history_cursor < 0:
		_history_cursor = -1
		_command_input.text = _pending_text
	else:
		_command_input.text = String(history[(history.size() - 1) - _history_cursor])
	_command_input.caret_column = _command_input.text.length()


# ---------------------------------------------------------------------------
# Key handling -- intercepted ahead of the GUI input system so a focused
# LineEdit does not swallow Tab/Up/Down/Escape before the console sees them.
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible or _service == null:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed:
		return
	if not _command_input.has_focus() and not _suggestions.visible:
		return
	match key_event.keycode:
		KEY_ESCAPE:
			if key_event.echo:
				return
			if _suggestions.visible:
				_dismiss_suggestions()
			else:
				_service.call("close_console")
			get_viewport().set_input_as_handled()
		KEY_TAB:
			_complete_selected_suggestion()
			get_viewport().set_input_as_handled()
		KEY_UP:
			if _suggestions.visible:
				_move_suggestion_selection(-1)
			else:
				_navigate_history(1)
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			if _suggestions.visible:
				_move_suggestion_selection(1)
			else:
				_navigate_history(-1)
			get_viewport().set_input_as_handled()


func _on_input_focus_changed(focused: bool) -> void:
	Style.apply_focused_input_frame(_input_frame, focused)
