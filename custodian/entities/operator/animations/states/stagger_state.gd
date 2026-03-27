extends AnimationState

var stagger_duration: float = 0.5

func _init(state_name: String = "stagger"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 25

func enter() -> void:
	if state_machine and state_machine.sprite:
		state_machine.sprite.play("stagger")

func update(delta: float) -> String:
	if state_machine and state_machine.sprite:
		if not state_machine.sprite.is_playing():
			return "idle"
	return name
