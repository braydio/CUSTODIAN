class_name SimulationKernel
extends RefCounted
const MACRO_TICK_INTERVAL := 60
signal snapshot_emitted(snapshot: SimulationSnapshot)
signal event_emitted(event: SimulationEvent)
signal macro_stage_completed(stage: StringName)
signal fixed_step_boundary(fixed_tick: int)
signal assault_handoff_ready(plan: AssaultSpawnPlan)
var state: WorldSimulationState
var command_queue: Array[SimulationCommand] = []
var strict_invariants := false
var _next_command_sequence := 1
var _power := PowerSimulationSystem.new()
var _logistics := LogisticsSimulationSystem.new()
var _repairs := RepairSimulationSystem.new()
var _fabrication := FabricationSimulationSystem.new()
var _relay := RelaySimulationSystem.new()
var _systemic_events := SystemicEventSimulationSystem.new()
var _strategic_assault := StrategicAssaultSimulationSystem.new()
var _wear := WearSimulationSystem.new()
var _fidelity := FidelitySimulationSystem.new()
var _abstract_activity := AbstractActivitySimulationSystem.new()
var _invariants := SimulationInvariants.new()

func _init(initial_state: WorldSimulationState = null) -> void: state = initial_state if initial_state != null else WorldSimulationState.new()
func enqueue(command: SimulationCommand) -> int:
	command.sequence = _next_command_sequence; _next_command_sequence += 1; command.issued_fixed_tick = state.fixed_tick; command.payload = command.payload.duplicate(true); command_queue.append(command); return command.sequence
func queue(kind: StringName, payload: Dictionary = {}, at_world_tick: int = -1) -> int: return enqueue(SimulationCommand.new(kind, payload, at_world_tick))
func apply_commands_at_current_boundary() -> void: _drain_commands()
func step_once() -> SimulationSnapshot:
	_drain_commands(); state.fixed_tick += 1; fixed_step_boundary.emit(state.fixed_tick)
	if state.fixed_tick % MACRO_TICK_INTERVAL == 0:
		_power.step_macro(state); macro_stage_completed.emit(&"power")
		_logistics.step_macro(state); macro_stage_completed.emit(&"logistics")
		_repairs.step_macro(state); macro_stage_completed.emit(&"repairs")
		_fabrication.step_macro(state); macro_stage_completed.emit(&"fabrication")
		_relay.step_macro(state); macro_stage_completed.emit(&"relay")
		_systemic_events.step_macro(state); macro_stage_completed.emit(&"systemic_events")
		_strategic_assault.step_macro(state); macro_stage_completed.emit(&"strategic_assault")
		_wear.step_macro(state); macro_stage_completed.emit(&"wear")
		_fidelity.step_macro(state); macro_stage_completed.emit(&"fidelity")
		state.world_tick += 1
		_abstract_activity.step_macro(state); macro_stage_completed.emit(&"abstract_activity")
		_validate(); _evaluate_failure()
		if state.assault.phase == "HANDOFF_READY" and not state.assault.handoff_consumed: assault_handoff_ready.emit(state.assault.to_spawn_plan())
	var snapshot := SimulationSnapshot.capture(state); snapshot_emitted.emit(snapshot); return snapshot
func _drain_commands() -> void:
	command_queue.sort_custom(func(a: SimulationCommand, b: SimulationCommand) -> bool: return a.sequence < b.sequence)
	var deferred: Array[SimulationCommand] = []
	for command in command_queue:
		if command.at_world_tick >= 0 and command.at_world_tick > state.world_tick: deferred.append(command)
		else: _apply_command(command)
	command_queue = deferred
