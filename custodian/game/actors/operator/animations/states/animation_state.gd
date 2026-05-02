class_name AnimationState
extends RefCounted

var name: String = ""
var state_machine: AnimationStateMachine = null

var can_interrupt: bool = true
var interrupt_priority: int = 0
var can_reenter: bool = false
var elapsed: float = 0.0
var enter_sequence: int = 0

func enter() -> void:
	elapsed = 0.0
	pass

func exit() -> void:
	pass

func update(_delta: float) -> String:
	return name

func tick(delta: float) -> String:
	elapsed += max(0.0, delta)
	return update(delta)

func can_be_interrupted_by(other_state: String, priority: int = 0) -> bool:
	if not can_interrupt:
		return false
	return priority >= interrupt_priority

func can_reenter_with_priority(priority: int = 0) -> bool:
	return can_reenter and priority >= interrupt_priority

func on_animation_event(event_name: String, event_type: String) -> void:
	pass
