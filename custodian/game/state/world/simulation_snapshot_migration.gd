class_name SimulationSnapshotMigration
extends RefCounted
static func migrate(data: Dictionary) -> Dictionary:
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == SimulationSnapshot.VERSION:
		var current := data.duplicate(true)
		var snapshot_state: Variant = current.get("state", {})
		var abstract_state: Variant = snapshot_state.get("abstract_activity", {}) if snapshot_state is Dictionary else {}
		if abstract_state is Dictionary and int(abstract_state.get("schema_version", 0)) == 1:
			return _capture_migrated_state(snapshot_state)
		return current
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == 4 and data.get("state", {}) is Dictionary:
		return _capture_migrated_state(data.state)
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == 3 and data.get("state", {}) is Dictionary:
		return _capture_migrated_state(data.state)
	if String(data.get("schema", "")) == SimulationSnapshot.SCHEMA and int(data.get("schema_version", 0)) == 2 and data.get("state", {}) is Dictionary:
		var legacy_state: Dictionary = data.state.duplicate(true)
		if (legacy_state.get("relays", {}) as Dictionary).is_empty(): legacy_state.erase("relays")
		legacy_state.erase("rng_state"); legacy_state.erase("systemic_event_state"); legacy_state.erase("relay_knowledge_level"); legacy_state.erase("relay_dormancy_pressure")
		if not legacy_state.has("assaults_enabled"): legacy_state.assaults_enabled = false
		return _capture_migrated_state(legacy_state)
	# Scaffold v1 used {tick,fingerprint,state}; recalculate the now-cross-runtime fingerprint.
	if data.has("tick") and data.has("state"):
		return _capture_migrated_state(data.state)
	push_error("Unsupported simulation snapshot schema/version")
	return {}


static func _capture_migrated_state(state_data: Dictionary) -> Dictionary:
	var state := WorldSimulationState.from_dict(state_data)
	if not state.snapshot_state_valid:
		return {}
	return SimulationSnapshot.capture(state).to_dict()
