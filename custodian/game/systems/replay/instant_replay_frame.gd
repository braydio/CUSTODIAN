extends RefCounted
class_name InstantReplayFrame

var timestamp_sec: float = 0.0
var entities: Array[Dictionary] = []
var camera: Dictionary = {}


func to_dictionary() -> Dictionary:
	return {
		"timestamp_sec": timestamp_sec,
		"entities": entities,
		"camera": camera,
	}
