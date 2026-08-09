class_name AssaultSpawnPlan
extends RefCounted
var plan_id := ""
var world_tick := 0
var waves: Array[Dictionary] = []
func to_dict() -> Dictionary: return {"plan_id": plan_id, "world_tick": world_tick, "waves": waves.duplicate(true)}
static func from_dict(data: Dictionary) -> AssaultSpawnPlan: var value := AssaultSpawnPlan.new(); value.plan_id=String(data.get("plan_id", "")); value.world_tick=int(data.get("world_tick", 0)); value.waves=(data.get("waves", []) as Array).duplicate(true); return value
