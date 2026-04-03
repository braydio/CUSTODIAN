extends AnimationState

func _init(state_name: String = "idle"):
	name = state_name
	can_interrupt = true
	interrupt_priority = 0

func enter() -> void:
	pass

func update(delta: float) -> String:
	return check_state_transitions()

func check_state_transitions() -> String:
	# Movement overrides idle
	# Combat overrides movement
	# Reactions override everything except death
	return name
