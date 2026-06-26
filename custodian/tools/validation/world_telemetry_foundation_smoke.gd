extends SceneTree

const WorldStateGraphScript := preload("res://game/systems/world/world_state_graph.gd")
const WorldHistoryScript := preload("res://game/systems/world/world_history.gd")
const SimulationInterestManagerScript := preload("res://game/systems/simulation/simulation_interest_manager.gd")


class DummyManaged:
	extends Node2D

	var simulation_tier: String = ""

	func _ready() -> void:
		add_to_group("interest_managed")

	func set_simulation_tier(tier: String) -> void:
		simulation_tier = tier


func _init() -> void:
	var observatory := Node.new()
	observatory.name = "DevObservatory"
	observatory.set_script(preload("res://game/systems/debug/dev_observatory.gd"))
	root.add_child(observatory)

	var graph := WorldStateGraphScript.new()
	graph.name = "WorldStateGraph"
	root.add_child(graph)

	var history := WorldHistoryScript.new()
	history.name = "WorldHistory"
	root.add_child(history)

	var manager := SimulationInterestManagerScript.new()
	manager.name = "SimulationInterestManager"
	root.add_child(manager)

	var player := Node2D.new()
	player.name = "Player"
	player.position = Vector2.ZERO
	player.add_to_group("player")
	root.add_child(player)

	var managed := DummyManaged.new()
	managed.position = Vector2(100, 0)
	root.add_child(managed)
	await process_frame

	graph.add_dependency("lights_online", {"generator_repaired": true}, true)
	graph.set_state("generator_repaired", true)
	history.record("test_sector", "player_damage", Vector2(8, 12), {"amount": 5.0})
	manager._process(0.016)

	var failures: Array[String] = []
	if not bool(graph.get_state("lights_online", false)):
		failures.append("derived world state did not resolve")
	if history.get_sector_history("test_sector").is_empty():
		failures.append("world history did not record sector entry")
	if managed.simulation_tier != "active":
		failures.append("interest manager did not classify nearby node as active")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("world_telemetry_foundation_smoke ok")
	quit(0)

