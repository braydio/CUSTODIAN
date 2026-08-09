extends SceneTree

const RING_SCENE := preload("res://game/actors/effects/target_ring.tscn")

var _failures: Array[String] = []


func _init() -> void:
	var ring := RING_SCENE.instantiate()
	root.add_child(ring)
	_expect(ring.has_method("set_melee_target_state"), "ring lacks progressive melee state API")
	ring.call("set_melee_target_state", {"proximity": 0.0, "alignment": 0.2, "reliable_contact": false, "newly_acquired": true})
	var far: Dictionary = ring.call("debug_get_melee_target_presentation")
	_expect(is_equal_approx(float(far.target_proximity), 0.0), "far state proximity is wrong")
	_expect(float(far.acquire_pulse) > 0.0, "acquisition did not pulse")
	ring.call("set_melee_target_state", {"proximity": 0.5, "alignment": 0.8, "reliable_contact": false})
	var approach: Dictionary = ring.call("debug_get_melee_target_presentation")
	_expect(is_equal_approx(float(approach.target_proximity), 0.5), "approach state is wrong")
	ring.call("set_melee_target_state", {"proximity": 1.0, "alignment": 1.0, "reliable_contact": true})
	var reliable: Dictionary = ring.call("debug_get_melee_target_presentation")
	_expect(bool(reliable.reliable_contact), "reliable state did not become green-authoritative")
	var pulse := float(reliable.reliable_pulse)
	ring.call("set_melee_target_state", {"proximity": 1.0, "alignment": 1.0, "reliable_contact": true})
	reliable = ring.call("debug_get_melee_target_presentation")
	_expect(is_equal_approx(float(reliable.reliable_pulse), pulse), "reliable pulse retriggered continuously")
	ring.call("set_in_strike_zone", false)
	_expect(not bool((ring.call("debug_get_melee_target_presentation") as Dictionary).reliable_contact), "compatibility strike-zone wrapper failed")
	if _failures.is_empty():
		print("melee_target_ring_readability_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
