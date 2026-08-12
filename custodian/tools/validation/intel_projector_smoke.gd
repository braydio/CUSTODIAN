extends SceneTree

const IntelProjectorScript := preload("res://game/systems/intel/intel_projector.gd")


func _init() -> void:
	var truth := {
		"id": "storage",
		"name": "STORAGE",
		"integrity": 42,
		"power": "LOW",
		"hostiles": 3,
		"activity": "CONTAINER BREACH",
		"objective": "STEALING",
		"eta": 18,
	}

	var full: Dictionary = IntelProjectorScript.project_sector(truth, IntelProjectorScript.Fidelity.FULL)
	_assert_eq(full["hostiles"], "3", "full fidelity exposes exact hostile count")
	_assert_eq(full["integrity"], "42%", "full fidelity exposes exact integrity")
	_assert_eq(full["objective"], "STEALING", "full fidelity exposes exact objective")

	var degraded: Dictionary = IntelProjectorScript.project_sector(truth, IntelProjectorScript.Fidelity.DEGRADED)
	_assert_eq(degraded["hostiles"], "FEW", "degraded fidelity buckets hostile count")
	_assert_eq(degraded["integrity"], "FAILING", "degraded fidelity buckets integrity")
	_assert_eq(degraded["objective"], "LOOTING", "degraded fidelity softens objective")

	var fragmented: Dictionary = IntelProjectorScript.project_sector(truth, IntelProjectorScript.Fidelity.FRAGMENTED)
	_assert_eq(fragmented["hostiles"], "UNKNOWN", "fragmented fidelity hides hostile count")
	_assert_eq(fragmented["activity"], "ACTIVITY DETECTED", "fragmented fidelity keeps only signal-level activity")

	var lost: Dictionary = IntelProjectorScript.project_sector(truth, IntelProjectorScript.Fidelity.LOST)
	_assert_eq(lost["activity"], "SIGNAL LOST", "lost fidelity hides operational detail")

	var contact_truth := {"contacts": [{"contact_id":"C-001", "world_position":Vector2(159, 257), "velocity":Vector2.RIGHT, "sector":"STORAGE", "class_label":"GRUNT", "health_pct":0.5, "activity":&"STEALING", "last_seen_tick":100}]}
	var full_contacts: Dictionary = IntelProjectorScript.project_contacts(contact_truth, IntelProjectorScript.Fidelity.FULL, &"command", 106)
	_assert_true((full_contacts["contacts"][0] as Dictionary).has("world_position"), "full command contact exposes exact position")
	var degraded_contacts: Dictionary = IntelProjectorScript.project_contacts(contact_truth, IntelProjectorScript.Fidelity.DEGRADED, &"command", 106)
	_assert_true(not (degraded_contacts["contacts"][0] as Dictionary).has("world_position"), "degraded contact physically omits exact position")
	_assert_true((degraded_contacts["contacts"][0] as Dictionary).has("coarse_map_position"), "degraded contact carries a snapped map marker")
	var fragmented_contacts: Dictionary = IntelProjectorScript.project_contacts(contact_truth, IntelProjectorScript.Fidelity.FRAGMENTED, &"command", 106)
	_assert_true((fragmented_contacts["contacts"] as Array).is_empty() and not (fragmented_contacts["sector_activity"][0] as Dictionary).has("contact_id"), "fragmented projection aggregates without identity")
	var lost_contacts: Dictionary = IntelProjectorScript.project_contacts(contact_truth, IntelProjectorScript.Fidelity.LOST, &"command", 106)
	_assert_true((lost_contacts["contacts"] as Array).is_empty() and not lost_contacts.has("current_count"), "lost projection omits hostile count and location")

	print("INTEL PROJECTOR SMOKE: PASS")
	quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected <%s>, got <%s>" % [message, str(expected), str(actual)])
		quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
