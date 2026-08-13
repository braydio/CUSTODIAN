class_name OceanShoreTopologyResolver
extends RefCounted

const N := 1
const E := 2
const S := 4
const W := 8

const CARDINAL_BY_BIT := {
	N: Vector2i.UP,
	E: Vector2i.RIGHT,
	S: Vector2i.DOWN,
	W: Vector2i.LEFT,
}


static func resolve(cell: Vector2i, floor_cells: Dictionary) -> Array[String]:
	var mask := cardinal_mask(cell, floor_cells)
	match mask:
		0:
			return _resolve_convex_diagonal(cell, floor_cells)
		N:
			return [_edge_or_endcap(cell, floor_cells, N, "n")]
		E:
			return [_edge_or_endcap(cell, floor_cells, E, "e")]
		S:
			return [_edge_or_endcap(cell, floor_cells, S, "s")]
		W:
			return [_edge_or_endcap(cell, floor_cells, W, "w")]
		N | E:
			return ["inner_corner_ne"]
		N | W:
			return ["inner_corner_nw"]
		S | E:
			return ["inner_corner_se"]
		S | W:
			return ["inner_corner_sw"]
		N | E | S:
			return ["t_junction_w"]
		N | E | W:
			return ["t_junction_s"]
		N | S | W:
			return ["t_junction_e"]
		E | S | W:
			return ["t_junction_n"]
		N | S:
			return ["shore_n", "shore_s"]
		E | W:
			return ["shore_e", "shore_w"]
		N | E | S | W:
			return ["shore_n", "shore_e", "shore_s", "shore_w"]
	return []


static func cardinal_mask(cell: Vector2i, floor_cells: Dictionary) -> int:
	var result := 0
	for bit in CARDINAL_BY_BIT:
		if floor_cells.has(cell + (CARDINAL_BY_BIT[bit] as Vector2i)):
			result |= int(bit)
	return result


static func _resolve_convex_diagonal(cell: Vector2i, floor_cells: Dictionary) -> Array[String]:
	if floor_cells.has(cell + Vector2i(1, -1)):
		return ["corner_ne"]
	if floor_cells.has(cell + Vector2i(-1, -1)):
		return ["corner_nw"]
	if floor_cells.has(cell + Vector2i(1, 1)):
		return ["corner_se"]
	if floor_cells.has(cell + Vector2i(-1, 1)):
		return ["corner_sw"]
	return []


static func _edge_or_endcap(
	cell: Vector2i,
	floor_cells: Dictionary,
	contact_bit: int,
	direction_name: String
) -> String:
	var tangent := Vector2i.RIGHT if contact_bit == N or contact_bit == S else Vector2i.DOWN
	var continuation_count := 0
	for offset in [-tangent, tangent]:
		if cardinal_mask(cell + offset, floor_cells) & contact_bit:
			continuation_count += 1
	return ("shore_" if continuation_count >= 2 else "endcap_") + direction_name
