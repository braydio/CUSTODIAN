extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")
const SIDEARM_DEFINITION := preload("res://game/actors/operator/sidearm_pistol_definition.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorRangedReadyInputSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	_validate_input_bindings()
	_validate_carbine_intents()
	_validate_sidearm_profile()
	await _validate_operator_ranged_ready(root)

	if _failed:
		push_error("operator_ranged_ready_input_smoke failed")
		quit(1)
		return
	print("operator_ranged_ready_input_smoke passed")
	quit()


func _validate_input_bindings() -> void:
	_assert_true(_action_has_mouse_button("attack_primary", MOUSE_BUTTON_LEFT), "attack_primary should include left mouse")
	_assert_true(_action_has_mouse_button("attack_secondary", MOUSE_BUTTON_RIGHT), "attack_secondary should include right mouse")
	_assert_true(_action_has_joy_axis("attack_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0), "attack_primary should include right trigger")
	_assert_true(_action_has_joy_axis("attack_secondary", JOY_AXIS_TRIGGER_LEFT, 1.0), "attack_secondary should include left trigger")
	_assert_true(_action_has_mouse_button("fire_primary", MOUSE_BUTTON_LEFT), "fire_primary should include left mouse")
	_assert_true(_action_has_mouse_button("aim_hold", MOUSE_BUTTON_RIGHT), "aim_hold should include right mouse")
	_assert_true(_action_has_joy_axis("fire_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0), "fire_primary should include right trigger")
	_assert_true(_action_has_joy_axis("aim_hold", JOY_AXIS_TRIGGER_LEFT, 1.0), "aim_hold should include left trigger")
	_assert_true(not _action_has_mouse_button("block", MOUSE_BUTTON_RIGHT), "block should not include right mouse")
	_assert_true(not _action_has_key("block", KEY_R), "block should not consume R after reload remap")
	_assert_true(_action_has_key("move_left", KEY_A), "move_left should include A")
	_assert_true(_action_has_key("move_right", KEY_D), "move_right should include D")
	_assert_true(_action_has_key("move_up", KEY_W), "move_up should include W")
	_assert_true(_action_has_key("move_down", KEY_S), "move_down should include S")
	_assert_true(_action_has_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0), "move_left should include left stick left")
	_assert_true(_action_has_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0), "move_right should include left stick right")
	_assert_true(_action_has_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0), "move_up should include left stick up")
	_assert_true(_action_has_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0), "move_down should include left stick down")
	_assert_true(_action_has_joy_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0), "aim_left should include right stick left")
	_assert_true(_action_has_joy_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0), "aim_right should include right stick right")
	_assert_true(_action_has_joy_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0), "aim_up should include right stick up")
	_assert_true(_action_has_joy_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0), "aim_down should include right stick down")
	_assert_true(_action_has_key("dodge", KEY_SPACE), "dodge should include Space")
	_assert_true(_action_has_joy_button("dodge", JOY_BUTTON_B), "dodge should include Xbox B")
	_assert_true(_action_has_key("interact", KEY_E), "interact should include E")
	_assert_true(_action_has_joy_button("interact", JOY_BUTTON_A), "interact should include Xbox A")
	_assert_true(_action_has_key("toggle_inventory", KEY_TAB), "toggle_inventory should include Tab")
	_assert_true(_action_has_key("inventory", KEY_I), "inventory should include I")
	_assert_true(_action_has_joy_button("inventory", JOY_BUTTON_Y), "inventory should include Xbox Y")
	_assert_true(_action_has_key("reload_weapon", KEY_R), "reload_weapon should include R")
	_assert_true(_action_has_key("reload", KEY_R), "reload should include R")
	_assert_true(_action_has_joy_button("reload", JOY_BUTTON_X), "reload should include Xbox X")
	_assert_true(_action_has_key("quick_item", KEY_Q), "quick_item should include Q")
	_assert_true(_action_has_joy_button("quick_item", JOY_BUTTON_DPAD_UP), "quick_item should include D-pad up")
	_assert_true(_action_has_key("cycle_item_left", KEY_Z), "cycle_item_left should include Z")
	_assert_true(_action_has_key("cycle_item_right", KEY_C), "cycle_item_right should include C")
	_assert_true(_action_has_joy_button("cycle_item_left", JOY_BUTTON_DPAD_LEFT), "cycle_item_left should include D-pad left")
	_assert_true(_action_has_joy_button("cycle_item_right", JOY_BUTTON_DPAD_RIGHT), "cycle_item_right should include D-pad right")
	_assert_true(_action_has_key("sneak", KEY_CTRL), "sneak should move to Ctrl")
	_assert_true(not _action_has_key("sneak", KEY_C), "sneak should not consume C after cycle-item remap")
	_assert_true(not _action_has_key("camera_follow_toggle", KEY_C), "camera debug toggle should not consume C")
	_assert_true(not _action_has_key("camera_auto_zoom_toggle", KEY_Z), "camera debug toggle should not consume Z")
	_assert_true(_action_has_key("pause", KEY_ESCAPE), "pause should include Escape")
	_assert_true(_action_has_joy_button("pause", JOY_BUTTON_START), "pause should include Start/Menu")
	_assert_true(_action_has_key("map", KEY_M), "map should include M")
	_assert_true(_action_has_joy_button("map", JOY_BUTTON_BACK), "map should include View/Back")


