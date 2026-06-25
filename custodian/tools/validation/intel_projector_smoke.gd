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

	print("INTEL PROJECTOR SMOKE: PASS")
	quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected <%s>, got <%s>" % [message, str(expected), str(actual)])
		quit(1)
