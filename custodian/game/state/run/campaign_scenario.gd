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


static func from_dict(data: Dictionary) -> CampaignScenario:
	var scenario := CampaignScenario.new(
		str(data.get("scenario_id", "")),
		int(data.get("seed", 0))
	)
	scenario.title = str(data.get("title", ""))
	var raw_rules: Variant = data.get("rules", {})
	if raw_rules is Dictionary:
		scenario.rules = (raw_rules as Dictionary).duplicate(true)
	var raw_objectives: Variant = data.get("objectives", [])
	if raw_objectives is Array:
		for objective: Variant in raw_objectives:
			scenario.objectives.append(str(objective))
	return scenario