func _validate_carbine_intents() -> void:
	_assert_true(CARBINE_DEFINITION.secondary_intent == "ranged_ready", "carbine secondary intent should ready/aim, not fire")
	_assert_true(CARBINE_DEFINITION.primary_intent.begins_with("ranged_"), "carbine primary intent should remain ranged")


func _validate_sidearm_profile() -> void:
	_assert_true(SIDEARM_DEFINITION.weapon_id == &"sidearm_pistol", "sidearm should use the dedicated inventory-slot weapon id")
	_assert_true(SIDEARM_DEFINITION.weapon_type == &"ranged_sidearm", "sidearm should not masquerade as a 2h ranged primary")
	_assert_true(SIDEARM_DEFINITION.weapon_data_path == "res://content/weapons/data/pistol_mk1.json", "sidearm should use the pistol default profile")
	_assert_true(SIDEARM_DEFINITION.animation_map.get("ranged_stance", "") == "ranged_2h_stance", "sidearm V1 should use current ranged placeholder stance")


func _validate_operator_ranged_ready(root: Node) -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.call("_exit_ranged_ready")

	_assert_true(operator.call("_get_active_ranged_weapon_definition") != null, "operator should find the carried ranged weapon for held ready")
	_assert_true(bool(operator.call("_can_enter_ranged_ready")), "operator should be able to enter ranged-ready from non-ranged loadout")

	operator.call("_enter_ranged_ready")
	_assert_true(bool(operator.call("_is_ranged_ready_active")), "entering ranged-ready should set the ready state")
	_assert_true(bool(operator.call("_is_ranged_context_active")), "ranged-ready should create an active ranged context")
	_assert_true(bool(operator.call("_is_using_ranged_2h_primary")), "ranged-ready should show the ranged weapon layer")
	_assert_true(bool(operator.call("_is_using_ranged_weapon_visual")), "ranged-ready should show a ranged visual layer")
	_assert_true((operator.call("_resolve_dodge_direction") as Vector2).is_equal_approx(Vector2.LEFT), "idle aiming dodge should hop back away from aim")

	operator.call("_exit_ranged_ready")
	_assert_true(not bool(operator.call("_is_ranged_ready_active")), "exiting ranged-ready should clear the ready state")
	operator.set("visual_idle_direction", Vector2.DOWN)
	_assert_true((operator.call("_resolve_dodge_direction") as Vector2).is_equal_approx(Vector2.DOWN), "fully idle dodge should use current facing")
	_validate_dodge_fx_overlay(operator)
	_validate_sidearm_ranged_ready(operator)
	operator.queue_free()


