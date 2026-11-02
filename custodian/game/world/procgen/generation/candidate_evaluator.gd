extends RefCounted

## Evaluates already-generated candidates. This service reads candidate state;
## it never owns, promotes, or disposes the candidate Node.

const DEFAULT_SETTINGS := {
	"pre_terrain_required_connectivity_min": 0.95,
	"terrain_rescue_reject_threshold": 200,
	"min_connected_room_ratio": 0.75,
	"require_compound_ingress_connectivity": true,
}
const WORLD_INGRESS_SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")


func evaluate_candidate(map_instance: Node, level_data: Dictionary, settings: Dictionary = {}) -> Dictionary:
	var policy := _settings(settings)
	var metrics := _get_map_layout_metrics(map_instance, level_data, policy)
	if map_instance == null or _get_procgen_node(map_instance) == null:
		metrics["required_ingresses_valid"] = false
		metrics["required_ingress_failures"] = []
		return _evaluation_result(metrics, policy, false)
	var ingress_validator = WORLD_INGRESS_SPAWNER_SCRIPT.new()
	var ingress_result: Dictionary = ingress_validator.call(
		"validate_required_ingresses",
		level_data,
		map_instance
	) as Dictionary
	ingress_validator.free()
	var required_ingresses_valid := bool(ingress_result.get("ok", false))
	metrics["required_ingresses_valid"] = required_ingresses_valid
	metrics["required_ingress_failures"] = (ingress_result.get("failures", []) as Array).duplicate(true)
	if not required_ingresses_valid:
		var reasons := metrics.get("rejection_reasons", []) as Array
		if not reasons.has("required_world_ingress"):
			reasons.append("required_world_ingress")
		metrics["rejection_reasons"] = reasons
		metrics["candidate_valid"] = false
	return _evaluation_result(metrics, policy, required_ingresses_valid)


func measure_candidate(map_instance: Node, level_data: Dictionary, settings: Dictionary = {}) -> Dictionary:
	var policy := _settings(settings)
	return _get_map_layout_metrics(map_instance, level_data, policy)


## Snapshot-based counterpart of evaluate_candidate(). Takes a
## custodian.procgen_candidate_semantic_model.v1 snapshot built by
## CandidateSemanticAdapter and never touches a live Node/TileMap; required-
## ingress facts are read from the snapshot rather than recomputed. Same
## acceptance/score/terrain-failure policy as the live path, so results are
## identical for the same candidate.
func evaluate_snapshot(snapshot: Dictionary, settings: Dictionary = {}) -> Dictionary:
	var policy := _settings(settings)
	var metrics := _get_map_layout_metrics_from_snapshot(snapshot, policy)
	if not bool(snapshot.get("has_map_instance", false)):
		metrics["required_ingresses_valid"] = false
		metrics["required_ingress_failures"] = []
		return _evaluation_result(metrics, policy, false)
	var required_ingresses_valid := bool(snapshot.get("required_ingresses_valid", false))
	metrics["required_ingresses_valid"] = required_ingresses_valid
	metrics["required_ingress_failures"] = (snapshot.get("required_ingress_failures", []) as Array).duplicate(true)
	if not required_ingresses_valid:
		var reasons := metrics.get("rejection_reasons", []) as Array
		if not reasons.has("required_world_ingress"):
			reasons.append("required_world_ingress")
		metrics["rejection_reasons"] = reasons
		metrics["candidate_valid"] = false
	return _evaluation_result(metrics, policy, required_ingresses_valid)


func measure_snapshot(snapshot: Dictionary, settings: Dictionary = {}) -> Dictionary:
	var policy := _settings(settings)
	return _get_map_layout_metrics_from_snapshot(snapshot, policy)


func _evaluation_result(metrics: Dictionary, policy: Dictionary, required_ingresses_valid: bool) -> Dictionary:
	return {
		"metrics": metrics,
		"score": score_candidate(metrics, policy),
		"terrain_failed": is_terrain_failed_candidate(metrics, policy),
		"accepted": is_candidate_acceptable(metrics, policy) and required_ingresses_valid,
	}