func _apply_command(command: SimulationCommand) -> void:
	var ok := false
	match command.kind:
		SimulationCommand.SET_POLICY:
			ok = true
			for key in command.payload:
				if not state.policies.set_level(StringName(key), int(command.payload[key])): ok = false; break
		SimulationCommand.SET_FABRICATION_ALLOCATION: ok = state.policies.set_fabrication_allocation(String(command.payload.get("category", "")), int(command.payload.get("level", -1)))
		SimulationCommand.SET_SECTOR_FORTIFICATION: ok = state.policies.set_sector_fortification(String(command.payload.get("sector_id", "")), int(command.payload.get("level", -1)))
		SimulationCommand.SET_TRANSIT_FORTIFICATION: ok = state.policies.set_transit_fortification(String(command.payload.get("transit_id", "")), int(command.payload.get("level", -1)))
		SimulationCommand.ADD_MATERIALS: var amount := int(command.payload.get("amount", 0)); ok = amount >= 0; if ok: state.materials += amount
		SimulationCommand.SPEND_MATERIALS: var cost := int(command.payload.get("amount", -1)); ok = cost >= 0 and state.materials >= cost; if ok: state.materials -= cost
		SimulationCommand.DAMAGE_STRUCTURE:
			var target: StructureSimulationState = state.structures.get(String(command.payload.get("structure_id", ""))); ok = target != null and int(command.payload.get("amount", 0)) >= 0; if ok: target.apply_damage(int(command.payload.amount))
		SimulationCommand.FAIL_CAMPAIGN: var reason := String(command.payload.get("reason", "")); ok = not reason.is_empty(); if ok: state.failed = true; state.failure_reason = reason
		SimulationCommand.QUEUE_REPAIR:
			var sid:=String(command.payload.get("structure_id","")); var structure: StructureSimulationState=state.structures.get(sid)
			var missing := structure.max_hp - structure.hp if structure != null else 0
			var base_cost := ceili(float(missing) / 20.0)
			var cost := maxi(0, ceili(float(base_cost) * SimulationPolicyTables.REPAIR_MATERIAL_MULT[clampi(state.policies.repair_intensity, 0, 4)]) - (1 if state.relay_knowledge_level >= 2 else 0))
			var power_factor := 1.0 if structure != null and structure.powered else 0.0
			var fidelity_factor: float = float({"FULL": 1.0, "DEGRADED": 0.9, "FRAGMENTED": 0.75, "LOST": 0.5}.get(state.macro_fidelity, 0.5))
			var load_factor: float = maxf(0.5, 1.0 - maxf(0.0, state.power_load - 4.0) * 0.05)
			var effective_speed: float = float(SimulationPolicyTables.REPAIR_SPEED[clampi(state.policies.repair_intensity, 0, 4)]) * fidelity_factor * load_factor * power_factor * state.logistics_multiplier
			var ticks := maxf(1.0, float(missing) / maxf(0.1, effective_speed))
			var assault_lockout := state.assault.phase != "NONE" and structure != null and state.assault.objective == structure.sector_id
			ok=structure!=null and structure.hp>0 and structure.powered and missing>0 and state.materials>=cost and state.repairs.is_empty() and not assault_lockout
			if ok: state.materials-=cost; state.repairs.append({"job_id":"repair_%d"%command.sequence,"structure_id":sid,"remaining":ticks,"total":ticks,"material_cost":cost,"repair_amount":missing,"progress":0.0})
		SimulationCommand.QUEUE_FABRICATION:
			var recipe_id := String(command.payload.get("recipe_id", "")); var recipe := FabricationRecipeContract.get_recipe(recipe_id, state.relay_knowledge_level)
			ok = not recipe.is_empty() and FabricationRecipeContract.has_inputs(state, recipe.get("inputs", {})) and not state.fabrication_queue.any(func(job: Variant) -> bool: return String((job as Dictionary).get("recipe_id", "")) == recipe_id)
			if ok:
				FabricationRecipeContract.consume_inputs(state, recipe.inputs); var duration := float(recipe.ticks) * (0.8 if state.relay_knowledge_level >= 5 else 1.0)
				state.fabrication_queue.append({"job_id":"fab_%d"%command.sequence,"recipe_id":recipe_id,"category":String(recipe.category),"remaining":duration,"total":duration,"inputs":recipe.inputs.duplicate(true),"outputs":recipe.outputs.duplicate(true)})
		SimulationCommand.STABILIZE_RELAY: ok = _relay.stabilize(state, String(command.payload.get("relay_id", "")))
		SimulationCommand.SYNC_RELAYS: ok = _relay.sync_packets(state) >= 0
		SimulationCommand.PHYSICAL_ASSAULT_COMPLETED:
			var assault_id := String(command.payload.get("assault_id", "")); ok = state.assault.phase == "HANDED_OFF" and assault_id == state.assault.assault_id
			if ok:
				state.assault.history.append({"assault_id": assault_id, "approach_tick": state.assault.approach_tick, "handoff_tick": state.world_tick, "physical_completion_tick": state.world_tick})
				while state.assault.history.size() > 32: state.assault.history.pop_front()
				state.assault.phase = "NONE"; state.assault.assault_id = ""; state.assault.objective = ""; state.assault.spawn_plan.clear(); state.assault.route.clear(); state.assault.eta_ticks = 0; state.assault.handoff_consumed = false
		SimulationCommand.ASSAULT_HANDOFF_ACCEPTED:
			var plan_id := String(command.payload.get("plan_id", "")); ok = state.assault.phase == "HANDOFF_READY" and not state.assault.handoff_consumed and plan_id == state.assault.assault_id
			if ok: state.assault.handoff_consumed = true; state.assault.phase = "HANDED_OFF"; state.assault.started_tick = state.world_tick
	if ok: _emit_event(&"command_applied", {"sequence": command.sequence, "kind": String(command.kind)})
	else: _emit_event(SimulationEvent.COMMAND_REJECTED, {"sequence": command.sequence, "kind": String(command.kind)})
func _validate() -> void:
	var errors := _invariants.validate(state, command_queue)
	if errors.is_empty(): return
	_emit_event(SimulationEvent.INVARIANT_VIOLATION, {"errors": errors}); if strict_invariants: assert(false, "Simulation invariant violation: %s" % errors); state.failed = true; state.failure_reason = "SIMULATION_INVARIANT_VIOLATION"
func _evaluate_failure() -> void:
	if state.failed: return
	for structure: StructureSimulationState in state.structures.values():
		if structure.critical_role == "COMMAND_POST" and structure.hp <= 0: state.failed = true; state.failure_reason = "COMMAND_POST_DESTROYED"; _emit_event(&"campaign_failed", {"reason": state.failure_reason}); return
func _emit_event(kind: StringName, payload: Dictionary) -> void:
	state.record_event(kind, payload); event_emitted.emit(SimulationEvent.new(kind, state.fixed_tick, state.world_tick, payload))
