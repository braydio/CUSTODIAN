class_name SimulationEvent
extends RefCounted
const COMMAND_REJECTED := &"command_rejected"
const INVARIANT_VIOLATION := &"invariant_violation"
var kind: StringName = &""
var fixed_tick: int = 0
var world_tick: int = 0
var payload: Dictionary = {}
func _init(event_kind: StringName = &"", event_fixed_tick: int = 0, event_world_tick: int = 0, data: Dictionary = {}) -> void: kind = event_kind; fixed_tick = event_fixed_tick; world_tick = event_world_tick; payload = data.duplicate(true)
func to_dict() -> Dictionary: return {"kind": String(kind), "fixed_tick": fixed_tick, "world_tick": world_tick, "payload": payload.duplicate(true)}
