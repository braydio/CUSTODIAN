extends AnimationState


func _init(state_name: String = "block"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 8


func enter() -> void:
	if state_machine and state_machine.actor and state_machine.actor.has_method("start_block"):
		state_machine.actor.call("start_block")


func update(_delta: float) -> String:
	if state_machine and state_machine.actor and state_machine.actor.has_method("update_block_state"):
		return String(state_machine.actor.call("update_block_state"))
	return "idle"
