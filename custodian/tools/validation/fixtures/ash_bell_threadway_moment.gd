extends Node2D

const THREADWAY_SCRIPT := preload(
	"res://game/world/approaches/ash_bell/ash_bell_threadway_causeway.gd"
)

var _threadway: AshBellThreadwayCauseway = null
var connector_committed: bool = false

var persistent_tiles: int:
	get:
		return 0 if _threadway == null else _threadway.debug_get_visible_persistent_tile_count()

var active_resolve_effects: int:
	get:
		return 0 if _threadway == null else _threadway.debug_get_active_resolve_effect_count()

var reveal_count: int:
	get:
		return 0 if _threadway == null else _threadway.debug_get_reveal_play_count()

var blocker_active: bool:
	get:
		return _threadway != null and _threadway.debug_has_temporary_blocker()


func _ready() -> void:
	queue_redraw()


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if command == "walk_operator_across":
		var operator := get_node_or_null("Operator") as Node2D
		if operator == null:
			return false
		create_tween().tween_property(operator, "position", Vector2(640, 292), 1.0)
		return true
	if command == "stand_at_lift_entrance":
		var operator := get_node_or_null("Operator") as Node2D
		if operator == null:
			return false
		operator.position = Vector2(640, 292)
		return true
	if command != "acquire_white_thread_knot" or _threadway != null:
		return false
	_threadway = THREADWAY_SCRIPT.new() as AshBellThreadwayCauseway
	_threadway.name = "AshBellThreadwayCauseway"
	add_child(_threadway)
	_threadway.visual_resolution_finished.connect(_on_visual_resolution_finished)
	var centerline: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(1, 3), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5),
	]
	var cells: Array[Vector2i] = []
	var variants: Dictionary = {}
	var progress_by_cell: Dictionary = {}
	for index in range(centerline.size()):
		var center := centerline[index]
		var tangents: Array[Vector2i] = []
		if index > 0:
			tangents.append(center - centerline[index - 1])
		if index + 1 < centerline.size():
			var outgoing := centerline[index + 1] - center
			if not tangents.has(outgoing):
				tangents.append(outgoing)
		for tangent in tangents:
			var perpendicular := Vector2i(-tangent.y, tangent.x)
			for offset in range(-1, 2):
				var cell := center + perpendicular * offset
				if not progress_by_cell.has(cell):
					cells.append(cell)
					variants[cell] = posmod(cell.x * 11 + cell.y * 7, 6)
					progress_by_cell[cell] = index
	_threadway.configure(self, {
		"ok": true,
		"cells": cells,
		"new_cells": cells,
		"centerline_cells": centerline,
		"centerline_progress_by_cell": progress_by_cell,
		"tile_variants": variants,
		"route_seed": 1138,
	}, true)
	return true


func _on_visual_resolution_finished() -> void:
	# The production ingress commits the exact evaluated procgen plan at this
	# boundary. This isolated fixture records that authority handoff before it
	# releases the temporary traversal blocker.
	connector_committed = true
	_threadway.finish_resolution()


func get_runtime_tile_size() -> Vector2:
	return Vector2(32.0, 32.0)


func tile_to_global_position(cell: Vector2i) -> Vector2:
	# Moment Forge mounts the fixture in a centered 1280x720 review canvas while
	# this adapter deliberately has no production TileMap transform.
	return Vector2(640.0, 360.0) + Vector2(cell.x * 32, cell.y * 32 - 72)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("10151c"))
	draw_rect(Rect2(0, 452, 1280, 268), Color("292821"))
	draw_rect(Rect2(0, 452, 1280, 20), Color("191b1d"))
