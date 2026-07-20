extends SceneTree

const FidelityPolicyScript := preload("res://game/ui/terminal/terminal_fidelity_policy.gd")
const StatusFormatterScript := preload("res://game/ui/terminal/terminal_status_formatter.gd")
const CommandTerminalScript := preload("res://game/actors/terminal/command_terminal.gd")

var _failed := false


func _init() -> void:
	var policy = FidelityPolicyScript.new()
	var formatter = StatusFormatterScript.new()
	var snapshot := _base_snapshot()
	var command_terminal = CommandTerminalScript.new()
	_require(command_terminal.grants_command_mode(), "The original physical terminal should grant command authority.")
	command_terminal.revoke_command_authority()
	_require(not command_terminal.grants_command_mode(), "A redeployed terminal should remain field-authority only.")
	command_terminal.free()

	_require(policy.resolve(&"command", [], {}) == &"full", "Command authority with a healthy local link should expose full fidelity.")
	_require(policy.resolve(&"field", [], {}) == &"degraded", "Field mode should degrade exact command information.")
	_require(policy.resolve(&"command", [_comms_sector("critical", "DEGRADED")], {}) == &"fragmented", "Critical communications should fragment command information.")
	_require(policy.resolve(&"command", [_comms_sector("operational", "OFFLINE")], {}) == &"lost", "Offline communications should remove network truth.")
	_require(policy.resolve(&"command", [_comms_sector("critical", "DEGRADED")], {"fidelity": "DEGRADED"}) == &"degraded", "ARRN reconstruction should be allowed to improve a damaged command return.")
	_require(policy.resolve(&"field", [], {"fidelity": "FULL"}) == &"degraded", "ARRN reconstruction must not erase command-versus-field asymmetry.")

	var full_text := formatter.format(snapshot)
	_require(full_text.contains("MODE=COMMAND | FIDELITY=FULL | RATE=1X"), "Full STATUS should identify actual mode, fidelity, and rate.")
	_require(full_text.contains("OPERATOR=ARCHIVE"), "Full STATUS should include exact Operator location.")
	_require(full_text.contains("HOSTILES=7"), "Full STATUS should include exact hostile count.")
	_require(full_text.contains("ARCHIVE=UNAVAILABLE"), "STATUS must not fabricate a nominal archive state.")
	_require(full_text.begins_with("STATUS // T+00:02:03 // TICK 7380"), "STATUS should begin with deterministic simulation time and tick.")

	var degraded := snapshot.duplicate(true)
	degraded["terminal_mode"] = &"field"
	degraded["fidelity"] = &"degraded"
	var degraded_text := formatter.format(degraded)
	_require(degraded_text.contains("MODE=FIELD | FIDELITY=DEGRADED"), "Degraded STATUS should expose field mode.")
	_require(degraded_text.contains("HOSTILES=MANY"), "Degraded STATUS should generalize hostile counts.")
	_require(not degraded_text.contains("HOSTILES=7"), "Degraded STATUS must omit exact hostile counts.")
	_require(degraded_text.contains("LOCATION=WITHHELD"), "Field STATUS should withhold exact Operator location.")

	var fragmented := snapshot.duplicate(true)
	fragmented["fidelity"] = &"fragmented"
	var fragmented_text := formatter.format(fragmented)
	_require(fragmented_text.contains("THREAT ACTIVITY=WIDESPREAD"), "Fragmented STATUS should replace exact counts with activity.")
	_require(not fragmented_text.contains("HOSTILES=7") and not fragmented_text.contains("OPERATOR=ARCHIVE"), "Fragmented STATUS must omit exact counts and location.")

	var lost := snapshot.duplicate(true)
	lost["fidelity"] = &"lost"
	var lost_text := formatter.format(lost)
	_require(lost_text.contains("NETWORK TRUTH=UNAVAILABLE"), "Lost STATUS should report unavailable network truth.")
	_require(not lost_text.contains("HOSTILES") and not lost_text.contains("ARCHIVE="), "Lost STATUS must omit tactical and archive claims.")

	var snapshot_source := FileAccess.get_file_as_string("res://game/ui/terminal/terminal_snapshot.gd")
	_require(not snapshot_source.contains("get_time_string_from_system"), "Terminal snapshot must not use the operating-system clock.")
	var terminal_ui_source := FileAccess.get_file_as_string("res://game/ui/hud/ui.gd")
	_require(not terminal_ui_source.contains("get_time_string_from_system"), "Terminal transcript and attention feed must use simulation time rather than a second clock domain.")

	if _failed:
		push_error("terminal_status_fidelity_smoke failed")
		quit(1)
		return
	print("[TerminalStatusFidelitySmoke] PASS")
	quit(0)


func _base_snapshot() -> Dictionary:
	return {
		"simulation_tick": 7380,
		"simulation_seconds": 123.0,
		"simulation_rate": 1.0,
		"terminal_mode": &"command",
		"fidelity": &"full",
		"archive_state": &"unavailable",
		"operator_location": &"ARCHIVE",
		"command_center_occupied": true,
		"contract_phase": "free_roam_prep",
		"threat_raw": 8.0,
		"materials": 14,
		"defense_rating": 72.5,
		"systems_compromised_count": 1,
		"systems_offline_count": 1,
		"enemies": {"total": 7},
		"sectors": [{"name": "ARCHIVE"}, {"name": "POWER"}],
	}


func _comms_sector(status: String, power_tier: String) -> Dictionary:
	return {"name": "COMMUNICATIONS", "sector_type": "COMMS", "status": status, "power_tier": power_tier}


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
