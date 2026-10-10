extends Node

@export var force_activation_failure := false
var _result: Dictionary = {}
var _map: Node

func _ready() -> void:
	call_deferred("_activate")

func _activate() -> void:
	if force_activation_failure:
		_result = {"ready": false, "code": "FIXTURE_ACTIVATION_FAILED"}
		return
	var bootstrap := get_node_or_null("/root/WorldContractBootstrap")
	var contract: Dictionary = bootstrap.call("get_latest_contract") if bootstrap != null else {}
	_map = contract.get("map", {}).get("instance") as Node
	var world := get_node_or_null("../World") as Node2D
	var camera := world.get_node_or_null("Camera2D") as Camera2D if world != null else null
	if _map == null or world == null or camera == null:
		_result = {"ready": false, "code": "FIXTURE_BINDING_MISSING"}
		return
	var runtime_map := world.get_node_or_null("ProcGenRuntime") as Node2D
	if runtime_map == null:
		runtime_map = Node2D.new()
		runtime_map.name = "ProcGenRuntime"
		world.add_child(runtime_map)
	_map.reparent(runtime_map)
	camera.call("set_runtime_map", _map)
	bootstrap.call("mark_claimed")
	_result = {"ready": true, "code": "FIXTURE_ACTIVATED", "map_instance_id": _map.get_instance_id()}

func wait_for_contract_activation(_max_frames: int = 3600) -> Dictionary:
	while _result.is_empty():
		await get_tree().process_frame
	return _result.duplicate(true)

func get_active_map_instance() -> Node:
	return _map

func return_preloaded_map_to_bootstrap() -> bool:
	if _map == null or not is_instance_valid(_map):
		return false
	var bootstrap := get_node_or_null("/root/WorldContractBootstrap")
	if bootstrap == null:
		return false
	_map.reparent(bootstrap)
	_map.visible = false
	_map = null
	_result.clear()
	return bool(bootstrap.call("restore_ready_after_deployment_rollback"))
