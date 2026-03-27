class_name AnimationState
extends RefCounted

var name: String = ""
var state_machine: AnimationStateMachine = null

var can_interrupt: bool = true
var interrupt_priority: int = 0

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> String:
	return name

func can_be_interrupted_by(other_state: String, priority: int = 0) -> bool:
	if not can_interrupt:
		return false
	return priority >= interrupt_priority

func on_animation_event(event_name: String, event_type: String) -> void:
	pass
