class_name CampaignScenario
extends RefCounted

var scenario_id := ""
var seed := 0
var title := ""
var rules: Dictionary = {}
var objectives: Array[String] = []

func _init(id: String = "", scenario_seed: int = 0) -> void:
	scenario_id = id
	seed = scenario_seed

func to_dict() -> Dictionary:
	return {"scenario_id": scenario_id, "seed": seed, "title": title, "rules": rules.duplicate(true), "objectives": objectives.duplicate()}