func is_candidate_acceptable(metrics: Dictionary, settings: Dictionary = {}) -> bool:
	var policy := _settings(settings)
	if not bool(metrics.get("layout_valid", false)):
		return false
	if not bool(metrics.get("candidate_valid", false)):
		return false
	if float(metrics.get("pre_terrain_connected_required_ratio", 1.0)) < float(policy["pre_terrain_required_connectivity_min"]):
		return false
	if bool(metrics.get("terrain_fallback", false)):
		return false
	if not bool(metrics.get("terrain_connectivity", true)):
		return false
	if int(metrics.get("terrain_rescue_carved", 0)) > int(policy["terrain_rescue_reject_threshold"]):
		return false
	if float(metrics.get("connected_ratio", 0.0)) < float(policy["min_connected_room_ratio"]):
		return false
	if bool(policy["require_compound_ingress_connectivity"]) and float(metrics.get("ingress_ratio", 0.0)) < 1.0:
		return false
	return true


func score_candidate(metrics: Dictionary, settings: Dictionary = {}) -> float:
	var policy := _settings(settings)
	if not bool(metrics.get("layout_valid", false)):
		return -1.0
	var score := float(metrics.get("connected_ratio", 0.0)) + float(metrics.get("ingress_ratio", 0.0)) * 0.1
	if float(metrics.get("pre_terrain_connected_required_ratio", 1.0)) < float(policy["pre_terrain_required_connectivity_min"]):
		score -= 1.0
	if bool(metrics.get("terrain_fallback", false)):
		score -= 1.0
	if not bool(metrics.get("terrain_connectivity", true)):
		score -= 1.0
	if int(metrics.get("terrain_rescue_carved", 0)) > int(policy["terrain_rescue_reject_threshold"]):
		score -= 1.0
	return score


func is_terrain_failed_candidate(metrics: Dictionary, settings: Dictionary = {}) -> bool:
	var policy := _settings(settings)
	return bool(metrics.get("terrain_fallback", false)) \
			or not bool(metrics.get("terrain_connectivity", true)) \
			or float(metrics.get("pre_terrain_connected_required_ratio", 1.0)) < float(policy["pre_terrain_required_connectivity_min"]) \
			or int(metrics.get("terrain_rescue_carved", 0)) > int(policy["terrain_rescue_reject_threshold"])


func is_better_fallback_candidate(candidate_score: float, candidate_terrain_failed: bool, best_score: float, best_terrain_failed: bool) -> bool:
	if candidate_terrain_failed != best_terrain_failed:
		return not candidate_terrain_failed
	return candidate_score > best_score


func can_use_degraded_fallback(metrics: Dictionary, settings: Dictionary = {}) -> bool:
	var policy := _settings(settings)
	if metrics.is_empty():
		return false
	if bool(metrics.get("terrain_fallback", false)):
		return false
	if not bool(metrics.get("terrain_connectivity", true)):
		return false
	if not bool(metrics.get("required_ingresses_valid", false)):
		return false
	if float(metrics.get("connected_ratio", 0.0)) < float(policy["min_connected_room_ratio"]):
		return false
	if bool(policy["require_compound_ingress_connectivity"]) and float(metrics.get("ingress_ratio", 0.0)) < 1.0:
		return false
	return int(metrics.get("terrain_rescue_carved", 0)) > int(policy["terrain_rescue_reject_threshold"])


