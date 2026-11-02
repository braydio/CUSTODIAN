class_name WearSimulationSystem
extends RefCounted

func step_macro(state: WorldSimulationState) -> void:
	var rate: float = float(SimulationPolicyTables.WEAR_RATE[clampi(state.policies.defense_readiness, 0, 4)])
	for sector_id in WorldIdentityContract.MACRO_SECTOR_IDS:
		var sector: SectorSimulationState = state.sectors.get(sector_id)
		if sector == null:
			continue
		var fortification := int(state.policies.sector_fortification.get(sector_id, 0))
		var mitigation: float = float(SimulationPolicyTables.FORTIFICATION_MULT[clampi(fortification, 0, 4)])
		sector.damage = snappedf(clampf(sector.damage + 0.0025 * rate / mitigation, 0.0, 10.0), 0.000001)
