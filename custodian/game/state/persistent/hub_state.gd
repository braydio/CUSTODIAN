class_name HubState
extends RefCounted
var seed: int = 0
var archive_losses := 0
var knowledge: Dictionary = {}
var capability_flags: Dictionary = {}
var history: CampaignHistory = CampaignHistory.new()
var applied_outcome_ids: Dictionary = {}
var authored_event_records: Dictionary = {}
var accepted_scenario: CampaignScenario

func _init(initial_seed: int = 0) -> void: seed = initial_seed

func accept_campaign_scenario(scenario: CampaignScenario) -> Dictionary:
	if accepted_scenario != null:
		return {"ok": false, "code": "SCENARIO_ALREADY_ACCEPTED"}
	if scenario == null or scenario.scenario_id.strip_edges().is_empty():
		return {"ok": false, "code": "MALFORMED_SCENARIO"}
	if scenario.seed == 0:
		return {"ok": false, "code": "SCENARIO_SEED_REQUIRED"}
	accepted_scenario = scenario
	return {
		"ok": true,
		"code": "SCENARIO_ACCEPTED",
		"scenario_id": scenario.scenario_id,
		"seed": scenario.seed,
	}

func get_accepted_scenario() -> CampaignScenario:
	return accepted_scenario


func get_authored_event_record(event_id: StringName) -> Dictionary:
	var key := String(event_id).strip_edges()
	if key.is_empty():
		return {}
	var record: Variant = authored_event_records.get(key, {})
	return (record as Dictionary).duplicate(true) if record is Dictionary else {}


func set_authored_event_record(event_id: StringName, record: Dictionary) -> bool:
	var key := String(event_id).strip_edges()
	if key.is_empty():
		return false
	authored_event_records[key] = record.duplicate(true)
	return true

func apply_campaign_outcome(outcome: CampaignOutcome) -> Dictionary:
	if outcome == null or not outcome.is_valid(): return {"ok": false, "code": "MALFORMED_OUTCOME"}
	if applied_outcome_ids.has(outcome.outcome_id): return {"ok": false, "code": "OUTCOME_ALREADY_APPLIED", "outcome_id": outcome.outcome_id}
	var next_knowledge := knowledge.duplicate(true); var next_capabilities := capability_flags.duplicate(true)
	for key in outcome.knowledge_delta: next_knowledge[key] = int(next_knowledge.get(key, 0)) + int(outcome.knowledge_delta[key])
	for key in outcome.capability_delta: next_capabilities[key] = outcome.capability_delta[key]
	archive_losses += outcome.archive_losses; knowledge = next_knowledge; capability_flags = next_capabilities; history.append_outcome(outcome); applied_outcome_ids[outcome.outcome_id] = true
	return {"ok": true, "code": "APPLIED", "outcome_id": outcome.outcome_id}
func snapshot() -> Dictionary:
	return {
		"seed": seed,
		"archive_losses": archive_losses,
		"knowledge": knowledge.duplicate(true),
		"capability_flags": capability_flags.duplicate(true),
		"campaign_history": history.snapshot(),
		"applied_outcome_ids": applied_outcome_ids.duplicate(true),
		"authored_event_records": authored_event_records.duplicate(true),
		"accepted_scenario": accepted_scenario.to_dict() if accepted_scenario != null else {},
	}

static func restore(data: Dictionary) -> HubState:
	var value := HubState.new(int(data.get("seed", 0)))
	value.archive_losses = int(data.get("archive_losses", 0))
	value.knowledge = (data.get("knowledge", {}) as Dictionary).duplicate(true)
	value.capability_flags = (data.get("capability_flags", {}) as Dictionary).duplicate(true)
	value.history = CampaignHistory.from_array(data.get("campaign_history", []))
	value.applied_outcome_ids = (data.get("applied_outcome_ids", {}) as Dictionary).duplicate(true)
	var raw_event_records: Variant = data.get("authored_event_records", {})
	if raw_event_records is Dictionary:
		for event_id: Variant in raw_event_records:
			var raw_record: Variant = raw_event_records[event_id]
			if event_id is String and not str(event_id).strip_edges().is_empty() and raw_record is Dictionary:
				value.authored_event_records[str(event_id)] = (raw_record as Dictionary).duplicate(true)
	var raw_scenario: Variant = data.get("accepted_scenario", {})
	if raw_scenario is Dictionary and not (raw_scenario as Dictionary).is_empty():
		value.accepted_scenario = CampaignScenario.from_dict(raw_scenario as Dictionary)
	return value
