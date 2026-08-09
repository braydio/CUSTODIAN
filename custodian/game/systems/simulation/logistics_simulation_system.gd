class_name LogisticsSimulationSystem
extends RefCounted

func step_macro(state: WorldSimulationState) -> void:
	var base := 3.0 + maxf(0.0, 4.0 - state.power_load) * 0.35 + maxf(0.0, 2.0 - float(state.policies.surveillance_coverage)) * 0.2
	base = clampf(base, 1.5, 5.0)
	var queue_load := (1.0 if not state.repairs.is_empty() else 0.0) + minf(2.0, state.fabrication_queue.size() * 0.4)
	if state.assault.phase != "NONE": queue_load += 0.8
	var load := state.power_load * 0.45 + queue_load
	var pressure := maxf(0.0, load - base)
	state.logistics_throughput = snappedf(base, 0.001); state.logistics_load = snappedf(load, 0.001); state.logistics_pressure = snappedf(pressure, 0.001); state.logistics_multiplier = snappedf(maxf(0.45, 1.0 - minf(0.55, pressure * 0.18)), 0.001)
