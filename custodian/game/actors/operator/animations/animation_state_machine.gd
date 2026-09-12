extends RefCounted
class_name AnimationStateMachine

signal state_changed(from_state: String, to_state: String)
signal animation_event(event_name: String, event_type: String)
signal state_entered(state_name: String)
signal state_exited(state_name: String)

@export var initial_state: String = "idle"

var current_state: String = ""
var states: Dictionary = {}
var animation_player: AnimationPlayer = null
var sprite: AnimatedSprite2D = null
## Shared playback authority, injected by the Operator. States drive playback
## through the narrow delegates below rather than touching `sprite` directly, so
## there is exactly one place that starts and stops an Operator clip. This is a
## compatibility seam: Slice E replaces these states with OperatorActionController.
var playback: OperatorAnimationPlayer = null
var actor: Node = null
var transition_sequence := 0

func _ready() -> void:
	current_state = initial_state

func register_state(state: AnimationState) -> void:
	states[state.name] = state
	state.state_machine = self


func request(new_state: String, priority: int = 0) -> bool:
	if not states.has(new_state):
		return false
	if current_state.is_empty() or not states.has(current_state):
		_enter_initial_state(new_state)
		return true
	if current_state == new_state:
		if not states[current_state].can_reenter_with_priority(priority):
			return true
		reenter_current_state()
		return true
	if not states[current_state].can_be_interrupted_by(new_state, priority):
		return false
	transition_to(new_state)
	return true

func _process(delta: float) -> void:
	if current_state.is_empty() or not states.has(current_state):
		return
	var next_state = states[current_state].tick(delta)
	if next_state != current_state:
		transition_to(next_state)

func _enter_initial_state(new_state: String) -> void:
	current_state = new_state
	transition_sequence += 1
	states[current_state].enter_sequence = transition_sequence
	states[current_state].enter()
	state_entered.emit(new_state)

func transition_to(new_state: String) -> void:
	if not states.has(new_state):
		return
	
	var old_state = current_state
	states[current_state].exit()
	current_state = new_state
	transition_sequence += 1
	states[current_state].enter_sequence = transition_sequence
	states[current_state].enter()
	state_changed.emit(old_state, new_state)
	state_exited.emit(old_state)
	state_entered.emit(new_state)

func reenter_current_state() -> void:
	if current_state.is_empty() or not states.has(current_state):
		return
	var state: AnimationState = states[current_state]
	state.exit()
	transition_sequence += 1
	state.enter_sequence = transition_sequence
	state.enter()
	state_exited.emit(current_state)
	state_entered.emit(current_state)

func trigger_event(event_name: String, event_type: String = "default") -> void:
	animation_event.emit(event_name, event_type)

## Whether `sprite` can actually play `animation`. States used to reach through
## `sprite.sprite_frames` to check this themselves.
func can_play_animation(animation: StringName) -> bool:
	if playback == null:
		return false
	return playback.can_play(sprite, animation)


## Play `animation` on the state machine's sprite through the shared authority.
func play_animation(animation: StringName, restart := false) -> bool:
	if playback == null:
		return false
	return playback.play(sprite, animation, restart)


func get_current_animation() -> String:
	if sprite:
		return sprite.animation
	return ""

func is_animation_playing(anim_name: String) -> bool:
	if sprite:
		return sprite.animation == anim_name and sprite.is_playing()
	return false
