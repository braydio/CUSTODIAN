extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")
const SIDEARM_DEFINITION := preload("res://game/actors/operator/sidearm_pistol_definition.tres")
const FALLEN_STAR_KATANA_DEFINITION := preload("res://game/actors/operator/fallen_star_katana_definition.tres")

var _failures: Array[String] = []
var _entered_states: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)

	var vigil_definition = operator.get("melee_weapon_definition")
	_expect(vigil_definition != null, "operator is missing a melee_weapon_definition")

	var state_machine = operator.get("_animation_state_machine")
	state_machine.state_entered.connect(_on_state_entered)

	await _run_case(operator, "MELEE -> UNARMED", vigil_definition, null, {"type": "unarmed"}, false)
	await _run_case(operator, "MELEE -> RANGED_2H", vigil_definition, CARBINE_DEFINITION, {"type": "armed"}, false)
	await _run_case(operator, "MELEE -> SIDEARM (ranged-kind target)", vigil_definition, SIDEARM_DEFINITION, {"type": "armed"}, false)
	await _run_case(operator, "MELEE -> DIFFERENT MELEE", vigil_definition, FALLEN_STAR_KATANA_DEFINITION, {"type": "armed"}, true)

	state_machine.state_entered.disconnect(_on_state_entered)
	operator.free()
	if _failures.is_empty():
		print("operator_melee_switch_chain_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _run_case(
	operator: Node,
	case_name: String,
	vigil_definition,
	target_definition,
	selection_template: Dictionary,
	expect_draw: bool
) -> void:
	# Re-arm Vigil directly (bypasses the transactional path; this is setup,
	# not the behavior under test) before exercising the switch under test.
	# primary_weapon_definition is set to the target BEFORE re-affirming
	# Vigil as current, since inserting the target can shift armed_weapons
	# indices out from under a stale armed_weapon_index (get_current_combat_profile()
	# resolves via armed_weapon_index, not just combat_loadout_mode).
	operator.set("primary_weapon_definition", target_definition)
	operator.call("_rebuild_armed_weapon_list")
	var vigil_index: int = (operator.get("armed_weapons") as Array).find(vigil_definition)
	_expect(vigil_index >= 0, "%s: Vigil missing from armed weapons during setup" % case_name)
	operator.call("_apply_armed_selection", vigil_index)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	_expect(bool(operator.call("_sync_modular_melee_posture", Vector2.RIGHT)), "%s: failed to reach ready posture" % case_name)

	var selection := selection_template.duplicate(true)
	if target_definition != null:
		var target_index: int = (operator.get("armed_weapons") as Array).find(target_definition)
		_expect(target_index >= 0, "%s: target weapon missing from armed weapons" % case_name)
		selection["index"] = target_index

	_entered_states.clear()
	operator.call("queue_weapon_selection", selection)
	_expect(
		operator.get("_animation_state_machine").current_state == "sheathe_weapon",
		"%s: selection did not enter sheathe_weapon" % case_name
	)
	_expect(
		operator.call("_get_equipped_primary_weapon_definition") == vigil_definition,
		"%s: old melee weapon must remain presentation authority during sheathe" % case_name
	)

	await create_timer(0.4).timeout
	operator.call("_update_animation_state_machine", 0.016)

	if expect_draw:
		_expect(
			operator.get("_animation_state_machine").current_state == "equip_weapon",
			"%s: expected draw did not start after sheathe committed" % case_name
		)
		await create_timer(0.4).timeout
		operator.call("_update_animation_state_machine", 0.016)

	_expect(
		operator.get("_animation_state_machine").current_state == "idle",
		"%s: state machine did not settle back to idle" % case_name
	)

	var sheathe_visits := _entered_states.count("sheathe_weapon")
	var draw_visits := _entered_states.count("equip_weapon")
	_expect(sheathe_visits == 1, "%s: expected exactly one sheathe transition, saw %d" % [case_name, sheathe_visits])
	_expect(
		draw_visits == (1 if expect_draw else 0),
		"%s: expected %d draw transition(s), saw %d" % [case_name, 1 if expect_draw else 0, draw_visits]
	)


func _on_state_entered(state_name: String) -> void:
	_entered_states.append(state_name)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
