class_name CampaignOutcome
extends RefCounted

var scenario_id := ""
var result := "UNRESOLVED"
var reason := ""
var tick := 0
var archive_losses := 0
var knowledge_delta: Dictionary = {}
var capability_delta: Dictionary = {}

func _init(id: String = "", outcome_result: String = "UNRESOLVED") -> void:
	scenario_id = id
	result = outcome_result

func to_dict() -> Dictionary:
	return {"scenario_id": scenario_id, "result": result, "reason": reason, "tick": tick, "archive_losses": archive_losses, "knowledge_delta": knowledge_delta.duplicate(true), "capability_delta": capability_delta.duplicate(true)}
