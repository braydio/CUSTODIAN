extends RefCounted
class_name TerminalStatusFormatter

const TerminalFidelityPolicyScript := preload("res://game/ui/terminal/terminal_fidelity_policy.gd")

var _policy: TerminalFidelityPolicy = TerminalFidelityPolicyScript.new()


func format(snapshot: Dictionary) -> String:
	return "\n".join(format_lines(snapshot))


func format_lines(snapshot: Dictionary) -> Array[String]:
	var fidelity := _policy.normalize(snapshot.get("fidelity", &"lost"))
	if fidelity.is_empty():
		fidelity = &"lost"
	var terminal_mode := StringName(String(snapshot.get("terminal_mode", "field")).to_lower())
	var lines: Array[String] = [
		"STATUS // T+%s // TICK %d" % [
			format_duration(float(snapshot.get("simulation_seconds", 0.0))),
			int(snapshot.get("simulation_tick", 0)),
		],
		"MODE=%s | FIDELITY=%s | RATE=%s" % [
			String(terminal_mode).to_upper(),
			String(fidelity).to_upper(),
			format_rate(float(snapshot.get("simulation_rate", 1.0))),
		],
	]

	match fidelity:
		TerminalFidelityPolicyScript.FULL:
			_append_full(lines, snapshot)
		TerminalFidelityPolicyScript.DEGRADED:
			_append_degraded(lines, snapshot)
		TerminalFidelityPolicyScript.FRAGMENTED:
			_append_fragmented(lines, snapshot)
		_:
			lines.append("NETWORK TRUTH=UNAVAILABLE")
			lines.append("TACTICAL DETAIL OMITTED // RESTORE COMMUNICATIONS")
	return lines


func structured_fields(snapshot: Dictionary) -> Array[Dictionary]:
	var fidelity := _policy.normalize(snapshot.get("fidelity", &"lost"))
	var fields: Array[Dictionary] = [
		{"label": "SIM TIME", "value": "T+%s" % format_duration(float(snapshot.get("simulation_seconds", 0.0)))},
		{"label": "SIM TICK", "value": str(int(snapshot.get("simulation_tick", 0)))},
		{"label": "MODE", "value": String(snapshot.get("terminal_mode", &"field")).to_upper()},
		{"label": "FIDELITY", "value": String(fidelity).to_upper()},
	]
	if fidelity == TerminalFidelityPolicyScript.FULL:
		fields.append({"label": "OPERATOR", "value": _operator_location(snapshot)})
		fields.append({"label": "ARCHIVE", "value": _archive_state(snapshot)})
	elif fidelity == TerminalFidelityPolicyScript.DEGRADED:
		fields.append({"label": "OPERATOR", "value": "FIELD LINK"})
		fields.append({"label": "ARCHIVE", "value": _generalize_archive(snapshot)})
	else:
		fields.append({"label": "OPERATOR", "value": "UNCONFIRMED"})
	return fields


func format_duration(seconds: float) -> String:
	var whole_seconds := maxi(0, int(floor(seconds)))
	var hours := whole_seconds / 3600
	var minutes := (whole_seconds % 3600) / 60
	var remainder := whole_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, remainder]


func format_rate(rate: float) -> String:
	if is_equal_approx(rate, round(rate)):
		return "%dX" % int(round(rate))
	return "%.1fX" % rate


