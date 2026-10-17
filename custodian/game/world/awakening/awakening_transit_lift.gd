extends "res://game/world/traversal/local_transit_lift_2d.gd"
class_name AwakeningTransitLift

## Thin Dust Lung compatibility consumer for the reusable same-map lift owner.
signal transit_started(from_station: int)
signal transit_finished(to_station: int)

enum Station { LOWER, UPPER }

const STATION_RADIUS := 48.0
const LIFT_TEXTURE := preload("res://content/sprites/environment/props/awakening/awakening_dust_lung_lift/runtime/body/awakening_dust_lung_lift__body__interaction__idle__omni__1f__192x256.png")

@export var lower_station := Vector2(384, -3008)
@export var upper_station := Vector2(384, -3424)

var current_station: int:
	get:
		return Station.UPPER if current_station_id == &"upper" else Station.LOWER
var _lift_sprite: Sprite2D
var _ride_tween: Tween


func _ready() -> void:
	interaction_prompt = "SERVICE LIFT"
	configure_stations([
		StationDefinition.new(&"lower", lower_station, STATION_RADIUS),
		StationDefinition.new(&"upper", upper_station, STATION_RADIUS),
	], &"lower")
	cycle_started.connect(_on_cycle_started)
	cycle_departed.connect(_on_cycle_departed)
	cycle_arrived.connect(_on_cycle_arrived)
	cycle_cancelled.connect(_on_cycle_cancelled)
	add_to_group("interactable")
	super._ready()
	_build_station_visuals()


func _build_station_visuals() -> void:
	_lift_sprite = Sprite2D.new()
	_lift_sprite.name = "ProductionLift"
	_lift_sprite.texture = LIFT_TEXTURE
	_lift_sprite.position = station_position(current_station)
	_lift_sprite.z_index = 1
	add_child(_lift_sprite)


func station_position(station: int) -> Vector2:
	return super.station_position_for(&"upper" if station == Station.UPPER else &"lower")


func other_station(station: int) -> int:
	return Station.LOWER if station == Station.UPPER else Station.UPPER


func station_under(actor: Node2D) -> int:
	var station_id := super.station_id_under(actor)
	if station_id == &"lower": return Station.LOWER
	if station_id == &"upper": return Station.UPPER
	return -1


func get_interaction_position() -> Vector2:
	var operator := get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	if operator != null:
		var nearest := station_under(operator)
		if nearest >= 0: return to_global(station_position(nearest))
		if operator.global_position.distance_to(to_global(upper_station)) < operator.global_position.distance_to(to_global(lower_station)):
			return to_global(upper_station)
	return to_global(station_position(current_station))


func can_interact(actor: Node) -> bool:
	return not is_busy() and station_under(actor as Node2D) >= 0


func ride(actor: Node2D) -> bool:
	return request_next_station(actor)


func _on_cycle_started(origin: StringName, _destination: StringName, _token: int) -> void:
	transit_started.emit(Station.UPPER if origin == &"upper" else Station.LOWER)


func _on_cycle_departed(_origin: StringName, destination: StringName, _token: int) -> void:
	if _lift_sprite == null: return
	if _ride_tween != null and _ride_tween.is_running(): _ride_tween.kill()
	_ride_tween = create_tween()
	_ride_tween.tween_property(_lift_sprite, "position", station_position(Station.UPPER if destination == &"upper" else Station.LOWER), TRAVEL_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_cycle_arrived(station: StringName, _token: int) -> void:
	transit_finished.emit(Station.UPPER if station == &"upper" else Station.LOWER)


func _on_cycle_cancelled(_origin: StringName, _destination: StringName, _reason: StringName, _token: int) -> void:
	if _ride_tween != null and _ride_tween.is_running(): _ride_tween.kill()
	_ride_tween = null
	if _lift_sprite != null:
		_lift_sprite.position = station_position(current_station)
	transit_finished.emit(current_station)


func reset_transient_state(station: StringName = &"") -> void:
	super.reset_transient_state(&"lower" if station.is_empty() else station)
	if _ride_tween != null and _ride_tween.is_running(): _ride_tween.kill()
	_ride_tween = null
	if _lift_sprite != null: _lift_sprite.position = lower_station
