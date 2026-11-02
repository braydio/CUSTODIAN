extends RefCounted
class_name SunderedKeepFrontageBuilder

const LANDMARK_ID := "sundered_keep_frontage"
const FRONTAGE_TAG := "sundered_keep_frontage_generated"
const GRAMMAR_ID := "curved_frontage_v1"
const MIN_ROUTE_RADIUS := 4
const SOFT_CLEARANCE_RADIUS := 6
const OCEAN_CLAIM_ID := &"sundered_keep_frontage_ocean"
const OCEAN_PROFILE := &"sundered_keep_cosmic_ocean"
const OCEAN_LATERAL_MARGIN_TILES := 18
const OCEAN_INWARD_MARGIN_TILES := 6
const VISTA_CONTRACT := preload("res://game/world/procgen/landmarks/sundered_keep/sundered_keep_vista_contract.gd")

const NEIGHBORS_8: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]


func build_frontage(
	graph,
	base_field: Dictionary,
	map_size: Vector2i,
	seed: int
) -> Dictionary:
	var semantic := _collect_semantic_nodes(graph)
	if semantic.is_empty():
		return {}
	var route_anchors := _to_vector2i_array(
		semantic.get("route_anchors", [])
	)
	if route_anchors.size() < 2:
		return {}
	var route_centerline := _build_curved_centerline(route_anchors, map_size)
	var cumulative_arc := _centerline_cumulative_arc(route_centerline)
	var cinematic_samples := {
		"first_influence_start": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.INFLUENCE_START_FROM_GATE_CELLS),
		"frontage_reveal_start": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.KEEP_DISCOVERY_FROM_GATE_CELLS),
		"first_reveal_apex": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.VISTA_APEX_FROM_GATE_CELLS),
		"vista_apex": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.VISTA_APEX_FROM_GATE_CELLS),
		"frontage_apex": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.MOONLIGHT_FROM_GATE_CELLS),
		"moonlight_anchor": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.MOONLIGHT_FROM_GATE_CELLS),
		"vista_apex_plateau_end": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.APEX_PLATEAU_END_FROM_GATE_CELLS),
		"first_return_complete": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.GAMEPLAY_RETURN_FROM_GATE_CELLS),
		"gameplay_return": _sample_centerline_from_gate_distance(route_centerline, cumulative_arc, VISTA_CONTRACT.GAMEPLAY_RETURN_FROM_GATE_CELLS),
	}
	var primary_route_cells: Dictionary = {}
	var hard_clearance_cells: Dictionary = {}
	var soft_clearance_cells: Dictionary = {}
	for index in range(route_centerline.size()):
		var point := route_centerline[index]
		var progress := float(index) / float(maxi(1, route_centerline.size() - 1))
		var radius := MIN_ROUTE_RADIUS
		if progress < 0.18 or (progress > 0.52 and progress < 0.80):
			radius += 1
		_add_disc(primary_route_cells, point, radius, map_size)
		_add_disc(hard_clearance_cells, point, MIN_ROUTE_RADIUS, map_size)
		_add_disc(soft_clearance_cells, point, SOFT_CLEARANCE_RADIUS, map_size)

	var terrace_cells: Dictionary = {}
	var terrace_specs := [
		{
			"center": route_anchors[0],
			"radius": Vector2i(8 + _seed_mod(seed, "entry_w", 3), 6),
		},
		{
			"center": semantic["overlook_anchor"],
			"radius": Vector2i(
				9 + _seed_mod(seed, "overlook_w", 4),
				6 + _seed_mod(seed, "overlook_h", 3)
			),
		},
		{
			"center": semantic["frontage_anchor"],
			"radius": Vector2i(
				10 + _seed_mod(seed, "frontage_w", 4),
				6 + _seed_mod(seed, "frontage_h", 3)
			),
		},
		{
			"center": semantic["gate_anchor"],
			"radius": Vector2i(7, 5),
		},
	]
	for spec in terrace_specs:
		_add_ellipse(
			terrace_cells,
			spec["center"],
			spec["radius"],
			map_size
		)

	var side_pocket_cells: Dictionary = {}
	var side_pocket_anchor: Vector2i = semantic["side_pocket_anchor"]
	var pocket_radius := Vector2i(
		6 + _seed_mod(seed, "pocket_w", 3),
		5 + _seed_mod(seed, "pocket_h", 2)
	)
	_add_ellipse(
		side_pocket_cells,
		side_pocket_anchor,
		pocket_radius,
		map_size
	)
	var pocket_connector := _bresenham(
		semantic["frontage_anchor"],
		side_pocket_anchor
	)
	for cell in pocket_connector:
		_add_disc(side_pocket_cells, cell, 2, map_size)

	var raw_floor := {}
	_merge_lookup(raw_floor, primary_route_cells)
	_merge_lookup(raw_floor, terrace_cells)
	_merge_lookup(raw_floor, side_pocket_cells)
	var eroded_floor := _erode_irregular_edges(
		raw_floor,
		hard_clearance_cells,
		seed
	)
	_merge_lookup(eroded_floor, hard_clearance_cells)

	var base_floor: Dictionary = base_field.get("floor_cells", {})
	var cliff_cells := _build_cliff_edge_cells(
		eroded_floor,
		base_floor,
		map_size,
		seed
	)
	var gate_anchor: Vector2i = semantic["gate_anchor"]
	var fortress_exclusion_cells: Dictionary = {}
	_add_ellipse(
		fortress_exclusion_cells,
		gate_anchor + Vector2i.UP * 3,
		Vector2i(16, 10),
		map_size
	)
	_merge_lookup(fortress_exclusion_cells, soft_clearance_cells)
	var presentation_clearance_cells: Dictionary = {}
	var presentation_limit := mini(route_centerline.size(), int((cinematic_samples["gameplay_return"] as Dictionary)["index"]) + 1)
	for index in presentation_limit:
		_add_disc(
			presentation_clearance_cells,
			route_centerline[index],
			9,
			map_size
		)
	for apex_name in ["vista_apex", "vista_apex_plateau_end"]:
		_add_disc(
			presentation_clearance_cells,
			(cinematic_samples[apex_name] as Dictionary)["cell"],
			15,
			map_size
		)
	_merge_lookup(presentation_clearance_cells, hard_clearance_cells)

	var camera_anchors := {
		"frontage_entry": _sample_centerline(route_centerline, 0.00),
		"gate_threshold": gate_anchor,
	}
	var camera_semantic_indices := {"frontage_entry": 0, "gate_threshold": route_centerline.size() - 1}
	for semantic_name in cinematic_samples:
		camera_anchors[semantic_name] = (cinematic_samples[semantic_name] as Dictionary)["cell"]
		camera_semantic_indices[semantic_name] = int((cinematic_samples[semantic_name] as Dictionary)["index"])
	var camera_distance_contract := {
		"influence_start_from_gate": float((cinematic_samples["first_influence_start"] as Dictionary)["actual_distance_from_gate"]),
		"keep_discovery_from_gate": float((cinematic_samples["frontage_reveal_start"] as Dictionary)["actual_distance_from_gate"]),
		"vista_apex_from_gate": float((cinematic_samples["vista_apex"] as Dictionary)["actual_distance_from_gate"]),
		"moonlight_from_gate": float((cinematic_samples["moonlight_anchor"] as Dictionary)["actual_distance_from_gate"]),
		"apex_end_from_gate": float((cinematic_samples["vista_apex_plateau_end"] as Dictionary)["actual_distance_from_gate"]),
		"gameplay_return_from_gate": float((cinematic_samples["gameplay_return"] as Dictionary)["actual_distance_from_gate"]),
	}
	var vista_commit_cells := _cross_section_cells(
		eroded_floor,
		route_centerline,
		0.56,
		1
	)
	var mandatory_separator_cells: Dictionary = {}
	for cell_variant in vista_commit_cells.keys():
		var cell := cell_variant as Vector2i
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + direction
			if not eroded_floor.has(neighbor):
				mandatory_separator_cells[neighbor] = true
	var terminal_apron_cells: Dictionary = {}
	_add_disc(terminal_apron_cells, gate_anchor, 5, map_size)
	for cell_variant in terminal_apron_cells.keys():
		if not eroded_floor.has(cell_variant):
			terminal_apron_cells.erase(cell_variant)
	var visual_anchors := {
		"fortress_front_anchor": gate_anchor + Vector2i.UP * 8,
		"tower_anchor_a": gate_anchor + Vector2i(-10, -7),
		"tower_anchor_b": gate_anchor + Vector2i(10, -6),
		"wall_run_anchor": semantic["frontage_anchor"] + Vector2i.UP * 5,
		"collapsed_parapet_anchor": semantic["overlook_anchor"] \
			+ Vector2i(-5, -2),
		"foreground_occluder_anchors": [
			semantic["overlook_anchor"] + Vector2i(-8, 5),
			semantic["frontage_anchor"] + Vector2i(7, 5),
		],
		"fog_seam_anchors": [
			semantic["overlook_anchor"] + Vector2i.UP * 3,
			semantic["frontage_anchor"] + Vector2i.UP * 3,
			gate_anchor + Vector2i.UP * 2,
		],
	}
	var ocean_claim := _build_ocean_surface_claim(
		eroded_floor,
		gate_anchor,
		camera_anchors,
		map_size
	)
	var encounter_anchor := _sample_centerline(route_centerline, 0.55)
	return {
		"schema": "custodian.procgen.sundered_keep_frontage.v1",
		"landmark_id": StringName(LANDMARK_ID),
		"grammar_id": StringName(GRAMMAR_ID),
		"seed": seed,
		"gate_anchor": gate_anchor,
		"fortress_outward_direction": Vector2i.UP,
		"route_centerline": route_centerline,
		"primary_route_cells": primary_route_cells,
		"hard_clearance_cells": hard_clearance_cells,
		"soft_clearance_cells": soft_clearance_cells,
		"terrace_cells": terrace_cells,
		"side_pocket_cells": side_pocket_cells,
		"vista_commit_cells": vista_commit_cells,
		"mandatory_separator_cells": mandatory_separator_cells,
		"terminal_apron_cells": terminal_apron_cells,
		"cliff_cells": cliff_cells,
		"fortress_exclusion_cells": fortress_exclusion_cells,
		"presentation_clearance_cells": presentation_clearance_cells,
		"overlook_anchor": semantic["overlook_anchor"],
		"side_pocket_anchors": [side_pocket_anchor],
		"encounter_pocket_anchors": [encounter_anchor],
		"camera_semantic_anchors": camera_anchors,
		"camera_semantic_indices": camera_semantic_indices,
		"camera_distance_contract": camera_distance_contract,
		"cinematic_route_arc_total": cumulative_arc[-1] if not cumulative_arc.is_empty() else 0.0,
		"visual_module_anchors": visual_anchors,
		"surface_claims": [ocean_claim],
		"floor_cells": eroded_floor,
		"debug_summary": {
			"grammar_id": GRAMMAR_ID,
			"centerline_cells": route_centerline.size(),
			"floor_cells": eroded_floor.size(),
			"terrace_cells": terrace_cells.size(),
			"side_pocket_cells": side_pocket_cells.size(),
			"cliff_cells": cliff_cells.size(),
			"vista_commit_cells": vista_commit_cells.size(),
			"ocean_claim_id": String(OCEAN_CLAIM_ID),
			"ocean_claim_profile": String(OCEAN_PROFILE),
			"ocean_claim_bounds": str(ocean_claim.get("bounds", Rect2i())),
			"rectangular_authored_footprint": false,
			"special_room_owned": false,
			"route_master_ground": false,
		},
	}


