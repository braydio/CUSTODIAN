class_name CampaignOutcome
extends RefCounted
var outcome_id: String = ""
var session_id: String = ""
var scenario_id: String = ""
var result: StringName = &"UNRESOLVED"
var reason: String = ""
var fixed_tick: int = 0
var world_tick: int = 0
var archive_losses: int = 0
var knowledge_delta: Dictionary = {}
var capability_delta: Dictionary = {}
var _sealed := false
static func create(stable_session_id: String, scenario: String, seed: int, outcome_result: StringName, outcome_reason: String, at_fixed_tick: int, at_world_tick: int) -> CampaignOutcome:
	var value := CampaignOutcome.new(); value.session_id = stable_session_id; value.scenario_id = scenario; value.result = outcome_result; value.reason = outcome_reason; value.fixed_tick = at_fixed_tick; value.world_tick = at_world_tick; value.outcome_id = SimulationCanonicalJson.sha256("%s|%s|%d|%s|%d" % [stable_session_id, scenario, seed, outcome_result, at_world_tick]); value._sealed = true; return value
func is_valid() -> bool: return _sealed and not outcome_id.is_empty() and not session_id.is_empty() and result != &"UNRESOLVED"
func to_dict() -> Dictionary: return {"outcome_id": outcome_id, "session_id": session_id, "scenario_id": scenario_id, "result": String(result), "reason": reason, "fixed_tick": fixed_tick, "world_tick": world_tick, "archive_losses": archive_losses, "knowledge_delta": knowledge_delta.duplicate(true), "capability_delta": capability_delta.duplicate(true)}
static func from_dict(data: Dictionary) -> CampaignOutcome:
	var value := CampaignOutcome.new(); value.outcome_id=String(data.get("outcome_id", "")); value.session_id=String(data.get("session_id", "")); value.scenario_id=String(data.get("scenario_id", "")); value.result=StringName(data.get("result", "UNRESOLVED")); value.reason=String(data.get("reason", "")); value.fixed_tick=int(data.get("fixed_tick", 0)); value.world_tick=int(data.get("world_tick", 0)); value.archive_losses=int(data.get("archive_losses", 0)); value.knowledge_delta=(data.get("knowledge_delta", {}) as Dictionary).duplicate(true); value.capability_delta=(data.get("capability_delta", {}) as Dictionary).duplicate(true); value._sealed=true; return value
