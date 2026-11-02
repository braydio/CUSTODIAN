extends SceneTree

const DEBUG_BUS_SCRIPT := preload("res://content/tiles/debug/debug_bus.gd")
const DEBUG_COLLECTOR_SCRIPT := preload("res://content/tiles/debug/debug_collector.gd")
const COMBAT_DRONE_SCENE := preload("res://game/actors/allies/combat_drone.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var debug_bus := DEBUG_BUS_SCRIPT.new()
	debug_bus.name = "DebugBus"
	debug_bus.enabled = true
	root.add_child(debug_bus)

	var collector := DEBUG_COLLECTOR_SCRIPT.new()
	root.add_child(collector)

	var drone := COMBAT_DRONE_SCENE.instantiate() as CombatDrone
	assert(drone != null, "Expected CombatDrone scene to instantiate.")
	root.add_child(drone)
	drone.global_position = Vector2(48.0, 64.0)
	await process_frame

	collector.call("_update_overlays", debug_bus)
	var ranges: Array = debug_bus.overlays.get("ranges", [])
	assert(ranges.size() == 1, "Expected one debug range overlay for CombatDrone, got %d." % ranges.size())
	var range_entry: Dictionary = ranges[0]
	assert(float(range_entry.get("radius", 0.0)) == drone.profile.drone_weapon_range, "CombatDrone debug range should use drone weapon range.")

	print("[DebugCollectorCombatDroneSmoke] ok range=%s" % str(range_entry))
	quit(0)
