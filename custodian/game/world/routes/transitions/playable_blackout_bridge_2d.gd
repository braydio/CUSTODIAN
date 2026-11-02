class_name PlayableBlackoutBridge2D
extends Node2D

const RUN_LENGTH := 320.0
const CORRIDOR_HALF_WIDTH := 56.0

var _actor: Node2D
var _run_direction := Vector2.UP
var _start_position := Vector2.ZERO
var _backdrop_layer: CanvasLayer
var _backdrop: ColorRect
var _contact_shadow: Polygon2D
var _route_ribbon: Line2D
var _collision_body: StaticBody2D


func begin(actor: Node2D) -> void:
	_actor = actor
	_start_position = actor.global_position
	_run_direction = _resolve_run_direction(actor)
	z_as_relative = false
	z_index = -1
	_build_backdrop()
	_build_route_ribbon()
	_build_contact_shadow()
	_build_corridor()
	set_process(true)


func _process(_delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	if _contact_shadow != null:
		_contact_shadow.global_position = _actor.global_position
		_contact_shadow.rotation = _run_direction.angle() + PI * 0.5


func get_run_progress() -> float:
	if _actor == null or not is_instance_valid(_actor):
		return 0.0
	return maxf(
		0.0,
		(_actor.global_position - _start_position).dot(_run_direction)
	)


func get_required_run_distance() -> float:
	return RUN_LENGTH


func _build_backdrop() -> void:
	_backdrop_layer = CanvasLayer.new()
	_backdrop_layer.name = "PlayableBlackoutBackdropLayer"
	_backdrop_layer.layer = -20
	_backdrop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_backdrop_layer)
	_backdrop = ColorRect.new()
	_backdrop.name = "BlackWorldSpaceBackdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color.BLACK
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_layer.add_child(_backdrop)


func _build_route_ribbon() -> void:
	var route_points := PackedVector2Array([
		_start_position - _run_direction * 64.0,
		_start_position + _run_direction * (RUN_LENGTH + 96.0),
	])
	_route_ribbon = Line2D.new()
	_route_ribbon.name = "BlackoutRouteRibbon"
	_route_ribbon.width = 76.0
	_route_ribbon.default_color = Color(0.11, 0.14, 0.16, 0.92)
	_route_ribbon.z_as_relative = false
	_route_ribbon.z_index = -3
	_route_ribbon.points = route_points
	add_child(_route_ribbon)

	var center_read := Line2D.new()
	center_read.name = "BlackoutRouteCenterRead"
	center_read.width = 7.0
	center_read.default_color = Color(0.30, 0.35, 0.37, 0.68)
	center_read.z_as_relative = false
	center_read.z_index = -2
	center_read.points = route_points
	add_child(center_read)


func _build_contact_shadow() -> void:
	_contact_shadow = Polygon2D.new()
	_contact_shadow.name = "OperatorContactShadow"
	_contact_shadow.polygon = PackedVector2Array([
		Vector2(-22.0, 0.0),
		Vector2(-15.0, -7.0),
		Vector2(0.0, -10.0),
		Vector2(15.0, -7.0),
		Vector2(22.0, 0.0),
		Vector2(15.0, 7.0),
		Vector2(0.0, 10.0),
		Vector2(-15.0, 7.0),
	])
	_contact_shadow.color = Color(0.02, 0.025, 0.03, 0.68)
	_contact_shadow.z_as_relative = false
	_contact_shadow.z_index = -1
	add_child(_contact_shadow)


func _build_corridor() -> void:
	_collision_body = StaticBody2D.new()
	_collision_body.name = "BlackoutRouteRails"
	_collision_body.collision_layer = 1
	_collision_body.collision_mask = 1
	add_child(_collision_body)
	var side := Vector2(-_run_direction.y, _run_direction.x)
	var midpoint := _start_position + _run_direction * RUN_LENGTH * 0.5
	for sign_value in [-1.0, 1.0]:
		var shape_node := CollisionShape2D.new()
		shape_node.name = "RailLeft" if sign_value < 0.0 else "RailRight"
		var rail := CapsuleShape2D.new()
		rail.radius = 8.0
		rail.height = RUN_LENGTH + 64.0
		shape_node.shape = rail
		shape_node.global_position = (
			midpoint + side * CORRIDOR_HALF_WIDTH * sign_value
		)
		shape_node.rotation = _run_direction.angle() - PI * 0.5
		_collision_body.add_child(shape_node)


func _resolve_run_direction(actor: Node2D) -> Vector2:
	if actor is CharacterBody2D:
		var velocity := (actor as CharacterBody2D).velocity
		if velocity.length_squared() > 1.0:
			return velocity.normalized()
	if "facing_direction" in actor:
		var facing: Variant = actor.get("facing_direction")
		if facing is Vector2 and (facing as Vector2).length_squared() > 0.1:
			return (facing as Vector2).normalized()
	return Vector2.UP