func _build_ocean_surface_claim(
	_floor_cells: Dictionary,
	gate_anchor: Vector2i,
	camera_anchors: Dictionary,
	map_size: Vector2i
) -> Dictionary:
	var min_x := gate_anchor.x
	var max_x := gate_anchor.x
	for key in [
		"first_reveal_apex",
		"frontage_reveal_start",
		"frontage_apex",
		"gameplay_return",
		"gate_threshold",
	]:
		var value: Variant = camera_anchors.get(key)
		if value is Vector2i:
			var cell := value as Vector2i
			min_x = mini(min_x, cell.x)
			max_x = maxi(max_x, cell.x)
	min_x = maxi(0, min_x - OCEAN_LATERAL_MARGIN_TILES)
	max_x = mini(map_size.x - 1, max_x + OCEAN_LATERAL_MARGIN_TILES)
	var reveal_start: Vector2i = camera_anchors.get(
		"frontage_reveal_start", gate_anchor
	)
	var bottom_y := clampi(
		reveal_start.y + OCEAN_INWARD_MARGIN_TILES,
		gate_anchor.y + 4,
		map_size.y - 1
	)
	return {
		"id": OCEAN_CLAIM_ID,
		"kind": &"ocean",
		"profile": OCEAN_PROFILE,
		"seed_edge": &"north",
		"must_touch_map_edge": true,
		"bounds": Rect2i(
			Vector2i(min_x, 0),
			Vector2i(max_x - min_x + 1, bottom_y + 1)
		),
	}


