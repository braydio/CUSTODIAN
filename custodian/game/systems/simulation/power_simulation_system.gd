class_name PowerSimulationSystem
extends RefCounted

const BASE_GENERATION := 4.0

func step(state, _fixed_dt: float) -> void:
	var structure_count: int = state.structures.size()
	var damaged_count: int = 0
	for key in state.structures:
		var structure = state.structures[key]
		if structure.hp <= 0:
			damaged_count += 1
	var generation := BASE_GENERATION * (1.0 + float(state.policies.repair_intensity) * 0.02)
	var load := maxf(0.0, float(structure_count - damaged_count) * 0.15)
	state.power_load = load / maxf(generation, 0.001)
	for key in state.sectors:
		var sector = state.sectors[key]
		sector.power = clampf(1.0 - maxf(0.0, state.power_load - 1.0), 0.0, 1.0)
