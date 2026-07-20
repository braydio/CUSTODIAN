extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const FIELD_FABRICATOR_SCENE := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")
const SOURCE_SCRIPT := preload("res://tools/validation/fixtures/power_rate_test_source.gd")

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
	power.total_power = 100.0
	power.max_power = 500.0
	game_root.add_child(power)
	power.set_process(false)
	var source := SOURCE_SCRIPT.new()
	source.output_rate = 120.0
	source.add_to_group("power_node")
	world.add_child(source)
	var fabricator := FIELD_FABRICATOR_SCENE.instantiate()
	world.add_child(fabricator)
	power.call("_process", 1.0 / 60.0)
	var status := power.get_power_status()
	_require(is_equal_approx(float(status.get("requested_per_second", 0.0)), 25.0), "Field Fabricator did not register 25 P/s standard demand.")
	_require(is_equal_approx(float(status.get("allocated_per_second", 0.0)), 25.0), "Field Fabricator was not allocated standard power.")
	_require(is_equal_approx(registry.get_service_output(&"FABRICATION"), 1.0), "Powered Fabricator did not expose full FABRICATION service.")
	var consumers: Array = status.get("infrastructure_consumers", [])
	_require(consumers.size() == 1, "Grid should expose exactly one registered infrastructure consumer.")
	_require(str((consumers[0] as Dictionary).get("id", "")) == "field_fabricator_primary", "Consumer snapshot lost stable identity.")
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[PowerGridComponentRegistrationSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[PowerGridComponentRegistrationSmoke] PASS")
	quit(0)
