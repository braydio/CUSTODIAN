extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "FieldPatchSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	_validate_input_binding()
	await _validate_commit(root)
	await _validate_interrupt(root)
	await _validate_input_interrupt(root)
	await _validate_add_field_patches(root)

	if _failed:
		push_error("field_patch_smoke failed")
		quit(1)
		return
	print("field_patch_smoke passed")
	quit(0)


func _validate_input_binding() -> void:
	_assert_true(InputMap.has_action("use_field_patch"), "use_field_patch input action should exist")
	_assert_true(_action_has_key("use_field_patch", KEY_B), "use_field_patch should include B")


func _validate_commit(root: Node) -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("field_patch_max_count", 2)
	operator.set("field_patch_count", 1)
	operator.set("field_patch_use_duration", 1.25)
	operator.set("field_patch_restore_fraction", 0.35)
	operator.set("health", 50.0)
	operator.set("current_health", 50.0)
	operator.call("start_field_patch")

	_assert_true(bool(operator.get("_field_patch_active")), "field patch should start while damaged and stocked")
	_assert_true(is_equal_approx(float(operator.get("current_health")), 50.0), "field patch should not heal on start")

	operator.call("_update_field_patch", 0.60)
	_assert_true(is_equal_approx(float(operator.get("current_health")), 50.0), "field patch should not heal before commit")
	_assert_true(int(operator.get("field_patch_count")) == 1, "field patch should not consume before commit")

	operator.call("_update_field_patch", 0.70)
	_assert_true(not bool(operator.get("_field_patch_active")), "field patch should stop after commit")
	_assert_true(int(operator.get("field_patch_count")) == 0, "field patch should consume one patch on commit")
	_assert_true(is_equal_approx(float(operator.get("current_health")), 85.0), "field patch should restore 35% max health")
	var status: Dictionary = operator.call("get_field_patch_status")
	_assert_true(int(status.get("count", -1)) == 0, "field patch status should report spent count")
	_assert_true(not bool(status.get("active", true)), "field patch status should report inactive after commit")
	operator.queue_free()


func _validate_interrupt(root: Node) -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("field_patch_count", 1)
	operator.set("field_patch_use_duration", 1.25)
	operator.set("health", 50.0)
	operator.set("current_health", 50.0)
	operator.call("start_field_patch")
	operator.call("_update_field_patch", 0.50)
	operator.call("take_damage", 5.0, false)

	_assert_true(not bool(operator.get("_field_patch_active")), "damage should interrupt field patch before commit")
	_assert_true(int(operator.get("field_patch_count")) == 1, "interrupted field patch should preserve count")
	_assert_true(is_equal_approx(float(operator.get("current_health")), 45.0), "interrupted field patch should not heal")

	operator.call("_update_field_patch", 1.0)
	_assert_true(is_equal_approx(float(operator.get("current_health")), 45.0), "interrupted field patch should not heal later")
	operator.queue_free()


func _validate_input_interrupt(root: Node) -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("field_patch_count", 1)
	operator.set("health", 50.0)
	operator.set("current_health", 50.0)
	operator.call("start_field_patch")
	Input.action_press("attack_primary")
	operator.call("_handle_field_patch_interrupt_input")
	Input.action_release("attack_primary")

	_assert_true(not bool(operator.get("_field_patch_active")), "attack input should interrupt field patch")
	_assert_true(int(operator.get("field_patch_count")) == 1, "input-interrupted field patch should preserve count")
	_assert_true(is_equal_approx(float(operator.get("current_health")), 50.0), "input-interrupted field patch should not heal")
	operator.queue_free()


func _validate_add_field_patches(root: Node) -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	operator.set("field_patch_max_count", 2)
	operator.set("field_patch_count", 1)
	var gained := int(operator.call("add_field_patches", 5))
	_assert_true(gained == 1, "add_field_patches should report only the capped gain")
	_assert_true(int(operator.get("field_patch_count")) == 2, "add_field_patches should clamp at max count")
	operator.queue_free()


func _action_has_key(action_name: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var event_key := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			if event_key == keycode:
				return true
	return false


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
