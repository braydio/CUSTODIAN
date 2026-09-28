class_name RelaySimulationSystem
extends RefCounted

const DECAY_BASE := 0.5
const DECAY_PER_APPROACH := 0.2
const KNOWLEDGE_MAX := 7
const KNOWLEDGE_DRIFT_PERIOD := 40

func step_macro(state: WorldSimulationState) -> void:
	var approaching := 1 if state.assault.phase in ["APPROACHING", "HANDOFF_READY", "HANDED_OFF"] else 0
	var decay := DECAY_BASE + approaching * DECAY_PER_APPROACH
	var ids: Array = state.relays.keys(); ids.sort()
	var dormant := 0
	for id in ids:
		var relay: Dictionary = state.relays[id]
		var status := String(relay.get("status", "UNKNOWN"))
		if status != "UNKNOWN":
			relay.stability = maxf(0.0, float(relay.get("stability", 0.0)) - decay)
			if status == "LOCATED":
				if float(relay.stability) < 30.0: relay.status = "DORMANT"
			elif float(relay.stability) >= 70.0: relay.status = "STABLE"
			elif float(relay.stability) >= 30.0: relay.status = "WEAK"
			else: relay.status = "DORMANT"
		if relay.status == "DORMANT": dormant += 1
	var level := state.relay_knowledge_level
	var pressure := maxi(0, ceili(float(dormant) / 2.0)) if level >= KNOWLEDGE_MAX else dormant
	state.relay_dormancy_pressure = pressure
	if pressure >= 3 and state.world_tick > 0 and state.world_tick % KNOWLEDGE_DRIFT_PERIOD == 0:
		state.relay_knowledge_level = maxi(0, level - 1)
		_recompute_pressure(state)
		state.record_event(&"relay_knowledge_drift", {"knowledge_level": state.relay_knowledge_level})

func stabilize(state: WorldSimulationState, relay_id: String) -> bool:
	if not state.relays.has(relay_id): return false
	var relay: Dictionary = state.relays[relay_id]
	if relay.status == "UNKNOWN": relay.status = "LOCATED"
	relay.status = "STABLE"; relay.stability = 100.0; relay.packets_pending = int(relay.get("packets_pending", 0)) + 1
	return true

func sync_packets(state: WorldSimulationState) -> int:
	var pending := 0
	var ids: Array = state.relays.keys(); ids.sort()
	for id in ids:
		var relay: Dictionary = state.relays[id]; pending += int(relay.get("packets_pending", 0)); relay.packets_pending = 0
	if pending <= 0: _recompute_pressure(state); return 0
	var weak := 0; var active := 0
	for relay: Dictionary in state.relays.values():
		if relay.status in ["STABLE", "WEAK"]: active += 1
		if relay.status == "WEAK": weak += 1
	var failed := 0
	for index in mini(weak, pending):
		if state.next_random_unit() < 0.1: failed += 1
	var successful := maxi(0, pending - failed)
	var gain := roundi(successful * (1.0 - (0.5 * (float(weak) / maxf(1.0, float(active))))))
	state.relay_knowledge_level = mini(KNOWLEDGE_MAX, state.relay_knowledge_level + gain)
	_recompute_pressure(state)
	return successful

func _recompute_pressure(state: WorldSimulationState) -> void:
	var dormant := 0
	for relay: Dictionary in state.relays.values():
		if String(relay.get("status", "")) == "DORMANT": dormant += 1
	state.relay_dormancy_pressure = maxi(0, ceili(float(dormant) / 2.0)) if state.relay_knowledge_level >= KNOWLEDGE_MAX else dormant
