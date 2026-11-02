extends SceneTree

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var coordinator := root.get_node_or_null("EnemyEngagementCoordinator")
	_assert(coordinator != null, "engagement coordinator autoload is missing")
	if coordinator == null:
		_finish()
		return
	coordinator.call("clear")
	var operator := Node2D.new()
	var attacker_a := Node2D.new()
	var attacker_b := Node2D.new()
	root.add_child(operator)
	root.add_child(attacker_a)
	root.add_child(attacker_b)
	operator.position = Vector2.ZERO
	attacker_a.position = Vector2(40.0, 0.0)
	attacker_b.position = Vector2(-40.0, 0.0)
	_assert(bool(coordinator.call("request_committed_attack", attacker_a, operator, 0.05)), "first nearby attacker did not receive permission")
	_assert(not bool(coordinator.call("request_committed_attack", attacker_b, operator, 0.05)), "second nearby attacker entered the same committed window")
	coordinator.call("release_committed_attack", attacker_a)
	_assert(bool(coordinator.call("request_committed_attack", attacker_b, operator, 0.05)), "permission did not transfer after interruption/recovery")
	attacker_a.position = Vector2(400.0, 0.0)
	_assert(bool(coordinator.call("request_committed_attack", attacker_a, operator, 0.05)), "distant attacker was incorrectly serialized")
	operator.queue_free()
	attacker_a.queue_free()
	attacker_b.queue_free()
	_finish()


func _finish() -> void:
	if _errors.is_empty():
		print("[EnemyEngagementCoordinatorSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[EnemyEngagementCoordinatorSmoke] %s" % error)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
