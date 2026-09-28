class_name SimulationSnapshotMigration
extends RefCounted
static func migrate(data: Dictionary) -> Dictionary:
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == SimulationSnapshot.VERSION: return data.duplicate(true)
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == 3 and data.get("state", {}) is Dictionary:
		return SimulationSnapshot.capture(WorldSimulationState.from_dict(data.state)).to_dict()
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == 2 and data.get("state", {}) is Dictionary:
		var legacy_state: Dictionary = data.state.duplicate(true)
		if (legacy_state.get("relays", {}) as Dictionary).is_empty(): legacy_state.erase("relays")
		legacy_state.erase("rng_state"); legacy_state.erase("systemic_event_state"); legacy_state.erase("relay_knowledge_level"); legacy_state.erase("relay_dormancy_pressure")
		if not legacy_state.has("assaults_enabled"): legacy_state.assaults_enabled = false
		return SimulationSnapshot.capture(WorldSimulationState.from_dict(legacy_state)).to_dict()
	# Scaffold v1 used {tick,fingerprint,state}; recalculate the now-cross-runtime fingerprint.
	if data.has("tick") and data.has("state"):
		var state := WorldSimulationState.from_dict(data.state)
		var snapshot := SimulationSnapshot.capture(state)
		return snapshot.to_dict()
	push_error("Unsupported simulation snapshot schema/version")
	return {}
