extends AnimationState

var knockback_direction: Vector2 = Vector2.ZERO

func _init(state_name: String = "hit_recoil"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 20

func enter() -> void:
	if state_machine and state_machine.sprite:
		state_machine.sprite.play("hit_recoil")
	# Trigger knockback
	state_machine.trigger_event("knockback", "hit_recoil")

func update(delta: float) -> String:
	if state_machine and state_machine.sprite:
		if not state_machine.sprite.is_playing():
			return "idle"
	return name
