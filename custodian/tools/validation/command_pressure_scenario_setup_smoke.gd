extends SceneTree

const BOOTSTRAP := preload("res://game/scenarios/command_pressure_v1/command_pressure_scenario_bootstrap.gd")
const SCENARIO := preload("res://game/scenarios/command_pressure_v1/command_pressure_scenario_root.tscn")
const GAME := preload("res://scenes/game.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_require(BOOTSTRAP.requested_scenario_id(PackedStringArray(["--scenario", "command_pressure_v1"])) == "command_pressure_v1", "split scenario argument was not recognized")
	_require(BOOTSTRAP.requested_scenario_id(PackedStringArray(["--scenario=command_pressure_v1"])) == "command_pressure_v1", "equals scenario argument was not recognized")
	_require(BOOTSTRAP.requested_scenario_id(PackedStringArray()) == "", "ordinary launch must not select a scenario")

	var game_state := GAME.get_state()
	_require(_scene_has_node(game_state, "CommandPressureScenarioBootstrap"), "game.tscn lacks the inert scenario bootstrap")
	_require(not _scene_has_node(game_state, "CommandPressureScenarioRoot"), "game.tscn must not embed the active scenario root")

	var scenario := SCENARIO.instantiate()
	root.add_child(scenario)
	await process_frame
	var resources := scenario.get_node("ResourceNodes")
	_require(resources.get_child_count() == 5, "scenario must own exactly five authored ResourceNodes")
	_assert_resource(resources.get_node("WreckA"), Vector2(560, -620), "ruin_scrap", 2, 10, {"power_components": 1})
	_assert_resource(resources.get_node("WreckB"), Vector2(980, -260), "ruin_scrap", 2, 10, {"power_components": 1})
	_assert_resource(resources.get_node("AlloyVein"), Vector2(1260, -300), "structural_alloy", 4, 8, {"ruin_scrap": 2})
	_assert_resource(resources.get_node("RupturedCapacitor"), Vector2(1320, -710), "capacitor_dust", 4, 8, {"ruin_scrap": 2})
	_assert_resource(resources.get_node("ResinPod"), Vector2(520, -300), "resin_clot", 2, 1, {})
	var director := scenario.get_node("ScenarioDirector")
	var setup: Dictionary = director.call("get_setup_snapshot")
	_require(float(setup.get("preparation_seconds", 0.0)) == 110.0, "preparation timing drifted")
	_require((setup.get("composition", []) as Array) == ["grunt", "grunt", "grunt", "marine", "grunt", "grunt"], "authored assault composition drifted")
	var ports := scenario.get_node("ServicePorts")
	_require(ports.get_child_count() == 2, "scenario must expose two physical repair ports")
	_require(float(ports.get_node("PowerServicePort").get("hold_duration")) == 3.5, "Power repair hold contract drifted")
	_require(float(ports.get_node("DefenseServicePort").get("hold_duration")) == 3.0, "Defense repair hold contract drifted")
	scenario.queue_free()
	await process_frame
	_finish()


func _assert_resource(node: Node, expected_position: Vector2, resource_id: String, work: int, amount: int, secondary: Dictionary) -> void:
	_require((node as Node2D).position == expected_position, "%s position drifted" % node.name)
	_require(String(node.get("resource_id")) == resource_id, "%s resource drifted" % node.name)
	_require(int(node.get("work_required")) == work, "%s work contract drifted" % node.name)
	_require(int(node.get("yield_amount")) == amount, "%s yield drifted" % node.name)
	_require((node.get("secondary_yields") as Dictionary) == secondary, "%s secondary yield drifted" % node.name)


func _scene_has_node(state: SceneState, node_name: String) -> bool:
	for index in range(state.get_node_count()):
		if String(state.get_node_name(index)) == node_name:
			return true
	return false


func _require(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("[CommandPressureScenarioSetupSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[CommandPressureScenarioSetupSmoke] PASS")
	quit(0)
