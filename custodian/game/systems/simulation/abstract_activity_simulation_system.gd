class_name AbstractActivitySimulationSystem
extends RefCounted


func step_macro(state: WorldSimulationState) -> bool:
	if state == null or state.abstract_activity == null:
		return false
	return state.abstract_activity.advance_to_fixed_tick(state.fixed_tick, state.world_tick)
