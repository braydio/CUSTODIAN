class_name CampaignSession
extends RefCounted
var session_id: String = ""
var scenario: CampaignScenario
var world: WorldSimulationState
var started := false
var resolved := false
var resolved_outcome_id := ""
func _init(session_scenario: CampaignScenario = null, initial_world: WorldSimulationState = null) -> void:
	scenario = session_scenario if session_scenario != null else CampaignScenario.new("default", 0); world = initial_world if initial_world != null else WorldSimulationState.new(scenario.seed); session_id = SimulationCanonicalJson.sha256("%s|%d" % [scenario.scenario_id, scenario.seed])
func start() -> void: started = true
func resolve_once(result: StringName, reason: String = "") -> CampaignOutcome:
	if not started or resolved: return null
	var outcome := CampaignOutcome.create(session_id, scenario.scenario_id, scenario.seed, result, reason, world.fixed_tick, world.world_tick); resolved = true; resolved_outcome_id = outcome.outcome_id; return outcome
func is_resolved() -> bool: return resolved
func to_outcome(result: String, reason: String = "") -> CampaignOutcome: return resolve_once(StringName(result), reason)
