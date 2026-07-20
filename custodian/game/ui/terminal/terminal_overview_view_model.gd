extends RefCounted
class_name TerminalOverviewViewModel


func build(snapshot: Dictionary) -> Dictionary:
	var sectors: Array = snapshot.get("sectors", []) if snapshot.get("sectors", []) is Array else []
	var ranked: Array[Dictionary] = []
	var incidents: Array[Dictionary] = []
	var offline_count := 0
	var cold_start_count := 0
	for sector_variant in sectors:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var scored := _score_sector(sector)
		ranked.append(scored)
		if _is_offline(sector):
			offline_count += 1
		if _is_cold_start(sector):
			cold_start_count += 1
		var incident := _incident_for_sector(scored)
		if not incident.is_empty():
			incidents.append(incident)

	ranked.sort_custom(_rank_before)
	incidents.sort_custom(_incident_before)
	var recommendations := _build_recommendations(ranked, snapshot)
	return {
		"priority_sectors": ranked,
		"active_incidents": incidents,
		"recommendations": recommendations,
		"operator_location": String(snapshot.get("operator_location", "UNKNOWN")),
		"systems_offline_count": offline_count,
		"cold_start_systems_count": cold_start_count,
	}


func _score_sector(sector: Dictionary) -> Dictionary:
	var score := 0
	var reasons: Array[String] = []
	if _is_offline(sector) or _is_compromised(sector):
		score += 100
		reasons.append("compromised_or_offline")
	if bool(sector.get("hostile_objective_active", false)):
		score += 80
		reasons.append("active_hostile_objective")
	if int(sector.get("hp_pct", 100)) <= 30:
		score += 60
		reasons.append("critical_integrity")
	if float(sector.get("power_margin", 0.0)) < 0.0:
		score += 40
		reasons.append("negative_power_margin")
	if bool(sector.get("unresolved_critical_incident", false)):
		score += 30
		reasons.append("unresolved_critical_incident")
	if bool(sector.get("operator_present", false)):
		score += 20
		reasons.append("operator_present")
	if bool(sector.get("strategic_priority", false)) or int(sector.get("power_priority", 0)) >= 85:
		score += 10
		reasons.append("strategic_priority")
	var result := sector.duplicate(true)
	result["diagnostic_score"] = score
	result["diagnostic_reasons"] = reasons
	return result


func _build_recommendations(ranked: Array[Dictionary], snapshot: Dictionary) -> Array[Dictionary]:
	var recommendations: Array[Dictionary] = []
	var power_status: Dictionary = snapshot.get("power_status", {}) if snapshot.get("power_status", {}) is Dictionary else {}
	if float(power_status.get("net", 0.0)) < 0.0:
		recommendations.append({
			"id": &"correct_power_deficit",
			"action": &"open_power",
			"label": "OPEN POWER // CORRECT DEFICIT",
			"score": 1000,
		})
	if not ranked.is_empty() and int(ranked[0].get("diagnostic_score", 0)) > 0:
		var sector: Dictionary = ranked[0]
		var raw_name := String(sector.get("name", sector.get("id", "SECTOR")))
		recommendations.append({
			"id": StringName("restore_sector_%s" % _slug(raw_name)),
			"action": &"open_sectors",
			"sector_id": raw_name,
			"label": "OPEN SECTORS // RESTORE %s" % raw_name.to_upper(),
			"score": 900 + int(sector.get("diagnostic_score", 0)),
		})
	var threat := float(snapshot.get("threat_raw", 0.0))
	if threat >= 4.0:
		recommendations.append({
			"id": &"review_defense_coverage",
			"action": &"open_defense",
			"label": "OPEN DEFENSE // REVIEW COVERAGE",
			"score": 800 + int(round(threat * 10.0)),
		})
	if recommendations.is_empty():
		recommendations.append({
			"id": &"verify_sector_priority",
			"action": &"open_sectors",
			"label": "OPEN SECTORS // VERIFY PRIORITY",
			"score": 0,
		})
	recommendations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("score", 0)) != int(b.get("score", 0)):
			return int(a.get("score", 0)) > int(b.get("score", 0))
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return recommendations


func _incident_for_sector(sector: Dictionary) -> Dictionary:
	var raw_name := String(sector.get("name", sector.get("id", "SECTOR")))
	if _is_offline(sector):
		return {"id": StringName("sector_offline_%s" % _slug(raw_name)), "severity": &"critical", "label": "%s OFFLINE" % raw_name.to_upper(), "score": 300}
	if _is_compromised(sector) or int(sector.get("hp_pct", 100)) <= 30:
		return {"id": StringName("sector_compromised_%s" % _slug(raw_name)), "severity": &"critical", "label": "%s COMPROMISED" % raw_name.to_upper(), "score": 250}
	if float(sector.get("power_margin", 0.0)) < 0.0:
		return {"id": StringName("sector_power_deficit_%s" % _slug(raw_name)), "severity": &"warning", "label": "%s POWER DEFICIT" % raw_name.to_upper(), "score": 150}
	if bool(sector.get("hostile_objective_active", false)):
		return {"id": StringName("hostile_objective_%s" % _slug(raw_name)), "severity": &"alert", "label": "%s HOSTILE OBJECTIVE" % raw_name.to_upper(), "score": 125}
	return {}


func _is_offline(sector: Dictionary) -> bool:
	var state := "%s %s" % [String(sector.get("status", "")), String(sector.get("power_tier", ""))]
	state = state.to_upper()
	return state.contains("OFFLINE") or state.contains("DESTROYED")


func _is_compromised(sector: Dictionary) -> bool:
	var state := String(sector.get("status", "")).to_upper()
	return state.contains("BREACH") or state.contains("DAMAGED") or state.contains("CRITICAL")


func _is_cold_start(sector: Dictionary) -> bool:
	var tier := String(sector.get("power_tier", "")).to_upper()
	return tier == "OFFLINE" and float(sector.get("power_standard", 0.0)) > 0.0


func _rank_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("diagnostic_score", 0)) != int(b.get("diagnostic_score", 0)):
		return int(a.get("diagnostic_score", 0)) > int(b.get("diagnostic_score", 0))
	return String(a.get("name", a.get("id", ""))) < String(b.get("name", b.get("id", "")))


func _incident_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("score", 0)) != int(b.get("score", 0)):
		return int(a.get("score", 0)) > int(b.get("score", 0))
	return String(a.get("id", "")) < String(b.get("id", ""))


func _slug(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
