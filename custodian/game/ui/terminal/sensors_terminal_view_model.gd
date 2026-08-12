extends RefCounted
class_name SensorsTerminalViewModel


static func build(snapshot: Dictionary, early_warning_ticks: int = 0) -> Dictionary:
	var intelligence: Dictionary = snapshot.get("sensor_intelligence", {})
	var director: Dictionary = snapshot.get("director", {})
	var arrn: Dictionary = snapshot.get("arrn", {})
	var fidelity := String(snapshot.get("fidelity", "lost")).to_upper()
	var contacts: Array = intelligence.get("contacts", [])
	var sector_activity: Array = intelligence.get("sector_activity", [])
	var ingress := String(director.get("active_lane", ""))
	if ingress.is_empty():
		ingress = String(director.get("lane", ""))
	if ingress.is_empty():
		ingress = "UNCONFIRMED"
	var objective := String(director.get("objective", "UNCONFIRMED"))
	if objective.is_empty():
		objective = "UNCONFIRMED"
	var composition: Array = director.get("composition", [])
	var confidence: String = String({"FULL": "HIGH", "DEGRADED": "MEDIUM", "FRAGMENTED": "LOW", "LOST": "NONE"}.get(fidelity, "NONE"))
	if ingress == "UNCONFIRMED" and confidence == "HIGH":
		confidence = "UNCONFIRMED"
	var relays: Array = arrn.get("relays", [])
	var stable_relays := 0
	for relay: Dictionary in relays:
		if String(relay.get("status", "")).to_upper() == "STABLE":
			stable_relays += 1
	return {
		"fidelity": fidelity,
		"terminal_mode": String(snapshot.get("terminal_mode", "field")).to_upper(),
		"tracked_count": int(intelligence.get("tracked_count", contacts.size())),
		"current_count": int(intelligence.get("current_count", contacts.size())),
		"stale_count": int(intelligence.get("stale_count", 0)),
		"contacts": contacts,
		"sector_activity": sector_activity,
		"message": intelligence.get("message", ""),
		"forecast": {
			"ingress": ingress.to_upper(),
			"objective": objective.replace("_", " ").to_upper(),
			"wave_profile": ", ".join(composition).to_upper() if not composition.is_empty() else "NONE PLANNED",
			"confidence": confidence,
			"early_warning_ticks": early_warning_ticks,
		},
		"network_support": {
			"arrn_knowledge": int(arrn.get("knowledge_index", 0)),
			"arrn_max": int(arrn.get("knowledge_max", 7)),
			"stable_relays": stable_relays,
			"relay_total": relays.size(),
			"threat_forecast_active": early_warning_ticks > 0,
		},
	}
