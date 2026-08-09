class_name SimulationSnapshotMigration
extends RefCounted
static func migrate(data: Dictionary) -> Dictionary:
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == SimulationSnapshot.VERSION: return data.duplicate(true)
	# Scaffold v1 used {tick,fingerprint,state}; recalculate the now-cross-runtime fingerprint.
	if data.has("tick") and data.has("state"):
		var state := WorldSimulationState.from_dict(data.state)
		var snapshot := SimulationSnapshot.capture(state)
		return snapshot.to_dict()
	push_error("Unsupported simulation snapshot schema/version")
	return {}
