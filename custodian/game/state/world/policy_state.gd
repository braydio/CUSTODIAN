class_name PolicySimulationState
extends RefCounted

const POLICY_LEVEL_MIN := 0
const POLICY_LEVEL_MAX := 4
const FABRICATION_CATEGORIES := ["DEFENSE", "DRONES", "REPAIRS", "ARCHIVE"]

var repair_intensity: int = 2
var defense_readiness: int = 2
var surveillance_coverage: int = 2
var sector_fortification: Dictionary = {}
var transit_fortification: Dictionary = {"T_NORTH": 0, "T_SOUTH": 0}
var fabrication_allocation: Dictionary = {"DEFENSE": 2, "DRONES": 2, "REPAIRS": 2, "ARCHIVE": 2}

func set_level(policy_id: StringName, level: int) -> bool:
	if not _valid_level(level): return false
	match policy_id:
		&"repair_intensity": repair_intensity = level
		&"defense_readiness": defense_readiness = level
		&"surveillance_coverage": surveillance_coverage = level
		_: return false
	return true

func set_sector_fortification(sector_id: String, level: int) -> bool:
	if not WorldIdentityContract.is_macro_sector(sector_id) or not _valid_level(level): return false
	sector_fortification[sector_id] = level
	return true

func set_transit_fortification(transit_id: String, level: int) -> bool:
	if not WorldIdentityContract.is_transit(transit_id) or not _valid_level(level): return false
	transit_fortification[transit_id] = level
	return true

func set_fabrication_allocation(category: String, level: int) -> bool:
	var normalized := category.to_upper()
	if normalized not in FABRICATION_CATEGORIES or not _valid_level(level): return false
	fabrication_allocation[normalized] = level
	return true

func to_dict() -> Dictionary:
	return {"repair_intensity": repair_intensity, "defense_readiness": defense_readiness, "surveillance_coverage": surveillance_coverage, "sector_fortification": sector_fortification.duplicate(true), "transit_fortification": transit_fortification.duplicate(true), "fabrication_allocation": fabrication_allocation.duplicate(true)}

static func from_dict(data: Dictionary) -> PolicySimulationState:
	var value := PolicySimulationState.new()
	value.set_level(&"repair_intensity", int(data.get("repair_intensity", 2)))
	value.set_level(&"defense_readiness", int(data.get("defense_readiness", 2)))
	value.set_level(&"surveillance_coverage", int(data.get("surveillance_coverage", 2)))
	value.sector_fortification.clear()
	for key in (data.get("sector_fortification", data.get("fortification", {})) as Dictionary): value.set_sector_fortification(String(key), int(data.get("sector_fortification", data.get("fortification", {}))[key]))
	for key in (data.get("transit_fortification", {}) as Dictionary): value.set_transit_fortification(String(key), int(data["transit_fortification"][key]))
	for key in (data.get("fabrication_allocation", {}) as Dictionary): value.set_fabrication_allocation(String(key), int(data["fabrication_allocation"][key]))
	return value

static func _valid_level(level: int) -> bool:
	return level >= POLICY_LEVEL_MIN and level <= POLICY_LEVEL_MAX
