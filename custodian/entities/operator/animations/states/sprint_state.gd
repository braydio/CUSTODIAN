extends AnimationState

func _init(state_name: String = "sprint"):
	name = state_name
	can_interrupt = true
	interrupt_priority = 1

func enter() -> void:
	pass

func update(delta: float) -> String:
	return check_state_transitions()

func check_state_transitions() -> String:
	# Stop sprinting returns to walk or idle
	return name
