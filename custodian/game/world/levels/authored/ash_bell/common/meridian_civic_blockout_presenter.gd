class_name MeridianCivicBlockoutPresenter
extends Node2D

var cell_size := 32.0
var map_origin := Vector2.ZERO


func configure(origin: Vector2, authored_cell_size: float) -> void:
	map_origin = origin
	cell_size = authored_cell_size
	queue_redraw()


func _rect(cells: Rect2i) -> Rect2:
	return Rect2(map_origin + Vector2(cells.position) * cell_size, Vector2(cells.size) * cell_size)


func _draw() -> void:
	# Pass-two placeholder massing. It follows authored topology but owns no collision.
	var civic := Color("252c31")
	var upper := Color("30383d")
	for cells in [
		Rect2i(48, 66, 10, 18), Rect2i(70, 68, 10, 16),
		Rect2i(26, 55, 12, 25), Rect2i(46, 48, 10, 18),
		Rect2i(10, 28, 6, 30), Rect2i(20, 25, 18, 9),
		Rect2i(62, 26, 12, 10), Rect2i(80, 24, 8, 6),
		Rect2i(52, 2, 40, 6), Rect2i(108, 18, 10, 48),
	]:
		draw_rect(_rect(cells), civic, true)
		draw_rect(_rect(cells), Color("596267"), false, 5.0)
	# Arcade pillars and roof masses create real occlusion cadence.
	for y in range(50, 78, 6):
		draw_rect(_rect(Rect2i(30, y, 2, 4)), upper, true)
	# Wrong Street is three physical visual bands with a fixed seam.
	draw_rect(_rect(Rect2i(74, 30, 10, 24)), Color("4f575b"), false, 6.0)
	draw_rect(_rect(Rect2i(84, 30, 8, 24)), Color("5d526e"), true)
	draw_rect(_rect(Rect2i(92, 30, 16, 24)), Color("292943"), false, 8.0)
	# Imported footprint deliberately cuts across the local grid angle.
	var center := map_origin + Vector2(99, 38) * cell_size
	draw_set_transform(center, deg_to_rad(-18.0))
	draw_rect(Rect2(-190, -95, 380, 190), Color("34314d"), true)
	draw_rect(Rect2(-190, -95, 380, 190), Color("7771aa"), false, 7.0)
	draw_set_transform(Vector2.ZERO, 0.0)
