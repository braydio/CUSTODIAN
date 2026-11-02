extends RefCounted
class_name EnemyState

var state_name: StringName = &"state"


func enter(_enemy: Node) -> void:
	pass


func physics_update(_enemy: Node, _delta: float) -> void:
	pass


func exit(_enemy: Node) -> void:
	pass


func can_interrupt_with(_new_state: StringName) -> bool:
	return true
