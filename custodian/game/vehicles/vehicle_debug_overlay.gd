class_name VehicleDebugOverlay
extends Node2D

@export var vehicle_path: NodePath = ^".."

var _vehicle: Node = null


func _ready() -> void:
	_vehicle = get_node_or_null(vehicle_path)
	visible = OS.is_debug_build()


func _draw() -> void:
	if _vehicle == null or not visible:
		return
	draw_circle(Vector2.ZERO, 5.0, Color(0.35, 0.9, 1.0, 0.8))
	if _vehicle.has_method("get_interaction_distance"):
		draw_arc(Vector2.ZERO, float(_vehicle.call("get_interaction_distance")), 0.0, TAU, 48, Color(0.35, 0.9, 1.0, 0.25), 1.0)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
