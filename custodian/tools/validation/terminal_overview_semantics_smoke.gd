extends SceneTree

const OverviewViewModelScript := preload("res://game/ui/terminal/terminal_overview_view_model.gd")

var _failed := false


func _init() -> void:
	var view_model = OverviewViewModelScript.new()
	var snapshot := {
		"operator_location": "ZETA KEEP",
		"threat_raw": 5.0,
		"power_status": {"net_per_second": 2.0},
		"sectors": [
			{
				"name": "ALPHA ARCHIVE",
				"status": "operational",
				"hp_pct": 100,
				"power_tier": "NORMAL",
				"power_standard": 10.0,
				"power_margin": 5.0,
				"power_priority": 35,
			},
			{
				"name": "ZETA KEEP",
				"status": "critical",
				"hp_pct": 24,
				"power_tier": "OFFLINE",
				"power_standard": 20.0,
				"power_margin": -20.0,
				"power_priority": 100,
				"hostile_objective_active": true,
				"unresolved_critical_incident": true,
				"operator_present": true,
			},
		],
	}
	var result: Dictionary = view_model.build(snapshot)
	var priority_sectors: Array = result.get("priority_sectors", [])
	_require(priority_sectors.size() == 2, "Overview should rank every sector candidate.")
	_require(not priority_sectors.is_empty() and String(priority_sectors[0].get("name", "")) == "ZETA KEEP", "An alphabetically late critical sector should rank first.")
	_require(not priority_sectors.is_empty() and int(priority_sectors[0].get("diagnostic_score", 0)) == 340, "Overview score should reconcile all documented impact weights.")
	_require(int(result.get("systems_offline_count", 0)) == 1, "Overview should count authoritative offline systems.")
	_require(int(result.get("cold_start_systems_count", 0)) == 1, "Overview should count powered-system cold starts.")
	_require(String(result.get("operator_location", "")) == "ZETA KEEP", "Overview should preserve authoritative Operator location.")

	var incidents: Array = result.get("active_incidents", [])
	_require(not incidents.is_empty() and String(incidents[0].get("id", "")) == "sector_offline_zeta_keep", "Overview incidents should use stable semantic IDs.")
	var recommendations: Array = result.get("recommendations", [])
	_require(not recommendations.is_empty() and String(recommendations[0].get("id", "")) == "restore_sector_zeta_keep", "Overview recommendations should target the highest-impact sector with a stable ID.")

	var repeated: Dictionary = view_model.build(snapshot)
	_require(result == repeated, "Overview ranking should be deterministic for an unchanged snapshot.")

	if _failed:
		push_error("terminal_overview_semantics_smoke failed")
		quit(1)
		return
	print("[TerminalOverviewSemanticsSmoke] PASS")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
