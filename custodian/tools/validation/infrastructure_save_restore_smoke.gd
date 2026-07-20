extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const BANK_SCENE := preload("res://game/infrastructure/structures/capacitor_bank_mk1.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry := root.get_node("InfrastructureRegistry")
	registry.clear_runtime_state()
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var power := POWER_SCRIPT.new()
	power.name = "Power"
	power.total_power = 420.0
	power.max_power = 500.0
	game_root.add_child(power)
	power.set_process(false)
	var bank := BANK_SCENE.instantiate()
	bank.global_position = Vector2(320, 480)
	world.add_child(bank)
	bank.call("begin_construction")
	bank.call("complete_construction")
	bank.call("take_damage", 60.0)
	power.call("request_grid_refresh")
	var saved: Dictionary = registry.capture_state()
	var saved_id := str(bank.get("infrastructure_instance_id"))
	var result: Dictionary = registry.restore_state(saved, world, true)
	await process_frame
	_require(int(result.get("restored", 0)) == 1, "Registry did not restore exactly one persistent structure.")
	_require((result.get("errors", PackedStringArray()) as PackedStringArray).is_empty(), "Restore reported errors: %s" % result.get("errors"))
	var restored: Node = registry.get_structure(StringName(saved_id))
	_require(restored != null, "Stable infrastructure instance ID was not restored.")
	if restored != null:
		_require(restored.global_position.is_equal_approx(Vector2(320, 480)), "Restored transform does not match saved transform.")
		_require(is_equal_approx(float(restored.get("current_integrity")), 180.0), "Restored integrity does not match saved integrity.")
	_require(is_equal_approx(power.total_power, 420.0), "Grid reserve did not round-trip through registry persistence.")
	_require(registry.get_structure_snapshot().size() == 1, "Restore duplicated infrastructure instances.")
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[InfrastructureSaveRestoreSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[InfrastructureSaveRestoreSmoke] PASS")
	quit(0)
