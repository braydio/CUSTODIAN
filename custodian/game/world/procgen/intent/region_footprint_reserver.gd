extends RefCounted
class_name RegionFootprintReserver

const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")


func build_reservations(graph, map_size: Vector2i) -> Dictionary:
	var floor_cells: Dictionary = {}
	var reserved_regions: Array[Dictionary] = []

	for edge in graph.edges:
		var from_node = graph.get_node_by_id(edge.from_id)
		var to_node = graph.get_node_by_id(edge.to_id)
		if from_node == null or to_node == null:
			continue
		_carve_path(floor_cells, from_node.cell, to_node.cell, edge.width_tiles, map_size)

	for node in graph.nodes:
		var rect := Rect2i(
			node.cell - Vector2i(node.radius_tiles, node.radius_tiles),
			Vector2i(node.radius_tiles * 2 + 1, node.radius_tiles * 2 + 1)
		)
		rect = rect.intersection(Rect2i(Vector2i.ZERO, map_size))
		_carve_rect(floor_cells, rect)
		reserved_regions.append({
			"id": node.id,
			"kind": IntentNodeScript.kind_to_string(node.kind),
			"rect": rect,
			"center": node.cell,
			"radius_tiles": node.radius_tiles,
			"runtime_height": node.runtime_height,
			"ascent_rank": node.ascent_rank,
			"band_id": node.band_id,
			"style_id": node.style_id,
			"faction_id": node.faction_id,
			"story_id": node.story_id,
			"required": node.required,
		})

	return {
		"floor_cells": floor_cells,
		"reserved_regions": reserved_regions,
	}


func _carve_path(floor_cells: Dictionary, from_cell: Vector2i, to_cell: Vector2i, width: int, map_size: Vector2i) -> void:
	var points := _bresenham(from_cell, to_cell)
	var radius := maxi(1, int(floor(float(width) * 0.5)))
	for point in points:
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if Vector2i(dx, dy).length_squared() > radius * radius:
					continue
				var cell := point + Vector2i(dx, dy)
				if Rect2i(Vector2i.ZERO, map_size).has_point(cell):
					floor_cells[cell] = true


func _carve_rect(floor_cells: Dictionary, rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			floor_cells[Vector2i(x, y)] = true


func _bresenham(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return points
