extends SceneTree

const OperatorScene := preload("res://game/actors/operator/operator.tscn")
const SunderedKeepMapScript := preload("res://game/world/sundered_keep/sundered_keep_map.gd")
const SidearmDefinition := preload("res://game/actors/operator/sidearm_pistol_definition.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_node := Node2D.new()
	root_node.name = "SunderedKeepSidearmUnlockSmokeRoot"
	root.add_child(root_node)
	current_scene = root_node

	var operator := OperatorScene.instantiate()
	operator.name = "SmokeOperator"
	root_node.add_child(operator)
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("equipped_primary_weapon_id", "fists")
	operator.set("using_unarmed", true)
	var inventory := root.get_node_or_null("InventoryManager")
	_assert_true(inventory != null, "InventoryManager autoload should exist")
	if inventory != null:
		inventory.call("clear")

	var map := SunderedKeepMapScript.new()
	map.name = "SmokeSunderedKeep"
	root_node.add_child(map)
	await process_frame

	var initial_state: Dictionary = map.call("get_sundered_keep_debug_state")
	var locker := map.get_node_or_null("SidearmLockerInteraction")
	_assert_true(locker != null, "Sundered Keep should build the sidearm locker interaction")
	_assert_true(bool(initial_state.get("sidearm_locker_available", false)), "sidearm locker should begin available")
	_assert_true(not bool(initial_state.get("sidearm_locker_opened", true)), "sidearm locker should begin unopened")
	_assert_true(not bool(operator.get("sidearm_slot_equipped")), "Operator should begin with sidearm locked")

	map.call("_grant_sidearm_locker", operator)
	await process_frame

	var opened_state: Dictionary = map.call("get_sundered_keep_debug_state")
	_assert_true(bool(opened_state.get("sidearm_locker_opened", false)), "sidearm locker should persist opened state after grant")
	_assert_true(not bool(opened_state.get("sidearm_locker_available", true)), "opened sidearm locker should no longer be interactable")
	_assert_true(not bool(operator.get("sidearm_slot_equipped")), "recovery alone must not equip the Operator sidearm slot")
	_assert_true(str(operator.get("combat_loadout_mode")) == "melee", "sidearm grant should preserve melee/unarmed selection")
	_assert_true(inventory != null and int(inventory.call("get_count", &"p9_sidearm")) == 1, "locker should add one carried P-9 equipment record")
	_assert_true(operator.call("_get_ranged_ready_candidate_weapon_definition") == null, "carried but unequipped P-9 must not become ranged-ready fallback")
	var equipped := bool(inventory.call("equip_item", &"p9_sidearm", &"sidearm")) if inventory != null else false
	_assert_true(equipped, "equipment authority should move the recovered P-9 into the sidearm slot")
	operator.call("grant_sidearm", SidearmDefinition)
	_assert_true(bool(operator.get("sidearm_slot_equipped")), "equipping should activate the Operator sidearm slot")
	_assert_true(operator.call("_get_ranged_ready_candidate_weapon_definition") == SidearmDefinition, "equipped P-9 should become melee/unarmed ranged-ready fallback")

	var count_before_repeat := int(inventory.call("get_count", &"p9_sidearm")) if inventory != null else -1
	map.call("_grant_sidearm_locker", operator)
	_assert_true(inventory != null and int(inventory.call("get_count", &"p9_sidearm")) == count_before_repeat, "opened locker should not grant sidearm twice")

	if _failed:
		push_error("[SunderedKeepSidearmUnlockSmoke] FAIL")
		quit(1)
		return
	print("[SunderedKeepSidearmUnlockSmoke] PASS")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error("[SunderedKeepSidearmUnlockSmoke] %s" % message)
