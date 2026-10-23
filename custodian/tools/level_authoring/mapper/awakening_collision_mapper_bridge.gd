class_name AwakeningCollisionMapperBridge
extends RefCounted

## Awakening-only bridge between the instantiated production scene and an
## authoring draft. It never writes runtime scripts, scenes, or Layout data.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const SCHEMA := "custodian.awakening_collision_draft.v1"

static func collect_colliders(root: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	_collect_node(root, root, result)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.id) < str(b.id))
	return result


static func _collect_node(node: Node, root: Node, result: Array[Dictionary]) -> void:
	if node is CollisionShape2D:
		var collision := node as CollisionShape2D
		var body := _physics_owner(collision)
		if collision.shape != null and not collision.disabled and body != null:
			var blocking := _is_blocking_body(body)
			result.append(_shape_record(collision, collision.shape, root, body, blocking))
	elif node is CollisionPolygon2D:
		var polygon := node as CollisionPolygon2D
		var body := _physics_owner(polygon)
		if body != null and not polygon.disabled and polygon.polygon.size() >= 3:
			var points := PackedVector2Array()
			for point in polygon.polygon:
				points.append(polygon.global_transform * point)
			var blocking := _is_blocking_body(body)
			result.append({
				"id": str(root.get_path_to(polygon)), "zone_id": _zone_id(polygon, root),
				"owner_id": str(root.get_path_to(body)), "kind": "CollisionPolygon2D",
				"shape": "polygon", "blocking": blocking, "physics_role": "blocker" if blocking else "trigger_or_nonblocking", "world_points": points,
				"source_transform": polygon.global_transform,
			})
	for child in node.get_children():
		_collect_node(child, root, result)


static func _physics_owner(node: Node) -> Node:
	var cursor := node.get_parent()
	while cursor != null:
		if cursor is PhysicsBody2D or cursor is Area2D:
			return cursor
		cursor = cursor.get_parent()
	return null


static func _is_blocking_body(body: Node) -> bool:
	if body is PhysicsBody2D: return (body as PhysicsBody2D).collision_layer != 0
	# Areas report overlaps and triggers; they do not physically block movement.
	return false


static func _zone_id(node: Node, root: Node) -> String:
	var cursor := node
	while cursor != null and cursor != root:
		var match_result := RegEx.create_from_string("Zone([0-9]{2})").search(String(cursor.name))
		if match_result != null:
			var zone := Layout.zone_by_index(int(match_result.get_string(1)))
			return String(zone.get("id", "shared"))
		cursor = cursor.get_parent()
	return "shared"


static func _shape_record(collision: CollisionShape2D, shape: Shape2D, root: Node, body: Node, blocking: bool) -> Dictionary:
	var points := PackedVector2Array()
	var kind := "bounds"
	if shape is RectangleShape2D:
		kind = "rectangle"
		var half := (shape as RectangleShape2D).size * 0.5
		for local_point in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
			points.append(collision.global_transform * local_point)
	elif shape is CircleShape2D:
		kind = "circle"
		var circle := shape as CircleShape2D
		for index in 32:
			var angle := TAU * float(index) / 32.0
			points.append(collision.global_transform * Vector2(cos(angle), sin(angle)) * circle.radius)
	elif shape is CapsuleShape2D:
		kind = "capsule"
		var capsule := shape as CapsuleShape2D
		var radius := capsule.radius
		var straight := maxf(0.0, capsule.height * 0.5 - radius)
		for index in 17:
			var angle := PI * float(index) / 16.0
			points.append(collision.global_transform * (Vector2(cos(angle), sin(angle)) * radius + Vector2(0, -straight)))
		for index in 17:
			var angle := PI + PI * float(index) / 16.0
			points.append(collision.global_transform * (Vector2(cos(angle), sin(angle)) * radius + Vector2(0, straight)))
	elif shape is ConvexPolygonShape2D:
		kind = "convex_polygon"
		for point in (shape as ConvexPolygonShape2D).points:
			points.append(collision.global_transform * point)
	else:
		var rect := collision.global_transform * shape.get_rect()
		points = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	return {
		"id": str(root.get_path_to(collision)), "zone_id": _zone_id(collision, root),
		"owner_id": str(root.get_path_to(body)), "kind": "CollisionShape2D",
		"shape": kind, "blocking": blocking, "physics_role": "blocker" if blocking else "trigger_or_nonblocking", "world_points": points,
		"source_transform": collision.global_transform,
	}


