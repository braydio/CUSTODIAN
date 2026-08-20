extends SceneTree

const LOWER_QUARTER := preload("res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn")
const WEST_GATE := preload("res://game/world/levels/authored/ash_bell/west_gate_works/west_gate_works.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := LOWER_QUARTER.instantiate() as AshBellLowerQuarter
	root.add_child(level)
	await process_frame
	assert(level.AUTHORING_CELL_SIZE_WORLD == 32.0)
	assert(level.MAP_SIZE_CELLS == Vector2i(128, 96))
	assert(level.has_spawn(&"Spawn_FromWorld"))
	var spawn := level.get_spawn_position(&"Spawn_FromWorld")
	var facade := level.get_node("PropsRoot/StationIXFacade") as Marker2D
	var north_cells := (spawn.y - facade.global_position.y) / 32.0
	assert(north_cells >= 14.0 and north_cells <= 17.0)
	var grid := level.blockout_grid as AuthoredBlockoutGrid2D
	var collapse := level.get_node("DynamicGates/DirectPersonnelCollapse") as StaticBody2D
	assert(collapse.visible)
	assert(not (collapse.get_node("CollisionShape2D") as CollisionShape2D).disabled)
	assert(_can_reach(grid, Vector2i(64, 87), Vector2i(64, 91)))
	var evac := level.get_node("POIRoot/EvacAnnunciator") as CivicRelay2D
	var pressure := level.get_node("POIRoot/GatePressureRelay") as CivicRelay2D
	var station := level.get_node("POIRoot/StationIXTransitInterlock") as CivicRelay2D
	assert(evac != null and pressure != null and station != null)
	assert(not level.west_gate_exit.is_local_gate_open())
	assert(not level.station_exit.is_local_gate_open())
	pressure.set_repaired(true)
	assert(level.west_gate_exit.is_local_gate_open())
	station.set_repaired(true)
	assert(level.station_exit.is_local_gate_open())
	assert(not level.station_gate.visible)
	assert((level.station_gate.get_node("CollisionShape2D") as CollisionShape2D).disabled)
	evac.set_repaired(true)
	var captured := level.capture_route_state()
	assert(captured.values().all(func(value: Variant) -> bool: return bool(value)))
	var restored := LOWER_QUARTER.instantiate() as AshBellLowerQuarter
	root.add_child(restored)
	await process_frame
	assert(restored.restore_route_state(captured))
	assert(restored.capture_route_state() == captured)
	assert(restored.blockout_grid.get_visual_regions().any(func(region: Dictionary) -> bool: return str(region.get("name")) == "wrong_street_ash_bell"))
	var answers := restored.debug_get_answers_positions()
	assert(answers.size() == 9)
	for index in 8:
		assert(not bool(answers[index].get("missing", true)))
	assert(bool(answers[8].get("missing", false)))
	var west_gate := WEST_GATE.instantiate() as AshBellWestGateWorks
	root.add_child(west_gate)
	await process_frame
	var motor := west_gate.get_node("POIRoot/GateMotorRelay") as CivicRelay2D
	motor.set_repaired(true)
	await create_timer(2.7).timeout
	assert(west_gate.debug_is_closure_complete())
	var west_state := west_gate.capture_route_state()
	var west_restored := WEST_GATE.instantiate() as AshBellWestGateWorks
	root.add_child(west_restored)
	await process_frame
	assert(west_restored.restore_route_state(west_state))
	assert(west_restored.capture_route_state() == west_state)
	assert(
		west_restored.debug_get_closure_slab_position().is_equal_approx(west_restored.debug_get_closed_slab_position()),
		"restored=%s expected=%s" % [west_restored.debug_get_closure_slab_position(), west_restored.debug_get_closed_slab_position()]
	)
	level.free()
	restored.free()
	west_gate.free()
	west_restored.free()
	await process_frame
	print("ash_bell_lower_quarter_layout_smoke: PASS relays=3 answers=9")
	quit(0)


func _can_reach(grid: AuthoredBlockoutGrid2D, start: Vector2i, target: Vector2i) -> bool:
	var pending: Array[Vector2i] = [start]
	var seen: Dictionary = {}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if cell == target:
			return true
		if seen.has(cell) or not grid.is_walkable_cell(cell):
			continue
		seen[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			pending.append(cell + direction)
	return false