func format_layout_metric_debug(metrics: Dictionary, settings: Dictionary = {}) -> String:
	var policy := _settings(settings)
	return "spawn=%s reachable=%d rooms=%d/%d represented=%d exact_walkable=%d ingress=%d/%d connected=%.2f ingress_ratio=%.2f pre_terrain_connected=%.2f pre_terrain_missing=%d pre_terrain_missing_samples=%s baseline_rescue=%d terrain_rescue=%d terrain_rescue_limit=%d terrain_rescue_ok=%s rejection_reasons=%s unreachable_samples=%s" % [
		str(metrics.get("spawn_tile", Vector2i.ZERO)),
		int(metrics.get("reachable_count", 0)),
		int(metrics.get("rooms_connected", 0)),
		int(metrics.get("rooms_total", 0)),
		int(metrics.get("rooms_represented", 0)),
		int(metrics.get("rooms_exact_walkable", 0)),
		int(metrics.get("ingress_connected", 0)),
		int(metrics.get("ingress_total", 0)),
		float(metrics.get("connected_ratio", 0.0)),
		float(metrics.get("ingress_ratio", 0.0)),
		float(metrics.get("pre_terrain_connected_required_ratio", 1.0)),
		int(metrics.get("pre_terrain_missing_required_count", 0)),
		str(metrics.get("pre_terrain_missing_required_samples", [])),
		int(metrics.get("terrain_baseline_rescue_carved", 0)),
		int(metrics.get("terrain_rescue_carved", 0)),
		int(metrics.get("terrain_rescue_limit", policy["terrain_rescue_reject_threshold"])),
		str(bool(metrics.get("terrain_rescue_ok", true))),
		str(metrics.get("rejection_reasons", [])),
		str(metrics.get("unreachable_room_samples", [])),
	]


