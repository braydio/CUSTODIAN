class_name GatedLevelExit2D
extends InteractableLevelExit2D

var _local_gate_open := true


func set_local_gate_open(open: bool) -> void:
	_local_gate_open = open


func is_local_gate_open() -> bool:
	return _local_gate_open


func can_interact(actor: Node = null) -> bool:
	return _local_gate_open and super.can_interact(actor)


func get_interaction_prompt() -> String:
	return super.get_interaction_prompt() if _local_gate_open else ""
