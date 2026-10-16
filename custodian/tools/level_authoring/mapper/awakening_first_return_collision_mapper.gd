extends AuthoredLevelMapper

const Bridge := preload("res://tools/level_authoring/mapper/awakening_collision_mapper_bridge.gd")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const DRAFT_PATH := "res://../reports/level_maps/awakening_first_return/collision_draft.json"

@export var proposal_owner_id := ""
@export var proposal_purpose := ""
@export_enum("floor", "void", "blocker", "decoration") var proposal_kind := "blocker"

var actual_colliders: Array[Dictionary] = []
var registration_bounds: Array[Dictionary] = []
var show_actual_colliders := true
var show_protected_paths := true
var show_registration_bounds := false
var _overlay_visible := true
var candidate_findings: Array[String] = []
var _owner_field: LineEdit
var _purpose_field: LineEdit
var _kind_field: OptionButton
var _dragging_selected_vertex := false
var proposal_metadata: Array[Dictionary] = []
var selected_collision_id := ""
var _selected_collision_index := 0
var _next_proposal_id := 1
var _stale_draft_authority := false


func _ready() -> void:
	adapter_script_path = "res://tools/level_authoring/mapper/adapters/awakening_first_return_mapper_adapter.gd"
	super._ready()
	await get_tree().process_frame
	if _target_level != null:
		# The scene finishes building art and collision first. Disable its game
		# loop and input after construction while retaining render/collider nodes.
		_target_level.process_mode = Node.PROCESS_MODE_DISABLED
		actual_colliders = Bridge.collect_colliders(_target_level)
		registration_bounds = Bridge.registered_art_bounds(_target_level)
	_load_saved_draft()
	_build_metadata_controls()
	_update_help()
	_overlay.queue_redraw()


func _build_metadata_controls() -> void:
	_owner_field = LineEdit.new()
	_owner_field.name = "ProposalOwner"
	_owner_field.placeholder_text = "Owner ID (required for dry-run)"
	_owner_field.position = Vector2(16, 204)
	_owner_field.size = Vector2(300, 32)
	_owner_field.text = proposal_owner_id
	_owner_field.text_changed.connect(func(value: String) -> void: proposal_owner_id = value)
	$CanvasLayer.add_child(_owner_field)
	_purpose_field = LineEdit.new()
	_purpose_field.name = "ProposalPurpose"
	_purpose_field.placeholder_text = "Purpose / adjustment intent"
	_purpose_field.position = Vector2(324, 204)
	_purpose_field.size = Vector2(300, 32)
	_purpose_field.text = proposal_purpose
	_purpose_field.text_changed.connect(func(value: String) -> void: proposal_purpose = value)
	$CanvasLayer.add_child(_purpose_field)
	_kind_field = OptionButton.new()
	_kind_field.name = "ProposalKind"
	_kind_field.position = Vector2(632, 204)
	_kind_field.size = Vector2(150, 32)
	for kind in ["floor", "void", "blocker", "decoration"]:
		_kind_field.add_item(kind)
	_kind_field.item_selected.connect(func(index: int) -> void: proposal_kind = _kind_field.get_item_text(index))
	_kind_field.select(maxi(0, ["floor", "void", "blocker", "decoration"].find(proposal_kind)))
	$CanvasLayer.add_child(_kind_field)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.alt_pressed:
			_select_collision_at_point(_camera.get_global_mouse_position())
			_dragging_selected_vertex = _selected_vertex_index >= 0
			if _dragging_selected_vertex: _push_history()
			return
		if not mouse.pressed:
			_dragging_selected_vertex = false
	if event is InputEventMouseMotion and _dragging_selected_vertex and _selected_polyline_index >= 0:
		(_draft_polylines[_selected_polyline_index] as Array)[_selected_vertex_index] = _snap_point(_camera.get_global_mouse_position())
		_overlay.queue_redraw()
		_update_help()
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		var key := event as InputEventKey
		if key.keycode == KEY_M: return # Marker editing has no safe Awakening persistence contract.
		if key.keycode == KEY_I and _selected_polyline_index >= 0:
			_insert_vertex_at_mouse()
			return
		if key.keycode == KEY_DELETE and _selected_polyline_index >= 0:
			if _selected_vertex_index >= 0:
				collision_delete_vertex(_selected_polyline_index, _selected_vertex_index)
			else:
				collision_delete(_selected_polyline_index)
			_selected_polyline_index = -1
			_selected_vertex_index = -1
			_overlay.queue_redraw()
			return
	super._unhandled_input(event)


