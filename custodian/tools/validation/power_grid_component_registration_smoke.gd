extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const FIELD_FABRICATOR_SCENE := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")
const SOURCE_SCRIPT := preload("res://tools/validation/fixtures/power_rate_test_source.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry := root.get_node("InfrastructureRegistry")
	var observatory := root.get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")
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
	var tier_events_before := _count_observatory_events(
		observatory,
		&"infrastructure_power_tier_changed"
	)
	var power_consumer := fabricator.get_node_or_null("PowerConsumer")
	_require(
		power_consumer != null,
		"Field Fabricator PowerConsumer node is missing."
	)
	if power_consumer != null:
		var stable_allocation := float(
			power_consumer.get("allocated_power")
		)
		power_consumer.call(
			"apply_power_allocation",
			stable_allocation
		)
		power_consumer.call(
			"apply_power_allocation",
			stable_allocation
		)
	var tier_events_after := _count_observatory_events(
		observatory,
		&"infrastructure_power_tier_changed"
	)
	_require(
		tier_events_after == tier_events_before,
		"Stable power allocation emitted a duplicate tier-change event."
	)
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[PowerGridComponentRegistrationSmoke] %s" % message)


func _count_observatory_events(
	observatory: Node,
	kind: StringName
) -> int:
	if observatory == null \
	or not observatory.has_method("get_recent_events"):
		return 0
	var events := observatory.call(
		"get_recent_events",
		1000,
		kind
	) as Array
	return events.size()


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[PowerGridComponentRegistrationSmoke] PASS")
	quit(0)
