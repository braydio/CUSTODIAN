class_name SystemicEventSimulationSystem
extends RefCounted

const CATEGORIES := ["QUIET", "ENVIRONMENTAL", "INFRASTRUCTURE", "RECON", "HOSTILE"]
const EVENT_CHANCE_BASE := 0.03
const EVENT_CHANCE_PER_THREAT := 0.012
const EVENT_CHANCE_MAX := 0.4
const BASE_WEIGHTS := {"QUIET": 0.35, "ENVIRONMENTAL": 0.20, "INFRASTRUCTURE": 0.15, "RECON": 0.15, "HOSTILE": 0.15}
const MIN_THREAT := {"QUIET": 0.0, "ENVIRONMENTAL": 0.8, "INFRASTRUCTURE": 1.5, "RECON": 1.0, "HOSTILE": 2.0}
const EVENT_KEYS := {"QUIET": ["quiet_signal"], "ENVIRONMENTAL": ["microfracture", "thermal_anomaly", "radiation_burst"], "INFRASTRUCTURE": ["fabrication_delay", "archive_integrity", "grid_recalibration"], "RECON": ["perimeter_probe", "sensor_jam", "signal_interference"], "HOSTILE": ["sabotage", "data_siphon", "infiltration"]}

func step_macro(state: WorldSimulationState) -> void:
	var context: Dictionary = state.systemic_event_state
	context.ticks_since_assault = int(context.get("ticks_since_assault", 0)) + 1
	context.ticks_since_hostile = int(context.get("ticks_since_hostile", 0)) + 1
	var weights: Dictionary = {}
	var total := 0.0
	for category in CATEGORIES:
		if state.ambient_threat < float(MIN_THREAT[category]): continue
		var weight := float(BASE_WEIGHTS[category])
		if int(context.ticks_since_assault) < 5 and category in ["ENVIRONMENTAL", "QUIET"]: weight *= 1.4
		if _aggregate_power(state) < 0.4 and category == "INFRASTRUCTURE": weight *= 1.5
		if int(context.ticks_since_hostile) > 25 and category == "RECON": weight *= 1.5
		if String(context.get("last_category", "")) == category: weight *= 0.25
		weights[category] = weight; total += weight
	var chance := minf(EVENT_CHANCE_MAX, EVENT_CHANCE_BASE + state.ambient_threat * EVENT_CHANCE_PER_THREAT)
	if total <= 0.0 or state.next_random_unit() >= chance: return
	var roll := state.next_random_unit() * total
	var selected := "QUIET"
	for category in CATEGORIES:
		if not weights.has(category): continue
		roll -= float(weights[category])
		if roll < 0.0: selected = category; break
	var recent: Array = context.get("recent_keys", [])
	var candidates: Array = EVENT_KEYS[selected].duplicate()
	if candidates.size() > 1:
		var filtered := candidates.filter(func(key: String) -> bool: return key not in recent)
		if not filtered.is_empty(): candidates = filtered
	var key: String = candidates[state.next_random_index(candidates.size())]
	context.last_category = selected
	context.ticks_since_hostile = 0 if selected == "HOSTILE" else int(context.ticks_since_hostile)
	recent.append(key); while recent.size() > 8: recent.pop_front(); context.recent_keys = recent
	var categories: Array = context.get("recent_categories", []); categories.append(selected); while categories.size() > 8: categories.pop_front(); context.recent_categories = categories
	var record := {"world_tick": state.world_tick, "category": selected, "event_key": key}
	var history: Array = context.get("history", []); history.append(record); while history.size() > 16: history.pop_front(); context.history = history
	_apply_consequence(state, selected, key)
	state.record_event(&"systemic_event", record)

func _apply_consequence(state: WorldSimulationState, category: String, key: String) -> void:
	if category == "QUIET": return
	state.ambient_threat = minf(10.0, state.ambient_threat + (0.25 if category == "HOSTILE" else 0.05))
	var target_id := "COMMAND" if category == "HOSTILE" else "COMMS" if category == "RECON" else "POWER" if category == "INFRASTRUCTURE" else "HANGAR"
	var sector: SectorSimulationState = state.sectors.get(target_id)
	if sector == null: return
	sector.alertness = minf(10.0, sector.alertness + (0.5 if category == "HOSTILE" else 0.2))
	if key == "perimeter_probe" or key == "infiltration": sector.occupied = true

func _aggregate_power(state: WorldSimulationState) -> float:
	if state.sectors.is_empty(): return 0.0
	var total := 0.0
	for sector: SectorSimulationState in state.sectors.values(): total += sector.power
	return total / float(state.sectors.size())
