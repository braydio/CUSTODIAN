extends SceneTree
## The fixed tick is the simulation spine; the render tick draws.
##
## Before Slice D the Operator advanced combat clocks, ran input handlers and
## changed state from `_process(delta)`, which made gameplay depend on frame rate:
## the same second of play resolved differently at 30 fps and at 240. This asserts
## the split directly -- render ticks must move nothing, fixed ticks must move
## everything -- across representative systems rather than every timer.
##
## It fails against the pre-Slice-D architecture, where `_process` drained exactly
## these clocks.
##
## Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")

## One clock per system the packet names, so a regression in any of them shows up
## as a named failure rather than a general one.
const CLOCKS := {
	"melee attack timeline": "melee_cooldown_remaining",
	"dodge cooldown": "_dodge_cooldown_remaining",
	"dodge iframes": "_dodge_iframe_timer",
	"ranged fire cooldown": "fire_cooldown_remaining",
}

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorFixedTickSpineRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	# Drive the ticks by hand so the engine's own scheduling cannot mask which one
	# is doing the work.
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set("unstuck_enabled", false)

	await _check_render_tick_moves_nothing(operator)
	await _check_fixed_tick_advances(operator)
	await _check_reload_is_fixed_tick_owned(operator)

	operator.queue_free()
	root.queue_free()
	await process_frame
	if _failures.is_empty():
		print("operator_fixed_tick_spine_smoke passed")
		quit(0)
		return
	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("operator_fixed_tick_spine_smoke: %d failure(s)" % _failures.size())
	quit(1)


func _arm_clocks(operator: Node) -> Dictionary:
	var armed := {}
	for label: String in CLOCKS:
		operator.set(CLOCKS[label], 1.0)
		armed[label] = 1.0
	return armed


## Render ticks are presentation. Ten of them must not move a single clock.
func _check_render_tick_moves_nothing(operator: Node) -> void:
	_arm_clocks(operator)
	for _i in 10:
		operator.call("_process", 0.1)
		await process_frame
	for label: String in CLOCKS:
		var value := float(operator.get(CLOCKS[label]))
		_check(
			is_equal_approx(value, 1.0),
			"%s advanced from the render tick: %s is %.4f after 1.0 s of _process"
				% [label, CLOCKS[label], value]
		)


## Fixed ticks are simulation, and they advance by exactly the delta they are given.
func _check_fixed_tick_advances(operator: Node) -> void:
	_arm_clocks(operator)
	for _i in 4:
		operator.call("_advance_simulation", 0.1)
		await process_frame
	for label: String in CLOCKS:
		var value := float(operator.get(CLOCKS[label]))
		_check(
			absf(value - 0.6) <= 0.001,
			"%s did not advance deterministically on the fixed tick: %s is %.4f, expected 0.600"
				% [label, CLOCKS[label], value]
		)

	# And the same total time in one step lands in the same place, which is what
	# "deterministic" has to mean for a clock.
	_arm_clocks(operator)
	operator.call("_advance_simulation", 0.4)
	await process_frame
	for label: String in CLOCKS:
		_check(
			absf(float(operator.get(CLOCKS[label])) - 0.6) <= 0.001,
			"%s is step-size dependent" % label
		)


## Reload is a separate subsystem with its own timer; prove it moved too.
func _check_reload_is_fixed_tick_owned(operator: Node) -> void:
	operator.set("_reload_active", true)
	operator.set("_reload_timer", 1.0)
	for _i in 5:
		operator.call("_process", 0.1)
		await process_frame
	_check(
		is_equal_approx(float(operator.get("_reload_timer")), 1.0),
		"reload advanced from the render tick, timer is %.4f" % float(operator.get("_reload_timer"))
	)
	operator.call("_advance_simulation", 0.25)
	await process_frame
	_check(
		float(operator.get("_reload_timer")) < 1.0,
		"reload did not advance on the fixed tick, timer is %.4f" % float(operator.get("_reload_timer"))
	)
	operator.set("_reload_active", false)
