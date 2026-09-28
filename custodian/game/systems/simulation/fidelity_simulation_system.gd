class_name FidelitySimulationSystem
extends RefCounted

const LEVELS := ["FULL", "DEGRADED", "FRAGMENTED", "LOST"]

func step_macro(state: WorldSimulationState) -> void:
	var comms: SectorSimulationState = state.sectors.get("COMMS")
	var previous := String(state.macro_fidelity)
	var raw := "FULL"
	if comms == null or comms.damage >= 2.0 or state.power_load >= 7.0:
		raw = "LOST"
	elif comms.damage >= 1.0 or state.power_load >= 5.5:
		raw = "FRAGMENTED"
	elif comms.damage > 0.0 or state.power_load >= 4.0:
		raw = "DEGRADED"
	var buffer: float = float(SimulationPolicyTables.FIDELITY_BUFFER[clampi(state.policies.surveillance_coverage, 0, 4)])
	if buffer >= 1.2 and raw == "LOST": raw = "FRAGMENTED"
	elif buffer >= 1.2 and raw == "FRAGMENTED": raw = "DEGRADED"
	if state.signal_interference_ticks > 0:
		if raw == "FULL": raw = "DEGRADED"
		elif raw == "DEGRADED": raw = "FRAGMENTED"
		state.signal_interference_ticks -= 1
	var effective := _relay_floor(raw, state.relay_knowledge_level)
	state.macro_fidelity = effective
	if previous != effective:
		state.record_event(&"macro_fidelity_changed", {"from": previous, "to": effective})

static func _relay_floor(value: String, knowledge: int) -> String:
	if knowledge >= 6 and value in ["LOST", "FRAGMENTED"]: return "DEGRADED"
	if knowledge >= 1 and value == "DEGRADED": return "FULL"
	return value
