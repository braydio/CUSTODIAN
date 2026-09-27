class_name SimulationKernel
extends RefCounted
const MACRO_TICK_INTERVAL := 60
signal snapshot_emitted(snapshot: SimulationSnapshot)
signal event_emitted(event: SimulationEvent)
signal macro_stage_completed(stage: StringName)
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
var _invariants := SimulationInvariants.new()

func _init(initial_state: WorldSimulationState = null) -> void: state = initial_state if initial_state != null else WorldSimulationState.new()
func enqueue(command: SimulationCommand) -> int:
	command.sequence = _next_command_sequence; _next_command_sequence += 1; command.issued_fixed_tick = state.fixed_tick; command.payload = command.payload.duplicate(true); command_queue.append(command); return command.sequence
func queue(kind: StringName, payload: Dictionary = {}, at_world_tick: int = -1) -> int: return enqueue(SimulationCommand.new(kind, payload, at_world_tick))
func apply_commands_at_current_boundary() -> void: _drain_commands()
func step_once() -> SimulationSnapshot:
	_drain_commands(); state.fixed_tick += 1
	if state.fixed_tick % MACRO_TICK_INTERVAL == 0:
		_power.step_macro(state); macro_stage_completed.emit(&"power")
		_logistics.step_macro(state); macro_stage_completed.emit(&"logistics")
		_repairs.step_macro(state); macro_stage_completed.emit(&"repairs")
		_fabrication.step_macro(state); macro_stage_completed.emit(&"fabrication")
		_relay.step_macro(state); macro_stage_completed.emit(&"relay")
		_systemic_events.step_macro(state); macro_stage_completed.emit(&"systemic_events")
		var previous_assault_phase := state.assault.phase
		_strategic_assault.step_macro(state); macro_stage_completed.emit(&"strategic_assault")
		if previous_assault_phase != "HANDOFF_READY" and state.assault.phase == "HANDOFF_READY": assault_handoff_ready.emit(state.assault.to_spawn_plan())
		state.world_tick += 1; _validate(); _evaluate_failure()
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
			var sid:=String(command.payload.get("structure_id","")); var structure: StructureSimulationState=state.structures.get(sid); var cost:=int(command.payload.get("material_cost",0)); ok=structure!=null and structure.hp<structure.max_hp and cost>=0 and state.materials>=cost
			if ok: state.materials-=cost; state.repairs.append({"job_id":"repair_%d"%command.sequence,"structure_id":sid,"remaining":float(command.payload.get("ticks",3.0)),"total":float(command.payload.get("ticks",3.0)),"material_cost":cost})
		SimulationCommand.QUEUE_FABRICATION:
			var category:=String(command.payload.get("category","")); ok=category in PolicySimulationState.FABRICATION_CATEGORIES
			if ok: state.fabrication_queue.append({"job_id":"fab_%d"%command.sequence,"recipe_id":String(command.payload.get("recipe_id","CUSTOM")),"category":category,"remaining":float(command.payload.get("ticks",3.0)),"total":float(command.payload.get("ticks",3.0)),"outputs":(command.payload.get("outputs",{}) as Dictionary).duplicate(true)})
		SimulationCommand.STABILIZE_RELAY: ok = _relay.stabilize(state, String(command.payload.get("relay_id", "")))
		SimulationCommand.SYNC_RELAYS: ok = _relay.sync_packets(state) >= 0
		SimulationCommand.PHYSICAL_ASSAULT_COMPLETED:
			var assault_id := String(command.payload.get("assault_id", "")); ok = state.assault.phase == "HANDED_OFF" and assault_id == state.assault.assault_id
			if ok:
				state.assault.history.append({"assault_id": assault_id, "approach_tick": state.assault.approach_tick, "handoff_tick": state.world_tick, "physical_completion_tick": state.world_tick})
				while state.assault.history.size() > 32: state.assault.history.pop_front()
				state.assault.phase = "NONE"; state.assault.assault_id = ""; state.assault.objective = ""; state.assault.spawn_plan.clear(); state.assault.route.clear(); state.assault.eta_ticks = 0; state.assault.handoff_consumed = false
		SimulationCommand.STABILIZE_RELAY: ok = _relay.stabilize(state, String(command.payload.get("relay_id", "")))
		SimulationCommand.SYNC_RELAYS: ok = _relay.sync_packets(state) >= 0
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