static func make_draft(polylines: Array, owner_id: String, purpose: String, geometry_kind: String, scene_sha: String, layout_sha: String, snap: float, proposal_metadata: Array = []) -> Dictionary:
	var proposals: Array[Dictionary] = []
	for index in polylines.size():
		var points: Array = polylines[index]
		var world_points: Array = []
		for point: Variant in points:
			if point is Vector2:
				world_points.append([point.x, point.y])
		var metadata: Dictionary = proposal_metadata[index] if index < proposal_metadata.size() and proposal_metadata[index] is Dictionary else {}
		var source_art: Variant = metadata.get("source_art", {"resource": "", "world_transform": [], "source_pixel_points": []})
		proposals.append({
			"id": str(metadata.get("id", "awakening-proposal-%03d" % (index + 1))),
			"zone_id": zone_for_point((points[0] as Vector2) if not points.is_empty() else Vector2.ZERO),
			"owner_id": str(metadata.get("owner_id", owner_id)), "purpose": str(metadata.get("purpose", purpose)), "geometry_kind": str(metadata.get("geometry_kind", geometry_kind)),
			"proposal_mode": str(metadata.get("proposal_mode", "additive")),
			"source_collision_id": str(metadata.get("source_collision_id", "")),
			"world_points_px": world_points,
			"geometry_form": _geometry_form(points),
			"bounds_px": _point_bounds(points),
			"source_art": source_art.duplicate(true) if source_art is Dictionary else source_art,
		})
	return {"schema": SCHEMA, "revision": 1.0, "base": {"scene_git_sha": scene_sha, "layout_git_sha": layout_sha}, "snap_px": snap, "proposals": proposals}


static func _geometry_form(points: Array) -> String:
	if points.size() == 2: return "segment"
	if points.size() == 4:
		var xs := {}
		var ys := {}
		for point: Vector2 in points:
			xs[point.x] = true
			ys[point.y] = true
		if xs.size() == 2 and ys.size() == 2: return "rect"
	return "polygon"


static func _point_bounds(points: Array) -> Array:
	if points.is_empty(): return []
	var vectors: Array[Vector2] = []
	for point: Variant in points:
		if point is Vector2: vectors.append(point)
	if vectors.is_empty(): return []
	var rect := _bounds(vectors)
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


static func zone_for_point(point: Vector2) -> String:
	for zone in Layout.ZONES:
		if (zone.envelope as Rect2).has_point(point):
			return String(zone.id)
	return "unknown"


static func art_provenance(root: Node, points: Array) -> Dictionary:
	if points.is_empty(): return {"resource": "", "world_transform": [], "source_pixel_points": []}
	var sprite := _sprite_for_world_point(root, points[0] as Vector2)
	return art_provenance_for_sprite(sprite, points)


static func art_provenance_for_sprite(sprite: Sprite2D, points: Array) -> Dictionary:
	if sprite == null or sprite.texture == null or points.is_empty():
		return {"resource": "", "world_transform": [], "source_pixel_points": []}
	var source_points: Array = []
	var source_rect := sprite.get_rect()
	for world_point: Variant in points:
		var local := sprite.to_local(world_point as Vector2)
		var normalized := Vector2(
			(local.x - source_rect.position.x) / maxf(0.001, source_rect.size.x),
			(local.y - source_rect.position.y) / maxf(0.001, source_rect.size.y)
		)
		var texture_size := Vector2(sprite.texture.get_size())
		source_points.append([normalized.x * texture_size.x, normalized.y * texture_size.y])
	var transform := sprite.global_transform
	return {
		"resource": sprite.texture.resource_path,
		"world_transform": [transform.x.x, transform.x.y, transform.y.x, transform.y.y, transform.origin.x, transform.origin.y],
		"source_pixel_points": source_points,
	}


static func _sprite_for_world_point(root: Node, point: Vector2) -> Sprite2D:
	var candidates: Array[Sprite2D] = []
	_collect_sprites(root, candidates)
	var best: Sprite2D
	var best_area := INF
	for sprite in candidates:
		if sprite.texture == null or not sprite.visible: continue
		if sprite.get_rect().has_point(sprite.to_local(point)):
			var area := sprite.get_rect().get_area()
			if area < best_area:
				best = sprite
				best_area = area
	return best


