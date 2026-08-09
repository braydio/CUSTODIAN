class_name SimulationSnapshot
extends RefCounted
const SCHEMA := "custodian.world_simulation_snapshot"
const VERSION := 2
var fixed_tick: int = 0
var world_tick: int = 0
var fingerprint: String = ""
var payload: Dictionary = {}

static func capture(state: WorldSimulationState) -> SimulationSnapshot:
	var value := SimulationSnapshot.new(); value.fixed_tick = state.fixed_tick; value.world_tick = state.world_tick; value.payload = state.to_dict().duplicate(true); value.fingerprint = SimulationCanonicalJson.sha256(value.payload); return value
static func restore(snapshot_data: Dictionary) -> WorldSimulationState:
	var migrated := SimulationSnapshotMigration.migrate(snapshot_data)
	if migrated.is_empty(): return null
	var state := WorldSimulationState.from_dict(migrated.get("state", {}))
	if String(migrated.get("fingerprint", "")) != SimulationCanonicalJson.sha256(state.to_dict()): return null
	return state
func to_dict() -> Dictionary: return {"schema": SCHEMA, "schema_version": VERSION, "fixed_tick": fixed_tick, "world_tick": world_tick, "fingerprint": fingerprint, "state": payload.duplicate(true)}
