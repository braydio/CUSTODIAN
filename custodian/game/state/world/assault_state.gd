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