static func _collect_sprites(node: Node, result: Array[Sprite2D]) -> void:
	if node is Sprite2D: result.append(node as Sprite2D)
	for child in node.get_children(): _collect_sprites(child, result)


static func registered_art_bounds(root: Node) -> Array[Dictionary]:
	var group := root.find_child("RegisteredComposition04_05", true, false)
	var sprites: Array[Sprite2D] = []
	if group == null: return []
	_collect_sprites(group, sprites)
	var result: Array[Dictionary] = []
	for sprite in sprites:
		if sprite.texture == null: continue
		var rect := sprite.get_rect()
		var local_corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		var world_points := PackedVector2Array()
		for point: Vector2 in local_corners: world_points.append(sprite.global_transform * point)
		result.append({"id": str(group.get_path_to(sprite)), "resource": sprite.texture.resource_path, "world_points": world_points})
	return result


static func validate_draft(draft: Variant, scene_sha: String, layout_sha: String) -> Array[String]:
	var errors: Array[String] = []
	if not draft is Dictionary or str((draft as Dictionary).get("schema", "")) != SCHEMA:
		return ["malformed_or_unknown_draft_schema"]
	var data := draft as Dictionary
	var snap: Variant = data.get("snap_px", 0.0)
	if not _finite_number(snap) or float(snap) <= 0.0:
		errors.append("invalid_snap_interval")
	var base: Variant = data.get("base")
	if not base is Dictionary:
		return ["draft_base_provenance_missing"]
	if str((base as Dictionary).get("scene_git_sha", "")) != scene_sha or str((base as Dictionary).get("layout_git_sha", "")) != layout_sha:
		errors.append("stale_scene_or_layout_sha")
	var proposals: Variant = data.get("proposals")
	if not proposals is Array:
		return errors + ["malformed_proposals"]
	var candidate_blockers: Array[Rect2] = []
	for proposal_variant: Variant in proposals:
		if not proposal_variant is Dictionary:
			errors.append("malformed_proposal")
			continue
		var proposal := proposal_variant as Dictionary
		if str(proposal.get("id", "")).strip_edges().is_empty():
			errors.append("missing_proposal_id")
		if str(proposal.get("proposal_mode", "")) not in ["additive", "replace_existing"]:
			errors.append("invalid_proposal_mode")
		var source_art: Variant = proposal.get("source_art")
		if not source_art is Dictionary:
			errors.append("source_art_provenance_missing")
		else:
			var art := source_art as Dictionary
			var transform: Variant = art.get("world_transform")
			var source_points: Variant = art.get("source_pixel_points")
			if not art.has("resource") or typeof(art.get("resource")) != TYPE_STRING or not transform is Array or not source_points is Array:
				errors.append("source_art_provenance_malformed")
			elif not str(art.get("resource", "")).is_empty():
				var world_points: Variant = proposal.get("world_points_px")
				if (transform as Array).size() != 6 or not world_points is Array or (source_points as Array).size() != (world_points as Array).size():
					errors.append("source_art_provenance_malformed")
				else:
					for value: Variant in transform:
						if not _finite_number(value):
							errors.append("source_art_provenance_malformed")
							break
					for source_point: Variant in source_points:
						if not source_point is Array or (source_point as Array).size() != 2:
							errors.append("source_art_provenance_malformed")
							break
						if not _finite_number(source_point[0]) or not _finite_number(source_point[1]):
							errors.append("source_art_provenance_malformed")
							break
		if str(proposal.get("owner_id", "")).strip_edges().is_empty():
			errors.append("missing_owner")
		if str(proposal.get("purpose", "")).strip_edges().is_empty():
			errors.append("missing_purpose")
		if str(proposal.get("geometry_kind", "")) not in ["floor", "void", "blocker", "decoration"]:
			errors.append("invalid_geometry_kind")
		var points: Variant = proposal.get("world_points_px")
		if not points is Array or (points as Array).size() < 2:
			errors.append("malformed_or_empty_geometry")
			continue
		var parsed_points: Array[Vector2] = []
		for raw_point: Variant in points:
			if not raw_point is Array or (raw_point as Array).size() != 2:
				errors.append("malformed_vertex")
				continue
			if not _finite_number(raw_point[0]) or not _finite_number(raw_point[1]):
				errors.append("malformed_vertex")
				continue
			parsed_points.append(Vector2(float(raw_point[0]), float(raw_point[1])))
		if parsed_points.size() != points.size():
			continue
		var zone_id := String(proposal.get("zone_id", "unknown"))
		if zone_id == "unknown" or Layout.zone_by_id(StringName(zone_id)).is_empty():
			errors.append("missing_or_unknown_zone")
		var kind := str(proposal.get("geometry_kind", ""))
		if kind in ["blocker", "void"]:
			var bounds := _bounds(parsed_points)
			candidate_blockers.append(bounds)
			for protected: Rect2 in _protected_rects():
				if bounds.intersects(protected):
					errors.append("protected_route_intersection")
					errors.append("protected_route_width_violation")
				elif bounds.grow(11.0).intersects(protected):
					errors.append("operator_11px_clearance_violation")
			for zone in Layout.ZONES:
				for marker in Layout.markers_for(StringName(zone.id)):
					if str(marker.get("kind", "")) in ["spawn", "locker", "lift"] and bounds.has_point(marker.position):
						errors.append("protected_spawn_locker_lift_overlap")
						break
	# Exact route/protected-marker failures are already terminal. The expensive
	# full occupancy search is reserved for otherwise admissible candidates.
	if not candidate_blockers.is_empty() and errors.is_empty() and not _candidate_route_exists(candidate_blockers):
		errors.append("candidate_route_or_operator_radius_failure")
	return errors


