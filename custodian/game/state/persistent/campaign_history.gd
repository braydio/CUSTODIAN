class_name CampaignHistory
extends RefCounted

var entries: Array[Dictionary] = []

func append_outcome(outcome) -> void:
	entries.append(outcome.to_dict())

func snapshot() -> Array[Dictionary]:
	return entries.duplicate(true)
