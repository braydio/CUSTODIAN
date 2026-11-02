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

var _zone_mode := false
var _zone_records: Array[Dictionary] = []
var _selected_zone_index := 0
var _zone_draft_start := Vector2.ZERO
var _zone_draft_rect := Rect2()
var _zone_has_start := false


func _ready() -> void:
	super()
	_refresh_zone_records()
	_report_marker_authority_issues()
	_update_help()
	_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_Z:
			_zone_mode = not _zone_mode
			if _zone_mode:
				_refresh_zone_records()
			_update_help()
			_overlay.queue_redraw()
			get_viewport().set_input_as_handled()
			return
	if not _zone_mode:
		super(event)
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mouse := event as InputEventMouseButton
		match mouse.button_index:
			MOUSE_BUTTON_LEFT:
				_set_zone_corner(_camera.get_global_mouse_position())
			MOUSE_BUTTON_RIGHT:
				_clear_zone_draft()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				super(event)
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var key := event as InputEventKey
		match key.keycode:
			KEY_PAGEUP:
				_cycle_selected_zone(-1)
			KEY_PAGEDOWN:
				_cycle_selected_zone(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_U:
				_save_selected_zone()
			KEY_R:
				_clear_zone_draft()
			_:
				super(event)
	_update_help()
	_overlay.queue_redraw()


func _refresh_zone_records() -> void:
	_zone_records.clear()
	var document := _read_json(LAYOUT_DATA_PATH)
	for raw: Variant in document.get("subregions", []):
		if raw is Dictionary and not str((raw as Dictionary).get("id", "")).is_empty():
			_zone_records.append((raw as Dictionary).duplicate(true))
	_selected_zone_index = clampi(_selected_zone_index, 0, maxi(0, _zone_records.size() - 1))
	_load_selected_zone_rect()


func _cycle_selected_zone(direction: int) -> void:
	if _zone_records.is_empty():
		return
	_selected_zone_index = posmod(_selected_zone_index + direction, _zone_records.size())
	_load_selected_zone_rect()


func _load_selected_zone_rect() -> void:
	_zone_has_start = false
	_zone_draft_rect = Rect2()
	if _zone_records.is_empty():
		return
	var values := _zone_records[_selected_zone_index].get("rect", []) as Array
	if values.size() >= 4:
		var authoring_rect := Rect2(
			Vector2(float(values[0]), float(values[1])),
			Vector2(float(values[2]), float(values[3]))
		)
		_zone_draft_rect = Rect2(
			authoring_rect.position + Vector2(0.0, 180.0),
			authoring_rect.size
		)


func _set_zone_corner(point: Vector2) -> void:
	if not _zone_has_start:
		_zone_draft_start = point
		_zone_draft_rect = Rect2(point, Vector2.ZERO)
		_zone_has_start = true
		return
	_zone_draft_rect = Rect2(_zone_draft_start, point - _zone_draft_start).abs()
	_zone_has_start = false


func _clear_zone_draft() -> void:
	_zone_has_start = false
	_zone_draft_rect = Rect2()


func _save_selected_zone() -> void:
	if _zone_records.is_empty() or _zone_draft_rect.size.x <= 0.0 or _zone_draft_rect.size.y <= 0.0:
		push_warning("[SunderedKeepApproachMapper] Select two zone corners before saving")
		return
	var record := _zone_records[_selected_zone_index]
	if save_subregion(
		str(record.get("id", "")),
		str(record.get("node_name", "FeatureZone")),
		str(record.get("kind", "feature_zone")),
		_zone_draft_rect
	):
		_refresh_zone_records()


func _selected_zone_id() -> String:
	if _zone_records.is_empty():
		return "none"
	return str(_zone_records[_selected_zone_index].get("id", "none"))


func _update_help() -> void:
	super()
	if _hud == null:
		return
	_hud.text += "\nZ: feature-zone mode"
	if _zone_mode:
		_hud.text += (
			"   ZONE selected=%s   PgUp/PgDn: cycle   Left click: two corners   Right/R: clear   Enter/U: save"
			% _selected_zone_id()
		)


func get_collision_mapper_state() -> Dictionary:
	var state := super()
	state["zone_mode"] = _zone_mode
	state["zone_records"] = _zone_records
	state["selected_zone"] = _selected_zone_id()
	state["zone_draft_rect"] = _zone_draft_rect
	state["zone_has_start"] = _zone_has_start
	return state


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
	var marker_report := _build_marker_authority_report(markers)
	if not (marker_report.get("errors", []) as Array).is_empty():
		push_error(
			"[SunderedKeepApproachMapper] Refusing marker save: %s"
			% "; ".join(marker_report.get("errors", []) as Array)
		)
		return false
	document["markers"] = markers
	document["layout_generator"] = (
		"res://scenes/debug/sundered_keep_approach_mapper.tscn"
	)
	return _write_json(LAYOUT_DATA_PATH, document)


func get_marker_authority_report() -> Dictionary:
	return _build_marker_authority_report(
		(_read_json(LAYOUT_DATA_PATH).get("markers", {}) as Dictionary)
	)


func _report_marker_authority_issues() -> void:
	var report := get_marker_authority_report()
	for error: Variant in report.get("errors", []):
		push_error("[SunderedKeepApproachMapper] %s" % str(error))


func _build_marker_authority_report(markers: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var node_owners: Dictionary = {}
	var position_owners: Dictionary = {}
	var marker_ids := markers.keys()
	marker_ids.sort()
	for marker_id_variant: Variant in marker_ids:
		var marker_id := str(marker_id_variant).strip_edges()
		var raw_record: Variant = markers.get(marker_id_variant)
		if marker_id.is_empty() or not (raw_record is Dictionary):
			errors.append("invalid marker record '%s'" % marker_id)
			continue
		var record := raw_record as Dictionary
		var node_name := str(record.get("node_name", "")).strip_edges()
		if node_name.is_empty():
			errors.append("marker '%s' has no node_name" % marker_id)
		elif node_owners.has(node_name):
			errors.append(
				"markers '%s' and '%s' share node_name '%s'"
				% [str(node_owners[node_name]), marker_id, node_name]
			)
		else:
			node_owners[node_name] = marker_id
		var position := record.get("position", []) as Array
		if position.size() < 2:
			errors.append("marker '%s' has no valid position" % marker_id)
			continue
		var position_key := "%.4f,%.4f" % [float(position[0]), float(position[1])]
		if position_owners.has(position_key):
			errors.append(
				"markers '%s' and '%s' share position %s"
				% [str(position_owners[position_key]), marker_id, position_key]
			)
		else:
			position_owners[position_key] = marker_id
	return {
		"canonical_path": LAYOUT_DATA_PATH,
		"marker_count": markers.size(),
		"marker_ids": marker_ids,
		"errors": errors,
	}


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