func _snap_point(point: Vector2) -> Vector2:
	if snap_step <= 0.0: return point
	return Vector2(roundf(point.x / snap_step) * snap_step, roundf(point.y / snap_step) * snap_step)


func _insert_vertex_at_mouse() -> void:
	var chain := _draft_polylines[_selected_polyline_index] as Array
	if chain.size() < 2: return
	var point := _snap_point(_camera.get_global_mouse_position())
	var best_index := 0
	var best_distance := INF
	for index in range(chain.size() - 1):
		var distance := Geometry2D.get_closest_point_to_segment(point, chain[index], chain[index + 1]).distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if best_distance <= 64.0 / maxf(0.05, _camera.zoom.x):
		collision_insert_vertex(_selected_polyline_index, best_index, point)
		_selected_vertex_index = best_index + 1
		_overlay.queue_redraw()


func _finish_active_polyline() -> void:
	var cleaned: Array[Vector2] = []
	for point in _active_polyline:
		if cleaned.is_empty() or not point.is_equal_approx(cleaned[-1]): cleaned.append(point)
	if cleaned.size() >= 2:
		_push_history()
		_draft_polylines.append(cleaned)
		proposal_metadata.append({
			"id": "awakening-proposal-%03d" % _next_proposal_id,
			"owner_id": proposal_owner_id,
			"purpose": proposal_purpose,
			"geometry_kind": proposal_kind,
			"proposal_mode": "additive",
			"source_collision_id": "",
		})
		_next_proposal_id += 1
	_active_polyline.clear()
	_update_help()
	_overlay.queue_redraw()


func _import_selected_collider_for_adjustment() -> void:
	if actual_colliders.is_empty(): return
	var record: Dictionary = actual_colliders[clampi(_selected_collision_index, 0, actual_colliders.size() - 1)]
	var points := record.get("world_points", PackedVector2Array()) as PackedVector2Array
	if points.size() < 2: return
	_push_history()
	var chain: Array[Vector2] = []
	for point in points: chain.append(point)
	_draft_polylines.append(chain)
	selected_collision_id = str(record.id)
	proposal_owner_id = str(record.owner_id)
	proposal_purpose = "adjust existing %s" % selected_collision_id
	proposal_kind = "blocker"
	proposal_metadata.append({
		"id": "adjust:%s" % selected_collision_id,
		"owner_id": str(record.owner_id),
		"purpose": proposal_purpose,
		"geometry_kind": "blocker",
		"proposal_mode": "replace_existing",
		"source_collision_id": selected_collision_id,
	})
	if _owner_field != null: _owner_field.text = proposal_owner_id
	if _purpose_field != null: _purpose_field.text = proposal_purpose
	_overlay.queue_redraw()
	_update_help()


func _push_history() -> void:
	history.push(_history_snapshot())


func _history_snapshot() -> Dictionary:
	return {"polylines": _draft_polylines.duplicate(true), "active": _active_polyline.duplicate(), "proposal_metadata": proposal_metadata.duplicate(true), "next_id": _next_proposal_id}


func _restore_snapshot(snapshot: Dictionary) -> void:
	super._restore_snapshot(snapshot)
	proposal_metadata = snapshot.get("proposal_metadata", []).duplicate(true)
	_next_proposal_id = int(snapshot.get("next_id", _next_proposal_id))


func mapper_undo() -> bool:
	var snapshot: Variant = history.undo(_history_snapshot())
	if not snapshot is Dictionary: return false
	_restore_snapshot(snapshot)
	_overlay.queue_redraw()
	return true


func mapper_redo() -> bool:
	var snapshot: Variant = history.redo(_history_snapshot())
	if not snapshot is Dictionary: return false
	_restore_snapshot(snapshot)
	_overlay.queue_redraw()
	return true


func collision_create(points: Array) -> bool:
	if not super.collision_create(points): return false
	proposal_metadata.append({"id": "awakening-proposal-%03d" % _next_proposal_id, "owner_id": proposal_owner_id, "purpose": proposal_purpose, "geometry_kind": proposal_kind, "proposal_mode": "additive", "source_collision_id": ""})
	_next_proposal_id += 1
	return true


