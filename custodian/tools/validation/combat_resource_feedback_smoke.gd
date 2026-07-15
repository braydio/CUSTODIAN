extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const HUD_SCENE := preload("res://game/ui/hud/custodian_hud.tscn")

var _failures: Array[String] = []
var _events: Array[StringName] = []
var _noise_event_count := 0


func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "CombatResourceFeedbackSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root

	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child.call_deferred(operator)
	await process_frame
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set_process_input(false)
	operator.set_process_unhandled_input(false)
	operator.set("combat_loadout_mode", &"ranged")
	operator.set("using_unarmed", false)
	operator.set("primary_weapon_equipped", true)
	operator.weapon_feedback_event.connect(func(event_id: StringName, _snapshot: Dictionary) -> void: _events.append(event_id))

	var noise_bus := root.get_node_or_null("NoiseEventBus")
	if noise_bus != null and noise_bus.has_signal("noise_emitted"):
		noise_bus.noise_emitted.connect(func(_event: Variant) -> void: _noise_event_count += 1)

	var primary = operator.get("primary_weapon_definition")
	var sidearm = operator.get("sidearm_weapon_definition")
	operator.set("_ranged_ready_weapon_definition", primary)
	var primary_key: String = operator.call("_get_weapon_state_key", primary)
	var sidearm_key: String = operator.call("_get_weapon_state_key", sidearm)
	var ammo_type: String = operator.call("_get_weapon_ammo_type", primary)

	_validate_status_contract(operator)
	_validate_reload_instead_of_dry(operator, primary_key, ammo_type)
	_validate_debounced_dry_fire(operator, primary_key, ammo_type)
	_validate_overheat_feedback(operator, primary_key)
	_validate_reload_progress(operator, primary_key, ammo_type)
	_validate_weapon_switch_persistence(operator, primary, sidearm, primary_key, sidearm_key)
	await _validate_hud_read_only(scene_root, operator)
	_expect(_noise_event_count == 0, "presentation feedback emitted gameplay NoiseEventBus events")

	scene_root.queue_free()
	if _failures.is_empty():
		print("COMBAT_RESOURCE_FEEDBACK_SMOKE: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _validate_status_contract(operator: Node) -> void:
	var status: Dictionary = operator.call("get_weapon_status")
	for field in [
		"reload_remaining", "reload_total", "reload_ratio", "heat_warn_threshold",
		"overheat_threshold", "overheat_ratio", "heat_decay_delay_remaining",
		"heat_per_shot", "shots_to_overheat", "overheat_total", "overheat_recovery_ratio",
	]:
		_expect(status.has(field), "weapon status missing '%s'" % field)
	_expect(float(status.get("heat_warn_threshold", -1.0)) >= 0.0, "heat warning threshold is invalid")
	_expect(float(status.get("overheat_threshold", 0.0)) > 0.0, "overheat threshold is invalid")
	_expect(_unit_ratio(status.get("overheat_ratio", -1.0)), "overheat ratio is outside 0..1")
	_expect(_unit_ratio(status.get("reload_ratio", -1.0)), "reload ratio is outside 0..1")


func _validate_reload_instead_of_dry(operator: Node, weapon_key: String, ammo_type: String) -> void:
	_events.clear()
	operator.set("_reload_active", false)
	operator.set("loaded_ammo_by_weapon_id", _with_value(operator.get("loaded_ammo_by_weapon_id"), weapon_key, 0))
	operator.set("ammo_reserve_by_type", _with_value(operator.get("ammo_reserve_by_type"), ammo_type, 8))
	operator.call("_request_ranged_shot")
	_expect(_events.count(&"reload_started") == 1, "empty magazine with reserve did not emit reload_started once")
	_expect(not _events.has(&"dry_fire"), "empty magazine with reserve emitted dry_fire")
	operator.call("_cancel_reload")


func _validate_debounced_dry_fire(operator: Node, weapon_key: String, ammo_type: String) -> void:
	_events.clear()
	operator.set("_last_weapon_failure_feedback", &"")
	operator.set("_weapon_failure_feedback_cooldown", 0.0)
	operator.set("loaded_ammo_by_weapon_id", _with_value(operator.get("loaded_ammo_by_weapon_id"), weapon_key, 0))
	operator.set("ammo_reserve_by_type", _with_value(operator.get("ammo_reserve_by_type"), ammo_type, 0))
	for _attempt in range(8):
		operator.call("_request_ranged_shot")
	_expect(_events.count(&"dry_fire") == 1, "held empty fire was not debounced to one dry_fire event")


func _validate_overheat_feedback(operator: Node, weapon_key: String) -> void:
	_events.clear()
	operator.set("_last_weapon_failure_feedback", &"")
	operator.set("_weapon_failure_feedback_cooldown", 0.0)
	operator.set("weapon_heat_by_id", _with_value(operator.get("weapon_heat_by_id"), weapon_key, 0.0))
	operator.set("weapon_heat_delay_by_id", _with_value(operator.get("weapon_heat_delay_by_id"), weapon_key, 0.0))
	operator.set("weapon_overheat_by_id", _with_value(operator.get("weapon_overheat_by_id"), weapon_key, 0.0))
	for _shot in range(10):
		operator.call("_apply_heat_for_shot")
	_expect(_events.count(&"heat_hot") == 1, "hot transition did not emit exactly once")
	_expect(_events.count(&"heat_critical") == 1, "critical transition did not emit exactly once")
	_expect(_events.count(&"overheated") == 1, "overheat entry did not emit exactly once")
	var before_blocked := _events.size()
	for _attempt in range(20):
		operator.call("_request_ranged_shot")
	_expect(_events.size() <= before_blocked + 1, "held fire during overheat flooded feedback events")
	operator.call("_update_weapon_heat", 2.0)
	_expect(_events.count(&"overheat_recovered") == 1, "overheat recovery did not emit exactly once")


func _validate_reload_progress(operator: Node, weapon_key: String, ammo_type: String) -> void:
	operator.set("weapon_overheat_by_id", _with_value(operator.get("weapon_overheat_by_id"), weapon_key, 0.0))
	operator.set("loaded_ammo_by_weapon_id", _with_value(operator.get("loaded_ammo_by_weapon_id"), weapon_key, 0))
	operator.set("ammo_reserve_by_type", _with_value(operator.get("ammo_reserve_by_type"), ammo_type, 18))
	operator.set("_reload_active", false)
	operator.call("_try_start_reload")
	var start: Dictionary = operator.call("get_weapon_status")
	var total := float(start.get("reload_total", 0.0))
	operator.call("_update_reload", total * 0.5)
	var middle: Dictionary = operator.call("get_weapon_status")
	_expect(float(middle.get("reload_ratio", 0.0)) >= float(start.get("reload_ratio", 0.0)), "reload progress was not monotonic")
	operator.call("_update_reload", total)
	var finished: Dictionary = operator.call("get_weapon_status")
	_expect(not bool(finished.get("reloading", true)), "reload did not complete")
	_expect(int(finished.get("loaded_ammo", 0)) == 18, "reload transferred incorrect loaded ammo")
	_expect(int(finished.get("reserve_ammo", -1)) == 0, "reload transferred incorrect reserve ammo")


func _validate_weapon_switch_persistence(operator: Node, primary: Variant, sidearm: Variant, primary_key: String, sidearm_key: String) -> void:
	operator.set("sidearm_slot_equipped", true)
	operator.set("loaded_ammo_by_weapon_id", _with_value(operator.get("loaded_ammo_by_weapon_id"), primary_key, 7))
	operator.set("weapon_heat_by_id", _with_value(operator.get("weapon_heat_by_id"), primary_key, 44.0))
	operator.set("loaded_ammo_by_weapon_id", _with_value(operator.get("loaded_ammo_by_weapon_id"), sidearm_key, 3))
	operator.set("weapon_heat_by_id", _with_value(operator.get("weapon_heat_by_id"), sidearm_key, 16.0))
	operator.set("_ranged_ready_weapon_definition", sidearm)
	var sidearm_status: Dictionary = operator.call("get_weapon_status")
	operator.set("_ranged_ready_weapon_definition", primary)
	var primary_status: Dictionary = operator.call("get_weapon_status")
	_expect(int(sidearm_status.get("loaded_ammo", -1)) == 3 and is_equal_approx(float(sidearm_status.get("heat", -1.0)), 16.0), "sidearm state was not preserved")
	_expect(int(primary_status.get("loaded_ammo", -1)) == 7 and is_equal_approx(float(primary_status.get("heat", -1.0)), 44.0), "primary weapon state was not preserved")


func _validate_hud_read_only(scene_root: Node, operator: Node) -> void:
	var hud := HUD_SCENE.instantiate()
	scene_root.add_child(hud)
	await process_frame
	var before: Dictionary = operator.call("get_weapon_status")
	hud.call("consume_weapon_status", before.duplicate(true), null)
	var after: Dictionary = operator.call("get_weapon_status")
	for field in ["loaded_ammo", "reserve_ammo", "heat", "overheat_remaining", "reload_remaining"]:
		_expect(before.get(field) == after.get(field), "HUD mutated Operator field '%s'" % field)
	_expect(hud.get_node_or_null("Root/TopLeftVitals/Margin/Content/WeaponPressureRow/WeaponPressureBar") != null, "HUD pressure bar is missing")
	hud.queue_free()


func _with_value(source: Dictionary, key: String, value: Variant) -> Dictionary:
	var result := source.duplicate(true)
	result[key] = value
	return result


func _unit_ratio(value: Variant) -> bool:
	var number := float(value)
	return number >= 0.0 and number <= 1.0


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
