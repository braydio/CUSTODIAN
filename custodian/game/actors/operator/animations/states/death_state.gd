extends AnimationState

func _init(state_name: String = "death"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 100

func enter() -> void:
	if state_machine and state_machine.sprite:
		state_machine.sprite.play("death")
	state_machine.trigger_event("death", "player_death")

func update(delta: float) -> String:
	# Death is terminal - no transitions out
	return name
