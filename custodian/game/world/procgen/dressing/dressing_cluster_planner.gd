extends RefCounted
class_name DressingClusterPlanner


func build_plan(context: Dictionary, catalog: DressingClusterCatalog) -> Dictionary:
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var candidates: Array[Dictionary] = []
	var profiles := _eligible_profiles(catalog, context)
	for profile in profiles:
		var anchors := _candidate_anchors(profile, context)
		for anchor in anchors:
			candidates.append({"profile": profile, "anchor": anchor})
	var seed := int(context.get("seed", 0))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left: DressingClusterProfile = a.profile
		var right: DressingClusterProfile = b.profile
		var left_anchor: Vector2i = a.anchor
		var right_anchor: Vector2i = b.anchor
		var left_hash := _stable_hash(seed, String(left.cluster_id), left_anchor)
		var right_hash := _stable_hash(seed, String(right.cluster_id), right_anchor)
		if left_hash != right_hash:
			return left_hash < right_hash
		if left_anchor.y != right_anchor.y:
			return left_anchor.y < right_anchor.y
		if left_anchor.x != right_anchor.x:
			return left_anchor.x < right_anchor.x
		return String(left.cluster_id) < String(right.cluster_id)
	)
	var target_count := _target_count(context, floor_cells)
	var placements: Array[Dictionary] = []
	var occupied_cells: Dictionary = {}
	var suppression_cells: Dictionary = {}
	var child_by_cell: Dictionary = {}
	var counts_by_profile: Dictionary = {}
	var remaining := candidates
	var choice_index := 0
	while placements.size() < target_count and not remaining.is_empty():
		var eligible_profiles: Array[DressingClusterProfile] = []
		var profile_candidate_count: Dictionary = {}
		for candidate in remaining:
			var profile: DressingClusterProfile = candidate.profile
			if int(counts_by_profile.get(profile.cluster_id, 0)) >= profile.max_instances_per_map:
				continue
			var anchor: Vector2i = candidate.anchor
			if not _fits_spacing_and_footprint(profile, anchor, placements, occupied_cells):
				continue
			profile_candidate_count[profile.cluster_id] = int(profile_candidate_count.get(profile.cluster_id, 0)) + 1
			if not eligible_profiles.has(profile):
				eligible_profiles.append(profile)
		eligible_profiles.sort_custom(func(a: DressingClusterProfile, b: DressingClusterProfile) -> bool:
			return String(a.cluster_id) < String(b.cluster_id)
		)
		if eligible_profiles.is_empty():
			break
		var total_weight := 0
		for profile in eligible_profiles:
			total_weight += profile.weight
		var ticket := _stable_hash(seed, "profile:%d" % choice_index, Vector2i(placements.size(), floor_cells.size())) % maxi(1, total_weight)
		var selected_profile := eligible_profiles[0]
		for profile in eligible_profiles:
			if ticket < profile.weight:
				selected_profile = profile
				break
			ticket -= profile.weight
		var selected_candidate: Dictionary = {}
		for candidate in remaining:
			var profile: DressingClusterProfile = candidate.profile
			if profile.cluster_id != selected_profile.cluster_id:
				continue
			var anchor: Vector2i = candidate.anchor
			if _fits_spacing_and_footprint(profile, anchor, placements, occupied_cells):
				selected_candidate = candidate
				break
		if selected_candidate.is_empty():
			remaining = remaining.filter(func(c: Dictionary) -> bool:
				return (c.profile as DressingClusterProfile).cluster_id != selected_profile.cluster_id
			)
			continue
		remaining.erase(selected_candidate)
		var selected_anchor: Vector2i = selected_candidate.anchor
		var footprint: Array[Vector2i] = []
		for offset in selected_profile.footprint_cells:
			var cell := selected_anchor + offset
			footprint.append(cell)
			occupied_cells[cell] = true
		for offset in selected_profile.suppression_cells:
			suppression_cells[selected_anchor + offset] = true
		var children: Array[Dictionary] = []
		for child in selected_profile.children:
			var child_cell := selected_anchor + child.offset_cells
			var child_record := {
				"kind": child.foliage_kind(),
				"required": child.required,
				"cell": child_cell,
			}
			children.append(child_record)
			child_by_cell[child_cell] = {
				"cluster_id": selected_profile.cluster_id,
				"kind": child.foliage_kind(),
				"required": child.required,
			}
		placements.append({
			"cluster_id": selected_profile.cluster_id,
			"anchor": selected_anchor,
			"footprint_cells": footprint,
			"children": children,
		})
		counts_by_profile[selected_profile.cluster_id] = int(counts_by_profile.get(selected_profile.cluster_id, 0)) + 1
		choice_index += 1
	var fingerprint := _fingerprint(seed, placements, counts_by_profile)
	return {
		"placements": placements,
		"child_by_cell": child_by_cell,
		"occupied_cells": occupied_cells,
		"suppression_cells": suppression_cells,
		"counts_by_profile": counts_by_profile,
		"target_cluster_count": target_count,
		"placed_cluster_count": placements.size(),
		"fingerprint": fingerprint,
	}


