class_name StrategicAssaultSimulationSystem
extends RefCounted

const TARGET_ORDER := ["COMMAND", "ARCHIVE", "DEFENSE_GRID", "POWER", "COMMS", "GATEWAY", "HANGAR", "STORAGE", "FABRICATION"]

func step_macro(state: WorldSimulationState) -> void:
	var assault: AssaultSimulationState = state.assault
	if not state.assaults_enabled: return
	if assault.phase == "HANDOFF_READY" or assault.phase == "HANDED_OFF": return
	if assault.phase == "APPROACHING":
		assault.eta_ticks = maxi(0, assault.eta_ticks - 1)
		assault.route_index = mini(assault.route_index + 1, maxi(0, assault.route.size() - 1))
		if assault.eta_ticks <= 1: assault.warning_issued = true
		if assault.eta_ticks == 0:
			assault.phase = "HANDOFF_READY"
			assault.spawn_plan = [{"composition": _composition(assault.threat_budget), "lane": "north" if assault.ingress_id == "T_NORTH" else "south", "objective": "breach_command", "behavior_profile": ""}]
			state.record_event(&"strategic_assault_handoff_ready", {"assault_id": assault.assault_id, "objective": assault.objective})
		return
	assault.pressure = float(assault.pressure) + 0.15 + state.ambient_threat * 0.02
	if state.ambient_threat <= 1.5 or state.next_random_unit() >= minf(0.8, 0.08 + state.ambient_threat * 0.06 + state.relay_dormancy_pressure * 0.03): return
	var targets := TARGET_ORDER.duplicate()
	targets.sort_custom(func(a: String, b: String) -> bool:
		var sa: SectorSimulationState = state.sectors[a]; var sb: SectorSimulationState = state.sectors[b]
		var wa := (2.0 if a == "COMMAND" else 1.0) + sa.damage * 1.2 + sa.alertness * 0.6
		var wb := (2.0 if b == "COMMAND" else 1.0) + sb.damage * 1.2 + sb.alertness * 0.6
		return wa > wb if not is_equal_approx(wa, wb) else a < b)
	var ingress := "T_NORTH" if state.next_random_index(2) == 0 else "T_SOUTH"
	assault.phase = "APPROACHING"; assault.assault_id = "assault_%d_%d" % [state.seed, state.world_tick]; assault.ingress_id = ingress; assault.objective = targets[0]; assault.route = [ingress, assault.objective]; assault.route_index = 0; assault.eta_ticks = 2; assault.approach_tick = state.world_tick; assault.started_tick = -1; assault.threat_budget = maxf(10.0, roundf(10.0 + state.ambient_threat * 3.0)); assault.pressure = assault.threat_budget; assault.warning_issued = false; assault.handoff_consumed = false
	state.record_event(&"strategic_assault_approaching", {"assault_id": assault.assault_id, "ingress": ingress, "objective": assault.objective, "eta_ticks": assault.eta_ticks})

func _composition(budget: float) -> Array[String]:
	var count := clampi(roundi(budget / 10.0), 1, 12); var result: Array[String] = []
	for index in count: result.append("grunt")
	return result
