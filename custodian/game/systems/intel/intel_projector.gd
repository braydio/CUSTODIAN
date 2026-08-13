class_name IntelProjector
extends RefCounted

enum Fidelity {
	FULL,
	DEGRADED,
	FRAGMENTED,
	LOST,
}

const FIDELITY_LABELS := {
	Fidelity.FULL: "FULL",
	Fidelity.DEGRADED: "DEGRADED",
	Fidelity.FRAGMENTED: "FRAGMENTED",
	Fidelity.LOST: "LOST",
}


static func fidelity_label(fidelity: int) -> String:
	return str(FIDELITY_LABELS.get(fidelity, "UNKNOWN"))


static func next_fidelity(fidelity: int) -> int:
	match fidelity:
		Fidelity.FULL:
			return Fidelity.DEGRADED
		Fidelity.DEGRADED:
			return Fidelity.FRAGMENTED
		Fidelity.FRAGMENTED:
			return Fidelity.LOST
		_:
			return Fidelity.FULL


static func project_sector(truth: Dictionary, fidelity: int) -> Dictionary:
	match fidelity:
		Fidelity.FULL:
			return _project_full(truth)
		Fidelity.DEGRADED:
			return _project_degraded(truth)
		Fidelity.FRAGMENTED:
			return _project_fragmented(truth)
		Fidelity.LOST:
			return _project_lost(truth)
	return _project_lost(truth)


static func project_all_sectors(truth_sectors: Array, fidelity: int) -> Array:
	var projected: Array = []
	for sector in truth_sectors:
		if sector is Dictionary:
			var sector_truth: Dictionary = sector as Dictionary
			projected.append(project_sector(sector_truth, fidelity))
	return projected


static func fidelity_from_name(value: Variant) -> int:
	match String(value).strip_edges().to_upper():
		"FULL": return Fidelity.FULL
		"DEGRADED": return Fidelity.DEGRADED
		"FRAGMENTED": return Fidelity.FRAGMENTED
		_: return Fidelity.LOST


static func project_contacts(truth_snapshot: Dictionary, fidelity: int, terminal_mode: StringName = &"command", current_tick: int = 0) -> Dictionary:
	var truth_contacts: Array = truth_snapshot.get("contacts", [])
	if fidelity == Fidelity.LOST:
		return {"contacts": [], "sector_activity": [], "message": "NO USABLE NETWORK RETURN", "confidence": "NONE"}
	if fidelity == Fidelity.FRAGMENTED:
		var aggregates: Dictionary = {}
		for contact: Dictionary in truth_contacts:
			var sector := String(contact.get("sector", "UNCONFIRMED"))
			if not aggregates.has(sector):
				aggregates[sector] = {"sector": sector, "activities": {}, "sector_map_position": contact.get("sector_map_position", null)}
			var activity := String(contact.get("activity", "ACTIVITY DETECTED"))
			(aggregates[sector]["activities"] as Dictionary)[activity] = true
		var sector_activity: Array[Dictionary] = []
		for sector in aggregates.keys():
			var activities := (aggregates[sector]["activities"] as Dictionary).keys()
			activities.sort()
			var activity_return := {"sector": sector, "activity": ", ".join(activities), "confidence": "LOW"}
			var anchor: Variant = aggregates[sector].get("sector_map_position", null)
			if anchor is Vector2:
				activity_return["sector_map_position"] = anchor
			sector_activity.append(activity_return)
		sector_activity.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["sector"]) < String(b["sector"]))
		return {"contacts": [], "sector_activity": sector_activity, "message": "ACTIVITY RETURNS FRAGMENTED", "confidence": "LOW"}
	var contacts: Array[Dictionary] = []
	for truth: Dictionary in truth_contacts:
		var age_ticks := maxi(0, current_tick - int(truth.get("last_seen_tick", current_tick)))
		var projected := {
			"contact_id": truth.get("contact_id", ""),
			"sector": truth.get("sector", "UNCONFIRMED"),
			"class_label": truth.get("class_label", "UNKNOWN"),
			"activity": truth.get("activity", "UNKNOWN"),
			"stale": bool(truth.get("stale", false)),
			"confidence": "HIGH" if fidelity == Fidelity.FULL and terminal_mode == &"command" else "MEDIUM",
		}
		if fidelity == Fidelity.FULL and terminal_mode == &"command":
			projected["world_position"] = truth.get("world_position", Vector2.ZERO)
			projected["health_pct"] = truth.get("health_pct", 0.0)
			projected["velocity"] = truth.get("velocity", Vector2.ZERO)
			projected["age_ticks"] = age_ticks
		else:
			projected["age_bucket"] = _contact_age_bucket(age_ticks)
			var position: Vector2 = truth.get("world_position", Vector2.ZERO)
			projected["coarse_map_position"] = Vector2(
				roundf(position.x / 256.0) * 256.0,
				roundf(position.y / 256.0) * 256.0
			)
		contacts.append(projected)
	return {
		"contacts": contacts,
		"sector_activity": [],
		"tracked_count": contacts.size(),
		"current_count": contacts.filter(func(contact: Dictionary) -> bool: return not bool(contact.get("stale", false))).size(),
		"stale_count": contacts.filter(func(contact: Dictionary) -> bool: return bool(contact.get("stale", false))).size(),
		"confidence": "HIGH" if fidelity == Fidelity.FULL and terminal_mode == &"command" else "MEDIUM",
	}


