extends AnimationState

func _init(state_name: String = "sheathe_weapon"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 5

func enter() -> void:
	if state_machine and state_machine.actor and state_machine.actor.has_method("start_sheathe_weapon_presentation"):
		state_machine.actor.call("start_sheathe_weapon_presentation")

func update(_delta: float) -> String:
	if state_machine and state_machine.actor and state_machine.actor.has_method("is_sheathe_weapon_presentation_complete"):
		if bool(state_machine.actor.call("is_sheathe_weapon_presentation_complete")):
			# commit decides whether the new loadout needs a draw; its
			# return value picks the next state so the state machine's
			# own transition_to() performs the switch (a request() from
			# inside this non-interruptible state would no-op).
			var needs_draw := false
			if state_machine.actor.has_method("commit_pending_weapon_selection_after_sheathe"):
				needs_draw = bool(state_machine.actor.call("commit_pending_weapon_selection_after_sheathe"))
			return "equip_weapon" if needs_draw else "idle"
	return name
