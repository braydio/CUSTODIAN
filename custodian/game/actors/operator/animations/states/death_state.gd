extends AnimationState

func _init(state_name: String = "death"):
	name = state_name
	can_interrupt = false
	interrupt_priority = 100

## C2a-R4: the canonical death identity, not the legacy `death` clip.
##
## This is a deliberate art replacement rather than a preserved migration: the
## re-authored 8-frame death supersedes the legacy 9-frame disintegrate, which is
## retired. The identity is OMNI -- one authored strip for every facing.
const DEATH_ANIMATION := &"unarmed/reaction/death_01/omni/full_body"


func enter() -> void:
	if state_machine:
		state_machine.play_animation(DEATH_ANIMATION)
	state_machine.trigger_event("death", "player_death")

func update(delta: float) -> String:
	# Death is terminal - no transitions out
	return name
