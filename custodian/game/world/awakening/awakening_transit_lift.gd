extends Node2D
class_name AwakeningTransitLift

## Bidirectional service lift between the Dust Lung Cistern's lower and upper
## stations.
##
## Deliberately not a Z-axis system: the Operator steps into a station, input is
## locked, the screen dims, and they are relocated to the paired station. Later
## art can replace the dim with an animated cage travelling the shaft without
## changing this interaction contract.

signal transit_started(from_station: int)
signal transit_finished(to_station: int)

enum Station { LOWER, UPPER }

const FADE_SEC := 0.15
const SHAKE_SEC := 0.20
const STATION_RADIUS := 48.0

@export var lower_station := Vector2(384, -3008)
@export var upper_station := Vector2(384, -3424)
@export var interaction_distance: float = 72.0

var current_station: int = Station.LOWER
var _busy := false
var _operator: Node2D = null


func _ready() -> void:
	add_to_group("interactable")
	_build_station_visuals()


func _build_station_visuals() -> void:
	for station in [lower_station, upper_station]:
		var pad := Polygon2D.new()
		pad.polygon = PackedVector2Array([
			station + Vector2(-STATION_RADIUS, -STATION_RADIUS),
			station + Vector2(STATION_RADIUS, -STATION_RADIUS),
			station + Vector2(STATION_RADIUS, STATION_RADIUS),
			station + Vector2(-STATION_RADIUS, STATION_RADIUS),
		])
		pad.color = Color(0.278, 0.455, 0.482, 0.5)
		pad.z_index = 1
		add_child(pad)


func station_position(station: int) -> Vector2:
	return upper_station if station == Station.UPPER else lower_station


func other_station(station: int) -> int:
	return Station.LOWER if station == Station.UPPER else Station.UPPER


## The station the actor is standing on, or -1.
func station_under(actor: Node2D) -> int:
	if actor == null:
		return -1
	for station in [Station.LOWER, Station.UPPER]:
		if actor.global_position.distance_to(station_position(station)) <= STATION_RADIUS:
			return station
	return -1


# --- Interactable contract ---------------------------------------------------

func get_interaction_prompt() -> String:
	return "SERVICE LIFT"


## Report whichever station the Operator is actually standing on so the prompt
## and the ride agree.
func get_interaction_position() -> Vector2:
	var operator := get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	if operator != null:
		var nearest := station_under(operator)
		if nearest >= 0: return station_position(nearest)
		if operator.global_position.distance_to(station_position(Station.UPPER)) \
				< operator.global_position.distance_to(station_position(Station.LOWER)):
			return station_position(Station.UPPER)
	return station_position(current_station)


func can_interact(actor: Node) -> bool:
	return not _busy and station_under(actor as Node2D) >= 0


func get_interaction_distance() -> float:
	return interaction_distance


func interact(actor: Node) -> void:
	ride(actor as Node2D)


## Rides from whichever station the actor occupies to its pair. Returns false if
## the lift is mid-cycle or the actor is not on a station.
func ride(actor: Node2D) -> bool:
	if _busy or actor == null:
		return false
	var from_station := station_under(actor)
	if from_station < 0:
		return false
	_operator = actor
	current_station = from_station
	_run_cycle(from_station, other_station(from_station))
	return true


func _run_cycle(from_station: int, to_station: int) -> void:
	_busy = true
	transit_started.emit(from_station)
	_set_operator_input_enabled(false)
	await _wait(FADE_SEC)
	await _wait(SHAKE_SEC)
	if _operator != null and is_instance_valid(_operator):
		_operator.global_position = station_position(to_station)
		if _operator is CharacterBody2D:
			(_operator as CharacterBody2D).velocity = Vector2.ZERO
	current_station = to_station
	await _wait(FADE_SEC)
	_set_operator_input_enabled(true)
	_busy = false
	transit_finished.emit(to_station)


func _wait(seconds: float) -> void:
	if get_tree() == null:
		return
	await get_tree().create_timer(seconds).timeout


## Reuses the Operator's existing transition lock rather than introducing a
## second way to suspend player input.
func _set_operator_input_enabled(enabled: bool) -> void:
	if _operator != null and is_instance_valid(_operator) \
			and _operator.has_method("set_portal_transition_locked"):
		_operator.call("set_portal_transition_locked", not enabled)


func is_busy() -> bool:
	return _busy
