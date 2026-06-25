extends SceneTree

var _done: bool = false
var _failed: bool = false
var _contract_map: CustodianContractMap = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_resource := load("res://game/world/procgen/custodian_contract_map.tscn")
	if not (scene_resource is PackedScene):
		push_error("[special_room_insertion_smoke] Could not load CustodianContractMap scene")
		quit(1)
		return
	var contract_map := (scene_resource as PackedScene).instantiate() as CustodianContractMap
	scene_resource = null
	if contract_map == null:
		push_error("[special_room_insertion_smoke] Could not instantiate CustodianContractMap")
		quit(1)
		return
	_contract_map = contract_map

	contract_map.auto_generate_on_ready = false
	contract_map.randomize_seed_on_ready = false
	contract_map.map_generation_attempts = 1
	contract_map.special_room_insertion_enabled = true
	contract_map.special_room_max_per_run = 1
	contract_map.contract_generated.connect(_on_contract_generated)
	root.add_child(contract_map)
	await process_frame
	contract_map.generate_contract(424242)

	var frames := 0
	while not _done and frames < 1800:
		frames += 1
		await process_frame

	if not _done:
		push_error("[special_room_insertion_smoke] Timed out waiting for contract generation")
		quit(1)
		return
	if _contract_map != null and is_instance_valid(_contract_map):
		await _contract_map._clear_previous_instances()
		_contract_map.queue_free()
		await _contract_map.tree_exited
		_contract_map = null
		await process_frame
	quit(1 if _failed else 0)


func _on_contract_generated(contract: Dictionary) -> void:
	var map_data: Dictionary = contract.get("map", {})
	var level_data: Dictionary = map_data.get("level_data", {})
	var sites: Array = level_data.get("special_room_sites", [])
	if sites.is_empty():
		push_error("[special_room_insertion_smoke] No special room sites inserted")
		_failed = true
	else:
		print("[special_room_insertion_smoke] inserted_sites=", sites)
	_done = true
