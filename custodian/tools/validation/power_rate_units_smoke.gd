extends SceneTree

const POWER_SCRIPT := preload("res://game/systems/core/systems/power.gd")
const SOURCE_SCRIPT := preload("res://tools/validation/fixtures/power_rate_test_source.gd")
const SECTOR_SCRIPT := preload("res://tools/validation/fixtures/power_rate_test_sector.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source := SOURCE_SCRIPT.new()
	source.add_to_group("power_node")
	root.add_child(source)
	var load_sector := SECTOR_SCRIPT.new()
	root.add_child(load_sector)
	for delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
		var power := POWER_SCRIPT.new()
		power.total_power = 1000.0
		power.max_power = 10000.0
		root.add_child(power)
		power.set_process(false)
		power.sectors = [load_sector]
		var steps := int(round(1.0 / delta))
		for _step in range(steps):
			power.call("_generate_power", delta)
			power.call("_drain_power", delta)
		var status: Dictionary = power.get_power_status()
		_require(is_equal_approx(float(status.get("generated_per_second", 0.0)), 120.0), "Generation rate changed with delta %.6f." % delta)
		_require(is_equal_approx(float(status.get("consumed_per_second", 0.0)), 36.0), "Consumption rate changed with delta %.6f." % delta)
		_require(is_equal_approx(float(status.get("net_per_second", 0.0)), 84.0), "Net rate changed with delta %.6f." % delta)
		_require(is_equal_approx(power.total_power, 1084.0), "One simulated second did not apply the expected +84 energy at delta %.6f." % delta)
		_require(not status.has("generated") and not status.has("consumed") and not status.has("net"), "Ambiguous legacy power-unit keys remain exposed.")
		power.queue_free()
		await process_frame
	source.queue_free()
	load_sector.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[PowerRateUnitsSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[PowerRateUnitsSmoke] PASS")
	quit(0)
