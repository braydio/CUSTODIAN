class_name OperatorLoadoutController
extends RefCounted

const RuntimeStateScript = preload("res://game/actors/operator/loadout/operator_weapon_runtime_state.gd")

## Single authority for selected/carried identity and mutable per-weapon state.
var armed_weapons: Array[OperatorWeaponDefinition] = []
var armed_weapon_index: int = 0
var last_armed_weapon_index: int = 0
var using_unarmed: bool = false
var pending_weapon_selection: Dictionary = {}
var runtime_states: Dictionary = {}


func runtime_state(weapon_key: String) -> OperatorWeaponRuntimeState:
	if not runtime_states.has(weapon_key):
		runtime_states[weapon_key] = RuntimeStateScript.new()
	return runtime_states[weapon_key] as OperatorWeaponRuntimeState


func runtime_magazines_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for key in runtime_states:
		result[key] = (runtime_states[key] as OperatorWeaponRuntimeState).loaded_magazine
	return result


func replace_runtime_magazines(values: Dictionary) -> void:
	var keep: Dictionary = {}
	for key in values:
		keep[str(key)] = true
		runtime_state(str(key)).loaded_magazine = maxi(0, int(values[key]))
	for key in runtime_states.keys():
		if not keep.has(str(key)):
			(runtime_states[key] as OperatorWeaponRuntimeState).loaded_magazine = 0


func clear_runtime_magazines() -> void:
	for key in runtime_states:
		(runtime_states[key] as OperatorWeaponRuntimeState).loaded_magazine = 0


func get_selection_state() -> Dictionary:
	return {
		"using_unarmed": using_unarmed,
		"armed_weapon_index": armed_weapon_index,
		"last_armed_weapon_index": last_armed_weapon_index,
	}


func request_toggle_unarmed(operator: Node) -> void:
	operator.call("_rebuild_armed_weapon_list")
	if armed_weapons.is_empty():
		queue_selection(operator, {"type": "unarmed"})
	elif using_unarmed:
		queue_selection(operator, {
			"type": "armed",
			"index": clampi(last_armed_weapon_index, 0, armed_weapons.size() - 1),
		})
	else:
		last_armed_weapon_index = clampi(armed_weapon_index, 0, armed_weapons.size() - 1)
		queue_selection(operator, {"type": "unarmed"})


func request_cycle_weapon(operator: Node, direction: int) -> void:
	operator.call("_rebuild_armed_weapon_list")
	if armed_weapons.is_empty():
		queue_selection(operator, {"type": "unarmed"})
		return
	var base_index := last_armed_weapon_index if using_unarmed else armed_weapon_index
	queue_selection(operator, {
		"type": "armed",
		"index": wrapi(base_index + direction, 0, armed_weapons.size()),
	})


func queue_selection(operator: Node, selection: Dictionary) -> void:
	pending_weapon_selection = selection.duplicate(true)
	try_apply_pending_selection(operator)


func try_apply_pending_selection(operator: Node) -> void:
	if pending_weapon_selection.is_empty() or not bool(operator.call("can_apply_weapon_selection_now")):
		return
	operator.call("_rebuild_armed_weapon_list")
	if bool(operator.call("_should_sheathe_before_selection", pending_weapon_selection)):
		operator.set("_sheathe_source_weapon", operator.call("_get_equipped_primary_weapon_definition"))
		operator.set("_weapon_selection_commit_pending", true)
		operator.call("_enter_sheathe_weapon_state_if_available")
		return
	_apply_selection(operator)
	operator.call("_refresh_primary_weapon_state")
	operator.call("_enter_equip_weapon_state_if_available")


func commit_pending_after_sheathe(operator: Node) -> bool:
	operator.set("_weapon_selection_commit_pending", false)
	operator.set("_sheathe_source_weapon", null)
	if not pending_weapon_selection.is_empty():
		operator.call("_rebuild_armed_weapon_list")
		_apply_selection(operator)
		operator.call("_refresh_primary_weapon_state")
	var target_is_melee := bool(operator.call("_is_melee_loadout_active")) and not using_unarmed
	var posture_state = operator.get("_melee_posture_state")
	if posture_state != null and not target_is_melee:
		posture_state.mark_sheathed()
	return target_is_melee


func restore_selection(operator: Node, state: Dictionary) -> void:
	operator.call("_rebuild_armed_weapon_list")
	restore_selection_state(state, armed_weapons.size())
	if using_unarmed or armed_weapons.is_empty():
		operator.call("_apply_unarmed_selection")
	else:
		operator.call("_apply_armed_selection", armed_weapon_index)
	operator.call("_refresh_primary_weapon_state")


func _apply_selection(operator: Node) -> void:
	var selection_type := str(pending_weapon_selection.get("type", ""))
	match selection_type:
		"unarmed": operator.call("_apply_unarmed_selection")
		"armed": operator.call("_apply_armed_selection", int(pending_weapon_selection.get("index", armed_weapon_index)))
	pending_weapon_selection.clear()


func restore_selection_state(state: Dictionary, weapon_count: int) -> void:
	using_unarmed = bool(state.get("using_unarmed", using_unarmed))
	armed_weapon_index = clampi(int(state.get("armed_weapon_index", armed_weapon_index)), 0, maxi(weapon_count - 1, 0))
	last_armed_weapon_index = clampi(int(state.get("last_armed_weapon_index", last_armed_weapon_index)), 0, maxi(weapon_count - 1, 0))
	pending_weapon_selection.clear()
