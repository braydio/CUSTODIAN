class_name SimulationEvent
extends RefCounted

var kind := ""
var tick := 0
var payload: Dictionary = {}

func _init(event_kind: String = "", event_tick: int = 0, data: Dictionary = {}) -> void:
	kind = event_kind
	tick = event_tick
	payload = data.duplicate(true)

func to_dict() -> Dictionary:
	return {"kind": kind, "tick": tick, "payload": payload.duplicate(true)}
