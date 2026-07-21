class_name RouteTestLevel
extends AuthoredLevel2D

@export var fail_activation := false
@export var fail_camera := false
@export var fail_state_restore := false
var test_state := 0
var activation_count := 0


func activate_route_node(actor: Node, spawn_id: StringName) -> bool:
	if fail_activation:
		return false
	activation_count += 1
	return super.activate_route_node(actor, spawn_id)


func capture_route_state() -> Dictionary:
	return {"test_state": test_state}


func restore_route_state(state: Dictionary) -> void:
	if fail_state_restore:
		return
	test_state = int(state.get("test_state", 0))


func can_restore_route_state(_state: Dictionary) -> bool:
	return not fail_state_restore


func refresh_route_camera(actor: Node) -> bool:
	if fail_camera:
		return false
	return super.refresh_route_camera(actor)
