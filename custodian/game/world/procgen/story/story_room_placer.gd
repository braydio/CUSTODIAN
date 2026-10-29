extends RefCounted
class_name StoryRoomPlacer

const StoryRoomTemplateScript := preload("res://game/world/procgen/story/story_room_template.gd")
const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")
const SITE_SCHEMA_VERSION := 1
const SITE_IDENTITY_VERSION := "es1-story-site-v1"


func place_story_rooms(context: Dictionary) -> Array[Dictionary]:
	var projection := project_story_rooms(context)
	var sites: Array[Dictionary] = []
	for site in projection.get("sites", []):
		if site is Dictionary:
			sites.append(site)
	return sites


## Projects intent reservations into normalized story-site records. Legacy
## generated worlds retain the former cell-sampled metadata path; intent-enabled
## worlds never fall back to independent marker selection.
func project_story_rooms(context: Dictionary) -> Dictionary:
	if bool(context.get("worldgen_intent_enabled", false)):
		return _project_reserved_story_rooms(context)
	return {
		"sites": _place_legacy_story_rooms(context),
		"skipped": [],
	}


func _project_reserved_story_rooms(context: Dictionary) -> Dictionary:
	var reservations: Array = context.get("reserved_regions", [])
	var map_size: Vector2i = context.get("map_size", Vector2i.ZERO)
	var identity_seed := int(context.get("identity_seed", context.get("seed", 0)))
	var region_identity := String(context.get("region_identity", ""))
	var max_sites := maxi(0, int(context.get("count", 6)))
	var blocked := _lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var protected := _lookup(_normalize_cell_array(context.get("required_cells", [])))
	var collision := _lookup(_normalize_cell_array(context.get("collision_cells", [])))
	var void_cells := _lookup(_normalize_cell_array(context.get("void_cells", [])))
	var intent_graph: Variant = context.get("intent_graph")
	var story_reservations: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	for reservation in reservations:
		if reservation is Dictionary and String(reservation.get("kind", "")) == "story_room":
			story_reservations.append((reservation as Dictionary).duplicate(true))
	story_reservations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _reservation_sort_key(a) < _reservation_sort_key(b)
	)

	var id_counts: Dictionary = {}
	for reservation in story_reservations:
		var node_id := String(reservation.get("id", ""))
		if not node_id.is_empty():
			id_counts[node_id] = int(id_counts.get(node_id, 0)) + 1

	var accepted: Array[Dictionary] = []
	var accepted_rects: Array[Rect2i] = []
	for reservation in story_reservations:
		var node_id := String(reservation.get("id", ""))
		var reason := _reservation_rejection_reason(
			reservation,
			map_size,
			int(id_counts.get(node_id, 0)),
			blocked,
			protected,
			collision,
			void_cells,
			intent_graph
		)
		if not reason.is_empty():
			skipped.append(_skip_record(node_id, reason))
			continue
		var rect: Rect2i = reservation.get("rect")
		var overlapping := false
		for other_rect in accepted_rects:
			if rect.intersects(other_rect):
				overlapping = true
				break
		if overlapping:
			skipped.append(_skip_record(node_id, "overlapping_story_rect"))
			continue
		if accepted.size() >= max_sites:
			skipped.append(_skip_record(node_id, "site_count_limit"))
			continue
		var site := _normalize_site_record(reservation, identity_seed, region_identity)
		accepted.append(site)
		accepted_rects.append(rect)
	accepted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.intent_node_id) < String(b.intent_node_id)
	)
	skipped.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if String(a.intent_node_id) == String(b.intent_node_id):
			return String(a.reason) < String(b.reason)
		return String(a.intent_node_id) < String(b.intent_node_id)
	)
	return {"sites": accepted, "skipped": skipped}


