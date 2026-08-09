class_name WorldSimulationRuntime
extends Node
signal campaign_started(session: CampaignSession)
signal snapshot_updated(snapshot: SimulationSnapshot)
signal simulation_event(event: SimulationEvent)
signal campaign_resolved(outcome: CampaignOutcome)
var clock: SimulationClock = SimulationClock.new()
var kernel: SimulationKernel
var session: CampaignSession
var latest_snapshot: SimulationSnapshot
var auto_start_default := true
func _ready() -> void:
	add_to_group("world_simulation_runtime")
	if auto_start_default and session == null: start_campaign(DefaultCampaignScenarioFactory.create_scenario())
func _process(delta: float) -> void:
	if kernel != null: clock.advance(delta, _authoritative_step)
func start_campaign(scenario: CampaignScenario) -> void:
	var world := DefaultCampaignScenarioFactory.create_world(scenario); session = CampaignSession.new(scenario, world); session.start(); kernel = SimulationKernel.new(world); kernel.event_emitted.connect(_on_event); latest_snapshot = SimulationSnapshot.capture(world); campaign_started.emit(session); snapshot_updated.emit(latest_snapshot)
func queue_command(kind: StringName, payload: Dictionary = {}, at_world_tick: int = -1) -> int: return -1 if kernel == null else kernel.queue(kind, payload, at_world_tick)
func set_simulation_paused(value: bool) -> void: clock.paused = value
func current_snapshot() -> SimulationSnapshot: return latest_snapshot
func resolve_campaign(result: StringName, reason: String = "") -> CampaignOutcome:
	if session == null: return null
	var outcome := session.resolve_once(result, reason)
	if outcome != null: campaign_resolved.emit(outcome)
	return outcome
func save_snapshot() -> Dictionary: return {} if latest_snapshot == null else latest_snapshot.to_dict()
func restore_snapshot(data: Dictionary) -> void:
	var restored := SimulationSnapshot.restore(data); if restored == null: return
	if session == null: var scenario := DefaultCampaignScenarioFactory.create_scenario(restored.seed); session = CampaignSession.new(scenario, restored); session.start()
	else: session.world = restored
	kernel = SimulationKernel.new(restored); kernel.event_emitted.connect(_on_event); latest_snapshot = SimulationSnapshot.capture(restored); clock.fixed_tick = restored.fixed_tick; snapshot_updated.emit(latest_snapshot)
func _authoritative_step() -> void:
	latest_snapshot = kernel.step_once(); var game_state := get_node_or_null("/root/GameState"); if game_state != null and game_state.has_method("advance"): game_state.advance(); snapshot_updated.emit(latest_snapshot)
func _on_event(event: SimulationEvent) -> void: simulation_event.emit(event)
