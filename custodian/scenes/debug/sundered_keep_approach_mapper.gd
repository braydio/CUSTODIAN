class_name SunderedKeepApproachMapper
extends LevelCollisionPoiMapper

const LAYOUT_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_outskirts.json"
)
const COLLISION_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_collision.json"
)
const OCCLUSION_DATA_PATH := (
	"res://content/levels/sundered_keep/"
	+ "sundered_keep_approach_occlusion.json"
)


func get_supported_authoring_features() -> PackedStringArray:
	return PackedStringArray([
		"route_floor_stamps",
		"authored_visual_overlays",
		"perimeter_collision_rails",
		"checkpoint_interior_collision",
		"spawn_exit_markers",
		"camera_influence_markers",
		"reveal_anchors",
		"parish_beach_region_tags",
		"roof_rectangles",
		"occlusion_fade_regions",
		"beach_causeway_handoff_marker",
		"foreground_mist_coverage",
	])


func get_production_preview_scene_path() -> String:
	return target_scene_path


func get_authority_paths() -> PackedStringArray:
	return PackedStringArray([
		LAYOUT_DATA_PATH,
		COLLISION_DATA_PATH,
		OCCLUSION_DATA_PATH,
	])


func _apply_draft_segments_to_runtime_collision_map() -> bool:
	if _draft_points.size() < 2:
		push_warning("[SunderedKeepApproachMapper] No complete collision rail")
		return false
	var document := _read_json(COLLISION_DATA_PATH)
	var segments: Array = []
	for index in range(_draft_points.size() - 1):
		var a := _to_authoring_point(_draft_points[index])
		var b := _to_authoring_point(_draft_points[index + 1])
		segments.append([[a.x, a.y], [b.x, b.y]])
	document["segments"] = segments
	document["layout_generator"] = (
		"res://scenes/debug/sundered_keep_approach_mapper.tscn"
	)
	return _write_json(COLLISION_DATA_PATH, document)


func _apply_draft_markers_to_runtime_marker_map() -> bool:
	if _draft_markers.is_empty():
		push_warning("[SunderedKeepApproachMapper] No marker drafts")
		return false
	var document := _read_json(LAYOUT_DATA_PATH)
	var markers := document.get("markers", {}) as Dictionary
	for marker_id: String in _draft_markers.keys():
		var record := (markers.get(marker_id, {}) as Dictionary).duplicate(true)
		var point := _to_authoring_point(_draft_markers[marker_id] as Vector2)
		record["position"] = [point.x, point.y]
		record["kind"] = str(record.get("kind", marker_id))
		record["label"] = str(record.get("label", marker_id.to_upper()))
		markers[marker_id] = record
	document["markers"] = markers
	document["layout_generator"] = (
		"res://scenes/debug/sundered_keep_approach_mapper.tscn"
	)
	return _write_json(LAYOUT_DATA_PATH, document)


func save_subregion(
	region_id: String,
	node_name: String,
	kind: String,
	runtime_rect: Rect2
) -> bool:
	var document := _read_json(LAYOUT_DATA_PATH)
	var regions := document.get("subregions", []) as Array
	var record := {
		"id": region_id,
		"node_name": node_name,
		"kind": kind,
		"rect": _authoring_rect_array(runtime_rect),
	}
	var replaced := false
	for index in regions.size():
		if str((regions[index] as Dictionary).get("id", "")) == region_id:
			regions[index] = record
			replaced = true
			break
	if not replaced:
		regions.append(record)
	document["subregions"] = regions
	return _write_json(LAYOUT_DATA_PATH, document)


func save_route_floor(
	texture_path: String,
	runtime_rect: Rect2,
	tile_size := 32
) -> bool:
	var document := _read_json(LAYOUT_DATA_PATH)
	document["route_floor"] = {
		"kind": "authored_route_master",
		"texture_path": texture_path,
		"rect": _authoring_rect_array(runtime_rect),
		"vertical_runtime_offset": 180.0,
		"tile_size": tile_size,
	}
	return _write_json(LAYOUT_DATA_PATH, document)


func save_visual_overlay(overlay_record: Dictionary) -> bool:
	var overlay_id := str(overlay_record.get("id", ""))
	if overlay_id.is_empty():
		push_warning("[SunderedKeepApproachMapper] Overlay id is required")
		return false
	var document := _read_json(LAYOUT_DATA_PATH)
	var overlays := document.get("visual_overlays", []) as Array
	var normalized := overlay_record.duplicate(true)
	if normalized.has("runtime_rect"):
		var runtime_rect := normalized["runtime_rect"] as Rect2
		normalized.erase("runtime_rect")
		normalized["rect"] = _authoring_rect_array(runtime_rect)
	normalized["collision_authority"] = false
	var replaced := false
	for index in overlays.size():
		if str((overlays[index] as Dictionary).get("id", "")) == overlay_id:
			overlays[index] = normalized
			replaced = true
			break
	if not replaced:
		overlays.append(normalized)
	document["visual_overlays"] = overlays
	return _write_json(LAYOUT_DATA_PATH, document)


func save_roof_occluder(
	roof_id: String,
	runtime_roof_rect: Rect2,
	runtime_fade_region: Rect2,
	faded_alpha := 0.08
) -> bool:
	var document := _read_json(OCCLUSION_DATA_PATH)
	var records := document.get("roof_occluders", []) as Array
	var record := {
		"id": roof_id,
		"roof_rect": _authoring_rect_array(runtime_roof_rect),
		"fade_region": _authoring_rect_array(runtime_fade_region),
		"faded_alpha": faded_alpha,
		"foreground_arch_persists": true,
	}
	var replaced := false
	for index in records.size():
		if str((records[index] as Dictionary).get("id", "")) == roof_id:
			records[index] = record
			replaced = true
			break
	if not replaced:
		records.append(record)
	document["roof_occluders"] = records
	return _write_json(OCCLUSION_DATA_PATH, document)


func _to_authoring_point(runtime_point: Vector2) -> Vector2:
	if _target_level != null and _target_level.has_method(
		"runtime_to_authoring_point"
	):
		return _target_level.call(
			"runtime_to_authoring_point",
			runtime_point
		) as Vector2
	return runtime_point


func _authoring_rect_array(runtime_rect: Rect2) -> Array:
	var origin := _to_authoring_point(runtime_rect.position)
	return [
		origin.x,
		origin.y,
		runtime_rect.size.x,
		runtime_rect.size.y,
	]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SunderedKeepApproachMapper] Missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _write_json(path: String, document: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SunderedKeepApproachMapper] Cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(document, "  ") + "\n")
	file.close()
	print("[SunderedKeepApproachMapper] Saved %s" % path)
	return true
