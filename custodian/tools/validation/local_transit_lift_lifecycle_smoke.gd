extends SceneTree

class LockActor extends Node2D:
	var lock_calls := 0
	var unlock_calls := 0
	var locked := false

	func set_local_transit_locked(value: bool) -> void:
		if value:
			lock_calls += 1
		else:
			unlock_calls += 1
		locked = value


const LiftScript := preload("res://game/world/traversal/local_transit_lift_2d.gd")
const StationScript := preload("res://game/world/traversal/local_transit_station_2d.gd")

var _checks := 0
var _failures: Array[String] = []


func _init() -> void:
	await process_frame
	await _test_round_trip_and_three_stations()
	await _test_busy_duplicate_and_unknown()
	await _test_reset_and_stale_callback()
	await _test_invalid_actor_and_owner_exit()
	print("LocalTransitLift lifecycle assertions: %d checks, %d failed" % [_checks, _failures.size()])
	for failure in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures.append(label)


func _make_lift(definitions: Array, initial: StringName) -> Node2D:
	var lift := LiftScript.new() as Node2D
	root.add_child(lift)
	var configured: bool = lift.call("configure_stations", definitions, initial)

	return lift


func _stations_three() -> Array:
	return [
		StationScript.new(&"alpha", Vector2(0, 0), 24.0),
		StationScript.new(&"middle", Vector2(100, 0), 24.0),
		StationScript.new(&"zeta", Vector2(200, 0), 24.0),
	]


func _actor_at(position: Vector2) -> LockActor:
	var actor := LockActor.new()
	root.add_child(actor)
	actor.global_position = position
	return actor


func _wait_idle(lift: Node) -> void:
	for _frame in 60:
		await process_frame
		if not bool(lift.call("is_busy")): return


func _test_round_trip_and_three_stations() -> void:
	var lift := _make_lift(_stations_three(), &"alpha")
	var actor := _actor_at(Vector2.ZERO)
	_check(bool(lift.call("validate_station_configuration")), "three unique stable station IDs validate")
	_check(bool(lift.call("request_next_station", actor)), "deterministic alpha to middle travel accepted")
	await _wait_idle(lift)
	_check(StringName(lift.get("current_station_id")) == &"middle" and actor.global_position == Vector2(100, 0), "three-stop arrival commits destination and actor position")
	_check(bool(lift.call("request_next_station", actor)), "three-stop middle to zeta travel accepted")
	await _wait_idle(lift)
	_check(StringName(lift.get("current_station_id")) == &"zeta", "three-stop sequence advances in stable ID order")
	_check(bool(lift.call("request_travel", actor, &"alpha")), "explicit reverse travel accepted")
	await _wait_idle(lift)
	_check(StringName(lift.get("current_station_id")) == &"alpha" and actor.global_position == Vector2.ZERO, "reverse arrival restores origin station")
	_check(actor.lock_calls == 3 and actor.unlock_calls == 3 and not actor.locked, "successful cycles lock and unlock exactly once")
	lift.queue_free()
	actor.queue_free()
	await process_frame


func _test_busy_duplicate_and_unknown() -> void:
	var defs := _stations_three()
	var duplicate_defs: Array = [defs[0], StationScript.new(&"alpha", Vector2(100, 0), 24.0)]
	var invalid := _make_lift(duplicate_defs, &"alpha")
	_check(not bool(invalid.call("validate_station_configuration")), "duplicate station IDs invalidate configuration")
	var actor := _actor_at(Vector2.ZERO)
	_check(not bool(invalid.call("request_travel", actor, &"missing")), "unknown destination rejected")
	invalid.queue_free()
	await process_frame

	var lift := _make_lift(_stations_three(), &"alpha")
	actor.global_position = Vector2.ZERO
	_check(bool(lift.call("request_next_station", actor)), "first busy-cycle request accepted")
	_check(not bool(lift.call("request_next_station", actor)), "second request while busy rejected")
	await _wait_idle(lift)
	_check(actor.lock_calls == 1 and actor.unlock_calls == 1, "busy rejection does not duplicate actor locking")
	lift.queue_free()
	actor.queue_free()
	await process_frame


func _test_reset_and_stale_callback() -> void:
	var lift := _make_lift(_stations_three(), &"alpha")
	var actor := _actor_at(Vector2.ZERO)
	_check(bool(lift.call("request_next_station", actor)), "reset fixture cycle starts")
	var old_token := int(lift.get("cycle_token"))
	await create_timer(0.04).timeout
	lift.call("reset_transient_state", &"alpha")
	_check(not bool(lift.call("is_busy")) and StringName(lift.get("current_station_id")) == &"alpha", "mid-cycle reset cancels and retains committed station")
	_check(actor.lock_calls == 1 and actor.unlock_calls == 1 and not actor.locked, "reset releases actor lock exactly once")
	_check(bool(lift.call("request_next_station", actor)), "new cycle starts after reset")
	var new_token := int(lift.get("cycle_token"))
	await create_timer(0.08).timeout
	_check(new_token > old_token and StringName(lift.get("current_station_id")) == &"alpha", "stale prior-cycle callback cannot commit newer cycle")
	await _wait_idle(lift)
	_check(StringName(lift.get("current_station_id")) == &"middle" and actor.lock_calls == 2 and actor.unlock_calls == 2, "new cycle commits and balances its own lock")
	lift.queue_free()
	actor.queue_free()
	await process_frame


func _test_invalid_actor_and_owner_exit() -> void:
	var lift := _make_lift(_stations_three(), &"alpha")
	var actor := _actor_at(Vector2.ZERO)
	_check(bool(lift.call("request_next_station", actor)), "invalid-actor fixture cycle starts")
	await create_timer(0.04).timeout
	root.remove_child(actor)
	_check(not bool(lift.call("is_busy")) and StringName(lift.get("current_station_id")) == &"alpha", "actor tree exit cancels without committing destination")
	_check(actor.lock_calls == 1 and actor.unlock_calls == 1 and not actor.locked, "tree-exited actor receives one lock and one unlock")
	actor.free()
	lift.queue_free()
	await process_frame

	var exiting_lift := _make_lift(_stations_three(), &"alpha")
	var surviving_actor := _actor_at(Vector2.ZERO)
	_check(bool(exiting_lift.call("request_next_station", surviving_actor)), "owner-exit fixture cycle starts")
	exiting_lift.get_parent().remove_child(exiting_lift)
	_check(not bool(exiting_lift.call("is_busy")) and surviving_actor.lock_calls == 1 and surviving_actor.unlock_calls == 1 and not surviving_actor.locked, "owner tree exit cancels and unlocks actor exactly once")
	exiting_lift.queue_free()
	surviving_actor.queue_free()
	await process_frame
