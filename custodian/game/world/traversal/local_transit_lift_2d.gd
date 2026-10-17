extends Node2D
class_name LocalTransitLift2D

## Same-map transit authority. Presentation consumes signals; this node owns
## eligibility, cycle identity, actor locking and station commitment.
signal cycle_started(origin: StringName, destination: StringName, token: int)
signal cycle_departed(origin: StringName, destination: StringName, token: int)
signal cycle_progress(phase: StringName, progress: float, token: int)
signal cycle_arrived(station: StringName, token: int)
signal cycle_cancelled(origin: StringName, destination: StringName, reason: StringName, token: int)

const StationDefinition := preload("res://game/world/traversal/local_transit_station_2d.gd")
const DEPARTURE_DELAY_SEC := 0.15
const TRAVEL_DURATION_SEC := 0.20

@export var interaction_prompt := "LOCAL LIFT"
@export var interaction_distance := 72.0
@export var stations: Array = []
@export var initial_station: StringName = &""

var current_station_id: StringName = &""
var origin_station_id: StringName = &""
var destination_station_id: StringName = &""
var cycle_token := 0
var _busy := false
var _actor: Node2D
var _lock_active := false
var _station_by_id: Dictionary = {}


func _ready() -> void:
	_rebuild_station_index()
	if initial_station.is_empty() and not stations.is_empty():
		initial_station = stations[0].station_id
	if _station_by_id.has(initial_station):
		current_station_id = initial_station


func configure_stations(definitions: Array, start_station: StringName) -> bool:
	if _busy:
		return false
	stations.clear()
	for definition in definitions:
		if definition is Resource and definition.get_script() == StationDefinition:
			stations.append(definition)
	initial_station = start_station
	_rebuild_station_index()
	if not _station_by_id.has(start_station):
		current_station_id = &""
		return false
	current_station_id = start_station
	return true


func _rebuild_station_index() -> void:
	_station_by_id.clear()
	for station in stations:
		if station == null or StringName(station.get("station_id")).is_empty() or _station_by_id.has(StringName(station.get("station_id"))):
			_station_by_id.clear()
			return
		_station_by_id[StringName(station.get("station_id"))] = station


func validate_station_configuration() -> bool:
	return stations.size() >= 2 and _station_by_id.size() == stations.size() and _station_by_id.has(initial_station)


func station_position_for(station_id: StringName) -> Vector2:
	var station: Variant = _station_by_id.get(station_id)
	return station.get("arrival_position") if station != null else Vector2.ZERO


func station_id_under(actor: Node2D) -> StringName:
	if not _actor_is_valid(actor):
		return &""
	for station in stations:
		if station != null and actor.global_position.distance_to(to_global(station.get("arrival_position"))) <= float(station.get("interaction_radius")):
			return StringName(station.get("station_id"))
	return &""


func request_travel(actor: Node2D, destination: StringName) -> bool:
	if _busy or not validate_station_configuration() or not _actor_is_valid(actor):
		return false
	if not _station_by_id.has(destination) or destination == current_station_id:
		return false
	var origin := station_id_under(actor)
	if origin.is_empty() or origin != current_station_id:
		return false
	return _begin_cycle(actor, origin, destination)


func request_next_station(actor: Node2D) -> bool:
	if _busy or not validate_station_configuration() or not _actor_is_valid(actor):
		return false
	var origin := station_id_under(actor)
	if origin.is_empty() or origin != current_station_id:
		return false
	var ids: Array[StringName] = []
	for station in stations:
		ids.append(StringName(station.get("station_id")))
	ids.sort_custom(_station_ids_less)
	var current_index := ids.find(origin)
	return _begin_cycle(actor, origin, ids[(current_index + 1) % ids.size()])


