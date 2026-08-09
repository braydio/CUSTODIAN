class_name SimulationInvariants
extends RefCounted
func validate(state: WorldSimulationState, queued_commands: Array = []) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	_check(errors, state.fixed_tick >= 0, "FIXED_TICK_NEGATIVE", "fixed_tick", state.fixed_tick)
	_check(errors, state.world_tick >= 0, "WORLD_TICK_NEGATIVE", "world_tick", state.world_tick)
	_check(errors, state.world_tick <= state.fixed_tick / 60, "WORLD_TICK_AHEAD", "world_tick", state.world_tick)
	_check(errors, is_finite(state.ambient_threat) and state.ambient_threat >= 0.0, "THREAT_INVALID", "ambient_threat", state.ambient_threat)
	_check(errors, state.materials >= 0, "MATERIALS_NEGATIVE", "resources.materials", state.materials)
	for collection_name in ["inventory", "stocks"]:
		var collection: Dictionary = state.get(collection_name)
		for key in collection: _check(errors, collection[key] is int and int(collection[key]) >= 0, "RESOURCE_INVALID", "%s.%s" % [collection_name, key], collection[key])
	for policy in ["repair_intensity", "defense_readiness", "surveillance_coverage"]: _check(errors, _level(state.policies.get(policy)), "POLICY_LEVEL_INVALID", "policies.%s" % policy, state.policies.get(policy))
	for category in PolicySimulationState.FABRICATION_CATEGORIES: _check(errors, state.policies.fabrication_allocation.has(category) and _level(int(state.policies.fabrication_allocation.get(category, -1))), "FABRICATION_CATEGORY_INVALID", "policies.fabrication_allocation.%s" % category, state.policies.fabrication_allocation.get(category))
	for field in ["sector_fortification", "transit_fortification"]:
		for key in state.policies.get(field): _check(errors, _level(int(state.policies.get(field)[key])), "FORTIFICATION_LEVEL_INVALID", "policies.%s.%s" % [field, key], state.policies.get(field)[key])
	for field in ["logistics_throughput", "logistics_load", "logistics_pressure", "logistics_multiplier"]: _check(errors, is_finite(float(state.get(field))), "LOGISTICS_NOT_FINITE", field, state.get(field))
	_check(errors, state.logistics_throughput >= 0.0, "LOGISTICS_THROUGHPUT_NEGATIVE", "logistics_throughput", state.logistics_throughput); _check(errors, state.logistics_pressure >= 0.0, "LOGISTICS_PRESSURE_NEGATIVE", "logistics_pressure", state.logistics_pressure); _check(errors, state.logistics_multiplier >= 0.45 and state.logistics_multiplier <= 1.0, "LOGISTICS_MULTIPLIER_INVALID", "logistics_multiplier", state.logistics_multiplier)
	for key in state.structures:
		var s: StructureSimulationState = state.structures[key]; _check(errors, s.hp >= 0 and s.hp <= s.max_hp, "STRUCTURE_HP_OUT_OF_RANGE", "structures.%s.hp" % key, s.hp); _check(errors, WorldIdentityContract.is_macro_sector(s.sector_id), "UNKNOWN_SECTOR", "structures.%s.sector" % key, s.sector_id)
	var sequences := {}; for command in queued_commands: _check(errors, not sequences.has(command.sequence), "DUPLICATE_COMMAND_SEQUENCE", "command_queue.sequence", command.sequence); sequences[command.sequence] = true
	_check(errors, not state.failed or not state.failure_reason.is_empty(), "FAILURE_REASON_EMPTY", "failure_reason", state.failure_reason)
	return errors
static func _level(value: int) -> bool: return value >= 0 and value <= 4
static func _check(errors: Array[Dictionary], condition: bool, code: String, path: String, value: Variant) -> void:
	if not condition: errors.append({"code": code, "path": path, "value": value})