func collision_delete(polyline_index: int) -> bool:
	if not super.collision_delete(polyline_index): return false
	if polyline_index < proposal_metadata.size(): proposal_metadata.remove_at(polyline_index)
	return true


func collision_duplicate(polyline_index: int) -> bool:
	if polyline_index < 0 or polyline_index >= _draft_polylines.size(): return false
	if not super.collision_duplicate(polyline_index): return false
	var metadata := proposal_metadata[polyline_index].duplicate(true) if polyline_index < proposal_metadata.size() else {}
	metadata.id = "awakening-proposal-%03d" % _next_proposal_id
	metadata.proposal_mode = "additive"
	metadata.source_collision_id = ""
	proposal_metadata.append(metadata)
	_next_proposal_id += 1
	return true


func _handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_S and event.ctrl_pressed:
		_save_collision_draft()
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_U:
		_finish_active_polyline()
		_update_help()
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_E:
		show_actual_colliders = not show_actual_colliders
		_overlay_visible = true
		_overlay.visible = _overlay_visible
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_V:
		_show_draft = not _show_draft
		_overlay_visible = true
		_overlay.visible = true
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_T:
		show_protected_paths = not show_protected_paths
		_overlay_visible = true
		_overlay.visible = true
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_F1:
		_show_draft = false
		show_actual_colliders = false
		show_protected_paths = false
		show_registration_bounds = false
		$World/AwakeningZoneOverlay.visible = false
		_overlay_visible = false
		_overlay.visible = false
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_F2:
		$World/AwakeningZoneOverlay.visible = true
		$World/AwakeningZoneOverlay.show_zone_bounds = false
		$World/AwakeningZoneOverlay.show_landmarks = false
		$World/AwakeningZoneOverlay.show_collision = not $World/AwakeningZoneOverlay.show_collision
		_overlay_visible = true
		_overlay.visible = true
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_F3:
		show_actual_colliders = not show_actual_colliders
		_overlay_visible = true
		_overlay.visible = true
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_F4:
		show_protected_paths = not show_protected_paths
		_overlay_visible = true
		_overlay.visible = true
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_F5:
		show_registration_bounds = not show_registration_bounds
		_overlay_visible = true
		_overlay.visible = true
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_COMMA or event.keycode == KEY_PERIOD:
		if not actual_colliders.is_empty():
			var delta := -1 if event.keycode == KEY_COMMA else 1
			_selected_collision_index = posmod(_selected_collision_index + delta, actual_colliders.size())
			selected_collision_id = str(actual_colliders[_selected_collision_index].id)
			_update_help()
			_overlay.queue_redraw()
		return
	if event.keycode == KEY_B:
		_import_selected_collider_for_adjustment()
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		_camera.position = Layout.zone_entry(event.keycode - KEY_1 + 1)
		return
	if event.keycode == KEY_0:
		_camera.position = Layout.zone_entry(10)
		return
	if event.keycode == KEY_BRACKETLEFT or event.keycode == KEY_BRACKETRIGHT:
		snap_step = 1.0 if snap_step == 4.0 else 4.0
		_update_help()
		return
	super._handle_key(event)


func _add_point(point: Vector2, finish_on_double_click := false) -> void:
	super._add_point(_snap_point(point), finish_on_double_click)


func _save_mapper_snapshot() -> void:
	_save_collision_draft()
	super._save_mapper_snapshot()


