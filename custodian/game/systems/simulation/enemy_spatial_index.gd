extends Node
class_name EnemySpatialIndex

@export_range(32.0, 256.0, 16.0) var cell_size_px := 64.0
@export_range(0.05, 0.5, 0.05) var refresh_interval_sec := 0.10

var _cells: Dictionary = {}
var _refresh_accum := 0.0


func _ready() -> void:
	add_to_group("enemy_spatial_index")


func _physics_process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum < refresh_interval_sec:
		return
	_refresh_accum = 0.0
	_rebuild()


func _rebuild() -> void:
	_cells.clear()
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if not candidate is Node2D or candidate.is_queued_for_deletion():
			continue
		var actor := candidate as Node2D
		var cell := _position_to_cell(actor.global_position)
		if not _cells.has(cell):
			_cells[cell] = []
		var actors := _cells[cell] as Array
		actors.append(actor)
	for actors_variant: Variant in _cells.values():
		var actors := actors_variant as Array
		actors.sort_custom(_stable_actor_before)


func get_nearby_enemies(position: Vector2) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var center := _position_to_cell(position)
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			var actors := _cells.get(
				center + Vector2i(x_offset, y_offset),
				[]
			) as Array
			for actor_variant: Variant in actors:
				if actor_variant is Node2D:
					result.append(actor_variant as Node2D)
	return result


func _position_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / cell_size_px),
		floori(position.y / cell_size_px)
	)


func _stable_actor_before(a: Node2D, b: Node2D) -> bool:
	var a_ordinal := int(a.get_meta("stable_spawn_ordinal", 0))
	var b_ordinal := int(b.get_meta("stable_spawn_ordinal", 0))
	if a_ordinal != b_ordinal:
		return a_ordinal < b_ordinal
	return String(a.get_path()) < String(b.get_path())
