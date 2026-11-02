extends CanvasLayer
class_name NpaShowcaseDebugOverlay

const REFRESH_INTERVAL := 0.25

@export var controller_path: NodePath = NodePath("../ScenarioController")

var _controller: Node
var _elapsed := 0.0
var _cards: Dictionary = {}
var _selection := OptionButton.new()
var _event_log := RichTextLabel.new()
var _spawn_button: Button
var _action_button: Button
var _damage_button: Button
var _allegiance_button: Button
var _target_button: Button
var _drone_buttons: Array[Button] = []


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	if _controller == null or not _controller.call("is_enabled"):
		queue_free()
		return
	_build_ui()
	_refresh()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= REFRESH_INTERVAL:
		_elapsed = 0.0
		_refresh()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "NpaShowcasePanel"
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "NPA SHOWCASE · LIVE RUNTIME"
	heading.add_theme_font_size_override("font_size", 16)
	column.add_child(heading)
	var selection_row := HBoxContainer.new()
	column.add_child(selection_row)
	_selection.custom_minimum_size = Vector2(190, 30)
	for actor_id in _controller.call("get_actor_ids"):
		_selection.add_item(String(actor_id).to_upper().replace("_", " "))
		_selection.set_item_metadata(_selection.item_count - 1, actor_id)
	selection_row.add_child(_selection)
	_selection.item_selected.connect(_on_actor_selected)
	_spawn_button = _button("SPAWN / REPLACE", _on_spawn_pressed)
	selection_row.add_child(_spawn_button)
	selection_row.add_child(_button("RESET", _on_reset_pressed))
	for actor_id in _controller.call("get_actor_ids"):
		var card := Label.new()
		card.text = "%s · N/A" % String(actor_id).to_upper()
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.custom_minimum_size = Vector2(420, 0)
		card.add_theme_font_size_override("font_size", 12)
		column.add_child(card)
		_cards[actor_id] = card
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_action_button = _button("ACT / ABILITY", _on_action_pressed)
	_damage_button = _button("LETHAL / LOOT", _on_damage_pressed)
	_allegiance_button = _button("TOGGLE ALLEGIANCE", _on_allegiance_pressed)
	_target_button = _button("CYCLE TARGET", _on_target_pressed)
	actions.add_child(_action_button)
	actions.add_child(_damage_button)
	actions.add_child(_allegiance_button)
	actions.add_child(_target_button)
	var drone_row := HBoxContainer.new()
	column.add_child(drone_row)
	for mode in [&"follow", &"hold", &"guard", &"recall"]:
		var button := _button("M7 %s" % String(mode).to_upper(), _on_drone_order.bind(mode))
		_drone_buttons.append(button)
		drone_row.add_child(button)
	_event_log.custom_minimum_size = Vector2(430, 95)
	_event_log.fit_content = false
	_event_log.scroll_following = true
	_event_log.bbcode_enabled = false
	_event_log.add_theme_font_size_override("normal_font_size", 11)
	column.add_child(_event_log)


func _refresh() -> void:
	if _controller == null or not is_instance_valid(_controller):
		return
	for actor_id in _cards:
		var state: Dictionary = _controller.call("get_actor_state", actor_id)
		var label: Label = _cards[actor_id]
		if state.get("status") != "LIVE":
			label.text = "%s · %s" % [String(actor_id).to_upper(), state.get("status", "N/A")]
		else:
			label.text = "%s · %s / %s · %s · targetable=%s\nHP %s · %s · target %s\nability %s · drone %s" % [
				String(actor_id).to_upper(), state.get("class", "N/A"), state.get("role", "N/A"), state.get("allegiance", "N/A"),
				state.get("target_eligible", "N/A"), state.get("health", "N/A"), state.get("corpse", "N/A"),
				state.get("target", "N/A"), state.get("ability", "N/A"), state.get("squad", "N/A")]
	var selected_id: StringName = _selection.get_item_metadata(_selection.selected) if _selection.item_count > 0 else &""
	var selected_state: Dictionary = _controller.call("get_actor_state", selected_id)
	var selected_live: bool = selected_state.get("status") == "LIVE"
	_spawn_button.disabled = not bool(selected_state.get("enabled", false))
	_action_button.disabled = not selected_live
	_damage_button.disabled = not selected_live
	_allegiance_button.disabled = not selected_live or not bool(selected_state.get("allegiance_control", false))
	_target_button.disabled = not selected_live or not bool(_controller.call("can_cycle_target", selected_id))
	for button in _drone_buttons:
		button.disabled = not _has_live_m7()
	var events: PackedStringArray = _controller.call("get_event_log")
	_event_log.text = "EVENTS\n" + "\n".join(events)


func _has_live_m7() -> bool:
	return _controller.call("get_actor_state", &"escort_frame_m7").get("status") == "LIVE"


func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(96, 30)
	button.pressed.connect(callback)
	return button


func _on_actor_selected(index: int) -> void:
	_controller.call("select_actor", _selection.get_item_metadata(index))


func _on_spawn_pressed() -> void:
	var actor_id: StringName = _selection.get_item_metadata(_selection.selected)
	_controller.call("spawn_actor", actor_id)
	_refresh()


func _on_reset_pressed() -> void:
	_controller.call("reset_scenario")
	_refresh()


func _on_action_pressed() -> void:
	_controller.call("request_actor_action", _selection.get_item_metadata(_selection.selected))
	_refresh()


func _on_damage_pressed() -> void:
	_controller.call("damage_actor", _selection.get_item_metadata(_selection.selected))
	_refresh()


func _on_allegiance_pressed() -> void:
	_controller.call("toggle_allegiance", _selection.get_item_metadata(_selection.selected))
	_refresh()


func _on_target_pressed() -> void:
	_controller.call("cycle_target", _selection.get_item_metadata(_selection.selected))
	_refresh()


func _on_drone_order(mode: StringName) -> void:
	_controller.call("set_drone_order", mode)
	_refresh()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.06, 0.91)
	style.border_color = Color(0.67, 0.56, 0.33, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
