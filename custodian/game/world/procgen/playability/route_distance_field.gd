extends RefCounted
class_name RouteDistanceField

const CARDINALS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]


func build(
	floor_cells: Dictionary,
	source_cells: Array[Vector2i],
	max_distance: int = -1
) -> Dictionary:
	var distance: Dictionary = {}
	var frontier: Array[Vector2i] = []
	var ordered_sources := source_cells.duplicate()
	ordered_sources.sort_custom(_sort_cells)

	for cell in ordered_sources:
		if not floor_cells.has(cell) or distance.has(cell):
			continue
		distance[cell] = 0
		frontier.append(cell)

	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		var next_distance := int(distance[cell]) + 1
		if max_distance >= 0 and next_distance > max_distance:
			continue

		for direction in CARDINALS:
			var neighbor := cell + direction
			if not floor_cells.has(neighbor) or distance.has(neighbor):
				continue
			distance[neighbor] = next_distance
			frontier.append(neighbor)

	return distance


func _sort_cells(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y
