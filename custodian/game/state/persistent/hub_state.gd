class_name HubState
extends RefCounted

const OutcomeScript := preload("res://game/state/run/campaign_outcome.gd")

## Persistent knowledge and campaign history. It must outlive a campaign world.

var seed: int
var archive_losses := 0
var knowledge: Dictionary = {}
var capability_flags: Dictionary = {}
var campaign_history: Array[Dictionary] = []

func _init(initial_seed: int = 0) -> void:
	seed = initial_seed

func apply_campaign_outcome(outcome) -> void:
	archive_losses += outcome.archive_losses
	for key in outcome.knowledge_delta:
		knowledge[key] = int(knowledge.get(key, 0)) + int(outcome.knowledge_delta[key])
	for key in outcome.capability_delta:
		capability_flags[key] = outcome.capability_delta[key]
	campaign_history.append(outcome.to_dict())

func snapshot() -> Dictionary:
	return {"seed": seed, "archive_losses": archive_losses, "knowledge": knowledge.duplicate(true), "capability_flags": capability_flags.duplicate(true), "campaign_history": campaign_history.duplicate(true)}
