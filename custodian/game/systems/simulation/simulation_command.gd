class_name SimulationCommand
extends RefCounted

var kind := ""
var payload: Dictionary = {}
var sequence := 0

func _init(command_kind: String = "", data: Dictionary = {}, order: int = 0) -> void:
	kind = command_kind
	payload = data.duplicate(true)
	sequence = order

func to_dict() -> Dictionary:
	return {"kind": kind, "payload": payload.duplicate(true), "sequence": sequence}