func _eligible_profiles(catalog: DressingClusterCatalog, context: Dictionary) -> Array[DressingClusterProfile]:
	var result: Array[DressingClusterProfile] = []
	if catalog == null:
		return result
	var biomes: Dictionary = context.get("biome_by_cell", {})
	var materials: Dictionary = context.get("surface_material_by_cell", {})
	var seen: Dictionary = {}
	for cell_variant in biomes.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var biome := StringName(biomes[cell])
		var material := StringName(materials.get(cell, &""))
		for profile in catalog.filter_profiles(biome, material):
			if not seen.has(profile.cluster_id):
				seen[profile.cluster_id] = true
				result.append(profile)
	result.sort_custom(func(a: DressingClusterProfile, b: DressingClusterProfile) -> bool:
		return String(a.cluster_id) < String(b.cluster_id)
	)
	return result


func _candidate_anchors(profile: DressingClusterProfile, context: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var floors: Dictionary = context.get("floor_cells", {})
	var biomes: Dictionary = context.get("biome_by_cell", {})
	var materials: Dictionary = context.get("surface_material_by_cell", {})
	var sparse: Dictionary = context.get("sparse_dressing_cells", {})
	var deep: Dictionary = context.get("deep_dressing_cells", {})
	for value in floors.keys():
		if not value is Vector2i:
			continue
		var anchor := value as Vector2i
		if not _cell_is_safe(anchor, profile, context):
			continue
		if StringName(biomes.get(anchor, &"")) != profile.required_biome:
			continue
		if not profile.allowed_surface_materials.has(String(materials.get(anchor, &""))):
			continue
		if not _cell_in_allowed_band(anchor, profile, sparse, deep):
			continue
		var children_fit := true
		for child in profile.children:
			var child_cell := anchor + child.offset_cells
			if not _cell_is_safe(child_cell, profile, context):
				children_fit = false
				break
		if children_fit:
			result.append(anchor)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ah := _stable_hash(int(context.get("seed", 0)), String(profile.cluster_id), a)
		var bh := _stable_hash(int(context.get("seed", 0)), String(profile.cluster_id), b)
		if ah != bh: return ah < bh
		if a.y != b.y: return a.y < b.y
		return a.x < b.x
	)
	return result


func _cell_in_allowed_band(cell: Vector2i, profile: DressingClusterProfile, sparse: Dictionary, deep: Dictionary) -> bool:
	return (profile.allow_sparse_band and sparse.has(cell)) or (profile.allow_deep_band and deep.has(cell))


func _cell_is_safe(cell: Vector2i, profile: DressingClusterProfile, context: Dictionary) -> bool:
	var floors: Dictionary = context.get("floor_cells", {})
	if not floors.has(cell): return false
	var foliage_safe: Dictionary = context.get("foliage_authored_safe_cells", {})
	if not foliage_safe.is_empty() and not foliage_safe.has(cell): return false
	for key in ["wall_cells", "chasm_cells", "ocean_cells", "route_hard_clearance_cells", "route_shoulder_cells", "road_cells", "parking_cells", "service_hardstand_cells", "encounter_reserved_cells", "authored_cells", "reserved_cells", "ingress_dressing_clearance_cells", "macro_dressing_clearance_cells", "indoor_cells"]:
		if (context.get(key, {}) as Dictionary).has(cell): return false
	var predicate: Callable = context.get("is_indoor_cell", Callable())
	if predicate.is_valid() and bool(predicate.call(cell)): return false
	predicate = context.get("is_encounter_reserved_cell", Callable())
	if predicate.is_valid() and bool(predicate.call(cell)): return false
	return true


func _fits_spacing_and_footprint(profile: DressingClusterProfile, anchor: Vector2i, placements: Array[Dictionary], occupied_cells: Dictionary) -> bool:
	for offset in profile.footprint_cells:
		if occupied_cells.has(anchor + offset): return false
	var minimum_squared := profile.min_anchor_spacing_cells * profile.min_anchor_spacing_cells
	for placement in placements:
		var prior: Vector2i = placement.anchor
		if anchor.distance_squared_to(prior) < minimum_squared: return false
	return true


func _target_count(context: Dictionary, floor_cells: Dictionary) -> int:
	var area := int(context.get("map_area", 0))
	if area <= 0:
		var max_x := 0
		var max_y := 0
		for value in floor_cells.keys():
			if value is Vector2i:
				max_x = maxi(max_x, (value as Vector2i).x)
				max_y = maxi(max_y, (value as Vector2i).y)
		area = (max_x + 1) * (max_y + 1)
	return clampi(roundi(float(area) / 4096.0), 4, 12)


func _stable_hash(seed: int, label: String, cell: Vector2i) -> int:
	var value := 2166136261 ^ (seed & 0x7fffffff)
	var bytes := (label + ":" + str(cell.x) + ":" + str(cell.y)).to_utf8_buffer()
	for byte in bytes:
		value = int((value ^ int(byte)) * 16777619) & 0x7fffffff
	return value


func _fingerprint(seed: int, placements: Array[Dictionary], counts: Dictionary) -> String:
	var canonical: Array[Dictionary] = []
	for placement in placements:
		var children: Array[String] = []
		for child in placement.children:
			children.append("%s@%d,%d" % [String(child.kind), child.cell.x, child.cell.y])
		canonical.append({"id": String(placement.cluster_id), "anchor": placement.anchor, "children": children})
	var data := {"seed": seed, "placements": canonical, "counts": counts}
	var hashing := HashingContext.new()
	_hashing_start(hashing, data)
	return hashing.finish().hex_encode()


func _hashing_start(hashing: HashingContext, data: Dictionary) -> void:
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(JSON.stringify(data).to_utf8_buffer())
