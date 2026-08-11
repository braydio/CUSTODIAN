extends Node2D

const THREADWAY_SCRIPT := preload(
	"res://game/world/approaches/ash_bell/ash_bell_threadway_causeway.gd"
)

var _threadway: AshBellThreadwayCauseway = null

var persistent_tiles: int:
	get:
		return 0 if _threadway == null else _threadway.debug_get_persistent_tile_count()

var reveal_count: int:
	get:
		return 0 if _threadway == null else _threadway.debug_get_reveal_play_count()

var blocker_active: bool:
	get:
		return _threadway != null and _threadway.debug_has_temporary_blocker()


func _ready() -> void:
	queue_redraw()


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if command != "acquire_white_thread_knot" or _threadway != null:
		return false
	_threadway = THREADWAY_SCRIPT.new() as AshBellThreadwayCauseway
	_threadway.name = "AshBellThreadwayCauseway"
	add_child(_threadway)
	var cells: Array[Vector2i] = []
	var variants: Dictionary = {}
	for y in range(0, 6):
		for x in range(-1, 2):
			var cell := Vector2i(x, y)
			cells.append(cell)
			variants[cell] = posmod(x * 11 + y * 7, 6)
	_threadway.configure(self, {
		"ok": true,
		"cells": cells,
		"new_cells": cells,
		"centerline_cells": [
			Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
			Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5),
		],
		"tile_variants": variants,
	}, true)
	return true


func get_runtime_tile_size() -> Vector2:
	return Vector2(32.0, 32.0)


func tile_to_global_position(cell: Vector2i) -> Vector2:
	# Moment Forge mounts the fixture in a centered 1280x720 review canvas while
	# this adapter deliberately has no production TileMap transform.
	return Vector2(640.0, 360.0) + Vector2(cell.x * 32, cell.y * 32 - 72)


func _draw() -> void:
	draw_rect(Rect2(-640, -360, 1280, 720), Color("10151c"))
	draw_rect(Rect2(-640, 88, 1280, 272), Color("292821"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-150, -250), Vector2(150, -250), Vector2(150, -54),
		Vector2(82, -24), Vector2(-82, -24), Vector2(-150, -54),
	]), Color("343229"))
	draw_rect(Rect2(-640, 68, 1280, 20), Color("191b1d"))
