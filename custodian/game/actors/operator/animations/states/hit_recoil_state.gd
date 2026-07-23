extends AnimationState

var recoil_duration: float = 0.22
var _played_animation: StringName = &""
var _modular_handled := false


func _init(state_name: String = "hit_recoil"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 20
	can_reenter = true


func enter() -> void:
	elapsed = 0.0
	_played_animation = &""
	_modular_handled = false
	if state_machine and state_machine.actor and state_machine.actor.has_method("get_damage_reaction_duration"):
		recoil_duration = maxf(0.01, float(state_machine.actor.call("get_damage_reaction_duration", name)))
	if state_machine \
	and state_machine.actor \
	and state_machine.actor.has_method("begin_modular_damage_reaction"):
		_modular_handled = bool(
			state_machine.actor.call("begin_modular_damage_reaction", name)
		)
		if _modular_handled:
			return
	if state_machine == null or state_machine.sprite == null:
		return
	var animation_name := &""
	if state_machine.actor and state_machine.actor.has_method("get_damage_reaction_animation"):
		animation_name = state_machine.actor.call("get_damage_reaction_animation", name)
	if animation_name == StringName():
		return
	if not state_machine.sprite.sprite_frames.has_animation(animation_name):
		return
	_played_animation = animation_name
	state_machine.sprite.speed_scale = 1.0
	state_machine.sprite.set_frame_and_progress(0, 0.0)
	state_machine.sprite.play(animation_name)
	if state_machine.actor and state_machine.actor.has_method("play_damage_reaction_fx"):
		state_machine.actor.call("play_damage_reaction_fx", animation_name)


func exit() -> void:
	if state_machine and state_machine.actor and state_machine.actor.has_method("finish_damage_reaction_presentation"):
		state_machine.actor.call("finish_damage_reaction_presentation")


func update(_delta: float) -> String:
	if elapsed >= recoil_duration:
		return "idle"
	if _modular_handled \
	and state_machine \
	and state_machine.actor \
	and state_machine.actor.has_method("is_modular_damage_reaction_playing"):
		if not bool(
			state_machine.actor.call("is_modular_damage_reaction_playing")
		):
			return "idle"
		return name
	if _played_animation != StringName() and state_machine and state_machine.sprite:
		if state_machine.sprite.animation == _played_animation and not state_machine.sprite.is_playing():
			return "idle"
	return name