static func _candidate_route_exists(candidate_blockers: Array[Rect2]) -> bool:
	const CELL := 16.0
	const START := Vector2(0, 160)
	const GOAL := Vector2(0, -6464)
	var bounds := Layout.WORLD_BOUNDS
	var cols := int(ceil(bounds.size.x / CELL))
	var rows := int(ceil(bounds.size.y / CELL))
	var open := PackedByteArray()
	open.resize(cols * rows)
	var existing_blockers: Array[Rect2] = []
	var traversal := Layout.traversal_rects()
	for rect in Layout.blocking_rects():
		var overlaps_traversal := false
		for route_rect in traversal:
			if route_rect.intersects(rect):
				overlaps_traversal = true
				break
		if not overlaps_traversal: existing_blockers.append(rect)
	for row in rows:
		for col in cols:
			var point := bounds.position + Vector2((col + 0.5) * CELL, (row + 0.5) * CELL)
			var walkable := Layout.is_point_walkable(point)
			if walkable:
				for blocker in existing_blockers:
					if blocker.has_point(point):
						walkable = false
						break
			if walkable:
				for blocker in candidate_blockers:
					if blocker.has_point(point):
						walkable = false
						break
			open[row * cols + col] = 1 if walkable else 0
	var safe := PackedByteArray()
	safe.resize(cols * rows)
	for row in rows:
		for col in cols:
			var clear := true
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var x: int = col + dx
					var y: int = row + dy
					if x < 0 or y < 0 or x >= cols or y >= rows or open[y * cols + x] == 0:
						clear = false
						break
				if not clear: break
			safe[row * cols + col] = 1 if clear else 0
	var start := _nearest_safe(START, bounds.position, CELL, cols, rows, safe)
	var goal := _nearest_safe(GOAL, bounds.position, CELL, cols, rows, safe)
	if start.x < 0 or goal.x < 0: return false
	var start_index := start.y * cols + start.x
	var goal_index := goal.y * cols + goal.x
	var visited := PackedByteArray()
	visited.resize(cols * rows)
	var queue: PackedInt32Array = [start_index]
	visited[start_index] = 1
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		if current == goal_index: return true
		var x: int = current % cols
		var y: int = current / cols
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next_x: int = x + offset.x
			var next_y: int = y + offset.y
			if next_x < 0 or next_y < 0 or next_x >= cols or next_y >= rows: continue
			var next: int = next_y * cols + next_x
			if safe[next] == 0 or visited[next] != 0: continue
			visited[next] = 1
			queue.append(next)
	return false


static func _nearest_safe(point: Vector2, origin: Vector2, cell: float, cols: int, rows: int, safe: PackedByteArray) -> Vector2i:
	var start := Vector2i(
		clampi(int(floor((point.x - origin.x) / cell)), 0, cols - 1),
		clampi(int(floor((point.y - origin.y) / cell)), 0, rows - 1)
	)
	if safe[start.y * cols + start.x] != 0: return start
	for ring in range(1, 7):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if absi(dx) != ring and absi(dy) != ring: continue
				var x := start.x + dx
				var y := start.y + dy
				if x >= 0 and y >= 0 and x < cols and y < rows and safe[y * cols + x] != 0:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