func _save_collision_draft() -> bool:
	if _stale_draft_authority:
		push_error("Awakening draft save refused: its scene/Layout authority is stale; export geometry and begin a new draft")
		return false
	if _owner_field != null: proposal_owner_id = _owner_field.text.strip_edges()
	if _purpose_field != null: proposal_purpose = _purpose_field.text.strip_edges()
	var root := ProjectSettings.globalize_path("res://..")
	var scene_sha := _git_blob_sha(root, "custodian/scenes/awakening_first_return.tscn")
	var layout_sha := _git_blob_sha(root, "custodian/game/world/awakening/awakening_layout.gd")
	if scene_sha.is_empty() or layout_sha.is_empty():
		push_error("Awakening draft save refused: scene/layout Git provenance unavailable")
		return false
	var draft := Bridge.make_draft(_draft_polylines, proposal_owner_id, proposal_purpose, proposal_kind, scene_sha, layout_sha, snap_step, proposal_metadata)
	for proposal: Dictionary in draft.proposals:
		proposal.source_art = Bridge.art_provenance(_target_level, proposal.world_points_px.map(func(point: Array) -> Vector2: return Vector2(float(point[0]), float(point[1]))))
	candidate_findings = Bridge.validate_draft(draft, scene_sha, layout_sha)
	var absolute := ProjectSettings.globalize_path(DRAFT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if not Bridge.atomic_write_readback(absolute, draft):
		push_error("Awakening collision draft failed atomic write/readback")
		return false
	print("Awakening draft saved: %s (dry-run findings: %s)" % [absolute, ", ".join(candidate_findings) if not candidate_findings.is_empty() else "none"])
	return true


func _load_saved_draft() -> void:
	var absolute := ProjectSettings.globalize_path(DRAFT_PATH)
	if not FileAccess.file_exists(absolute):
		return
	var file := FileAccess.open(absolute, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or str(parsed.get("schema", "")) != Bridge.SCHEMA:
		push_warning("Ignoring malformed Awakening collision draft")
		return
	var root := ProjectSettings.globalize_path("res://..")
	var scene_sha := _git_blob_sha(root, "custodian/scenes/awakening_first_return.tscn")
	var layout_sha := _git_blob_sha(root, "custodian/game/world/awakening/awakening_layout.gd")
	candidate_findings = Bridge.validate_draft(parsed, scene_sha, layout_sha)
	_stale_draft_authority = candidate_findings.has("stale_scene_or_layout_sha")
	if _stale_draft_authority:
		push_warning("Awakening collision draft is stale and will be shown read-only; save is disabled")
	var proposals: Variant = parsed.get("proposals", [])
	if not proposals is Array:
		return
	_draft_polylines.clear()
	proposal_metadata.clear()
	for proposal: Variant in proposals:
		if not proposal is Dictionary: continue
		var data := proposal as Dictionary
		proposal_owner_id = str(data.get("owner_id", proposal_owner_id))
		proposal_purpose = str(data.get("purpose", proposal_purpose))
		proposal_kind = str(data.get("geometry_kind", proposal_kind))
		var points: Array[Vector2] = []
		for raw_point: Variant in data.get("world_points_px", []):
			if raw_point is Array and raw_point.size() == 2:
				points.append(Vector2(float(raw_point[0]), float(raw_point[1])))
		if points.size() >= 2: _draft_polylines.append(points)
		proposal_metadata.append({
			"id": str(data.get("id", "")),
			"owner_id": str(data.get("owner_id", "")),
			"purpose": str(data.get("purpose", "")),
			"geometry_kind": str(data.get("geometry_kind", "blocker")),
			"proposal_mode": str(data.get("proposal_mode", "additive")),
			"source_collision_id": str(data.get("source_collision_id", "")),
		})
		_next_proposal_id += 1


func _git_blob_sha(root: String, path: String) -> String:
	var output: Array = []
	var code := OS.execute("git", PackedStringArray(["-C", root, "rev-parse", "HEAD:" + path]), output, true)
	return str(output[0]).strip_edges() if code == 0 and not output.is_empty() else ""


func get_collision_mapper_state() -> Dictionary:
	var state := super.get_collision_mapper_state()
	state["actual_colliders"] = actual_colliders
	state["show_actual_colliders"] = show_actual_colliders
	state["show_protected_paths"] = show_protected_paths
	state["registration_bounds"] = registration_bounds
	state["show_registration_bounds"] = show_registration_bounds
	state["overlay_visible"] = _overlay_visible
	state["candidate_findings"] = candidate_findings
	state["selected_collision_id"] = selected_collision_id
	state["awakening_mapper"] = true
	return state


func _update_help() -> void:
	super._update_help()
	if _hud != null:
		_hud.text = "%s\nCtrl+S save draft only | Enter/U finish chain | E actual collision | T protected paths | F1 art only | F2 Layout floor/void | F3 actual colliders | F4 connectors/thresholds | F5 04-05 registration | V proposals | [/] snap 4/1 | 0-9 zones | Alt-drag vertex | I insert | Delete vertex | ,/. choose actual collider | B propose replacement\nSelected actual source: %s\nOwner/purpose required; Layout and runtime collision remain read-only.\nDRY RUN: %s\n" % [mapper_title, selected_collision_id, ", ".join(candidate_findings) if not candidate_findings.is_empty() else "clean / not compiled"] + _hud.text


func validate_mapper() -> Array[String]:
	var findings := super.validate_mapper()
	findings.append_array(candidate_findings)
	return findings
