extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const PATCH_PICKUP_SCENE := preload("res://game/actors/items/consumables/lattice_field_patch_pickup.tscn")
const FabricationTerminalViewModelScript := preload("res://game/ui/terminal/fabrication_terminal_view_model.gd")

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
	await _validate_terminal_fabrication_restock(root)
	await _validate_emergency_cache_pickup(root)

	if _failed:
		push_error("field_patch_smoke failed")
		quit(1)
		return
	print("field_patch_smoke passed")
	quit(0)


func _validate_input_binding() -> void:
	_assert_true(InputMap.has_action("use_field_patch"), "use_field_patch input action should exist")
	_assert_true(_action_has_key("use_field_patch", KEY_P), "use_field_patch should include P")
	_assert_true(not _action_has_key("use_field_patch", KEY_B), "use_field_patch should not share B with build")
	_assert_true(_action_has_key("build", KEY_B), "build should keep B")


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


func _validate_terminal_fabrication_restock(root: Node) -> void:
	var ledger := get_root().get_node_or_null("/root/ResourceLedger")
	var fab_pipeline := get_root().get_node_or_null("/root/FabPipeline")
	_assert_true(ledger != null, "ResourceLedger should be available for Field Patch fabrication")
	_assert_true(fab_pipeline != null, "FabPipeline should be available for Field Patch fabrication")
	if ledger == null or fab_pipeline == null:
		return

	ledger.call("clear")
	fab_pipeline.call("clear_jobs")

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set("field_patch_max_count", 2)
	operator.set("field_patch_count", 1)

	ledger.call("add", "resin_clot", 2)
	ledger.call("add", "signal_filament", 1)
	ledger.call("add", "capacitor_dust", 1)

	_assert_true(bool(fab_pipeline.call("has_recipe", "lattice_field_patch")), "lattice_field_patch fabrication recipe should exist")
	_assert_true(bool(fab_pipeline.call("can_start_recipe", "lattice_field_patch")), "lattice_field_patch should be craftable below carry cap with materials")
	var view_model := FabricationTerminalViewModelScript.new() as FabricationTerminalViewModel
	var below_cap_view := view_model.build(root, "lattice_field_patch")
	var below_cap_row := _find_work_order(below_cap_view.get("work_orders", []), "lattice_field_patch")
	_assert_true(str(below_cap_row.get("state", "")) == "READY", "lattice_field_patch terminal row should be READY below carry cap")
	var started := bool(fab_pipeline.call("try_start_recipe", "lattice_field_patch"))
	_assert_true(started, "lattice_field_patch fabrication should start")
	await _wait_for_fab_jobs(fab_pipeline, 3.0)
	_assert_true(int(operator.get("field_patch_count")) == 2, "lattice_field_patch fabrication should add one carried patch")
	_assert_true(int(ledger.call("get_amount", "resin_clot")) == 0, "lattice_field_patch should spend resin_clot")
	_assert_true(int(ledger.call("get_amount", "signal_filament")) == 0, "lattice_field_patch should spend signal_filament")
	_assert_true(int(ledger.call("get_amount", "capacitor_dust")) == 0, "lattice_field_patch should spend capacitor_dust")

	ledger.call("add", "resin_clot", 2)
	ledger.call("add", "signal_filament", 1)
	ledger.call("add", "capacitor_dust", 1)
	_assert_true(not bool(fab_pipeline.call("can_start_recipe", "lattice_field_patch")), "lattice_field_patch should be disabled at carry cap")
	var at_cap_view := view_model.build(root, "lattice_field_patch")
	var at_cap_row := _find_work_order(at_cap_view.get("work_orders", []), "lattice_field_patch")
	_assert_true(str(at_cap_row.get("state", "")) == "CARRIED MAX", "lattice_field_patch terminal row should show CARRIED MAX at cap")
	_assert_true(str(at_cap_row.get("action_text", "")) == "CARRY CAP REACHED", "lattice_field_patch terminal action should be disabled at cap")
	var blocked := bool(fab_pipeline.call("try_start_recipe", "lattice_field_patch"))
	_assert_true(not blocked, "lattice_field_patch fabrication should not start at carry cap")
	_assert_true(int(ledger.call("get_amount", "resin_clot")) == 2, "carry-cap blocked fabrication should not spend resources")
	operator.queue_free()


func _wait_for_fab_jobs(fab_pipeline: Node, max_seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var jobs: Array = fab_pipeline.call("get_jobs_snapshot")
		if jobs.is_empty():
			return
		await process_frame


func _find_work_order(rows: Array, row_id: String) -> Dictionary:
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row := row_variant as Dictionary
		if str(row.get("id", "")) == row_id:
			return row
	return {}


func _validate_emergency_cache_pickup(root: Node) -> void:
	var ledger := get_root().get_node_or_null("/root/ResourceLedger")
	_assert_true(ledger != null, "ResourceLedger should be available for emergency cache fallback")
	if ledger == null:
		return

	ledger.call("clear")

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set("field_patch_max_count", 2)
	operator.set("field_patch_count", 1)

	var pickup := PATCH_PICKUP_SCENE.instantiate()
	root.add_child(pickup)
	await process_frame
	pickup.call("_on_body_entered", operator)
	_assert_true(int(operator.get("field_patch_count")) == 2, "emergency cache should grant a patch below cap")

	var full_pickup := PATCH_PICKUP_SCENE.instantiate()
	root.add_child(full_pickup)
	await process_frame
	full_pickup.call("_on_body_entered", operator)
	_assert_true(int(operator.get("field_patch_count")) == 2, "emergency cache should not exceed patch cap")
	_assert_true(int(ledger.call("get_amount", "resin_clot")) == 1, "full emergency cache should grant fallback resin_clot")
	_assert_true(int(ledger.call("get_amount", "capacitor_dust")) == 1, "full emergency cache should grant fallback capacitor_dust")
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