static func _protected_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for value: Variant in Layout.CONNECTORS.values(): rects.append(value as Rect2)
	for value: Variant in Layout.THRESHOLDS.values(): rects.append(value as Rect2)
	for value: Variant in Layout.PASSAGES.values(): rects.append(value as Rect2)
	return rects


static func _bounds(points: Array[Vector2]) -> Rect2:
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	return Rect2(min_point, max_point - min_point)


static func _finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func atomic_write_readback(path: String, draft: Dictionary) -> bool:
	var json := JSON.stringify(draft, "  ")
	var parsed: Variant = JSON.parse_string(json)
	if not parsed is Dictionary or JSON.stringify(parsed, "  ") != json:
		push_warning("Awakening draft validation failed before write")
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("Awakening draft temporary file could not be opened: %s" % temp)
		return false
	file.store_string(json)
	file.close()
	file = FileAccess.open(temp, FileAccess.READ)
	if file == null:
		push_warning("Awakening draft temporary file could not be reopened: %s" % temp)
		DirAccess.remove_absolute(temp)
		return false
	var readback: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not readback is Dictionary or JSON.stringify(readback, "  ") != json:
		push_warning("Awakening draft readback differed from the serialized bytes")
		DirAccess.remove_absolute(temp)
		return false
	DirAccess.remove_absolute(path + ".bak")
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(path, path + ".bak") != OK:
		push_warning("Awakening draft backup rename failed: %s" % path)
		DirAccess.remove_absolute(temp)
		return false
	if DirAccess.rename_absolute(temp, path) != OK:
		push_warning("Awakening draft atomic rename failed: %s" % path)
		if FileAccess.file_exists(path + ".bak"): DirAccess.rename_absolute(path + ".bak", path)
		return false
	DirAccess.remove_absolute(path + ".bak")
	return true


static func write_capture_bundle(base_path: String, image: Image, payload: Dictionary) -> Dictionary:
	if base_path.strip_edges().is_empty(): return {"ok": false, "error": "output_path_empty"}
	if not base_path.is_absolute_path(): return {"ok": false, "error": "output_path_must_be_absolute"}
	if image == null or image.is_empty(): return {"ok": false, "error": "viewport_capture_unavailable"}
	var png_path := base_path + ".png"
	var json_path := base_path + ".json"
	if FileAccess.file_exists(png_path) or FileAccess.file_exists(json_path) or FileAccess.file_exists(png_path + ".tmp") or FileAccess.file_exists(json_path + ".tmp"):
		return {"ok": false, "error": "output_path_occupied"}
	var json := JSON.stringify(payload, "  ")
	var png_temp := png_path + ".tmp"
	var json_temp := json_path + ".tmp"
	DirAccess.make_dir_recursive_absolute(base_path.get_base_dir())
	if image.save_png(png_temp) != OK:
		DirAccess.remove_absolute(png_temp)
		return {"ok": false, "error": "png_write_failed"}
	var file := FileAccess.open(json_temp, FileAccess.WRITE)
	if file == null:
		DirAccess.remove_absolute(png_temp)
		return {"ok": false, "error": "json_write_failed"}
	file.store_string(json)
	file.close()
	var readback := FileAccess.open(json_temp, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(readback.get_as_text()) if readback != null else null
	if readback != null: readback.close()
	if not parsed is Dictionary or JSON.stringify(parsed, "  ") != json:
		DirAccess.remove_absolute(png_temp)
		DirAccess.remove_absolute(json_temp)
		return {"ok": false, "error": "json_readback_mismatch"}
	if DirAccess.rename_absolute(png_temp, png_path) != OK:
		DirAccess.remove_absolute(png_temp)
		DirAccess.remove_absolute(json_temp)
		return {"ok": false, "error": "png_publish_failed"}
	if DirAccess.rename_absolute(json_temp, json_path) != OK:
		DirAccess.remove_absolute(png_path)
		DirAccess.remove_absolute(json_temp)
		return {"ok": false, "error": "json_publish_failed"}
	return {"ok": true, "png_path": png_path, "json_path": json_path, "json_sha256": FileAccess.get_sha256(json_path)}
