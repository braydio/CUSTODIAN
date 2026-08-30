extends SceneTree

const REQUIRED_ACTIONS := [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"aim_up", &"aim_down", &"aim_left", &"aim_right",
	&"sprint", &"sneak", &"attack_primary", &"attack_secondary",
	&"heavy_attack", &"dodge", &"interact", &"reload_weapon",
	&"toggle_inventory", &"toggle_minimap", &"use_field_patch", &"build", &"repair",
]
const EXPECTED_BUTTONS := {
	&"interact": 0, &"dodge": 1, &"reload_weapon": 2,
	&"toggle_inventory": 3, &"toggle_minimap": 4, &"pause": 6,
	&"sprint": 7, &"sneak": 8, &"repair": 9, &"heavy_attack": 10,
	&"use_field_patch": 11, &"build": 12,
	&"cycle_prev_weapon": 13, &"cycle_next_weapon": 14,
}
const EXPECTED_AXES := {
	&"move_left": [0, -1.0], &"move_right": [0, 1.0],
	&"move_up": [1, -1.0], &"move_down": [1, 1.0],
	&"aim_left": [2, -1.0], &"aim_right": [2, 1.0],
	&"aim_up": [3, -1.0], &"aim_down": [3, 1.0],
	&"attack_secondary": [4, 1.0], &"attack_primary": [5, 1.0],
}

var failures: Array[String] = []


func _initialize() -> void:
	for action in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action), "missing action %s" % action)
	for action in EXPECTED_BUTTONS:
		_expect(_has_button(action, EXPECTED_BUTTONS[action]), "%s missing button %d" % [action, EXPECTED_BUTTONS[action]])
	for action in EXPECTED_AXES:
		var expected: Array = EXPECTED_AXES[action]
		_expect(_has_axis(action, expected[0], expected[1]), "%s missing axis %d direction %.1f" % [action, expected[0], expected[1]])
	for action in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		_expect(is_equal_approx(InputMap.action_get_deadzone(action), 0.20), "%s deadzone must be 0.20" % action)
	for action in [&"aim_up", &"aim_down", &"aim_left", &"aim_right"]:
		_expect(is_equal_approx(InputMap.action_get_deadzone(action), 0.22), "%s deadzone must be 0.22" % action)
	for action in [&"attack_primary", &"fire_primary", &"attack_secondary", &"aim_hold"]:
		_expect(InputMap.action_get_deadzone(action) <= 0.20, "%s trigger deadzone remains too high" % action)
	_expect(not _has_any_joypad_event(&"quick_item"), "quick_item still collides with Field Patch controller input")
	_expect(not _has_any_joypad_event(&"cycle_item_left"), "cycle_item_left still collides with weapon cycling")
	_expect(not _has_any_joypad_event(&"cycle_item_right"), "cycle_item_right still collides with weapon cycling")
	_expect(_has_key(&"sprint"), "sprint lost keyboard compatibility")
	_expect(_has_key(&"heavy_attack"), "heavy_attack lost keyboard compatibility")

	var operator_source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	_expect(operator_source.contains('Input.is_action_pressed("sprint")'), "operator sprint is not action-driven")
	_expect(not operator_source.contains("Input.is_key_pressed(KEY_CTRL)"), "operator retains raw Ctrl gameplay dependency")
	_expect(not operator_source.contains("Input.is_key_pressed(KEY_SHIFT)"), "operator retains raw Shift gameplay dependency")

	var service := get_root().get_node_or_null("InputPromptService")
	_expect(service != null, "InputPromptService autoload missing")
	if service != null:
		_expect(service.resolve_action_label(&"interact", &"gamepad") == "A", "interact gamepad prompt is not A")
		_expect(not service.resolve_action_label(&"interact", &"keyboard_mouse").is_empty(), "interact keyboard prompt is empty")
		_expect(service.resolve_action_label(&"heavy_attack", &"gamepad") == "RB", "heavy attack gamepad prompt is not RB")

	var pause_source := FileAccess.get_file_as_string("res://game/ui/hud/pause_ui.gd")
	_expect(pause_source.contains('Input.is_action_just_pressed("ui_cancel")'), "pause UI does not handle ui_cancel")
	var inventory_source := FileAccess.get_file_as_string("res://game/ui/inventory/inventory_ui.gd")
	_expect(inventory_source.contains('event.is_action_pressed("ui_cancel")'), "inventory UI lost ui_cancel")
	_expect(inventory_source.contains("_focus_current_page()"), "inventory UI does not establish focus")

	if failures.is_empty():
		print("CONTROLLER_INPUT_CONTRACT_SMOKE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("CONTROLLER_INPUT_CONTRACT_SMOKE: FAIL (%d)" % failures.size())
		quit(1)


func _has_button(action: StringName, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _has_axis(action: StringName, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false


func _has_key(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return true
	return false


func _has_any_joypad_event(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
