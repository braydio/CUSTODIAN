class_name DirectionalAnimationFallback
extends RefCounted

const SECTOR_ORDER: Array[StringName] = [
	&"n", &"ne", &"e", &"se", &"s", &"sw", &"w", &"nw",
]
const TIE_ORDER: Array[StringName] = [
	&"s", &"n", &"e", &"w", &"se", &"sw", &"ne", &"nw",
]
const SECTOR_VECTORS := {
	&"n": Vector2.UP,
	&"ne": Vector2(0.70710678, -0.70710678),
	&"e": Vector2.RIGHT,
	&"se": Vector2(0.70710678, 0.70710678),
	&"s": Vector2.DOWN,
	&"sw": Vector2(-0.70710678, 0.70710678),
	&"w": Vector2.LEFT,
	&"nw": Vector2(-0.70710678, -0.70710678),
}


static func vector_to_sector(
	direction: Vector2,
	default_sector: StringName = &"s"
) -> StringName:
	if direction.length_squared() <= 0.0001:
		return default_sector
	var angle := wrapf(direction.angle(), 0.0, TAU)
	var sector_index := int(round(angle / (PI / 4.0))) % 8
	var angle_order: Array[StringName] = [
		&"e", &"se", &"s", &"sw", &"w", &"nw", &"n", &"ne",
	]
	return angle_order[sector_index]


static func nearest_available_sector(
	requested_sector: StringName,
	available_sectors: Array[StringName],
	previous_sector: StringName = &""
) -> StringName:
	if available_sectors.is_empty():
		return &""
	if available_sectors.has(requested_sector):
		return requested_sector

	var requested_vector: Vector2 = SECTOR_VECTORS.get(
		requested_sector,
		SECTOR_VECTORS[&"s"]
	)
	var best_dot := -INF
	var tied: Array[StringName] = []
	for candidate: StringName in available_sectors:
		if not SECTOR_VECTORS.has(candidate):
			continue
		var candidate_vector: Vector2 = SECTOR_VECTORS[candidate]
		var candidate_dot := requested_vector.dot(candidate_vector)
		if candidate_dot > best_dot + 0.0001:
			best_dot = candidate_dot
			tied.assign([candidate])
		elif is_equal_approx(candidate_dot, best_dot):
			tied.append(candidate)

	if tied.is_empty():
		return &""
	if tied.has(previous_sector):
		return previous_sector
	for candidate: StringName in TIE_ORDER:
		if tied.has(candidate):
			return candidate
	return tied[0]
