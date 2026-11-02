extends Node2D
class_name LastRoutekeeperEvent

signal trace_recovered(route_hint_tile: Vector2i)

const INTERACTABLE_SCRIPT := preload("res://game/world/sundered_keep/sundered_keep_interactable.gd")
const STATE_SCRIPT := preload("res://game/world/events/last_routekeeper/last_routekeeper_event_state.gd")

const TILE_SIZE := 32.0
const EVENT_KIND := &"last_routekeeper_trace"

@export var interaction_distance := 78.0

var connected_map: Node = null
var state = null  # LastRoutekeeperEventState instance
var route_hint_tile := Vector2i.ZERO

var _interactable: Node2D = null
var _projection: Node2D = null
var _beacon: Node2D = null
var _pulse_tween: Tween = null


func configure(p_map: Node, p_route_hint_tile: Vector2i) -> void:
	connected_map = p_map
	route_hint_tile = p_route_hint_tile
	state = STATE_SCRIPT.new()
	state.route_hint_tile = route_hint_tile


func _ready() -> void:
	if state == null:
		state = STATE_SCRIPT.new()
		state.route_hint_tile = route_hint_tile
	_build_placeholder_visuals()
	_build_interactable()


func recover_trace() -> void:
	if state.completed:
		return
	state.completed = true
	_play_recovery_feedback()
	trace_recovered.emit(route_hint_tile)


func get_recovery_lines() -> Array[String]:
	if state == null:
		return []
	return state.get_recovery_lines()


func _build_interactable() -> void:
	_interactable = INTERACTABLE_SCRIPT.new() as Node2D
	_interactable.name = "LastRoutekeeperTraceInteraction"
	_interactable.position = Vector2.ZERO
	add_child(_interactable)
	_interactable.call(
		"configure",
		connected_map,
		EVENT_KIND,
		"RECOVER ROUTEKEEPER TRACE",
		interaction_distance
	)


func _build_placeholder_visuals() -> void:
	# Placeholder beacon. Replace with routekeeper_survey_beacon_01.png later.
	_beacon = Node2D.new()
	_beacon.name = "RoutekeeperSurveyBeaconPlaceholder"
	add_child(_beacon)

	var base := Polygon2D.new()
	base.name = "BeaconBase"
	base.polygon = PackedVector2Array([
		Vector2(-8, 4),
		Vector2(8, 4),
		Vector2(6, 18),
		Vector2(-6, 18),
	])
	base.color = Color(0.18, 0.16, 0.13, 0.95)
	_beacon.add_child(base)

	var glow := Polygon2D.new()
	glow.name = "BeaconGlow"
	glow.polygon = PackedVector2Array([
		Vector2(-5, -18),
		Vector2(5, -18),
		Vector2(9, 2),
		Vector2(-9, 2),
	])
	glow.color = Color(0.25, 0.85, 0.95, 0.55)
	_beacon.add_child(glow)

	# Placeholder residual figure. Replace with animated sprite later.
	_projection = Node2D.new()
	_projection.name = "RoutekeeperResidualProjectionPlaceholder"
	_projection.position = Vector2(18, -8)
	add_child(_projection)

	var body := Polygon2D.new()
	body.name = "ResidualBody"
	body.polygon = PackedVector2Array([
		Vector2(-10, -42),
		Vector2(10, -42),
		Vector2(14, 8),
		Vector2(-14, 8),
	])
	body.color = Color(0.36, 0.83, 0.95, 0.22)
	_projection.add_child(body)

	var head := Polygon2D.new()
	head.name = "ResidualHead"
	head.polygon = PackedVector2Array([
		Vector2(-7, -58),
		Vector2(7, -58),
		Vector2(8, -43),
		Vector2(-8, -43),
	])
	head.color = Color(0.36, 0.83, 0.95, 0.28)
	_projection.add_child(head)

	var slate := Polygon2D.new()
	slate.name = "SurveySlate"
	slate.polygon = PackedVector2Array([
		Vector2(10, -28),
		Vector2(24, -24),
		Vector2(20, -10),
		Vector2(7, -14),
	])
	slate.color = Color(0.20, 0.95, 0.86, 0.38)
	_projection.add_child(slate)

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(_projection, "modulate:a", 0.35, 0.9)
	_pulse_tween.tween_property(_projection, "modulate:a", 0.82, 0.9)


func _play_recovery_feedback() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	var tween := create_tween()
	tween.tween_property(_projection, "modulate:a", 0.05, 0.55)
	tween.parallel().tween_property(_beacon, "modulate:a", 0.35, 0.55)
	if _interactable != null:
		_interactable.remove_from_group("interactable")
		_interactable.visible = false
