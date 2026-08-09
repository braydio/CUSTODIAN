class_name CampaignHistory
extends RefCounted
var entries: Array[Dictionary] = []
func append_outcome(outcome: CampaignOutcome) -> void: entries.append(outcome.to_dict().duplicate(true))
func snapshot() -> Array[Dictionary]: return entries.duplicate(true)
static func from_array(data: Array) -> CampaignHistory: var value := CampaignHistory.new(); value.entries=data.duplicate(true); return value
