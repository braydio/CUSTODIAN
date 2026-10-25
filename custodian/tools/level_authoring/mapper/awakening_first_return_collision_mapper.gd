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
var _export_status := ""
var _capture_in_progress := false
var _clipboard_dialog: AcceptDialog


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
	var copy_button := Button.new()
	copy_button.name = "CopyExactVertices"
	copy_button.text = "Copy Exact Vertices"
	copy_button.position = Vector2(16, 244)
	copy_button.size = Vector2(190, 34)
	copy_button.pressed.connect(copy_exact_vertices)
	$CanvasLayer.add_child(copy_button)
	var capture_button := Button.new()
	capture_button.name = "CaptureAnnotatedDraft"
	capture_button.text = "Capture Annotated Draft"
	capture_button.position = Vector2(214, 244)
	capture_button.size = Vector2(220, 34)
	capture_button.pressed.connect(_capture_annotated_draft_to_default)
	$CanvasLayer.add_child(capture_button)


func _unhandled_input(event: InputEvent) -> void:
	if _capture_in_progress: return
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
	if event.keycode == KEY_C and event.ctrl_pressed and event.shift_pressed:
		copy_exact_vertices()
		return
	if event.keycode == KEY_P and event.ctrl_pressed and event.shift_pressed:
		_capture_annotated_draft_to_default()
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
	return save_collision_draft_to(ProjectSettings.globalize_path(DRAFT_PATH))


func save_collision_draft_to(absolute_path: String) -> bool:
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
	var authority := _source_sha_report(root)
	if authority.changed:
		push_error("Awakening draft save refused: source SHA changed against HEAD: %s" % JSON.stringify(authority))
		return false
	var draft := Bridge.make_draft(_draft_polylines, proposal_owner_id, proposal_purpose, proposal_kind, scene_sha, layout_sha, snap_step, proposal_metadata)
	for index in draft.proposals.size():
		var proposal: Dictionary = draft.proposals[index]
		var prior_art: Variant = proposal_metadata[index].get("source_art") if index < proposal_metadata.size() else null
		if prior_art is Dictionary and not str(prior_art.get("resource", "")).is_empty():
			proposal.source_art = prior_art.duplicate(true)
		else:
			proposal.source_art = Bridge.art_provenance(_target_level, proposal.world_points_px.map(func(point: Array) -> Vector2: return Vector2(float(point[0]), float(point[1]))))
	candidate_findings = Bridge.validate_draft(draft, scene_sha, layout_sha)
	if not candidate_findings.is_empty():
		push_error("Awakening draft save refused: %s" % ", ".join(candidate_findings))
		return false
	var absolute := absolute_path
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if not Bridge.atomic_write_readback(absolute, draft):
		push_error("Awakening collision draft failed atomic write/readback")
		return false
	print("Awakening draft saved: %s (dry-run findings: %s)" % [absolute, ", ".join(candidate_findings) if not candidate_findings.is_empty() else "none"])
	return true


func _load_saved_draft() -> void:
	load_collision_draft_from(ProjectSettings.globalize_path(DRAFT_PATH))


