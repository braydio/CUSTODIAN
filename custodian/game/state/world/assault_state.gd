class_name AssaultSimulationState
extends RefCounted

var phase := "NONE"
var assault_id := ""
var threat_budget := 0.0
var approach_tick := -1
var started_tick := -1
var objective := ""
var spawn_plan: Array[Dictionary] = []
var ingress_id := ""
var route: Array[String] = []
var route_index := 0
var eta_ticks := 0
var pressure := 0.0
var warning_issued := false
var handoff_consumed := false
var history: Array[Dictionary] = []

func to_dict() -> Dictionary:
	return {"phase": phase, "assault_id": assault_id, "threat_budget": threat_budget, "approach_tick": approach_tick, "started_tick": started_tick, "objective": objective, "spawn_plan": spawn_plan.duplicate(true), "ingress_id": ingress_id, "route": route.duplicate(), "route_index": route_index, "eta_ticks": eta_ticks, "pressure": pressure, "warning_issued": warning_issued, "handoff_consumed": handoff_consumed, "history": history.duplicate(true)}

static func from_dict(data: Dictionary) -> AssaultSimulationState:
	var value := AssaultSimulationState.new(); value.phase = String(data.get("phase", "NONE")); value.assault_id = String(data.get("assault_id", "")); value.threat_budget = float(data.get("threat_budget", 0.0)); value.approach_tick = int(data.get("approach_tick", -1)); value.started_tick = int(data.get("started_tick", -1)); value.objective = String(data.get("objective", ""))
	for row: Dictionary in data.get("spawn_plan", []): value.spawn_plan.append(row.duplicate(true))
	value.ingress_id=String(data.get("ingress_id", "")); value.route.assign(data.get("route", [])); value.route_index=int(data.get("route_index", 0)); value.eta_ticks=int(data.get("eta_ticks", 0)); value.pressure=float(data.get("pressure", value.threat_budget)); value.warning_issued=bool(data.get("warning_issued", false)); value.handoff_consumed=bool(data.get("handoff_consumed", false)); for row: Dictionary in data.get("history", []): value.history.append(row.duplicate(true))
	return value

func to_spawn_plan() -> AssaultSpawnPlan:
	var plan := AssaultSpawnPlan.new(); plan.plan_id=assault_id; plan.world_tick=approach_tick
	plan.waves=spawn_plan.duplicate(true)
	return plan