## Snapshot mirror of _get_map_layout_metrics(): identical policy/branching,
## reading snapshot.walkable_cells/elevation_blocked_edges instead of calling
## into a live map_instance/TileMap.
func _get_map_layout_metrics_from_snapshot(snapshot: Dictionary, policy: Dictionary) -> Dictionary:
	var level_data: Dictionary = snapshot.get("level_data", {})
	var terrain_builder: Dictionary = level_data.get("terrain_builder", {})
	var pre_terrain: Dictionary = level_data.get("pre_terrain_connectivity", terrain_builder.get("pre_terrain_connectivity", {}))
	var terrain_connectivity := bool(terrain_builder.get("connectivity_ok", true))
	var terrain_fallback := bool(terrain_builder.get("fallback_used", false))
	var rescue_limit := int(policy["terrain_rescue_reject_threshold"])
	var terrain_rescue_carved := int(terrain_builder.get("rescue_carved_cells", terrain_builder.get("summary", {}).get("rescue_carved_cells", 0)))
	var terrain_baseline_rescue_carved := int(terrain_builder.get("baseline_rescue_carved_cells", terrain_builder.get("summary", {}).get("baseline_rescue_carved_cells", 0)))
	var terrain_rescue_ok := terrain_rescue_carved <= rescue_limit
	var pre_terrain_connected_ratio := float(pre_terrain.get("pre_terrain_connected_required_ratio", 1.0))
	var pre_terrain_missing_count := int(pre_terrain.get("pre_terrain_missing_required_count", 0))
	var base_metrics := {
		"valid": false, "layout_valid": false, "candidate_valid": false,
		"rejection_reasons": [], "terrain_connectivity": terrain_connectivity,
		"terrain_fallback": terrain_fallback, "terrain_rescue_carved": terrain_rescue_carved,
		"terrain_baseline_rescue_carved": terrain_baseline_rescue_carved,
		"terrain_rescue_limit": rescue_limit, "terrain_rescue_ok": terrain_rescue_ok,
		"pre_terrain_connected_required_ratio": pre_terrain_connected_ratio,
		"pre_terrain_missing_required_count": pre_terrain_missing_count,
		"pre_terrain_required_cell_count": int(pre_terrain.get("pre_terrain_required_cell_count", 0)),
		"pre_terrain_missing_required_samples": pre_terrain.get("pre_terrain_missing_required_samples", []).duplicate(true),
		"spawn_tile": level_data.get("player_spawn", Vector2i.ZERO),
		"rooms_total": 0, "rooms_connected": 0, "rooms_exact_walkable": 0,
		"rooms_represented": 0, "ingress_total": 0, "ingress_connected": 0,
		"reachable_count": 0, "unreachable_room_samples": [],
	}
	if not bool(snapshot.get("has_map_instance", false)):
		base_metrics["rejection_reasons"] = ["missing_map_instance"]
		return base_metrics
	var spawn_variant: Variant = level_data.get("player_spawn", Vector2i.ZERO)
	if not (spawn_variant is Vector2i):
		base_metrics["rejection_reasons"] = ["missing_spawn_tile"]
		return base_metrics
	var spawn_tile := spawn_variant as Vector2i
	base_metrics["spawn_tile"] = spawn_tile
	if not _is_layout_walkable_tile_snapshot(snapshot, spawn_tile):
		base_metrics["rejection_reasons"] = ["spawn_not_walkable"]
		return base_metrics
	var reachable := _flood_fill_walkable_snapshot(snapshot, spawn_tile)
	if reachable.is_empty():
		base_metrics["rejection_reasons"] = ["no_reachable_walkable_tiles"]
		return base_metrics
	base_metrics["reachable_count"] = reachable.size()
	var rooms_total := 0
	var rooms_connected := 0
	var rooms_exact_walkable := 0
	var rooms_represented := 0
	var unreachable_room_samples: Array[Dictionary] = []
	for room_item in level_data.get("rooms_by_distance", []):
		if not (room_item is Vector2i):
			continue
		rooms_total += 1
		var room_anchor := room_item as Vector2i
		if _is_layout_walkable_tile_snapshot(snapshot, room_anchor):
			rooms_exact_walkable += 1
		var representative := _find_nearest_walkable_layout_tile_snapshot(snapshot, room_anchor)
		if representative == Vector2i.ZERO:
			if unreachable_room_samples.size() < 10:
				unreachable_room_samples.append({"anchor": room_anchor, "representative": null, "reason": "no nearby walkable representative"})
			continue
		rooms_represented += 1
		if reachable.has(representative):
			rooms_connected += 1
		elif unreachable_room_samples.size() < 10:
			unreachable_room_samples.append({"anchor": room_anchor, "representative": representative, "reason": "representative unreachable from spawn"})
	if rooms_total <= 0:
		base_metrics["rejection_reasons"] = ["no_room_anchors"]
		return base_metrics
	var connected_ratio := float(rooms_connected) / float(rooms_total)
	var ingress_total := 0
	var ingress_connected := 0
	for ingress_item in level_data.get("compound_ingress", []):
		if not (ingress_item is Vector2i):
			continue
		ingress_total += 1
		if reachable.has(ingress_item):
			ingress_connected += 1
	var ingress_ratio := 1.0
	if ingress_total > 0:
		ingress_ratio = float(ingress_connected) / float(ingress_total)
	var rejection_reasons: Array[String] = []
	if pre_terrain_connected_ratio < float(policy["pre_terrain_required_connectivity_min"]):
		rejection_reasons.append("pre_terrain_required_connectivity")
	if terrain_fallback:
		rejection_reasons.append("terrain_fallback")
	if not terrain_connectivity:
		rejection_reasons.append("terrain_connectivity")
	if terrain_rescue_carved > rescue_limit:
		rejection_reasons.append("terrain_rescue")
	if connected_ratio < float(policy["min_connected_room_ratio"]):
		rejection_reasons.append("connected_room_ratio")
	if bool(policy["require_compound_ingress_connectivity"]) and ingress_ratio < 1.0:
		rejection_reasons.append("compound_ingress_connectivity")
	var candidate_valid := rejection_reasons.is_empty()
	return {
		"valid": true, "layout_valid": true, "candidate_valid": candidate_valid,
		"rejection_reasons": rejection_reasons, "connected_ratio": connected_ratio,
		"ingress_ratio": ingress_ratio, "terrain_connectivity": terrain_connectivity,
		"terrain_fallback": terrain_fallback, "terrain_rescue_carved": terrain_rescue_carved,
		"terrain_baseline_rescue_carved": terrain_baseline_rescue_carved,
		"terrain_rescue_limit": rescue_limit, "terrain_rescue_ok": terrain_rescue_ok,
		"pre_terrain_connected_required_ratio": pre_terrain_connected_ratio,
		"pre_terrain_missing_required_count": pre_terrain_missing_count,
		"pre_terrain_required_cell_count": int(pre_terrain.get("pre_terrain_required_cell_count", 0)),
		"pre_terrain_missing_required_samples": pre_terrain.get("pre_terrain_missing_required_samples", []).duplicate(true),
		"spawn_tile": spawn_tile, "rooms_total": rooms_total,
		"rooms_connected": rooms_connected, "rooms_exact_walkable": rooms_exact_walkable,
		"rooms_represented": rooms_represented, "ingress_total": ingress_total,
		"ingress_connected": ingress_connected, "reachable_count": reachable.size(),
		"unreachable_room_samples": unreachable_room_samples,
	}


