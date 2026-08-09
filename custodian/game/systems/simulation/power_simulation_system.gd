class_name PowerSimulationSystem
extends RefCounted

func step_macro(state: WorldSimulationState) -> void:
	var p := state.policies
	var strategic_load: float = 1.0 + SimulationPolicyTables.DEFENSE_POWER_DRAW[p.defense_readiness] + SimulationPolicyTables.SURVEILLANCE_POWER[p.surveillance_coverage] + SimulationPolicyTables.REPAIR_POWER_MULT[p.repair_intensity]
	for level in p.sector_fortification.values(): strategic_load += SimulationPolicyTables.FORTIFICATION_POWER[clampi(int(level), 0, 4)]
	for level in p.transit_fortification.values(): strategic_load += SimulationPolicyTables.FORTIFICATION_POWER[clampi(int(level), 0, 4)]
	state.power_load = snappedf(strategic_load, 0.001)

static func blackout_event_weight_multiplier(state: WorldSimulationState) -> int:
	return maxi(1, 1 + int(maxf(0.0, state.power_load - 3.5) * 2.0))
static func blackout_event_chance_bonus(state: WorldSimulationState) -> float:
	return minf(0.12, maxf(0.0, state.power_load - 4.0) * 0.02)
