class_name PolicySimulationState
extends RefCounted

var repair_intensity := 0
var defense_readiness := 0
var surveillance_coverage := 0
var fortification := 0
var fabrication_allocation := 0

func to_dict() -> Dictionary:
	return {"repair_intensity": repair_intensity, "defense_readiness": defense_readiness, "surveillance_coverage": surveillance_coverage, "fortification": fortification, "fabrication_allocation": fabrication_allocation}