func _validate_sidearm_ranged_ready(operator: Node) -> void:
	operator.call("_exit_ranged_ready")
	operator.set("primary_weapon_definition", null)
	operator.set("primary_weapon_equipped", false)
	operator.set("sidearm_weapon_definition", SIDEARM_DEFINITION)
	operator.set("sidearm_slot_equipped", true)
	operator.set("combat_loadout_mode", "melee")
	operator.set("aim_direction", Vector2.RIGHT)
	_assert_true(bool(operator.call("_can_enter_ranged_ready")), "operator should be able to ready sidearm with no ranged primary equipped")
	operator.call("_enter_ranged_ready")
	_assert_true(bool(operator.call("_is_ranged_ready_active")), "sidearm should enter ranged-ready")
	_assert_true(operator.call("_get_active_ranged_weapon_definition") == SIDEARM_DEFINITION, "active ranged weapon should be the sidearm slot")
	_assert_true(not bool(operator.call("_is_using_ranged_2h_primary")), "sidearm should not report as the 2h primary")
	_assert_true(bool(operator.call("_is_using_ranged_weapon_visual")), "sidearm should still use the ranged visual presentation")
	var profile: Dictionary = operator.call("_get_current_ranged_profile")
	_assert_true(is_equal_approx(float(profile.get("damage", 0.0)), 18.0), "sidearm should read pistol damage profile")
	_assert_true(operator.call("_get_current_magazine_size") == 12, "sidearm should read pistol magazine size")
	operator.call("_exit_ranged_ready")


func _validate_dodge_fx_overlay(operator: Node) -> void:
	var body_sprite := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var dodge_fx := operator.get_node_or_null("DodgeFXBackSprite") as AnimatedSprite2D
	_assert_true(body_sprite != null, "operator should expose the body sprite")
	_assert_true(dodge_fx != null, "operator should expose a dedicated dodge back FX sprite")
	if body_sprite == null or dodge_fx == null:
		return
	_assert_true(dodge_fx.z_index < body_sprite.z_index, "dodge FX should render behind/under the Custodian body")
	_assert_true(dodge_fx.sprite_frames != null and dodge_fx.sprite_frames.has_animation(&"operator_dodge_step_fx"), "dodge FX sprite should own the dodge FX animation")
	operator.set("stamina", 100.0)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.RIGHT)
	_add_placeholder_animation(body_sprite.sprite_frames, &"operator_dodge_recovery")
	_assert_true(bool(operator.call("_try_start_dodge")), "operator should start a deterministic dodge")
	_assert_true(String(body_sprite.animation) == "operator_dodge_step", "dodge should start the body dodge track")
	_assert_true(String(dodge_fx.animation) == "operator_dodge_step_fx", "dodge should start the synchronized FX track")
	_assert_true(body_sprite.frame == 0, "body dodge should restart on frame 0")
	_assert_true(dodge_fx.frame == 0, "dodge FX should restart on frame 0")
	_assert_true(dodge_fx.visible, "dodge FX should be visible during dodge")
	_assert_true(dodge_fx.position.x < body_sprite.position.x, "east dodge FX should be offset behind the Custodian")
	operator.call("_update_dodge", 1.0)
	_assert_true(bool(operator.get("_dodge_recovery_active")), "finishing dodge should enter recovery when a recovery animation exists")
	_assert_true(String(body_sprite.animation) == "operator_dodge_recovery", "dodge recovery should play as the second phase")
	operator.call("_cancel_dodge")
	_assert_true(not dodge_fx.visible, "canceling dodge should hide the dodge FX")


func _add_placeholder_animation(sprite_frames: SpriteFrames, animation_name: StringName) -> void:
	if sprite_frames == null or sprite_frames.has_animation(animation_name):
		return
	var texture := PlaceholderTexture2D.new()
	texture.size = Vector2(96, 96)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 18.0)
	sprite_frames.add_frame(animation_name, texture)


func _action_has_mouse_button(action_name: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null and mouse_event.button_index == button:
			return true
	return false


func _action_has_key(action_name: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		var key_event := event as InputEventKey
		if key_event != null and (key_event.physical_keycode == key or key_event.keycode == key or key_event.key_label == key):
			return true
	return false


func _action_has_joy_axis(action_name: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action_name):
		var axis_event := event as InputEventJoypadMotion
		if axis_event != null and axis_event.axis == axis and is_equal_approx(axis_event.axis_value, axis_value):
			return true
	return false


func _action_has_joy_button(action_name: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		var button_event := event as InputEventJoypadButton
		if button_event != null and button_event.button_index == button:
			return true
	return false


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
