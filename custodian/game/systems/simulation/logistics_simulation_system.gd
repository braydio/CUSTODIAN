class_name LogisticsSimulationSystem
extends RefCounted

func step_macro(state) -> void:
	var repair_load: int = state.repairs.size()
	var fabrication_load: int = state.fabrication.size()
	state.logistics_load = float(repair_load + fabrication_load) + state.power_load
	state.logistics_pressure = maxf(0.0, state.logistics_load - state.logistics_throughput)
	state.logistics_multiplier = 1.0 / (1.0 + state.logistics_pressure * 0.25)
