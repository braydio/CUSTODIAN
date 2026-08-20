extends SceneTree

const STATION_IX := preload("res://game/world/levels/authored/ash_bell/station_ix/station_ix.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var station := STATION_IX.instantiate() as AshBellStationIX
	root.add_child(station)
	await process_frame
	var a := station.get_node("POIRoot/AssemblyA") as CivicRelay2D
	var b := station.get_node("POIRoot/AssemblyB") as CivicRelay2D
	var c := station.get_node("POIRoot/AssemblyC") as CivicRelay2D
	assert(a.is_actionable())
	assert(not b.is_actionable() and not c.is_actionable())
	a.set_repaired(true)
	assert(b.is_actionable() and not c.is_actionable())
	b.set_repaired(true)
	assert(c.is_actionable())
	c.set_repaired(true)
	assert(station.is_station_isolated())
	assert(station.debug_get_one_shot_completion_count() == 1)
	var captured := station.capture_route_state()
	var restored := STATION_IX.instantiate() as AshBellStationIX
	root.add_child(restored)
	await process_frame
	assert(restored.restore_route_state(captured))
	assert(restored.capture_route_state() == captured)
	assert(restored.debug_get_one_shot_completion_count() == 0)
	var final_status := restored.debug_get_final_status_content()
	assert("STATUS: UNARRIVAL" in final_status)
	assert("LATE RESPONSE:\nACCEPTED" in final_status)
	assert("REGIONAL COUPLING:\nTERMINATED" in final_status)
	station.free()
	restored.free()
	await process_frame
	print("ash_bell_station_ix_state_smoke: PASS assemblies=3 isolated=true")
	quit(0)