func _cross_section_cells(
	floor_cells: Dictionary,
	centerline: Array[Vector2i],
	progress: float,
	half_depth: int
) -> Dictionary:
	var result: Dictionary = {}
	if centerline.size() < 3:
		return result
	var index := clampi(
		int(round(progress * float(centerline.size() - 1))),
		1,
		centerline.size() - 2
	)
	var center := centerline[index]
	var tangent := centerline[index + 1] - centerline[index - 1]
	var normal := Vector2i(-signi(tangent.y), signi(tangent.x))
	if normal == Vector2i.ZERO:
		normal = Vector2i.RIGHT
	var pending: Array[Vector2i] = []
	for depth in range(-half_depth, half_depth + 1):
		var slice_center := center + Vector2i(signi(tangent.x), signi(tangent.y)) * depth
		pending.append(slice_center)
		for direction in [normal, -normal]:
			var cursor: Vector2i = slice_center + direction
			while floor_cells.has(cursor):
				pending.append(cursor)
				cursor += direction
	for cell in pending:
		if floor_cells.has(cell):
			result[cell] = true
	return result


func _collect_semantic_nodes(graph) -> Dictionary:
	var entry = null
	var overlook = null
	var frontage = null
	var compression = null
	var gate = null
	var side_pocket = null
	for node in graph.nodes:
		if node.tags.has("sundered_keep_frontage_entry"):
			entry = node
		if not node.tags.has(FRONTAGE_TAG):
			continue
		if node.id == "sundered_keep_overlook":
			overlook = node
		elif node.id == "sundered_keep_outer_wall":
			frontage = node
		elif node.id == "sundered_keep_gate_compression":
			compression = node
		elif node.id == LANDMARK_ID:
			gate = node
		elif node.id == "sundered_keep_side_pocket":
			side_pocket = node
	if (
		entry == null
		or overlook == null
		or frontage == null
		or compression == null
		or gate == null
		or side_pocket == null
	):
		return {}
	return {
		"route_anchors": [
			entry.cell,
			overlook.cell,
			frontage.cell,
			compression.cell,
			gate.cell,
		],
		"overlook_anchor": overlook.cell,
		"frontage_anchor": frontage.cell,
		"gate_anchor": gate.cell,
		"side_pocket_anchor": side_pocket.cell,
	}


