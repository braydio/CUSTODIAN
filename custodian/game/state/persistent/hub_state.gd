class_name HubState
extends RefCounted
var seed: int = 0
var archive_losses := 0
var knowledge: Dictionary = {}
var capability_flags: Dictionary = {}
var history: CampaignHistory = CampaignHistory.new()
var applied_outcome_ids: Dictionary = {}
func _init(initial_seed: int = 0) -> void: seed = initial_seed
func apply_campaign_outcome(outcome: CampaignOutcome) -> Dictionary:
	if outcome == null or not outcome.is_valid(): return {"ok": false, "code": "MALFORMED_OUTCOME"}
	if applied_outcome_ids.has(outcome.outcome_id): return {"ok": false, "code": "OUTCOME_ALREADY_APPLIED", "outcome_id": outcome.outcome_id}
	var next_knowledge := knowledge.duplicate(true); var next_capabilities := capability_flags.duplicate(true)
	for key in outcome.knowledge_delta: next_knowledge[key] = int(next_knowledge.get(key, 0)) + int(outcome.knowledge_delta[key])
	for key in outcome.capability_delta: next_capabilities[key] = outcome.capability_delta[key]
	archive_losses += outcome.archive_losses; knowledge = next_knowledge; capability_flags = next_capabilities; history.append_outcome(outcome); applied_outcome_ids[outcome.outcome_id] = true
	return {"ok": true, "code": "APPLIED", "outcome_id": outcome.outcome_id}
func snapshot() -> Dictionary: return {"seed": seed, "archive_losses": archive_losses, "knowledge": knowledge.duplicate(true), "capability_flags": capability_flags.duplicate(true), "campaign_history": history.snapshot(), "applied_outcome_ids": applied_outcome_ids.duplicate(true)}
static func restore(data: Dictionary) -> HubState:
	var value := HubState.new(int(data.get("seed", 0))); value.archive_losses=int(data.get("archive_losses", 0)); value.knowledge=(data.get("knowledge", {}) as Dictionary).duplicate(true); value.capability_flags=(data.get("capability_flags", {}) as Dictionary).duplicate(true); value.history=CampaignHistory.from_array(data.get("campaign_history", [])); value.applied_outcome_ids=(data.get("applied_outcome_ids", {}) as Dictionary).duplicate(true); return value
