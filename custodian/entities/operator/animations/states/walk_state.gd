extends AnimationState

func _init(state_name: String = "walk"):
	name = state_name
	can_interrupt = true
	interrupt_priority = 1

func enter() -> void:
	pass

func update(delta: float) -> String:
	return check_state_transitions()

func check_state_transitions() -> String:
	# Transition to sprint if moving fast
	# Transition to idle if not moving
	# Combat states interrupt
	return name
