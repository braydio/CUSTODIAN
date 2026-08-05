class_name SimulationKernel
extends RefCounted

const ClockScript := preload("res://game/systems/simulation/simulation_clock.gd")
const CommandScript := preload("res://game/systems/simulation/simulation_command.gd")
const EventScript := preload("res://game/systems/simulation/simulation_event.gd")
const SnapshotScript := preload("res://game/state/world/simulation_snapshot.gd")
const InvariantsScript := preload("res://game/systems/simulation/simulation_invariants.gd")
const PowerSystemScript := preload("res://game/systems/simulation/power_simulation_system.gd")
const LogisticsSystemScript := preload("res://game/systems/simulation/logistics_simulation_system.gd")
const WorldStateScript := preload("res://game/state/world/world_simulation_state.gd")

const MACRO_TICK_INTERVAL := 60

signal snapshot_emitted(snapshot)
signal event_emitted(event)

var state
var simulation_tick := 0
var command_queue: Array = []
var _next_command_sequence := 1
var _macro_systems: Array[Callable] = []
var _fixed_systems: Array[Callable] = []
var invariants = InvariantsScript.new()
var _power_system
var _logistics_system

func _init(initial_state = null) -> void:
	state = initial_state if initial_state != null else WorldStateScript.new()
	_power_system = PowerSystemScript.new()
	_logistics_system = LogisticsSystemScript.new()
	_fixed_systems.append(Callable(_power_system, "step"))
	_macro_systems.append(Callable(_logistics_system, "step_macro"))

func enqueue(command) -> int:
	command.sequence = _next_command_sequence
	_next_command_sequence += 1
	command_queue.append(command)
	return command.sequence

func queue(kind: String, payload: Dictionary = {}) -> int:
	return enqueue(CommandScript.new(kind, payload))

func step_once():
	_drain_commands()
	for system in _fixed_systems:
		system.call(state, ClockScript.FIXED_DT)
	simulation_tick += 1
	state.tick = simulation_tick
	if simulation_tick % MACRO_TICK_INTERVAL == 0:
		for system in _macro_systems:
			system.call(state)
		invariants.validate(state)
	var snapshot = SnapshotScript.new(state)
	snapshot_emitted.emit(snapshot)
	return snapshot

func _drain_commands() -> void:
	command_queue.sort_custom(func(left, right) -> bool: return left.sequence < right.sequence)
	var pending := command_queue
	command_queue = []
	for command in pending:
		_apply_command(command)

func _apply_command(command) -> void:
	match command.kind:
		"set_policy":
			for key in command.payload:
				if key in ["repair_intensity", "defense_readiness", "surveillance_coverage", "fortification", "fabrication_allocation"]:
					state.policies.set(StringName(key), clampi(int(command.payload[key]), 0, 4))
			_emit_event("policy_changed", command.payload)
		"damage_structure":
			var structure_id := String(command.payload.get("structure_id", ""))
			var structure = state.structures.get(structure_id)
			if structure != null:
				var amount: int = structure.apply_damage(int(command.payload.get("amount", 0)))
				_emit_event("structure_damaged", {"structure_id": structure_id, "amount": amount, "source": command.payload.get("source", "unknown")})
		"fail_campaign":
			state.failed = true
			state.failure_reason = String(command.payload.get("reason", "unspecified"))
			_emit_event("campaign_failed", {"reason": state.failure_reason})
		_:
			_emit_event("command_rejected", {"kind": command.kind})

func _emit_event(kind: String, payload: Dictionary) -> void:
	state.record_event(kind, payload)
	event_emitted.emit(EventScript.new(kind, state.tick, payload))
