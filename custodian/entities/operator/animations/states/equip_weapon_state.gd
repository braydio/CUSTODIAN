extends AnimationState

func _init(state_name: String = "equip_weapon"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 5

func enter() -> void:
	if state_machine and state_machine.sprite:
		state_machine.sprite.play("equip_weapon")

func update(delta: float) -> String:
	if state_machine and state_machine.sprite:
		if not state_machine.sprite.is_playing():
			return "idle"
	return name