func load_collision_draft_from(absolute: String) -> bool:
	if not FileAccess.file_exists(absolute):
		return false
	var file := FileAccess.open(absolute, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or str(parsed.get("schema", "")) != Bridge.SCHEMA:
		push_warning("Ignoring malformed Awakening collision draft")
		return false
	var root := ProjectSettings.globalize_path("res://..")
	var scene_sha := _git_blob_sha(root, "custodian/scenes/awakening_first_return.tscn")
	var layout_sha := _git_blob_sha(root, "custodian/game/world/awakening/awakening_layout.gd")
	var findings := Bridge.validate_draft(parsed, scene_sha, layout_sha)
	var authority := _source_sha_report(root)
	if authority.changed:
		findings.append("source_file_sha_changed")
	var fatal_findings := findings.duplicate()
	fatal_findings.erase("stale_scene_or_layout_sha")
	fatal_findings.erase("source_file_sha_changed")
	if not fatal_findings.is_empty():
		push_warning("Ignoring invalid Awakening collision draft: %s" % ", ".join(fatal_findings))
		return false
	candidate_findings = findings
	_stale_draft_authority = findings.has("stale_scene_or_layout_sha") or findings.has("source_file_sha_changed")
	if _stale_draft_authority:
		push_warning("Awakening collision draft source SHA changed or is stale and will be shown read-only; save is disabled (%s)" % JSON.stringify(authority))
	var proposals: Variant = parsed.get("proposals", [])
	if not proposals is Array:
		return false
	var loaded_polylines: Array = []
	var loaded_metadata: Array[Dictionary] = []
	var next_id := 1
	for proposal: Variant in proposals:
		if not proposal is Dictionary: return false
		var data := proposal as Dictionary
		var points: Array[Vector2] = []
		for raw_point: Variant in data.get("world_points_px", []):
			if not raw_point is Array or raw_point.size() != 2: return false
			points.append(Vector2(float(raw_point[0]), float(raw_point[1])))
		if points.size() < 2: return false
		loaded_polylines.append(points)
		var metadata := {
			"id": str(data.get("id", "")),
			"owner_id": str(data.get("owner_id", "")),
			"purpose": str(data.get("purpose", "")),
			"geometry_kind": str(data.get("geometry_kind", "blocker")),
			"proposal_mode": str(data.get("proposal_mode", "additive")),
			"source_collision_id": str(data.get("source_collision_id", "")),
			"source_art": (data.get("source_art", {}) as Dictionary).duplicate(true),
		}
		if metadata.id.is_empty(): return false
		loaded_metadata.append(metadata)
		var numeric_suffix := RegEx.create_from_string("([0-9]+)$").search(metadata.id)
		if numeric_suffix != null: next_id = maxi(next_id, int(numeric_suffix.get_string(1)) + 1)
	_draft_polylines = loaded_polylines
	proposal_metadata = loaded_metadata
	_next_proposal_id = next_id
	snap_step = float(parsed.get("snap_px", snap_step))
	if not loaded_metadata.is_empty():
		proposal_owner_id = str(loaded_metadata[0].owner_id)
		proposal_purpose = str(loaded_metadata[0].purpose)
		proposal_kind = str(loaded_metadata[0].geometry_kind)
		if _owner_field != null: _owner_field.text = proposal_owner_id
		if _purpose_field != null: _purpose_field.text = proposal_purpose
		if _kind_field != null:
			var kind_index := ["floor", "void", "blocker", "decoration"].find(proposal_kind)
			if kind_index >= 0: _kind_field.select(kind_index)
	_overlay.queue_redraw()
	_update_help()
	return true


func copy_exact_vertices() -> String:
	if _selected_polyline_index < 0 or _selected_polyline_index >= _draft_polylines.size():
		_export_status = "Select a proposal before copying exact vertices."
		_update_help()
		return ""
	var index := _selected_polyline_index
	if index >= proposal_metadata.size():
		_export_status = "Selected proposal metadata is incomplete; copy refused."
		_update_help()
		return ""
	var metadata: Dictionary = proposal_metadata[index]
	var vertices: Array = []
	for point: Vector2 in _draft_polylines[index]: vertices.append([point.x, point.y])
	var source_art_variant: Variant = metadata.get("source_art", {})
	var source_art: Dictionary = source_art_variant as Dictionary if source_art_variant is Dictionary else {}
	var payload := {
		"id": str(metadata.get("id", "")),
		"zone_id": Bridge.zone_for_point(_draft_polylines[index][0]),
		"owner_id": str(metadata.get("owner_id", "")),
		"world_points_px": vertices,
		"source_pixel_points": source_art.get("source_pixel_points", []),
	}
	var text := JSON.stringify(payload, "  ")
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(text)
		_export_status = "Exact vertices copied for %s." % str(metadata.get("id", "selected proposal"))
	else:
		_export_status = "Clipboard is unavailable; exact vertices are ready in the return value."
		if _clipboard_dialog == null:
			_clipboard_dialog = AcceptDialog.new()
			_clipboard_dialog.title = "Exact Vertices"
			$CanvasLayer.add_child(_clipboard_dialog)
		_clipboard_dialog.dialog_text = "Clipboard unavailable. Record this exact proposal JSON:\n\n%s" % text
		_clipboard_dialog.popup_centered(Vector2i(760, 520))
	_update_help()
	return text


func capture_annotated_draft(base_path: String) -> Dictionary:
	if base_path.strip_edges().is_empty(): return {"ok": false, "error": "output_path_empty"}
	if DisplayServer.get_name() == "headless": return {"ok": false, "error": "headless_capture_unavailable"}
	var root := ProjectSettings.globalize_path("res://..")
	var scene_sha := _git_blob_sha(root, "custodian/scenes/awakening_first_return.tscn")
	var layout_sha := _git_blob_sha(root, "custodian/game/world/awakening/awakening_layout.gd")
	if scene_sha.is_empty() or layout_sha.is_empty(): return {"ok": false, "error": "source_provenance_unavailable"}
	var initial_authority := _source_sha_report(root)
	if initial_authority.changed:
		return {"ok": false, "error": "source_sha_changed", "authority": initial_authority}
	var snapshot := Bridge.make_draft(_draft_polylines, proposal_owner_id, proposal_purpose, proposal_kind, scene_sha, layout_sha, snap_step, proposal_metadata)
	for index in snapshot.proposals.size():
		var proposal: Dictionary = snapshot.proposals[index]
		if index < proposal_metadata.size() and proposal_metadata[index].get("source_art") is Dictionary:
			proposal.source_art = proposal_metadata[index].source_art.duplicate(true)
	var errors := Bridge.validate_draft(snapshot, scene_sha, layout_sha)
	if not errors.is_empty(): return {"ok": false, "error": "draft_invalid", "findings": errors}
	var old_show_actual := show_actual_colliders
	var old_show_protected := show_protected_paths
	var old_overlay_visible := _overlay.visible
	_capture_in_progress = true
	set_process(false)
	show_actual_colliders = true
	show_protected_paths = false
	_overlay.visible = true
	_overlay.queue_redraw()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_capture_in_progress = false
	set_process(true)
	show_actual_colliders = old_show_actual
	show_protected_paths = old_show_protected
	_overlay.visible = old_overlay_visible
	_overlay.queue_redraw()
	var final_authority := _source_sha_report(root)
	if final_authority.changed or final_authority != initial_authority:
		return {"ok": false, "error": "source_sha_changed", "authority": final_authority}
	var payload := {"schema": Bridge.SCHEMA, "base": snapshot.base.duplicate(true), "snap_px": snap_step, "proposals": snapshot.proposals.duplicate(true), "capture": {"png_path": base_path + ".png", "json_path": base_path + ".json", "camera_position": [_camera.global_position.x, _camera.global_position.y], "camera_zoom": [_camera.zoom.x, _camera.zoom.y], "layers": ["registered_production_art", "source_collision_red_or_green", "draft_proposal_cyan"]}}
	return Bridge.write_capture_bundle(base_path, image, payload)


func _capture_annotated_draft_to_default() -> void:
	var output_dir := ProjectSettings.globalize_path("user://awakening_mapper_exports")
	var stamp := Time.get_datetime_string_from_system(true, true).replace(":", "-")
	var result: Dictionary = await capture_annotated_draft(output_dir.path_join("awakening_" + stamp))
	_export_status = "Capture saved: %s" % result.get("png_path", result.get("error", "failed"))
	_update_help()


func _git_blob_sha(root: String, path: String) -> String:
	var output: Array = []
	var code := OS.execute("git", PackedStringArray(["-C", root, "rev-parse", "HEAD:" + path]), output, true)
	return str(output[0]).strip_edges() if code == 0 and not output.is_empty() else ""


func _working_blob_sha(root: String, path: String) -> String:
	var output: Array = []
	var code := OS.execute("git", PackedStringArray(["-C", root, "hash-object", "--", path]), output, true)
	return str(output[0]).strip_edges() if code == 0 and not output.is_empty() else ""


func _source_sha_report(root: String) -> Dictionary:
	var scene_path := "custodian/scenes/awakening_first_return.tscn"
	var layout_path := "custodian/game/world/awakening/awakening_layout.gd"
	var scene_expected := _git_blob_sha(root, scene_path)
	var layout_expected := _git_blob_sha(root, layout_path)
	var scene_working := _working_blob_sha(root, scene_path)
	var layout_working := _working_blob_sha(root, layout_path)
	return {
		"scene_expected": scene_expected,
		"scene_working": scene_working,
		"layout_expected": layout_expected,
		"layout_working": layout_working,
		"changed": scene_expected.is_empty() or layout_expected.is_empty() or scene_expected != scene_working or layout_expected != layout_working,
	}


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
		_hud.text = "%s\nCtrl+S save draft only | Enter/U finish chain | E actual collision | T protected paths | F1 art only | F2 Layout floor/void | F3 actual colliders | F4 connectors/thresholds | F5 04-05 registration | V proposals | [/] snap 4/1 | 0-9 zones | Alt-drag vertex | I insert | Delete vertex | ,/. choose actual collider | B propose replacement | Ctrl+Shift+C copy exact vertices | Ctrl+Shift+P capture annotated draft\nSelected actual source: %s\nOwner/purpose required; Layout and runtime collision remain read-only.\nDRY RUN: %s\nEXPORT: %s\n" % [mapper_title, selected_collision_id, ", ".join(candidate_findings) if not candidate_findings.is_empty() else "clean / not compiled", _export_status] + _hud.text


func validate_mapper() -> Array[String]:
	var findings := super.validate_mapper()
	findings.append_array(candidate_findings)
	return findings
