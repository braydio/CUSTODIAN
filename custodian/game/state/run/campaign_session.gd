class_name CampaignSession
extends RefCounted

const ScenarioScript := preload("res://game/state/run/campaign_scenario.gd")
const OutcomeScript := preload("res://game/state/run/campaign_outcome.gd")
const WorldStateScript := preload("res://game/state/world/world_simulation_state.gd")

var scenario
var world
var started := false
var resolved := false

func _init(session_scenario = null) -> void:
	scenario = session_scenario if session_scenario != null else ScenarioScript.new()
	world = WorldStateScript.new(scenario.seed)

func to_outcome(result: String, reason: String = ""):
	var outcome = OutcomeScript.new(scenario.scenario_id, result)
	outcome.reason = reason
	outcome.tick = world.tick
	return outcome
