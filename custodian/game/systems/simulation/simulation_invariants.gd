class_name SimulationInvariants
extends RefCounted

func validate(state) -> Array[String]:
	var errors: Array[String] = []
	if state.tick < 0:
		errors.append("tick must be non-negative")
	if state.ambient_threat < 0.0:
		errors.append("ambient threat must be non-negative")
	if state.materials < 0:
		errors.append("materials must be non-negative")
	for key in state.structures:
		var structure = state.structures[key]
		if structure.hp < 0 or structure.hp > structure.max_hp:
			errors.append("structure %s health is out of bounds" % key)
	if errors.is_empty():
		return errors
	state.record_event("invariant_violation", {"errors": errors.duplicate()})
	return errors
