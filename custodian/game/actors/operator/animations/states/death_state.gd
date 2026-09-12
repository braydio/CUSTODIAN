extends AnimationState

func _init(state_name: String = "death"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 100

func enter() -> void:
	if state_machine:
		state_machine.play_animation(&"death")
	state_machine.trigger_event("death", "player_death")

func update(delta: float) -> String:
	# Death is terminal - no transitions out
	return name
