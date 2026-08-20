extends RefCounted
class_name EncounterCadencePlanner

const MAJOR_EVERY_N_COMBAT := 3
const MINOR_COUNT_MIN := 2
const MINOR_COUNT_MAX := 3
const MAJOR_COUNT_MIN := 3
const MAJOR_COUNT_MAX := 4


func build(context: Dictionary) -> Dictionary:
	var seed := int(context.get("seed", 0))
	var playability := context.get("playability", {}) as Dictionary
	var spawn_tile := context.get("spawn_tile", Vector2i.ZERO) as Vector2i
	var runtime_walkable := context.get("is_runtime_walkable", Callable()) as Callable
	var spawn_valid := context.get("is_valid_spawn_cell", Callable()) as Callable
	var hard_clearance := playability.get("hard_clearance_cells", {}) as Dictionary
	var pockets := playability.get("pockets", []) as Array
	var candidates: Array[Dictionary] = []
	var safe_progressions: Array[float] = []
	for index in pockets.size():
		var pocket := pockets[index] as Dictionary
		var progression := _progression_for(pocket, spawn_tile)
		if String(pocket.get("role", "")) == "safe_pocket":
			safe_progressions.append(progression)
		if String(pocket.get("role", "")) == "combat_pocket" and bool(pocket.get("encounter_eligible", false)):
			candidates.append({"pocket": pocket, "pocket_index": index, "progression": progression})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.progression) != float(b.progression):
			return float(a.progression) < float(b.progression)
		var ac := _pocket_center(a.pocket)
		var bc := _pocket_center(b.pocket)
		return ac.y < bc.y or (ac.y == bc.y and ac.x < bc.x)
	)
	safe_progressions.sort()
	var encounters: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var last_major_progression := -INF
	var accepted_count := 0
	for entry in candidates:
		var pocket := entry.pocket as Dictionary
		var pocket_index := int(entry.pocket_index)
		var anchors: Array[Vector2i] = []
		for cell_variant in pocket.get("encounter_spawn_cells", []) as Array:
			if not cell_variant is Vector2i:
				continue
			var cell := cell_variant as Vector2i
			if hard_clearance.has(cell):
				continue
			if spawn_valid.is_valid() and not bool(spawn_valid.call(cell)):
				continue
			if runtime_walkable.is_valid() and not bool(runtime_walkable.call(cell)):
				continue
			anchors.append(cell)
		anchors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var ah := _stable_hash(seed, pocket_index, a.x * 31 + a.y)
			var bh := _stable_hash(seed, pocket_index, b.x * 31 + b.y)
			return ah < bh or (ah == bh and (a.y < b.y or (a.y == b.y and a.x < b.x)))
		)
		if anchors.is_empty():
			skipped.append({"pocket_index": pocket_index, "reason": "no_valid_encounter_anchor"})
			continue
		var home := _resolve_home(pocket, context.get("floor_cells", {}) as Dictionary, runtime_walkable)
		if home == Vector2i(2147483647, 2147483647):
			skipped.append({"pocket_index": pocket_index, "reason": "no_valid_home_in_pocket"})
			continue
		accepted_count += 1
		var progression := float(entry.progression)
		var major_eligible := accepted_count % MAJOR_EVERY_N_COMBAT == 0
		var has_safe_break := last_major_progression == -INF or _has_safe_between(safe_progressions, last_major_progression, progression)
		var tier := "major" if major_eligible and has_safe_break else "minor"
		if tier == "major":
			last_major_progression = progression
		var rect := pocket.get("rect", Rect2i()) as Rect2i
		var min_count := MAJOR_COUNT_MIN if tier == "major" else MINOR_COUNT_MIN
		var max_count := MAJOR_COUNT_MAX if tier == "major" else MINOR_COUNT_MAX
		var count_offset := _stable_hash(seed, pocket_index, 97) % (max_count - min_count + 1)
		encounters.append({
			"encounter_id": "combat_%02d" % (encounters.size()),
			"tier": tier,
			"pocket_index": pocket_index,
			"home_tile": home,
			"anchor_tile": anchors[0],
			"leash_radius_tiles": maxi(8, ceili(float(maxi(rect.size.x, rect.size.y)) * 0.75)),
			"spawn_radius_tiles": 3,
			"activation_range_tiles": 24,
			"enemy_count_min": min_count + count_offset,
			"enemy_count_max": min_count + count_offset,
			"behavior_profile_id": &"raider_grunt",
		})
	var minor_count := 0
	var major_count := 0
	for encounter in encounters:
		if String(encounter.tier) == "major": major_count += 1
		else: minor_count += 1
	return {"schema": "custodian.procgen_encounter_plan.v1", "seed": seed, "encounters": encounters, "minor_count": minor_count, "major_count": major_count, "skipped": skipped}


func _pocket_center(pocket: Dictionary) -> Vector2i:
	var rect := pocket.get("rect", Rect2i()) as Rect2i
	return pocket.get("center", rect.get_center()) as Vector2i


func _progression_for(pocket: Dictionary, spawn_tile: Vector2i) -> float:
	for key in [&"progression_index", &"beat_index", &"progression"]:
		if pocket.has(key): return float(pocket[key])
	return float(_pocket_center(pocket).distance_squared_to(spawn_tile))


func _resolve_home(pocket: Dictionary, floor_cells: Dictionary, runtime_walkable: Callable) -> Vector2i:
	var rect := pocket.get("rect", Rect2i()) as Rect2i
	var center := _pocket_center(pocket)
	if rect.has_point(center) and floor_cells.has(center) and (not runtime_walkable.is_valid() or bool(runtime_walkable.call(center))):
		return center
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if floor_cells.has(cell) and (not runtime_walkable.is_valid() or bool(runtime_walkable.call(cell))): cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ad := a.distance_squared_to(center); var bd := b.distance_squared_to(center)
		return ad < bd or (ad == bd and (a.y < b.y or (a.y == b.y and a.x < b.x)))
	)
	return cells[0] if not cells.is_empty() else Vector2i(2147483647, 2147483647)


func _has_safe_between(safe_progressions: Array[float], from_progression: float, to_progression: float) -> bool:
	for progression in safe_progressions:
		if progression > from_progression and progression < to_progression: return true
	return false


func _stable_hash(seed: int, pocket_index: int, channel: int) -> int:
	return ("%d:%d:%d" % [seed, pocket_index, channel]).hash() & 0x7fffffff
