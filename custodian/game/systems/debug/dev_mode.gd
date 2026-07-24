extends Node

signal capabilities_changed(capabilities: Dictionary)
signal playtest_controls_changed(controls: Dictionary)

const SETTING_ENABLED := "custodian/dev/enabled"
const SETTING_HEAVY_DIAGNOSTICS := "custodian/dev/heavy_diagnostics"
const DEBUG_CAMERA_ACTION := &"debug_free_camera"
const INFINITE_HEALTH_ACTION := &"debug_infinite_health"
const INFINITE_STAMINA_ACTION := &"debug_infinite_stamina"
const STATUS_HOLD_SEC := 2.5

var enabled := false
var debug_ui_enabled := false
var observatory_sampling_enabled := false
var heavy_diagnostics_enabled := false
var debug_free_camera_enabled := false
var infinite_health_enabled := false
var infinite_stamina_enabled := false

var _status_layer: CanvasLayer
var _status_label: Label
var _status_hold_remaining := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	refresh()


func _process(delta: float) -> void:
	if _status_label == null:
		return
	if _status_hold_remaining > 0.0:
		_status_hold_remaining = maxf(
			0.0,
			_status_hold_remaining - maxf(delta, 0.0)
		)
	_update_status_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not debug_ui_enabled or event.is_echo():
		return
	if event.is_action_pressed(DEBUG_CAMERA_ACTION):
		set_debug_free_camera_enabled(not debug_free_camera_enabled)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(INFINITE_HEALTH_ACTION):
		set_infinite_health_enabled(not infinite_health_enabled)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(INFINITE_STAMINA_ACTION):
		set_infinite_stamina_enabled(not infinite_stamina_enabled)
		get_viewport().set_input_as_handled()


func refresh() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_args():
		if not args.has(argument):
			args.append(argument)
	for argument in OS.get_cmdline_user_args():
		if not args.has(argument):
			args.append(argument)
	var resolved := resolve_capabilities(
		OS.is_debug_build(),
		OS.has_feature("custodian_dev"),
		bool(ProjectSettings.get_setting(SETTING_ENABLED, false)),
		args,
		bool(ProjectSettings.get_setting(SETTING_HEAVY_DIAGNOSTICS, false))
	)
	enabled = bool(resolved.get("enabled", false))
	debug_ui_enabled = bool(resolved.get("debug_ui_enabled", false))
	observatory_sampling_enabled = bool(resolved.get("observatory_sampling_enabled", false))
	heavy_diagnostics_enabled = bool(resolved.get("heavy_diagnostics_enabled", false))
	if not debug_ui_enabled:
		debug_free_camera_enabled = false
		infinite_health_enabled = false
		infinite_stamina_enabled = false
	else:
		_ensure_status_overlay()
	capabilities_changed.emit(get_capabilities())
	playtest_controls_changed.emit(get_playtest_controls())
	_update_status_overlay()


func allows(capability: StringName) -> bool:
	match capability:
		&"dev", &"enabled":
			return enabled
		&"debug_ui":
			return debug_ui_enabled
		&"observatory_sampling":
			return observatory_sampling_enabled
		&"heavy_diagnostics":
			return heavy_diagnostics_enabled
		_:
			return false


func get_capabilities() -> Dictionary:
	return {
		"enabled": enabled,
		"debug_ui_enabled": debug_ui_enabled,
		"observatory_sampling_enabled": observatory_sampling_enabled,
		"heavy_diagnostics_enabled": heavy_diagnostics_enabled,
	}


func set_debug_free_camera_enabled(value: bool) -> void:
	_set_playtest_control(&"debug_free_camera", value)


func set_infinite_health_enabled(value: bool) -> void:
	_set_playtest_control(&"infinite_health", value)


func set_infinite_stamina_enabled(value: bool) -> void:
	_set_playtest_control(&"infinite_stamina", value)


func get_playtest_controls() -> Dictionary:
	return {
		"debug_free_camera": debug_free_camera_enabled,
		"infinite_health": infinite_health_enabled,
		"infinite_stamina": infinite_stamina_enabled,
	}


