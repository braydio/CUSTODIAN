class_name AuthoredLevelMapper
extends LevelCollisionPoiMapper

const Validation := preload("res://tools/level_authoring/mapper/mapper_validation.gd")
const History := preload("res://tools/level_authoring/mapper/mapper_history.gd")

@export_file("*.gd") var adapter_script_path: String

var adapter: AuthoredLevelMapperAdapter
var mapper_mode := "COLLISION"
var snap_step := 4.0
var validation_status := "READY"
var history := History.new()

func _ready() -> void:
	adapter = _load_adapter()
	super._ready()

func _load_adapter() -> AuthoredLevelMapperAdapter:
	if adapter_script_path.is_empty():
		return AuthoredLevelMapperAdapter.new()
	var script := load(adapter_script_path) as Script
	if script == null:
		push_warning("Unable to load mapper adapter: %s" % adapter_script_path)
		return AuthoredLevelMapperAdapter.new()
	var value: Variant = script.new()
	return value as AuthoredLevelMapperAdapter if value is AuthoredLevelMapperAdapter else AuthoredLevelMapperAdapter.new()

func _handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_Z and event.ctrl_pressed and not event.shift_pressed:
		mapper_undo()
		return
	if (event.keycode == KEY_Y and event.ctrl_pressed) or (event.keycode == KEY_Z and event.ctrl_pressed and event.shift_pressed):
		mapper_redo()
		return
	if event.keycode == KEY_K:
		var modes := adapter.authoring_modes()
		var index := modes.find(mapper_mode)
		index = posmod(index + (-1 if event.shift_pressed else 1), modes.size())
		mapper_mode = modes[index]
		_marker_mode = mapper_mode == "MARKERS"
		_update_help()
		_overlay.queue_redraw()
		return
	if event.keycode == KEY_Z and event.ctrl_pressed:
		return
	super._handle_key(event)

func _add_point(point: Vector2, finish_on_double_click := false) -> void:
	if mapper_mode != "COLLISION":
		return
	if snap_step > 0.0:
		point = Vector2(roundf(point.x / snap_step) * snap_step, roundf(point.y / snap_step) * snap_step)
	super._add_point(point, finish_on_double_click)

func get_collision_mapper_state() -> Dictionary:
	var state := super.get_collision_mapper_state()
	state["level"] = adapter.level_id()
	state["mode"] = mapper_mode
	state["snap"] = snap_step
	state["validation_status"] = validation_status
	return state

func _update_help() -> void:
	super._update_help()
	if _hud != null and adapter != null:
		_hud.text = "%s\nLEVEL: %s   MODE: %s   SNAP: %s px   DIRTY: %s   VALIDATION: %s" % [adapter.level_id(), adapter.level_id(), mapper_mode, snap_step, "YES" if _active_polyline.size() > 0 else "NO", validation_status] + "\n" + _hud.text

func validate_mapper() -> Array[String]:
	var findings := Validation.collision_findings(_draft_polylines)
	validation_status = "PASS" if findings.is_empty() else "REVIEW"
	return findings

func collision_create(points: Array) -> bool:
	if points.size() < 2:
		return false
	_push_history()
	var chain: Array[Vector2] = []
	for value: Variant in points:
		if value is Vector2:
			chain.append(value)
	if chain.size() < 2:
		return false
	_draft_polylines.append(chain)
	return true

func collision_finish() -> bool:
	if _active_polyline.size() < 2:
		return false
	_push_history()
	_finish_active_polyline()
	return true

func collision_move_vertex(polyline_index: int, vertex_index: int, point: Vector2) -> bool:
	if not _valid_vertex(polyline_index, vertex_index):
		return false
	_push_history()
	_draft_polylines[polyline_index][vertex_index] = point
	return true

func collision_insert_vertex(polyline_index: int, segment_index: int, point: Vector2) -> bool:
	if polyline_index < 0 or polyline_index >= _draft_polylines.size():
		return false
	var chain := _draft_polylines[polyline_index] as Array
	if segment_index < 0 or segment_index >= chain.size() - 1:
		return false
	_push_history()
	chain.insert(segment_index + 1, point)
	return true

func collision_delete_vertex(polyline_index: int, vertex_index: int) -> bool:
	if not _valid_vertex(polyline_index, vertex_index):
		return false
	_push_history()
	(_draft_polylines[polyline_index] as Array).remove_at(vertex_index)
	return true

func collision_delete(polyline_index: int) -> bool:
	if polyline_index < 0 or polyline_index >= _draft_polylines.size():
		return false
	_push_history()
	_draft_polylines.remove_at(polyline_index)
	return true

func collision_duplicate(polyline_index: int) -> bool:
	if polyline_index < 0 or polyline_index >= _draft_polylines.size():
		return false
	_push_history()
	_draft_polylines.append((_draft_polylines[polyline_index] as Array).duplicate())
	return true

func collision_split(polyline_index: int, vertex_index: int) -> bool:
	if not _valid_vertex(polyline_index, vertex_index) or vertex_index <= 0 or vertex_index >= (_draft_polylines[polyline_index] as Array).size() - 1:
		return false
	_push_history()
	var chain := _draft_polylines[polyline_index] as Array
	var left := chain.slice(0, vertex_index + 1)
	var right := chain.slice(vertex_index)
	_draft_polylines[polyline_index] = left
	_draft_polylines.insert(polyline_index + 1, right)
	return true

func collision_join(first_index: int, second_index: int) -> bool:
	if first_index < 0 or second_index < 0 or first_index >= _draft_polylines.size() or second_index >= _draft_polylines.size() or first_index == second_index:
		return false
	_push_history()
	var first := _draft_polylines[first_index] as Array
	var second := _draft_polylines[second_index] as Array
	if (first[-1] as Vector2).is_equal_approx(second[0] as Vector2):
		first.append_array(second.slice(1))
	elif (first[-1] as Vector2).is_equal_approx((second[-1] as Vector2)):
		second.reverse(); first.append_array(second.slice(1))
	else:
		return false
	_draft_polylines.remove_at(second_index)
	return true

func _valid_vertex(polyline_index: int, vertex_index: int) -> bool:
	return polyline_index >= 0 and polyline_index < _draft_polylines.size() and vertex_index >= 0 and vertex_index < (_draft_polylines[polyline_index] as Array).size()

func _push_history() -> void:
	history.push({"polylines": _draft_polylines.duplicate(true), "active": _active_polyline.duplicate()})

func mapper_undo() -> bool:
	var snapshot: Variant = history.undo({"polylines": _draft_polylines.duplicate(true), "active": _active_polyline.duplicate()})
	if not snapshot is Dictionary:
		return false
	_restore_snapshot(snapshot as Dictionary)
	_overlay.queue_redraw()
	return true

func mapper_redo() -> bool:
	var snapshot: Variant = history.redo({"polylines": _draft_polylines.duplicate(true), "active": _active_polyline.duplicate()})
	if not snapshot is Dictionary:
		return false
	_restore_snapshot(snapshot as Dictionary)
	_overlay.queue_redraw()
	return true

func _restore_snapshot(snapshot: Dictionary) -> void:
	_draft_polylines = snapshot.get("polylines", []).duplicate(true)
	_active_polyline = snapshot.get("active", []).duplicate()
	_draft_points = _active_polyline