static func project_forecast(director: Dictionary, fidelity: int) -> Dictionary:
	var ingress := String(director.get("active_lane", director.get("lane", ""))).strip_edges()
	var objective := String(director.get("objective", "")).strip_edges()
	var composition: Array = director.get("composition", [])
	match fidelity:
		Fidelity.FULL:
			return {"ingress": ingress if not ingress.is_empty() else "UNCONFIRMED", "objective": objective if not objective.is_empty() else "UNCONFIRMED", "composition": composition.duplicate()}
		Fidelity.DEGRADED:
			return {"ingress": ingress if not ingress.is_empty() else "UNCONFIRMED", "objective": _soften_forecast_objective(objective), "composition": _bucket_composition(composition)}
		Fidelity.FRAGMENTED:
			return {"ingress": "UNCONFIRMED", "objective": "HOSTILE PRESSURE", "composition": ["COMPOSITION UNCONFIRMED"]}
		_:
			return {"ingress": "NO RETURN", "objective": "NO RETURN", "composition": ["NO RETURN"]}


static func _soften_forecast_objective(objective: String) -> String:
	if objective.is_empty() or objective.to_lower() in ["none", "unknown"]:
		return "UNCONFIRMED"
	return "HOSTILE PRESSURE"


static func _bucket_composition(composition: Array) -> Array:
	if composition.is_empty():
		return []
	return ["MIXED HOSTILES" if composition.size() > 1 else "HOSTILE ELEMENT"]


static func _contact_age_bucket(age_ticks: int) -> String:
	if age_ticks <= 30: return "CURRENT"
	if age_ticks <= 180: return "RECENT"
	return "STALE"


static func _project_full(truth: Dictionary) -> Dictionary:
	return {
		"id": truth.get("id", ""),
		"name": truth.get("name", "UNKNOWN"),
		"integrity": "%d%%" % int(truth.get("integrity", 0)),
		"power": truth.get("power", "UNKNOWN"),
		"hostiles": str(int(truth.get("hostiles", 0))),
		"activity": truth.get("activity", "UNKNOWN"),
		"objective": truth.get("objective", "UNKNOWN"),
		"eta": _format_eta(int(truth.get("eta", -1))),
		"confidence": "HIGH",
	}


static func _project_degraded(truth: Dictionary) -> Dictionary:
	var hostile_count := int(truth.get("hostiles", 0))
	return {
		"id": truth.get("id", ""),
		"name": truth.get("name", "UNKNOWN"),
		"integrity": _bucket_integrity(int(truth.get("integrity", 0))),
		"power": _soften_power_state(str(truth.get("power", "UNKNOWN"))),
		"hostiles": _bucket_hostiles(hostile_count),
		"activity": truth.get("activity", "UNKNOWN") if hostile_count > 0 else "NO HOSTILE RETURN",
		"objective": _soften_objective(str(truth.get("objective", "UNKNOWN"))),
		"eta": _bucket_eta(int(truth.get("eta", -1))),
		"confidence": "MEDIUM",
	}


static func _project_fragmented(truth: Dictionary) -> Dictionary:
	var hostile_count := int(truth.get("hostiles", 0))
	var integrity := int(truth.get("integrity", 0))
	var signal_text := "NO CLEAR RETURN"
	if hostile_count > 0:
		signal_text = "ACTIVITY DETECTED"
	elif integrity < 70:
		signal_text = "STRUCTURAL SIGNAL DEGRADED"
	return {
		"id": truth.get("id", ""),
		"name": truth.get("name", "UNKNOWN"),
		"integrity": "UNCONFIRMED",
		"power": "UNCONFIRMED",
		"hostiles": "UNKNOWN",
		"activity": signal_text,
		"objective": "UNCONFIRMED",
		"eta": "UNCONFIRMED",
		"confidence": "LOW",
	}


static func _project_lost(truth: Dictionary) -> Dictionary:
	return {
		"id": truth.get("id", ""),
		"name": truth.get("name", "UNKNOWN"),
		"integrity": "",
		"power": "",
		"hostiles": "",
		"activity": "SIGNAL LOST",
		"objective": "",
		"eta": "",
		"confidence": "NONE",
	}


static func _bucket_hostiles(count: int) -> String:
	if count <= 0:
		return "NONE"
	if count == 1:
		return "ONE"
	if count <= 3:
		return "FEW"
	if count <= 6:
		return "SEVERAL"
	return "MANY"


static func _bucket_integrity(integrity: int) -> String:
	if integrity >= 90:
		return "STABLE"
	if integrity >= 65:
		return "DAMAGED"
	if integrity >= 35:
		return "FAILING"
	return "CRITICAL"


static func _soften_power_state(power: String) -> String:
	match power:
		"ONLINE":
			return "ONLINE"
		"LOW":
			return "UNSTABLE"
		"OFFLINE":
			return "DARK"
		_:
			return "UNKNOWN"


static func _soften_objective(objective: String) -> String:
	match objective:
		"STEALING":
			return "LOOTING"
		"ATTACKING":
			return "HOSTILE PRESSURE"
		"MOVING":
			return "MOVEMENT"
		"IDLE":
			return "NO CLEAR OBJECTIVE"
		_:
			return "UNKNOWN"


static func _format_eta(seconds: int) -> String:
	if seconds < 0:
		return "NONE"
	return "%ds" % seconds


static func _bucket_eta(seconds: int) -> String:
	if seconds < 0:
		return "NONE"
	if seconds <= 10:
		return "IMMEDIATE"
	if seconds <= 30:
		return "SHORT"
	if seconds <= 60:
		return "MEDIUM"
	return "LONG"
