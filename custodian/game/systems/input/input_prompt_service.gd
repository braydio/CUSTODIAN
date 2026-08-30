extends Node

signal device_family_changed(device_family: StringName)

const KEYBOARD_MOUSE := &"keyboard_mouse"
const GAMEPAD := &"gamepad"
const JOYPAD_MOTION_THRESHOLD := 0.35
const MOUSE_MOTION_THRESHOLD := 2.0

const XBOX_BUTTON_LABELS := {
	0: "A", 1: "B", 2: "X", 3: "Y", 4: "VIEW", 6: "MENU",
	7: "L3", 8: "R3", 9: "LB", 10: "RB",
	11: "D-PAD UP", 12: "D-PAD DOWN", 13: "D-PAD LEFT", 14: "D-PAD RIGHT",
}
const XBOX_AXIS_LABELS := {4: "LT", 5: "RT"}

var device_family: StringName = KEYBOARD_MOUSE


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_set_device_family(GAMEPAD)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= JOYPAD_MOTION_THRESHOLD:
		_set_device_family(GAMEPAD)
	elif event is InputEventKey and event.pressed and not event.echo:
		_set_device_family(KEYBOARD_MOUSE)
	elif event is InputEventMouseButton and event.pressed:
		_set_device_family(KEYBOARD_MOUSE)
	elif event is InputEventMouseMotion and event.relative.length() >= MOUSE_MOTION_THRESHOLD:
		_set_device_family(KEYBOARD_MOUSE)


func is_gamepad_active() -> bool:
	return device_family == GAMEPAD


func resolve_action_label(action: StringName, family: StringName = &"") -> String:
	var resolved_family := device_family if family.is_empty() else family
	if not InputMap.has_action(action):
		return String(action).to_upper()
	for event in InputMap.action_get_events(action):
		if resolved_family == GAMEPAD:
			if event is InputEventJoypadButton:
				return str(XBOX_BUTTON_LABELS.get(event.button_index, "PAD %d" % event.button_index))
			if event is InputEventJoypadMotion:
				return str(XBOX_AXIS_LABELS.get(event.axis, "STICK"))
		else:
			if event is InputEventKey:
				var code: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
				return OS.get_keycode_string(code).to_upper()
			if event is InputEventMouseButton:
				return _mouse_button_label(event.button_index)
	return String(action).to_upper().replace("_", " ")


func _set_device_family(next_family: StringName) -> void:
	if next_family == device_family:
		return
	device_family = next_family
	device_family_changed.emit(device_family)


func _mouse_button_label(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT: return "LMB"
		MOUSE_BUTTON_RIGHT: return "RMB"
		MOUSE_BUTTON_MIDDLE: return "MMB"
		_: return "MOUSE %d" % button_index
