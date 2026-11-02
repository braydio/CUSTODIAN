extends Node2D

const MAX_RESULTS := 16


func _get_debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _process(_delta: float) -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	if not debug_bus.enabled:
		debug_bus.set_hovered_entity(null)
		return
	var mouse_pos := get_global_mouse_position()
	var params := PhysicsPointQueryParameters2D.new()
	params.position = mouse_pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var results := get_world_2d().direct_space_state.intersect_point(params, MAX_RESULTS)
	var entity: Object = null
	if not results.is_empty():
		var hit = results[0]
		entity = hit.get("collider", null)
	debug_bus.set_hovered_entity(entity)
