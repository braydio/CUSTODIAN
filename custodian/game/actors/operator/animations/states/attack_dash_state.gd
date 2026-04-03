extends AnimationState

var current_phase: String = "start"
var dash_started: bool = false

func _init(state_name: String = "attack_dash"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 15

func enter() -> void:
	current_phase = "start"
	dash_started = false
	if state_machine and state_machine.sprite:
		state_machine.sprite.play("attack_dash")

func on_animation_event(event_name: String, event_type: String) -> void:
	match event_name:
		"windup":
			current_phase = "windup"
		"active":
			current_phase = "active"
			if not dash_started:
				start_dash_movement()
		"recovery":
			current_phase = "recovery"

func start_dash_movement() -> void:
	dash_started = true
	state_machine.trigger_event("dash_start", "attack_dash")

func update(delta: float) -> String:
	if state_machine and state_machine.sprite:
		if not state_machine.sprite.is_playing():
			return "idle"
	return name
