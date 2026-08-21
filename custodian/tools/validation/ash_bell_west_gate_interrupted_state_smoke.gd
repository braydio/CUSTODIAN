extends SceneTree

const LEVEL := preload("res://game/world/levels/authored/ash_bell/west_gate_works/west_gate_works.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := LEVEL.instantiate() as AshBellWestGateWorks
	root.add_child(first)
	await process_frame
	(first.get_node("POIRoot/GateMotorRelay") as CivicRelay2D).set_repaired(true)
	await create_timer(1.2).timeout
	var state := first.capture_route_state()
	assert(int(state.closure_phase) == AshBellWestGateWorks.ClosurePhase.CLOSING)
	assert(float(state.closure_progress) > 0.35 and float(state.closure_progress) < 0.7)
	first.free()
	await process_frame
	var restored := LEVEL.instantiate() as AshBellWestGateWorks
	root.add_child(restored)
	await process_frame
	assert(restored.restore_route_state(state))
	assert(restored.debug_get_closure_phase() == AshBellWestGateWorks.ClosurePhase.CLOSING)
	await create_timer(1.7).timeout
	assert(restored.debug_is_closure_complete())
	assert(restored.debug_get_closure_progress() == 1.0)
	assert(restored.debug_get_closure_slab_position().is_equal_approx(restored.debug_get_closed_slab_position()))
	print("ash_bell_west_gate_interrupted_state_smoke: PASS progress=%.3f" % float(state.closure_progress))
	quit(0)
