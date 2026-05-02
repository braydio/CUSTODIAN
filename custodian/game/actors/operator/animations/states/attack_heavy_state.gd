extends AnimationState

var current_phase: String = "start"
var damage_frame_triggered: bool = false

func _init(state_name: String = "attack_heavy"):
	name = state_name
	can_interrupt = true
	interrupt_priority = 8
	can_reenter = true

func enter() -> void:
	current_phase = "start"
	damage_frame_triggered = false
	if state_machine and state_machine.actor and state_machine.actor.has_method("start_attack"):
		state_machine.actor.call("start_attack", "melee_heavy")
	elif state_machine and state_machine.sprite:
		if state_machine.sprite.sprite_frames and state_machine.sprite.sprite_frames.has_animation("melee_2h_heavy_right"):
			state_machine.sprite.play("melee_2h_heavy_right")
		elif state_machine.sprite.sprite_frames and state_machine.sprite.sprite_frames.has_animation("melee_2h_heavy"):
			state_machine.sprite.play("melee_2h_heavy")

func on_animation_event(event_name: String, event_type: String) -> void:
	match event_name:
		"windup":
			current_phase = "windup"
		"active":
			current_phase = "active"
			if not damage_frame_triggered:
				trigger_damage_frame()
		"recovery":
			current_phase = "recovery"

func trigger_damage_frame() -> void:
	damage_frame_triggered = true
	state_machine.trigger_event("damage_frame", "melee_heavy")

func update(delta: float) -> String:
	if state_machine and state_machine.actor and state_machine.actor.has_method("is_attack_state_complete"):
		if bool(state_machine.actor.call("is_attack_state_complete", "heavy")):
			return "idle"
	return name
