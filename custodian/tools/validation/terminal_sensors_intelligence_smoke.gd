extends SceneTree

const READ_MODEL := preload("res://game/systems/intel/sensor_intelligence_read_model.gd")
const CLASSIFIER := preload("res://game/systems/intel/sensor_activity_classifier.gd")
const VIEW_MODEL := preload("res://game/ui/terminal/sensors_terminal_view_model.gd")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	var model := READ_MODEL.new()
	fixture.add_child(model)
	var enemy_a := _enemy("GRUNT", false)
	var enemy_b := _enemy("MARINE", false)
	var passive := _enemy("SHRUMB", true)
	fixture.add_child(enemy_a)
	fixture.add_child(enemy_b)
	fixture.add_child(passive)
	model.collect_now(100)
	var first: Dictionary = model.get_truth_snapshot()
	model.collect_now(110)
	var second: Dictionary = model.get_truth_snapshot()
	_expect((first["contacts"] as Array).size() == 2, "passive creatures must be excluded")
	_expect(first["contacts"][0]["contact_id"] == second["contacts"][0]["contact_id"], "contact ID must remain stable")
	_expect(first["contacts"][0]["contact_id"] != first["contacts"][1]["contact_id"], "two enemies need distinct IDs")
	_expect(CLASSIFIER.classify("steal_resources") == &"STEALING", "steal classification")
	_expect(CLASSIFIER.classify("sabotage_storage") == &"VANDALIZING", "sabotage classification")
	_expect(CLASSIFIER.classify("escape_with_loot") == &"EXFILTRATING", "exfiltration classification")

	var snapshot := {
		"fidelity":"full", "terminal_mode":&"command",
		"sensor_intelligence":{"contacts":[], "tracked_count":0, "current_count":0},
		"director":{"active_lane":"north", "lane":"east", "objective":"destroy_power", "composition":["grunt"]},
		"arrn":{"knowledge_index":3, "knowledge_max":7, "relays":[{"status":"STABLE"}]},
	}
	var vm: Dictionary = VIEW_MODEL.build(snapshot, 2)
	_expect(vm["forecast"]["ingress"] == "NORTH", "active ingress must be a lane")
	_expect(vm["forecast"]["objective"] == "DESTROY POWER", "objective must remain separate")
	_expect(not String(vm["forecast"]["ingress"]).contains("DESTROY"), "objective must never render as ingress")
	_expect(vm["forecast"]["confidence"] == "HIGH", "ARRN bonus must not alter fidelity confidence")
	_expect(vm["forecast"]["early_warning_ticks"] == 2, "ARRN bonus only affects early warning")

	fixture.free()
	if _failed:
		quit(1)
		return
	print("TERMINAL_SENSORS_INTELLIGENCE_SMOKE: PASS")
	quit(0)


func _enemy(label: String, passive: bool) -> Node2D:
	var enemy := CharacterBody2D.new()
	enemy.name = label
	enemy.add_to_group("enemy")
	enemy.set_meta("sensor_test_passive", passive)
	var script := GDScript.new()
	script.source_code = "extends CharacterBody2D\nvar enemy_name := '%s'\nvar health := 10.0\nvar max_health := 10.0\nfunc is_passive_enemy(): return %s\nfunc is_dead(): return false\nfunc get_behavior_snapshot(): return {'state':'idle','blackboard':{}}\n" % [label, "true" if passive else "false"]
	script.reload()
	enemy.set_script(script)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
