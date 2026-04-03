extends Node

const OVERLAY_MODE_COUNT := 6

const INPUT_DEFS := [
	{"action": "debug_toggle", "keycode": KEY_F3, "shift": false},
	{"action": "debug_minimal", "keycode": KEY_F3, "shift": true},
	{"action": "debug_overlay_cycle", "keycode": KEY_F4, "shift": false},
	{"action": "debug_lock_inspector", "keycode": KEY_F5, "shift": false},
]


func _get_debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -20
	set_process_input(true)
	set_process(true)
	_ensure_input_map()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var debug_bus := _get_debug_bus()
	if debug_bus != null:
		debug_bus.clear_frame_overlays()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	if event.is_action_pressed("debug_toggle"):
		debug_bus.enabled = not debug_bus.enabled
		return
	if event.is_action_pressed("debug_minimal"):
		debug_bus.minimal_mode = not debug_bus.minimal_mode
		return
	if event.is_action_pressed("debug_overlay_cycle"):
		debug_bus.overlay_mode = (debug_bus.overlay_mode + 1) % OVERLAY_MODE_COUNT
		return
	if event.is_action_pressed("debug_lock_inspector"):
		debug_bus.toggle_selected_entity(debug_bus.hovered_entity)
		return
	if debug_bus.enabled and event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			debug_bus.toggle_selected_entity(debug_bus.hovered_entity)

func _ensure_input_map() -> void:
	for definition in INPUT_DEFS:
		var action: String = definition.action
		var keycode: int = definition.keycode
		var shift: bool = definition.shift
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if _action_has_key(action, keycode, shift):
			continue
		var event := InputEventKey.new()
		event.keycode = keycode
		event.shift_pressed = shift
		InputMap.action_add_event(action, event)

func _action_has_key(action: String, keycode: int, shift: bool) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == keycode and key_event.shift_pressed == shift:
				return true
	return false
