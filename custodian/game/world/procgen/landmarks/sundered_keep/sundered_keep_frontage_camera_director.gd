extends RefCounted
class_name SunderedKeepFrontageCameraDirector

const VISTA_CONTRACT := preload("res://game/world/procgen/landmarks/sundered_keep/sundered_keep_vista_contract.gd")


func evaluate(
	operator_position: Vector2,
	centerline_cells: Array,
	centerline_world: PackedVector2Array,
	influence_start_index: int
) -> Dictionary:
	var projection := project_onto_centerline(operator_position, centerline_cells, centerline_world)
	var route_arc := float(projection.get("route_arc_cells", 0.0))
	var influence_arc := _arc_at_index(centerline_cells, influence_start_index)
	var route_s := route_arc - influence_arc
	var corridor_distance := sqrt(float(projection.get("distance_squared", INF)))
	var camera_weight := VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.CAMERA_WEIGHT_KEYS, route_s)
	if corridor_distance > 256.0:
		camera_weight = 0.0
	return {
		"route_s_cells": route_s,
		"distance_to_centerline": corridor_distance,
		"camera_weight": camera_weight,
		"camera_zoom_target": VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.CAMERA_ZOOM_KEYS, route_s),
		"camera_offset_target": Vector2(0.0, VISTA_CONTRACT.sample_spatial_key_curve(VISTA_CONTRACT.CAMERA_OFFSET_Y_KEYS, route_s)),
	}


func project_onto_centerline(point: Vector2, cells: Array, world_points: PackedVector2Array) -> Dictionary:
	if cells.is_empty() or world_points.is_empty() or cells.size() != world_points.size():
		return {"route_arc_cells": 0.0, "distance_squared": INF, "segment_index": -1, "t": 0.0}
	var cumulative := 0.0
	var best := {"route_arc_cells": 0.0, "distance_squared": INF, "segment_index": 0, "t": 0.0}
	for index in range(world_points.size() - 1):
		var world_segment := world_points[index + 1] - world_points[index]
		var world_length_squared := world_segment.length_squared()
		var t := 0.0
		if world_length_squared > 0.001:
			t = clampf((point - world_points[index]).dot(world_segment) / world_length_squared, 0.0, 1.0)
		var projected := world_points[index] + world_segment * t
		var distance_squared := point.distance_squared_to(projected)
		var tile_length := Vector2((cells[index + 1] as Vector2i) - (cells[index] as Vector2i)).length()
		if distance_squared < float(best["distance_squared"]):
			best = {"route_arc_cells": cumulative + tile_length * t, "distance_squared": distance_squared, "segment_index": index, "t": t}
		cumulative += tile_length
	return best


func _arc_at_index(cells: Array, target_index: int) -> float:
	var total := 0.0
	for index in range(clampi(target_index, 0, cells.size() - 1)):
		total += Vector2((cells[index + 1] as Vector2i) - (cells[index] as Vector2i)).length()
	return total
