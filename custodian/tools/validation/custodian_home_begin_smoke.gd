extends SceneTree

const HOME_SCENE := "res://scenes/home_custodian_begin.tscn"
const HOME_SCRIPT := "res://game/world/home/custodian_home_begin.gd"
const TERMINAL_SCRIPT := "res://game/world/home/field_terminal_interactable.gd"
const ROAD_MAP := "res://content/levels/hub/Road_of_Witnesses_Tilemap.png"
const HUD_SCENE := "res://game/ui/hud/custodian_hud.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	_check_exists(HOME_SCENE)
	_check_exists(HOME_SCRIPT)
	_check_exists(TERMINAL_SCRIPT)
	_check_exists(ROAD_MAP)
	_check_exists(HUD_SCENE)
	_check_scene_loads(HOME_SCENE)
	_check_scene_loads(HUD_SCENE)
	if _failures.is_empty():
		print("[custodian_home_begin_smoke] PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("[custodian_home_begin_smoke] FAIL missing_or_invalid=%d" % _failures.size())
		quit(1)


func _check_exists(path: String) -> void:
	if not ResourceLoader.exists(path):
		_failures.append("Missing resource: %s" % path)


func _check_scene_loads(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		_failures.append("Scene did not load: %s" % path)
		return
	var instance := packed.instantiate()
	if instance == null:
		_failures.append("Scene did not instantiate: %s" % path)
		return
	if path == HUD_SCENE:
		_check_hud_instance(instance)
	if path == HOME_SCENE:
		_check_home_instance(instance)
	instance.queue_free()


func _check_home_instance(instance: Node) -> void:
	for node_path in [
		"World/RoadOfWitnessesPrototype",
		"World/Operator",
		"World/FieldTerminal",
		"World/SignalNeedle",
		"World/Camera2D",
		"CustodianHUD",
	]:
		if instance.get_node_or_null(NodePath(node_path)) == null:
			_failures.append("Home scene missing node: %s" % node_path)
	var terminal := instance.get_node_or_null("World/FieldTerminal")
	if terminal == null:
		return
	for method_name in ["get_interaction_prompt", "get_interaction_position", "get_interaction_distance", "interact", "establish_witness"]:
		if not terminal.has_method(method_name):
			_failures.append("FieldTerminal missing method: %s" % method_name)


func _check_hud_instance(instance: Node) -> void:
	for node_path in [
		"Root/TopLeftVitals",
		"Root/TopLeftLoadout",
		"Root/TopRightPanel",
	]:
		if instance.get_node_or_null(NodePath(node_path)) == null:
			_failures.append("HUD scene missing node: %s" % node_path)
