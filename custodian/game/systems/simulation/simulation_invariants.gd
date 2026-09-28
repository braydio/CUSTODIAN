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
	for sector_id in state.sectors:
		var sector: SectorSimulationState = state.sectors[sector_id]; _check(errors, is_finite(sector.damage) and sector.damage >= 0.0 and sector.damage <= 10.0, "SECTOR_WEAR_INVALID", "sectors.%s.damage" % sector_id, sector.damage)
	_check(errors, state.macro_fidelity in ["FULL", "DEGRADED", "FRAGMENTED", "LOST"], "MACRO_FIDELITY_INVALID", "macro_fidelity", state.macro_fidelity)
	for category in PolicySimulationState.FABRICATION_CATEGORIES:
		var cycle := float(FabricationSimulationSystem.AMBIENT_RULES[category].cycle)
		var progress := float(state.ambient_fab_progress.get(category, -1.0))
		_check(errors, is_finite(progress) and progress >= 0.0 and progress <= cycle * 1.5, "AMBIENT_FAB_PROGRESS_INVALID", "ambient_fab_progress.%s" % category, progress)
	for raw_job in state.repairs:
		var repair_job := RepairJobState.from_dict(raw_job) if raw_job is Dictionary else raw_job as RepairJobState
		_check(errors, state.structures.has(repair_job.structure_id) and repair_job.material_cost >= 0 and repair_job.repair_amount >= 0 and repair_job.remaining >= 0.0 and repair_job.progress >= 0.0, "REPAIR_JOB_INVALID", "repairs.%s" % repair_job.job_id, repair_job.to_dict())
	for raw_job in state.fabrication_queue:
		var fabrication_job := FabricationJobState.from_dict(raw_job) if raw_job is Dictionary else raw_job as FabricationJobState
		var recipe := FabricationRecipeContract.get_recipe(fabrication_job.recipe_id, maxi(state.relay_knowledge_level, 4))
		_check(errors, not recipe.is_empty() and fabrication_job.remaining >= 0.0 and fabrication_job.total > 0.0 and fabrication_job.outputs == recipe.get("outputs", {}), "FABRICATION_JOB_INVALID", "fabrication_queue.%s" % fabrication_job.job_id, fabrication_job.to_dict())
	_check(errors, state.rng_state > 0 and state.rng_state <= 0x7fffffff, "RNG_STATE_INVALID", "rng_state", state.rng_state)
	for relay_id in state.relays:
		var relay: Dictionary = state.relays[relay_id]
		_check(errors, String(relay.get("id", "")) == String(relay_id), "RELAY_ID_MISMATCH", "relays.%s.id" % relay_id, relay.get("id"))
		_check(errors, String(relay.get("status", "")) in ["UNKNOWN", "LOCATED", "UNSTABLE", "STABLE", "WEAK", "DORMANT"], "RELAY_STATUS_INVALID", "relays.%s.status" % relay_id, relay.get("status"))
		_check(errors, is_finite(float(relay.get("stability", -1.0))) and float(relay.get("stability", -1.0)) >= 0.0 and float(relay.get("stability", 101.0)) <= 100.0, "RELAY_STABILITY_INVALID", "relays.%s.stability" % relay_id, relay.get("stability"))
		_check(errors, WorldIdentityContract.is_macro_sector(String(relay.get("sector_id", ""))) or WorldIdentityContract.is_transit(String(relay.get("sector_id", ""))), "RELAY_SECTOR_INVALID", "relays.%s.sector_id" % relay_id, relay.get("sector_id"))
		_check(errors, int(relay.get("packets_pending", -1)) >= 0, "RELAY_PROGRESSION_INVALID", "relays.%s.packets_pending" % relay_id, relay.get("packets_pending"))
	var event_state: Dictionary = state.systemic_event_state
	for field in ["ticks_since_assault", "ticks_since_hostile"]:
		if event_state.has(field): _check(errors, int(event_state[field]) >= 0, "SYSTEMIC_EVENT_COUNTER_INVALID", "systemic_event_state.%s" % field, event_state[field])
	_check(errors, state.relay_knowledge_level >= 0 and state.relay_knowledge_level <= 7 and state.relay_dormancy_pressure >= 0, "RELAY_NETWORK_PROGRESSION_INVALID", "relay_network", {"knowledge_level": state.relay_knowledge_level, "dormancy_pressure": state.relay_dormancy_pressure})
	_check(errors, String(event_state.get("last_category", "")) in ["", "QUIET", "ENVIRONMENTAL", "INFRASTRUCTURE", "RECON", "HOSTILE"], "SYSTEMIC_EVENT_CATEGORY_INVALID", "systemic_event_state.last_category", event_state.get("last_category"))
	_check(errors, (event_state.get("recent_keys", []) as Array).size() <= 8 and (event_state.get("history", []) as Array).size() <= 16, "SYSTEMIC_EVENT_HISTORY_OVERFLOW", "systemic_event_state.history", event_state.get("history"))
	_check(errors, String(state.assault.phase) in ["NONE", "APPROACHING", "HANDOFF_READY", "HANDED_OFF"], "ASSAULT_PHASE_INVALID", "assault.phase", state.assault.phase)
	_check(errors, state.assault.eta_ticks >= 0 and state.assault.route_index >= 0 and is_finite(state.assault.pressure) and state.assault.pressure >= 0.0, "ASSAULT_APPROACH_INVALID", "assault", state.assault.to_dict())
	var sequences := {}; for command in queued_commands: _check(errors, not sequences.has(command.sequence), "DUPLICATE_COMMAND_SEQUENCE", "command_queue.sequence", command.sequence); sequences[command.sequence] = true
	_check(errors, not state.failed or not state.failure_reason.is_empty(), "FAILURE_REASON_EMPTY", "failure_reason", state.failure_reason)
	return errors
static func _level(value: int) -> bool: return value >= 0 and value <= 4
static func _check(errors: Array[Dictionary], condition: bool, code: String, path: String, value: Variant) -> void:
	if not condition: errors.append({"code": code, "path": path, "value": value})