func _begin_cycle(actor: Node2D, origin: StringName, destination: StringName) -> bool:
	if not actor.has_method("set_local_transit_locked") and not actor.has_method("set_portal_transition_locked"):
		return false
	cycle_token += 1
	var token := cycle_token
	_actor = actor
	origin_station_id = origin
	destination_station_id = destination
	_busy = true
	if actor.has_signal("tree_exited"):
		actor.tree_exited.connect(_on_actor_tree_exited.bind(token), CONNECT_ONE_SHOT)
	_set_actor_locked(true)
	cycle_started.emit(origin, destination, token)
	_run_cycle(token)
	return true


func _station_ids_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)


func _run_cycle(token: int) -> void:
	await get_tree().create_timer(DEPARTURE_DELAY_SEC).timeout
	if not _cycle_is_current(token): return
	cycle_departed.emit(origin_station_id, destination_station_id, token)
	cycle_progress.emit(&"travel", 0.0, token)
	await get_tree().create_timer(TRAVEL_DURATION_SEC).timeout
	if not _cycle_is_current(token): return
	if not _actor_is_valid(_actor):
		_cancel_cycle(&"invalid_actor", token)
		return
	_actor.global_position = to_global(station_position_for(destination_station_id))
	if _actor is CharacterBody2D:
		(_actor as CharacterBody2D).velocity = Vector2.ZERO
	current_station_id = destination_station_id
	cycle_progress.emit(&"arrival", 1.0, token)
	var arrived := current_station_id
	_disconnect_actor(token)
	_set_actor_locked(false)
	_busy = false
	_actor = null
	cycle_arrived.emit(arrived, token)


func _cycle_is_current(token: int) -> bool:
	return _busy and token == cycle_token and is_inside_tree()


func _actor_is_valid(actor: Node2D) -> bool:
	return actor != null and is_instance_valid(actor) and actor.is_inside_tree() and not actor.is_queued_for_deletion()


func _set_actor_locked(locked: bool) -> void:
	if locked:
		if _lock_active or not _actor_is_valid(_actor): return
		if _actor.has_method("set_local_transit_locked"):
			_actor.call("set_local_transit_locked", true)
		elif _actor.has_method("set_portal_transition_locked"):
			_actor.call("set_portal_transition_locked", true)
		else:
			return
		_lock_active = true
		return
	if not _lock_active: return
	if _actor != null and is_instance_valid(_actor):
		if _actor.has_method("set_local_transit_locked"):
			_actor.call("set_local_transit_locked", false)
		elif _actor.has_method("set_portal_transition_locked"):
			_actor.call("set_portal_transition_locked", false)
	_lock_active = false


func _on_actor_tree_exited(token: int) -> void:
	_cancel_cycle(&"actor_tree_exited", token)


func _disconnect_actor(token: int) -> void:
	if _actor != null and is_instance_valid(_actor):
		var callback := _on_actor_tree_exited.bind(token)
		if _actor.tree_exited.is_connected(callback):
			_actor.tree_exited.disconnect(callback)


func _cancel_cycle(reason: StringName, token: int = -1) -> void:
	if not _busy or (token >= 0 and token != cycle_token): return
	var cancelled_token := cycle_token
	var old_origin := origin_station_id
	var old_destination := destination_station_id
	cycle_token += 1
	_disconnect_actor(cancelled_token)
	_set_actor_locked(false)
	_busy = false
	_actor = null
	origin_station_id = &""
	destination_station_id = &""
	cycle_cancelled.emit(old_origin, old_destination, reason, cancelled_token)


func reset_transient_state(station: StringName = &"") -> void:
	_cancel_cycle(&"reset")
	if not station.is_empty() and _station_by_id.has(station):
		current_station_id = station
	elif _station_by_id.has(initial_station):
		current_station_id = initial_station


func is_busy() -> bool:
	return _busy


func get_interaction_prompt() -> String:
	return interaction_prompt


func get_interaction_position() -> Vector2:
	return to_global(station_position_for(current_station_id))


func can_interact(actor: Node) -> bool:
	return not _busy and station_id_under(actor as Node2D) == current_station_id


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	request_next_station(actor as Node2D)


func _exit_tree() -> void:
	_cancel_cycle(&"owner_tree_exited")