func _reservation_rejection_reason(
	reservation: Dictionary,
	map_size: Vector2i,
	id_count: int,
	blocked: Dictionary,
	protected: Dictionary,
	collision: Dictionary,
	void_cells: Dictionary,
	intent_graph: Variant
) -> String:
	var node_id := String(reservation.get("id", ""))
	if node_id.is_empty():
		return "missing_intent_node_id"
	if id_count > 1:
		return "duplicate_intent_node_id"
	if not reservation.get("center") is Vector2i or not reservation.get("rect") is Rect2i:
		return "invalid_reserved_geometry"
	var center: Vector2i = reservation.center
	var rect: Rect2i = reservation.rect
	if rect.size.x <= 0 or rect.size.y <= 0 or not _rect_inside_map(rect, map_size):
		return "out_of_bounds_rect"
	if not rect.has_point(center):
		return "center_outside_rect"
	var radius := int(reservation.get("radius_tiles", -1))
	if radius < 0 or rect != Rect2i(center - Vector2i(radius, radius), Vector2i(radius * 2 + 1, radius * 2 + 1)):
		return "clipped_rect"
	var graph_reason := _intent_graph_rejection_reason(intent_graph, node_id, reservation)
	if not graph_reason.is_empty():
		return graph_reason
	if blocked.has(center):
		return "blocked_anchor"
	if _rect_contains_any(rect, protected):
		return "protected_rect_overlap"
	if _rect_contains_any(rect, collision):
		return "collision_rect_overlap"
	if _rect_contains_any(rect, void_cells):
		return "void_rect_overlap"
	return ""


func _intent_graph_rejection_reason(intent_graph: Variant, node_id: String, reservation: Dictionary) -> String:
	if intent_graph == null:
		return "missing_intent_graph"
	if not intent_graph is Object or not intent_graph.has_method("get_node_by_id"):
		return "invalid_intent_graph"
	var edges: Variant = intent_graph.get("edges")
	if not edges is Array:
		return "invalid_intent_graph"
	var node = intent_graph.get_node_by_id(node_id) if intent_graph.has_method("get_node_by_id") else null
	if node == null or int(node.kind) != IntentNodeScript.NodeKind.STORY_ROOM:
		return "missing_story_intent_node"
	if node.cell != reservation.get("center") or int(node.radius_tiles) != int(reservation.get("radius_tiles", -1)):
		return "intent_geometry_mismatch"
	for edge in edges:
		if edge.to_id == node_id and int(edge.kind) == IntentEdgeScript.EdgeKind.STORY_APPROACH \
				and intent_graph.get_node_by_id(edge.from_id) != null:
			return ""
	return "missing_story_approach"


func _rect_contains_any(rect: Rect2i, cells: Dictionary) -> bool:
	for cell_variant in cells.keys():
		if cell_variant is Vector2i and rect.has_point(cell_variant):
			return true
	return false


func _normalize_site_record(reservation: Dictionary, identity_seed: int, region_identity: String) -> Dictionary:
	var node_id := String(reservation.get("id", ""))
	var center: Vector2i = reservation.center
	var rect: Rect2i = reservation.rect
	return {
		"schema_version": SITE_SCHEMA_VERSION,
		"site_id_version": SITE_IDENTITY_VERSION,
		"site_id": _site_identity(identity_seed, region_identity, node_id),
		"scope_kind": "f02_generated_region",
		"scope_id": region_identity,
		"identity_seed": identity_seed,
		"intent_node_id": node_id,
		"cell": center,
		"rect": rect,
		"reserved_rect": rect,
		"band_id": String(reservation.get("band_id", "")),
		"dominant_style": String(reservation.get("style_id", "")),
		"faction_id": String(reservation.get("faction_id", "")),
		"story_id": String(reservation.get("story_id", "")),
		"required": bool(reservation.get("required", false)),
		"metadata_only_v1": false,
	}


func _site_identity(identity_seed: int, region_identity: String, node_id: String) -> String:
	var input := PackedByteArray()
	for part in [SITE_IDENTITY_VERSION, str(identity_seed), region_identity, node_id]:
		var encoded: PackedByteArray = String(part).to_utf8_buffer()
		input.append_array(("%d:" % encoded.size()).to_utf8_buffer())
		input.append_array(encoded)
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(input)
	return "es1:%s" % hasher.finish().hex_encode()


func _skip_record(node_id: String, reason: String) -> Dictionary:
	return {"intent_node_id": node_id, "reason": reason}


func _reservation_sort_key(reservation: Dictionary) -> String:
	var rect: Variant = reservation.get("rect", Rect2i())
	var center: Variant = reservation.get("center", Vector2i())
	return "%s|%s|%s" % [
		String(reservation.get("id", "")),
		str(rect),
		str(center),
	]


func _rect_inside_map(rect: Rect2i, map_size: Vector2i) -> bool:
	return map_size.x > 0 and map_size.y > 0 \
		and rect.position.x >= 0 and rect.position.y >= 0 \
		and rect.end.x <= map_size.x and rect.end.y <= map_size.y


