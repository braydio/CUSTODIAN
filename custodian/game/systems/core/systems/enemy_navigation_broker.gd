extends Node
class_name EnemyNavigationBroker

@export_range(1, 8, 1) var max_queries_per_physics_frame := 2

var navigation_system: NavigationSystem
var _pending: Array[Dictionary] = []
var _pending_by_requester: Dictionary = {}
var _query_count := 0
var _query_total_usec := 0
var _query_max_usec := 0


func configure(owner_navigation: NavigationSystem) -> void:
	navigation_system = owner_navigation


func request_path(
	requester: Node,
	start: Vector2,
	target: Vector2,
	callback: Callable
) -> bool:
	if requester == null or not callback.is_valid():
		return false
	var requester_id := requester.get_instance_id()
	var request := {
		"requester": requester,
		"start": start,
		"target": target,
		"callback": callback,
	}
	if _pending_by_requester.has(requester_id):
		var index := int(_pending_by_requester[requester_id])
		if index >= 0 and index < _pending.size():
			_pending[index] = request
			return true
	_pending.append(request)
	_reindex_requests()
	_set_gauge("enemy_nav_queue_depth", _pending.size())
	return true


func _physics_process(_delta: float) -> void:
	var budget := mini(max_queries_per_physics_frame, _pending.size())
	for _index in budget:
		var request := _pending.pop_front() as Dictionary
		var requester := request.get("requester") as Node
		if requester == null or not is_instance_valid(requester):
			continue
		var started := Time.get_ticks_usec()
		var path := PackedVector2Array()
		if navigation_system != null:
			path = navigation_system.compute_path_immediate(
				request.get("start", Vector2.ZERO),
				request.get("target", Vector2.ZERO)
			)
		var elapsed := Time.get_ticks_usec() - started
		_query_count += 1
		_query_total_usec += elapsed
		_query_max_usec = maxi(_query_max_usec, elapsed)
		_increment("enemy_nav_query_count")
		_increment("enemy_nav_query_total_usec", elapsed)
		_set_gauge("enemy_nav_query_last_usec", elapsed)
		var callback := request.get("callback") as Callable
		if callback.is_valid():
			callback.call(path, request.get("target", Vector2.ZERO))
	_reindex_requests()
	_set_gauge("enemy_nav_queue_depth", _pending.size())


func _reindex_requests() -> void:
	_pending_by_requester.clear()
	for index in _pending.size():
		var requester := _pending[index].get("requester") as Node
		if requester != null and is_instance_valid(requester):
			_pending_by_requester[requester.get_instance_id()] = index


func get_pending_query_count() -> int:
	return _pending.size()


func get_performance_snapshot() -> Dictionary:
	return {
		"query_count": _query_count,
		"query_total_usec": _query_total_usec,
		"query_average_usec": (
			float(_query_total_usec) / float(_query_count)
			if _query_count > 0 else 0.0
		),
		"query_max_usec": _query_max_usec,
		"queue_depth": _pending.size(),
	}


func _observatory() -> Node:
	return get_node_or_null("/root/DevObservatory")


func _increment(counter_name: String, amount: int = 1) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("increment"):
		observatory.call("increment", counter_name, amount)


func _set_gauge(gauge_name: String, value: Variant) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", gauge_name, value)