func _build_curved_centerline(
	anchors: Array[Vector2i],
	map_size: Vector2i
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var seen := {}
	for index in range(anchors.size() - 1):
		for point in _bresenham(anchors[index], anchors[index + 1]):
			if not Rect2i(Vector2i.ZERO, map_size).has_point(point):
				continue
			if seen.has(point):
				continue
			seen[point] = true
			result.append(point)
	return result


func _erode_irregular_edges(
	raw_floor: Dictionary,
	hard_clearance: Dictionary,
	seed: int
) -> Dictionary:
	var result := raw_floor.duplicate()
	for cell_variant in raw_floor.keys():
		var cell := cell_variant as Vector2i
		if hard_clearance.has(cell):
			continue
		var neighbor_count := 0
		for offset in NEIGHBORS_8:
			if raw_floor.has(cell + offset):
				neighbor_count += 1
		if neighbor_count >= 7:
			continue
		var roll := _cell_roll(seed, cell, "edge_erosion")
		var threshold := 0.20 if neighbor_count >= 5 else 0.34
		if roll < threshold:
			result.erase(cell)
	return result


func _build_cliff_edge_cells(
	frontage_floor: Dictionary,
	base_floor: Dictionary,
	map_size: Vector2i,
	seed: int
) -> Dictionary:
	var cliffs := {}
	for cell_variant in frontage_floor.keys():
		var cell := cell_variant as Vector2i
		for offset in NEIGHBORS_8:
			var neighbor := cell + offset
			if not Rect2i(Vector2i.ONE, map_size - Vector2i(2, 2)).has_point(
				neighbor
			):
				continue
			if frontage_floor.has(neighbor) or base_floor.has(neighbor):
				continue
			if _cell_roll(seed, neighbor, "cliff") < 0.72:
				cliffs[neighbor] = true
	return cliffs


func _add_disc(
	target: Dictionary,
	center: Vector2i,
	radius: int,
	map_size: Vector2i
) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var offset := Vector2i(x, y)
			if offset.length_squared() > radius * radius:
				continue
			var cell := center + offset
			if Rect2i(Vector2i.ZERO, map_size).has_point(cell):
				target[cell] = true


func _add_ellipse(
	target: Dictionary,
	center: Vector2i,
	radius: Vector2i,
	map_size: Vector2i
) -> void:
	for y in range(-radius.y, radius.y + 1):
		for x in range(-radius.x, radius.x + 1):
			var normalized := Vector2(
				float(x) / float(maxi(1, radius.x)),
				float(y) / float(maxi(1, radius.y))
			)
			if normalized.length_squared() > 1.0:
				continue
			var cell := center + Vector2i(x, y)
			if Rect2i(Vector2i.ZERO, map_size).has_point(cell):
				target[cell] = true


func _sample_centerline(
	centerline: Array[Vector2i],
	progress: float
) -> Vector2i:
	if centerline.is_empty():
		return Vector2i.ZERO
	var index := clampi(
		int(round(clampf(progress, 0.0, 1.0) * (centerline.size() - 1))),
		0,
		centerline.size() - 1
	)
	return centerline[index]


func _centerline_cumulative_arc(centerline: Array[Vector2i]) -> PackedFloat32Array:
	var cumulative := PackedFloat32Array()
	if centerline.is_empty():
		return cumulative
	cumulative.append(0.0)
	for index in range(1, centerline.size()):
		cumulative.append(cumulative[-1] + Vector2(centerline[index] - centerline[index - 1]).length())
	return cumulative


func _sample_centerline_from_gate_distance(
	centerline: Array[Vector2i],
	cumulative: PackedFloat32Array,
	distance_from_gate_cells: float
) -> Dictionary:
	if centerline.is_empty() or cumulative.is_empty():
		return {"cell": Vector2i.ZERO, "index": 0, "actual_distance_from_gate": 0.0}
	var total := cumulative[-1]
	var target_arc := maxf(0.0, total - distance_from_gate_cells)
	var best_index := 0
	var best_delta := INF
	for index in range(cumulative.size()):
		var delta := absf(cumulative[index] - target_arc)
		if delta < best_delta:
			best_delta = delta
			best_index = index
	return {
		"cell": centerline[best_index],
		"index": best_index,
		"actual_distance_from_gate": total - cumulative[best_index],
	}


func _merge_lookup(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = true


func _to_vector2i_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not value is Array:
		return result
	for entry in value:
		if entry is Vector2i:
			result.append(entry as Vector2i)
	return result


func _seed_mod(seed: int, label: String, modulus: int) -> int:
	return int(abs(("%d:%s" % [seed, label]).hash())) % maxi(1, modulus)


func _cell_roll(seed: int, cell: Vector2i, label: String) -> float:
	var basis := int(abs(("%d:%d:%d:%s" % [
		seed,
		cell.x,
		cell.y,
		label,
	]).hash()))
	return float(basis % 10000) / 10000.0


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
	var error := dx + dy
	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var twice_error := 2 * error
		if twice_error >= dy:
			error += dy
			x0 += sx
		if twice_error <= dx:
			error += dx
			y0 += sy
	return points
