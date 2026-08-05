class_name SimulationSnapshot
extends RefCounted

var tick := 0
var fingerprint := ""
var payload: Dictionary = {}

func _init(source = null) -> void:
	if source != null:
		tick = source.tick
		fingerprint = source.fingerprint()
		payload = source.to_dict()

func to_dict() -> Dictionary:
	return {"tick": tick, "fingerprint": fingerprint, "state": payload.duplicate(true)}
