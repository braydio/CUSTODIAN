class_name AssaultSimulationState
extends RefCounted

var phase := "NONE"
var assault_id := ""
var threat_budget := 0.0
var approach_tick := -1
var started_tick := -1
var objective := ""
var spawn_plan: Array[Dictionary] = []

func to_dict() -> Dictionary:
	return {"phase": phase, "assault_id": assault_id, "threat_budget": threat_budget, "approach_tick": approach_tick, "started_tick": started_tick, "objective": objective, "spawn_plan": spawn_plan.duplicate(true)}

static func from_dict(data: Dictionary) -> AssaultSimulationState:
	var value := AssaultSimulationState.new(); value.phase = String(data.get("phase", "NONE")); value.assault_id = String(data.get("assault_id", "")); value.threat_budget = float(data.get("threat_budget", 0.0)); value.approach_tick = int(data.get("approach_tick", -1)); value.started_tick = int(data.get("started_tick", -1)); value.objective = String(data.get("objective", ""))
	for row: Dictionary in data.get("spawn_plan", []): value.spawn_plan.append(row.duplicate(true))
	return value