func _set_playtest_control(control: StringName, value: bool) -> void:
	if value and not debug_ui_enabled:
		return
	match control:
		&"debug_free_camera":
			debug_free_camera_enabled = value
		&"infinite_health":
			infinite_health_enabled = value
		&"infinite_stamina":
			infinite_stamina_enabled = value
		_:
			return
	_status_hold_remaining = STATUS_HOLD_SEC
	_apply_operator_resource_overrides()
	playtest_controls_changed.emit(get_playtest_controls())
	_update_status_overlay()
	print(
		"[DevMode] %s: %s"
		% [String(control), "ON" if value else "OFF"]
	)


func _apply_operator_resource_overrides() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null \
			and player.has_method("apply_debug_resource_overrides"):
		player.call("apply_debug_resource_overrides")


func _ensure_input_actions() -> void:
	_ensure_action_key(DEBUG_CAMERA_ACTION, KEY_F6)
	_ensure_action_key(INFINITE_HEALTH_ACTION, KEY_F7)
	_ensure_action_key(INFINITE_STAMINA_ACTION, KEY_F8)


func _ensure_action_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey \
			and (existing as InputEventKey).keycode == keycode:
			return
	var key := InputEventKey.new()
	key.keycode = keycode
	InputMap.action_add_event(action, key)


func _ensure_status_overlay() -> void:
	if _status_layer != null and is_instance_valid(_status_layer):
		return
	_status_layer = CanvasLayer.new()
	_status_layer.name = "DevPlaytestControlsOverlay"
	_status_layer.layer = 120
	add_child(_status_layer)

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.position = Vector2(18.0, 18.0)
	_status_label.add_theme_color_override(
		"font_color",
		Color(0.84, 0.94, 1.0, 1.0)
	)
	_status_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.92)
	)
	_status_label.add_theme_constant_override("shadow_offset_x", 2)
	_status_label.add_theme_constant_override("shadow_offset_y", 2)
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_layer.add_child(_status_label)


func _update_status_overlay() -> void:
	if _status_label == null:
		return
	var has_active_control := debug_free_camera_enabled \
		or infinite_health_enabled \
		or infinite_stamina_enabled
	_status_label.visible = debug_ui_enabled \
		and (has_active_control or _status_hold_remaining > 0.0)
	if not _status_label.visible:
		return
	var rows: Array[String] = [
		"PLAYTEST  F6 Camera  F7 Health  F8 Stamina",
		"Camera: %s | Health: %s | Stamina: %s"
		% [
			"FREE (arrows / MMB / wheel)"
				if debug_free_camera_enabled else "follow",
			"∞" if infinite_health_enabled else "normal",
			"∞" if infinite_stamina_enabled else "normal",
		],
	]
	_status_label.text = "\n".join(rows)


static func resolve_capabilities(
	debug_build: bool,
	custodian_dev_feature: bool,
	project_enabled: bool,
	command_line_args: PackedStringArray,
	project_heavy_diagnostics: bool = false
) -> Dictionary:
	var explicitly_enabled := _has_any_arg(command_line_args, [
		"--custodian-dev", "--dev-mode", "--debug-ui", "--observe", "--heavy-diagnostics",
	])
	var base_enabled := debug_build or custodian_dev_feature or project_enabled or explicitly_enabled
	if _has_any_arg(command_line_args, ["--no-custodian-dev", "--no-dev-mode"]):
		base_enabled = false
	var debug_ui := base_enabled and not _has_any_arg(command_line_args, ["--no-debug-ui"])
	var observatory := base_enabled and not _has_any_arg(command_line_args, ["--no-observe"])
	var heavy := base_enabled \
		and (project_heavy_diagnostics or _has_any_arg(command_line_args, ["--heavy-diagnostics"])) \
		and not _has_any_arg(command_line_args, ["--no-heavy-diagnostics"])
	return {
		"enabled": base_enabled,
		"debug_ui_enabled": debug_ui,
		"observatory_sampling_enabled": observatory,
		"heavy_diagnostics_enabled": heavy,
	}


static func _has_any_arg(args: PackedStringArray, candidates: Array[String]) -> bool:
	for candidate in candidates:
		if args.has(candidate):
			return true
	return false
