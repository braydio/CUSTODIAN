extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []; var packed := load("res://game/world/sundered_keep/sundered_keep_map.tscn") as PackedScene
	if packed == null: errors.append("Keep production scene failed to load")
	else:
		var keep := packed.instantiate()
		var state := {"has_sundered_gate_key": true, "main_gate_open": true, "return_mooring_created": true, "great_hall_door_open": true, "sidearm_locker_opened": true, "routekeeper_trace_recovered": true, "siege_started": true, "siege_wave_index": 2, "siege_pressure_tick": 7, "siege_state": "active", "siege_game_over_triggered": false}
		keep.call("restore_route_state", state)
		var captured: Dictionary = keep.call("capture_route_state")
		for key in state.keys():
			if captured.get(key) != state[key]: errors.append("state field did not round-trip: %s" % key)
		keep.free()
	if errors.is_empty(): print("[SunderedKeepRouteStateSmoke] PASS"); quit(0); return
	for error in errors: push_error("[SunderedKeepRouteStateSmoke] %s" % error)
	quit(1)