func _place_legacy_story_rooms(context: Dictionary) -> Array[Dictionary]:
	var profile = context.get("world_progress_profile", null)
	if profile == null:
		return []
	var seed := int(context.get("seed", 0))
	var count := int(context.get("count", 6))
	var floor_cells := _normalize_cell_array(context.get("floor_cells", []))
	var blocked_lookup := _lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var required_lookup := _lookup(_normalize_cell_array(context.get("required_cells", [])))
	var faction_sites: Array = context.get("faction_sites", [])
	var candidates: Array[Vector2i] = []
	for cell in floor_cells:
		if blocked_lookup.has(cell) or required_lookup.has(cell):
			continue
		var progress: Dictionary = profile.get_cell_progress(cell, seed)
		if float(progress.get("distance_tiles", 0.0)) < 128.0:
			continue
		var roll := float(abs(("%d:%d:%d:story" % [seed, cell.x, cell.y]).hash()) % 100000) / 100000.0
		if roll <= float(progress.get("story_room_chance", 0.0)):
			candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return profile.get_distance_tiles(a) > profile.get_distance_tiles(b)
	)
	var templates := _default_templates()
	var rooms: Array[Dictionary] = []
	var occupied: Array[Vector2i] = []
	for cell in candidates:
		if rooms.size() >= count:
			break
		if not _far_enough(cell, occupied, 20):
			continue
		var progress: Dictionary = profile.get_cell_progress(cell, seed)
		var faction_id := _nearest_faction_site(cell, faction_sites)
		var template = _pick_template(templates, progress, faction_id, cell, seed)
		if template == null:
			continue
		rooms.append({
			"story_id": template.story_id,
			"cell": cell,
			"band_id": String(progress.get("band_id", "")),
			"dominant_style": String(progress.get("dominant_style", "")),
			"faction_id": faction_id,
			"footprint_tiles": template.footprint_tiles,
			"activity_tags": template.activity_tags.duplicate(),
			"metadata_only_v1": true,
		})
		occupied.append(cell)
	return rooms


func _default_templates() -> Array:
	return [
		StoryRoomTemplateScript.make("first_switchback_camp", ["broken_foothills", "slog_ascent"], "scavenger", Vector2i(12, 9), ["set_winch", "haul_crate", "sleep_camp"]),
		StoryRoomTemplateScript.make("erased_archive_wall", ["broken_foothills", "slog_ascent", "upper_exhaustion"], "iconoclast", Vector2i(11, 8), ["scrape_inscription", "index_relic"]),
		StoryRoomTemplateScript.make("machine_pilgrim_rest", ["slog_ascent", "upper_exhaustion"], "cult_mechanist", Vector2i(10, 10), ["pray_to_machine", "repair_wrong"]),
		StoryRoomTemplateScript.make("collapsed_stair_underpass", ["broken_foothills", "slog_ascent"], "", Vector2i(14, 8), ["collapsed_stair", "vista"]),
		StoryRoomTemplateScript.make("dead_patrol_overlook", ["slog_ascent", "upper_exhaustion"], "", Vector2i(10, 7), ["stand_watch", "dead_patrol"]),
	]


func _pick_template(templates: Array, progress: Dictionary, faction_id: String, cell: Vector2i, seed: int):
	var valid: Array = []
	for template in templates:
		if template.accepts(progress, faction_id):
			valid.append(template)
	if valid.is_empty():
		return null
	return valid[int(abs(("%d:%d:%d:%s" % [seed, cell.x, cell.y, faction_id]).hash()) % valid.size())]


func _nearest_faction_site(cell: Vector2i, faction_sites: Array) -> String:
	var best_faction := ""
	var best_dist := INF
	for site in faction_sites:
		if not site is Dictionary:
			continue
		var dist := cell.distance_squared_to((site as Dictionary).get("cell", Vector2i.ZERO))
		if dist < best_dist:
			best_dist = dist
			best_faction = String((site as Dictionary).get("faction_id", ""))
	return best_faction


func _far_enough(cell: Vector2i, occupied: Array[Vector2i], min_distance_tiles: int) -> bool:
	for other in occupied:
		if cell.distance_squared_to(other) < min_distance_tiles * min_distance_tiles:
			return false
	return true


func _lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


func _normalize_cell_array(value: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if key is Vector2i:
				cells.append(key)
	elif value is Array:
		for item in value:
			if item is Vector2i:
				cells.append(item)
	return cells
