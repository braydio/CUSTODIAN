class_name VehicleSeat
extends Node2D

@export var vehicle_path: NodePath = ^".."
@export var seat_id: String = "driver"


func get_vehicle() -> Node:
	if vehicle_path != NodePath():
		return get_node_or_null(vehicle_path)
	return get_parent()


func can_accept(actor: Node) -> bool:
	var vehicle := get_vehicle()
	return vehicle != null and vehicle.has_method("can_enter") and bool(vehicle.call("can_enter", actor))


func enter(actor: Node) -> bool:
	var vehicle := get_vehicle()
	return vehicle != null and vehicle.has_method("enter_vehicle") and bool(vehicle.call("enter_vehicle", actor))