func _append_full(lines: Array[String], snapshot: Dictionary) -> void:
	var sectors: Array = snapshot.get("sectors", []) if snapshot.get("sectors", []) is Array else []
	var enemies: Dictionary = snapshot.get("enemies", {}) if snapshot.get("enemies", {}) is Dictionary else {}
	lines.append("OPERATOR=%s | COMMAND_CENTER=%s" % [
		_operator_location(snapshot),
		"OCCUPIED" if bool(snapshot.get("command_center_occupied", false)) else "VACANT",
	])
	lines.append("PHASE=%s | THREAT=%s | HOSTILES=%d" % [
		String(snapshot.get("contract_phase", "unknown")).to_upper(),
		_threat_band(snapshot),
		int(enemies.get("total", 0)),
	])
	lines.append("SECTORS=%d | COMPROMISED=%d | OFFLINE=%d" % [
		sectors.size(),
		int(snapshot.get("systems_compromised_count", 0)),
		int(snapshot.get("systems_offline_count", 0)),
	])
	lines.append("ARCHIVE=%s | MATERIAL=%d | DEFENSE=%.1f" % [
		_archive_state(snapshot),
		int(snapshot.get("materials", 0)),
		float(snapshot.get("defense_rating", 0.0)),
	])


func _append_degraded(lines: Array[String], snapshot: Dictionary) -> void:
	var enemies: Dictionary = snapshot.get("enemies", {}) if snapshot.get("enemies", {}) is Dictionary else {}
	lines.append("OPERATOR=FIELD LINK | LOCATION=WITHHELD")
	lines.append("PHASE=%s | THREAT=%s | HOSTILES=%s" % [
		String(snapshot.get("contract_phase", "unknown")).to_upper(),
		_threat_band(snapshot),
		_bucket_count(int(enemies.get("total", 0))),
	])
	lines.append("SYSTEMS=%s | ARCHIVE=%s" % [
		_system_condition(snapshot),
		_generalize_archive(snapshot),
	])
	lines.append("EXACT POSITIONS AND POSTURE TARGETS OMITTED")


func _append_fragmented(lines: Array[String], snapshot: Dictionary) -> void:
	lines.append("OPERATOR=UNCONFIRMED | LOCATION=UNAVAILABLE")
	lines.append("THREAT ACTIVITY=%s" % _activity_band(snapshot))
	lines.append("SYSTEM STATE=INTERMITTENT RETURNS")
	lines.append("EXACT COUNTS, POSITIONS, AND ARCHIVE STATE OMITTED")


func _operator_location(snapshot: Dictionary) -> String:
	var location := String(snapshot.get("operator_location", "")).strip_edges()
	return location.to_upper() if not location.is_empty() else "UNKNOWN"


func _archive_state(snapshot: Dictionary) -> String:
	var state := String(snapshot.get("archive_state", "unavailable")).strip_edges()
	return state.to_upper() if not state.is_empty() else "UNAVAILABLE"


func _generalize_archive(snapshot: Dictionary) -> String:
	var state := _archive_state(snapshot)
	if state in ["NOMINAL", "AVAILABLE", "ONLINE"]:
		return "RESPONDING"
	if state in ["DEGRADED", "PARTIAL", "CONTESTED"]:
		return "UNSTABLE"
	return "UNCONFIRMED"


func _threat_band(snapshot: Dictionary) -> String:
	var threat := float(snapshot.get("threat_raw", 0.0))
	if threat >= 7.5:
		return "CRITICAL"
	if threat >= 4.0:
		return "ELEVATED"
	if threat > 0.0:
		return "GUARDED"
	return "STABLE"


func _activity_band(snapshot: Dictionary) -> String:
	var enemies: Dictionary = snapshot.get("enemies", {}) if snapshot.get("enemies", {}) is Dictionary else {}
	var total := int(enemies.get("total", 0))
	if total <= 0:
		return "NO CLEAR RETURN"
	if total <= 3:
		return "LOCALIZED"
	return "WIDESPREAD"


func _bucket_count(count: int) -> String:
	if count <= 0:
		return "NONE DETECTED"
	if count == 1:
		return "ONE"
	if count <= 3:
		return "FEW"
	if count <= 6:
		return "SEVERAL"
	return "MANY"


func _system_condition(snapshot: Dictionary) -> String:
	if int(snapshot.get("systems_offline_count", 0)) > 0:
		return "OFFLINE RETURNS"
	if int(snapshot.get("systems_compromised_count", 0)) > 0:
		return "DEGRADED RETURNS"
	return "STABLE RETURNS"
