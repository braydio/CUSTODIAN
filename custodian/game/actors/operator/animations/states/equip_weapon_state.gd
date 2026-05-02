extends AnimationState

func _init(state_name: String = "equip_weapon"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 5

func enter() -> void:
	if state_machine and state_machine.sprite:
		if state_machine.sprite.sprite_frames and state_machine.sprite.sprite_frames.has_animation("equip_weapon"):
			state_machine.sprite.play("equip_weapon")

func update(delta: float) -> String:
	if state_machine and state_machine.sprite:
		if state_machine.sprite.sprite_frames == null or not state_machine.sprite.sprite_frames.has_animation("equip_weapon"):
			return "idle"
		if not state_machine.sprite.is_playing():
			return "idle"
	return name
