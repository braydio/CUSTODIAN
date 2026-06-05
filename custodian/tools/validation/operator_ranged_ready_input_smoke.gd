extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")

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
	_assert_true(not _action_has_mouse_button("block", MOUSE_BUTTON_RIGHT), "block should not include right mouse")
	_assert_true(_action_has_key("block", KEY_R), "block should remain available on R")


func _validate_carbine_intents() -> void:
	_assert_true(CARBINE_DEFINITION.secondary_intent == "ranged_ready", "carbine secondary intent should ready/aim, not fire")
	_assert_true(CARBINE_DEFINITION.primary_intent.begins_with("ranged_"), "carbine primary intent should remain ranged")


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

	operator.call("_exit_ranged_ready")
	_assert_true(not bool(operator.call("_is_ranged_ready_active")), "exiting ranged-ready should clear the ready state")
	operator.queue_free()


func _action_has_mouse_button(action_name: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null and mouse_event.button_index == button:
			return true
	return false


func _action_has_key(action_name: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == key:
			return true
	return false


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