func _flood_fill_walkable_snapshot(snapshot: Dictionary, start_tile: Vector2i) -> Dictionary:
	var walkable_cells: Dictionary = snapshot.get("walkable_cells", {})
	var elevation_blocked_edges: Dictionary = snapshot.get("elevation_blocked_edges", {})
	var reachable := {start_tile: true}
	var open: Array[Vector2i] = [start_tile]
	var map_size: Vector2i = snapshot.get("map_size", Vector2i.ZERO)
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not open.is_empty():
		var current: Vector2i = open.pop_back()
		for direction in directions:
			var next := current + direction
			if next.x < 0 or next.y < 0 or next.x >= map_size.x or next.y >= map_size.y:
				continue
			if reachable.has(next) or not walkable_cells.has(next):
				continue
			var blocked: Array = elevation_blocked_edges.get(current, [])
			if blocked.has(next):
				continue
			reachable[next] = true
			open.append(next)
	return reachable


func _is_layout_walkable_tile_snapshot(snapshot: Dictionary, tile: Vector2i) -> bool:
	var walkable_cells: Dictionary = snapshot.get("walkable_cells", {})
	return walkable_cells.has(tile)


func _find_nearest_walkable_layout_tile_snapshot(snapshot: Dictionary, anchor: Vector2i, max_radius := 8) -> Vector2i:
	var map_size: Vector2i = snapshot.get("map_size", Vector2i.ZERO)
	if _is_tile_inside_map(anchor, map_size) and _is_layout_walkable_tile_snapshot(snapshot, anchor):
		return anchor
	var best_tile := Vector2i.ZERO
	var best_distance := INF
	for radius in range(1, max_radius + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate := anchor + Vector2i(dx, dy)
				if not _is_tile_inside_map(candidate, map_size) or not _is_layout_walkable_tile_snapshot(snapshot, candidate):
					continue
				var distance := candidate.distance_squared_to(anchor)
				if distance < best_distance:
					best_distance = distance
					best_tile = candidate
		if best_tile != Vector2i.ZERO:
			return best_tile
	return Vector2i.ZERO


func _get_map_layout_metrics(map_instance: Node, level_data: Dictionary, policy: Dictionary) -> Dictionary:
	var terrain_builder: Dictionary = level_data.get("terrain_builder", {})
	var pre_terrain: Dictionary = level_data.get("pre_terrain_connectivity", terrain_builder.get("pre_terrain_connectivity", {}))
	var terrain_connectivity := bool(terrain_builder.get("connectivity_ok", true))
	var terrain_fallback := bool(terrain_builder.get("fallback_used", false))
	var rescue_limit := int(policy["terrain_rescue_reject_threshold"])
	var terrain_rescue_carved := int(terrain_builder.get("rescue_carved_cells", terrain_builder.get("summary", {}).get("rescue_carved_cells", 0)))
	var terrain_baseline_rescue_carved := int(terrain_builder.get("baseline_rescue_carved_cells", terrain_builder.get("summary", {}).get("baseline_rescue_carved_cells", 0)))
	var terrain_rescue_ok := terrain_rescue_carved <= rescue_limit
	var pre_terrain_connected_ratio := float(pre_terrain.get("pre_terrain_connected_required_ratio", 1.0))
	var pre_terrain_missing_count := int(pre_terrain.get("pre_terrain_missing_required_count", 0))
	var base_metrics := {
		"valid": false, "layout_valid": false, "candidate_valid": false,
		"rejection_reasons": [], "terrain_connectivity": terrain_connectivity,
		"terrain_fallback": terrain_fallback, "terrain_rescue_carved": terrain_rescue_carved,
		"terrain_baseline_rescue_carved": terrain_baseline_rescue_carved,
		"terrain_rescue_limit": rescue_limit, "terrain_rescue_ok": terrain_rescue_ok,
		"pre_terrain_connected_required_ratio": pre_terrain_connected_ratio,
		"pre_terrain_missing_required_count": pre_terrain_missing_count,
		"pre_terrain_required_cell_count": int(pre_terrain.get("pre_terrain_required_cell_count", 0)),
		"pre_terrain_missing_required_samples": pre_terrain.get("pre_terrain_missing_required_samples", []).duplicate(true),
		"spawn_tile": level_data.get("player_spawn", Vector2i.ZERO),
		"rooms_total": 0, "rooms_connected": 0, "rooms_exact_walkable": 0,
		"rooms_represented": 0, "ingress_total": 0, "ingress_connected": 0,
		"reachable_count": 0, "unreachable_room_samples": [],
	}
	if map_instance == null or _get_procgen_node(map_instance) == null:
		base_metrics["rejection_reasons"] = ["missing_map_instance"]
		return base_metrics
	var spawn_variant: Variant = level_data.get("player_spawn", Vector2i.ZERO)
	if not (spawn_variant is Vector2i):
		base_metrics["rejection_reasons"] = ["missing_spawn_tile"]
		return base_metrics
	var spawn_tile := spawn_variant as Vector2i
	base_metrics["spawn_tile"] = spawn_tile
	if not _is_layout_walkable_tile(map_instance, spawn_tile):
		base_metrics["rejection_reasons"] = ["spawn_not_walkable"]
		return base_metrics
	var reachable := _flood_fill_walkable(map_instance, level_data, spawn_tile)
	if reachable.is_empty():
		base_metrics["rejection_reasons"] = ["no_reachable_walkable_tiles"]
		return base_metrics
	base_metrics["reachable_count"] = reachable.size()
	var rooms_total := 0
	var rooms_connected := 0
	var rooms_exact_walkable := 0
	var rooms_represented := 0
	var unreachable_room_samples: Array[Dictionary] = []
	for room_item in level_data.get("rooms_by_distance", []):
		if not (room_item is Vector2i):
			continue
		rooms_total += 1
		var room_anchor := room_item as Vector2i
		if _is_layout_walkable_tile(map_instance, room_anchor):
			rooms_exact_walkable += 1
		var representative := _find_nearest_walkable_layout_tile(map_instance, level_data, room_anchor)
		if representative == Vector2i.ZERO:
			if unreachable_room_samples.size() < 10:
				unreachable_room_samples.append({"anchor": room_anchor, "representative": null, "reason": "no nearby walkable representative"})
			continue
		rooms_represented += 1
		if reachable.has(representative):
			rooms_connected += 1
		elif unreachable_room_samples.size() < 10:
			unreachable_room_samples.append({"anchor": room_anchor, "representative": representative, "reason": "representative unreachable from spawn"})
	if rooms_total <= 0:
		base_metrics["rejection_reasons"] = ["no_room_anchors"]
		return base_metrics
	var connected_ratio := float(rooms_connected) / float(rooms_total)
	var ingress_total := 0
	var ingress_connected := 0
	for ingress_item in level_data.get("compound_ingress", []):
		if not (ingress_item is Vector2i):
			continue
		ingress_total += 1
		if reachable.has(ingress_item):
			ingress_connected += 1
	var ingress_ratio := 1.0
	if ingress_total > 0:
		ingress_ratio = float(ingress_connected) / float(ingress_total)
	var rejection_reasons: Array[String] = []
	if pre_terrain_connected_ratio < float(policy["pre_terrain_required_connectivity_min"]):
		rejection_reasons.append("pre_terrain_required_connectivity")
	if terrain_fallback:
		rejection_reasons.append("terrain_fallback")
	if not terrain_connectivity:
		rejection_reasons.append("terrain_connectivity")
	if terrain_rescue_carved > rescue_limit:
		rejection_reasons.append("terrain_rescue")
	if connected_ratio < float(policy["min_connected_room_ratio"]):
		rejection_reasons.append("connected_room_ratio")
	if bool(policy["require_compound_ingress_connectivity"]) and ingress_ratio < 1.0:
		rejection_reasons.append("compound_ingress_connectivity")
	var candidate_valid := rejection_reasons.is_empty()
	return {
		"valid": true, "layout_valid": true, "candidate_valid": candidate_valid,
		"rejection_reasons": rejection_reasons, "connected_ratio": connected_ratio,
		"ingress_ratio": ingress_ratio, "terrain_connectivity": terrain_connectivity,
		"terrain_fallback": terrain_fallback, "terrain_rescue_carved": terrain_rescue_carved,
		"terrain_baseline_rescue_carved": terrain_baseline_rescue_carved,
		"terrain_rescue_limit": rescue_limit, "terrain_rescue_ok": terrain_rescue_ok,
		"pre_terrain_connected_required_ratio": pre_terrain_connected_ratio,
		"pre_terrain_missing_required_count": pre_terrain_missing_count,
		"pre_terrain_required_cell_count": int(pre_terrain.get("pre_terrain_required_cell_count", 0)),
		"pre_terrain_missing_required_samples": pre_terrain.get("pre_terrain_missing_required_samples", []).duplicate(true),
		"spawn_tile": spawn_tile, "rooms_total": rooms_total,
		"rooms_connected": rooms_connected, "rooms_exact_walkable": rooms_exact_walkable,
		"rooms_represented": rooms_represented, "ingress_total": ingress_total,
		"ingress_connected": ingress_connected, "reachable_count": reachable.size(),
		"unreachable_room_samples": unreachable_room_samples,
	}


func _flood_fill_walkable(map_instance: Node, level_data: Dictionary, start_tile: Vector2i) -> Dictionary:
	var reachable := {start_tile: true}
	var open: Array[Vector2i] = [start_tile]
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	if map_size == Vector2i.ZERO and map_instance != null and _get_procgen_node(map_instance) != null:
		map_size = (_get_procgen_node(map_instance) as Object).get("map_size")
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not open.is_empty():
		var current: Vector2i = open.pop_back()
		for direction in directions:
			var next := current + direction
			if next.x < 0 or next.y < 0 or next.x >= map_size.x or next.y >= map_size.y:
				continue
			if reachable.has(next) or not _is_layout_walkable_tile(map_instance, next):
				continue
			if map_instance != null and map_instance.has_method("can_traverse_elevation") and not bool(map_instance.call("can_traverse_elevation", current, next)):
				continue
			reachable[next] = true
			open.append(next)
	return reachable


func _is_layout_walkable_tile(map_instance: Node, tile: Vector2i) -> bool:
	if map_instance != null and map_instance.has_method("is_valid_spawn_cell"):
		return bool(map_instance.call("is_valid_spawn_cell", tile))
	if map_instance != null and _get_procgen_node(map_instance) != null:
		return not bool((_get_procgen_node(map_instance) as Object).call("is_full_at", tile))
	return false


func _find_nearest_walkable_layout_tile(map_instance: Node, level_data: Dictionary, anchor: Vector2i, max_radius := 8) -> Vector2i:
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	if map_size == Vector2i.ZERO and map_instance != null and _get_procgen_node(map_instance) != null:
		map_size = (_get_procgen_node(map_instance) as Object).get("map_size")
	if _is_tile_inside_map(anchor, map_size) and _is_layout_walkable_tile(map_instance, anchor):
		return anchor
	var best_tile := Vector2i.ZERO
	var best_distance := INF
	for radius in range(1, max_radius + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate := anchor + Vector2i(dx, dy)
				if not _is_tile_inside_map(candidate, map_size) or not _is_layout_walkable_tile(map_instance, candidate):
					continue
				var distance := candidate.distance_squared_to(anchor)
				if distance < best_distance:
					best_distance = distance
					best_tile = candidate
		if best_tile != Vector2i.ZERO:
			return best_tile
	return Vector2i.ZERO


func _is_tile_inside_map(tile: Vector2i, map_size: Vector2i) -> bool:
	return map_size == Vector2i.ZERO or (tile.x >= 0 and tile.y >= 0 and tile.x < map_size.x and tile.y < map_size.y)


func _get_procgen_node(map_instance: Node) -> Variant:
	return map_instance.get("procgen_node") if map_instance != null else null


func _settings(overrides: Dictionary) -> Dictionary:
	var result := DEFAULT_SETTINGS.duplicate()
	result.merge(overrides, true)
	return result
