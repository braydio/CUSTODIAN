extends AuthoredLevelMapper
class_name CarrowInteriorLayoutMapper

const DraftModel := preload("res://tools/level_authoring/mapper/carrow_interior_layout_draft.gd")
const ROOM_ORDER := ["west_draft_house", "east_machine_house", "operations_house"]
const MODES := ["FLOOR", "PROPS", "COLLISION", "PORTAL", "STORAGE", "WAYPOINTS"]

var room_id := "west_draft_house"
var draft: Dictionary = {}
var _draft_cache := {}
var _fixture: Node2D
var _operator: CharacterBody2D
var _game_camera: CameraController
var _floor_root: Node2D
var _art_root: Node2D
var _collision_root: Node2D
var _panel: PanelContainer
var _room_select: OptionButton
var _mode_select: OptionButton
var _asset_select: OptionButton
var _floor_select: OptionButton
var _placement_select: OptionButton
var _storage_select: OptionButton
var _storage_art_select: OptionButton
var _placement_id: LineEdit
var _waypoint_id: LineEdit
var _scale_x: SpinBox
var _scale_y: SpinBox
var _z_index: SpinBox
var _status: Label
var _selected_collision := ""
var _selected_placement := ""
var _pointer_down := false
var _drag_kind := ""
var _drag_origin := Vector2i.ZERO
var _drag_offset := Vector2i.ZERO
var _drag_shape_id := ""
var _drag_rect := Rect2i()
var _drag_art_id := ""
var _new_rect_serial := 1


func _ready() -> void:
	room_id = ROOM_ORDER[0]
	adapter_script_path = "res://tools/level_authoring/mapper/carrow_interior_layout_mapper_adapter.gd"
	super._ready()
	if _camera != null:
		_camera.enabled = false
	if _target_level != null:
		_fixture = _target_level
		_bind_fixture_nodes()
	draft = DraftModel.create_draft(room_id)
	_build_preview()
	_build_authoring_panel()
	_update_help()
	if _overlay != null:
		_overlay.queue_redraw()


func _load_target_level() -> void:
	var config := DraftModel.room_config(room_id)
	var scene_path := String(config.get("scene", ""))
	var packed := ResourceLoader.load(scene_path, "PackedScene") as PackedScene
	if packed == null:
		push_error("[CarrowLayoutMapper] Missing accepted scale fixture: %s" % scene_path)
		return
	_target_level = packed.instantiate() as Node2D
	if _target_level == null:
		push_error("[CarrowLayoutMapper] Fixture root must be Node2D")
		return
	_target_level.name = "ScaleFixture"
	_world.add_child(_target_level)
	_hide_target_canvas_layers(_target_level)
	_fixture = _target_level
	_bind_fixture_nodes()
	_strip_fixture_blockout()


func _bind_fixture_nodes() -> void:
	if _fixture == null:
		return
	_operator = _fixture.get_node_or_null("Operator") as CharacterBody2D
	_game_camera = _fixture.get_node_or_null("Camera2D") as CameraController
	if _operator == null or _game_camera == null:
		push_error("[CarrowLayoutMapper] The scale fixture must supply its real Operator and CameraController")
		return
	_game_camera.enabled = true
	_game_camera.auto_zoom_enabled = false
	_game_camera.zoom = _game_camera.base_zoom
	_game_camera.target_zoom = _game_camera.base_zoom
	_game_camera._locked_zoom = _game_camera.base_zoom
	_game_camera.follow_target = _operator
	_game_camera.operator_ref = _operator
	_game_camera.make_current()
	var window := get_window()
	window.size = Vector2i(1280, 720)
	window.content_scale_size = Vector2i(1280, 720)


func _strip_fixture_blockout() -> void:
	if _fixture == null:
		return
	_fixture.set_process(false)
	_fixture.set_process_input(false)
	_fixture.set_process_unhandled_input(false)
	for child in _fixture.get_children():
		if child == _operator or child == _game_camera:
			continue
		_fixture.remove_child(child)
		child.free()


func _build_authoring_panel() -> void:
	var canvas := get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas == null:
		return
	_panel = PanelContainer.new()
	_panel.name = "CarrowAuthoringPanel"
	_panel.position = Vector2(12, 112)
	_panel.size = Vector2(310, 590)
	_panel.custom_minimum_size = Vector2(310, 0)
	canvas.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	scroll.add_child(column)
	_add_label(column, "CARROW INTERIOR LAYOUT DRAFTS")
	_add_label(column, "Draft-only editor · 32px cells · no production writes")
	_room_select = _option(column, "Room", [])
	for id in ROOM_ORDER:
		var config := DraftModel.room_config(id)
		var grid: Vector2i = config.grid_wh
		_room_select.add_item("%s · %d×%d" % [id.replace("_", " ").capitalize(), grid.x, grid.y])
		_room_select.set_item_metadata(_room_select.item_count - 1, id)
	_room_select.select(0)
	_room_select.item_selected.connect(_on_room_selected)
	_mode_select = _option(column, "Mode", MODES)
	_mode_select.select(0)
	_mode_select.item_selected.connect(_on_mode_selected)
	_asset_select = _option(column, "Registered art", [])
	for asset in DraftModel.asset_records():
		if String(asset.family_id) == DraftModel.FLOOR_FAMILY:
			continue
		_asset_select.add_item(String(asset.asset_id))
		_asset_select.set_item_metadata(_asset_select.item_count - 1, String(asset.asset_id))
	_asset_select.item_selected.connect(_on_asset_selected)
	_floor_select = _option(column, "Floor state", [])
	for asset_id in DraftModel.floor_asset_ids():
		var asset := DraftModel.asset_record(asset_id)
		_floor_select.add_item(String(asset.state_id))
		_floor_select.set_item_metadata(_floor_select.item_count - 1, String(asset.state_id))
		if String(asset.state_id) == "slab_worn_01":
			_floor_select.select(_floor_select.item_count - 1)
	_floor_select.item_selected.connect(_on_floor_selected)
	_placement_select = _option(column, "Prop anchor", [])
	_placement_select.add_item("New placement")
	_placement_select.set_item_metadata(0, "")
	_placement_select.select(0)
	_placement_select.item_selected.connect(_on_placement_selected)
	_placement_id = LineEdit.new()
	_placement_id.placeholder_text = "Unique prop anchor name"
	_placement_id.text = "prop_01"
	column.add_child(_placement_id)
	var transform_row := HBoxContainer.new()
	column.add_child(transform_row)
	_scale_x = _spin(transform_row, "Scale X", 0.1, 4.0, 0.1, 1.0)
	_scale_y = _spin(transform_row, "Y", 0.1, 4.0, 0.1, 1.0)
	_z_index = _spin(transform_row, "Z", -100.0, 100.0, 1.0, -10.0)
	_scale_x.value_changed.connect(_on_scale_changed.bind(0))
	_scale_y.value_changed.connect(_on_scale_changed.bind(1))
	_z_index.value_changed.connect(_on_z_changed)
	var prop_buttons := HBoxContainer.new()
	column.add_child(prop_buttons)
	_add_button(prop_buttons, "Delete prop", _delete_selected_prop)
	_storage_select = _option(column, "Existing resource", [])
	_storage_art_select = _option(column, "Bind to art anchor", [])
	var storage_buttons := HBoxContainer.new()
	column.add_child(storage_buttons)
	_add_button(storage_buttons, "Bind", _bind_selected_storage)
	_add_button(storage_buttons, "Unbind", _unbind_selected_storage)
	_waypoint_id = LineEdit.new()
	_waypoint_id.placeholder_text = "Named clearance waypoint"
	column.add_child(_waypoint_id)
	var waypoint_buttons := HBoxContainer.new()
	column.add_child(waypoint_buttons)
	_add_button(waypoint_buttons, "Add/move waypoint", _arm_waypoint)
	_add_button(waypoint_buttons, "Delete waypoint", _delete_waypoint)
	var draft_buttons := HBoxContainer.new()
	column.add_child(draft_buttons)
	_add_button(draft_buttons, "Save draft", _save_draft)
	_add_button(draft_buttons, "Load draft", _load_draft)
	var report_buttons := HBoxContainer.new()
	column.add_child(report_buttons)
	_add_button(report_buttons, "Validate", _validate_draft)
	_add_button(report_buttons, "Export report", _export_report)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(280, 150)
	_status.text = "Fresh empty layout draft. Select a mode and edit the room explicitly."
	column.add_child(_status)
	_refresh_storage_controls()
	_refresh_placement_controls()


func _option(parent: Node, label_text: String, values: Array) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 102
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in values:
		option.add_item(String(value))
	row.add_child(option)
	return option


func _spin(parent: Node, label_text: String, minimum: float, maximum: float, step: float, initial: float) -> SpinBox:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = initial
	row.add_child(spin)
	return spin


func _add_label(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _add_button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)


func _on_room_selected(index: int) -> void:
	if not draft.is_empty():
		_draft_cache[room_id] = draft.duplicate(true)
	room_id = String(_room_select.get_item_metadata(index))
	draft = (_draft_cache.get(room_id, DraftModel.create_draft(room_id)) as Dictionary).duplicate(true)
	_recreate_fixture()
	_build_preview()
	_refresh_placement_controls()
	_refresh_storage_controls()
	_set_status("Loaded in-memory %s draft. Save remains explicit." % room_id)


func _recreate_fixture() -> void:
	if _fixture != null:
		_world.remove_child(_fixture)
		_fixture.free()
	_fixture = null
	_target_level = null
	_load_target_level()
	if _fixture != null:
		_bind_fixture_nodes()
		_strip_fixture_blockout()
	if _overlay != null:
		_overlay.queue_redraw()


func _on_mode_selected(index: int) -> void:
	mapper_mode = MODES[index]
	if _overlay != null:
		_overlay.queue_redraw()
	_update_help()


func _on_asset_selected(_index: int) -> void:
	pass


func _on_floor_selected(_index: int) -> void:
	pass


func _on_placement_selected(index: int) -> void:
	_selected_placement = String(_placement_select.get_item_metadata(index))
	var placement := _placement_record(_selected_placement)
	if placement.is_empty():
		return
	var scale: Array = placement.get("scale", [1.0, 1.0])
	_scale_x.set_value_no_signal(float(scale[0]))
	_scale_y.set_value_no_signal(float(scale[1]))
	_z_index.set_value_no_signal(float(placement.get("z_index", -10)))


func _on_scale_changed(value: float, axis: int) -> void:
	var placement := _placement_record(_selected_placement)
	if placement.is_empty():
		return
	var scale: Array = placement.get("scale", [1.0, 1.0]).duplicate()
	scale[axis] = value
	placement["scale"] = scale
	_commit_mutation()


func _on_z_changed(value: float) -> void:
	var placement := _placement_record(_selected_placement)
	if placement.is_empty():
		return
	placement["z_index"] = int(value)
	_commit_mutation()


func _build_preview() -> void:
	if _target_level == null or _operator == null or _game_camera == null or draft.is_empty():
		return
	var grid := Vector2i(int(draft.grid_wh[0]), int(draft.grid_wh[1]))
	var config := DraftModel.room_config(room_id)
	_game_camera.authored_map_bounds = Rect2(Vector2.ZERO, Vector2(grid * DraftModel.TILE_SIZE))
	_game_camera.map_bounds = _game_camera.authored_map_bounds
	_game_camera.zoom = Vector2(0.84, 0.84)
	_game_camera.target_zoom = _game_camera.zoom
	_game_camera.auto_zoom_enabled = false
	_game_camera.follow_enabled = false
	var door_center := DraftModel._cell(draft.portal_cells[1])
	_operator.global_position = Vector2(door_center.x * DraftModel.TILE_SIZE + 16, (grid.y - 2) * DraftModel.TILE_SIZE + 16)
	_operator.velocity = Vector2.ZERO
	_game_camera.reset_smoothing()
	_game_camera.global_position = Vector2(grid.x * DraftModel.TILE_SIZE * 0.5, grid.y * DraftModel.TILE_SIZE * 0.5)
	_floor_root = _replace_preview_layer("DraftFloor", -50)
	_art_root = _replace_preview_layer("DraftArt", 0)
	_collision_root = _replace_preview_layer("DraftCollision", 50)
	_build_floor(grid)
	_build_art()
	_build_collision()
	if _overlay != null:
		_overlay.queue_redraw()


func _replace_preview_layer(node_name: String, z: int) -> Node2D:
	var prior := _target_level.get_node_or_null(node_name)
	if prior != null:
		_target_level.remove_child(prior)
		prior.free()
	var layer := Node2D.new()
	layer.name = node_name
	layer.z_index = z
	_target_level.add_child(layer)
	return layer


func _build_floor(grid: Vector2i) -> void:
	_clear_layer(_floor_root)
	var floor_records := {}
	for region_variant in draft.get("floor_regions", []):
		var region := region_variant as Dictionary
		for cell_variant in region.get("cells", []):
			var cell := DraftModel._cell(cell_variant)
			floor_records[Vector2i(cell)] = String(region.get("state_id", ""))
	var cache := {}
	for y in range(grid.y):
		for x in range(grid.x):
			var cell := Vector2i(x, y)
			var state_id := String(floor_records.get(cell, String(draft.get("base_floor_state", "slab_plain_01"))))
			var asset_id := "carrow_machine_house_floor/%s::omni" % state_id
			var asset := DraftModel.asset_record(asset_id)
			if asset.is_empty():
				continue
			var texture: Texture2D = cache.get(state_id)
			if texture == null:
				texture = ResourceLoader.load(String(asset.path)) as Texture2D
				cache[state_id] = texture
			if texture == null:
				continue
			var sprite := Sprite2D.new()
			sprite.name = "Floor_%02d_%02d" % [x, y]
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(x * 32 + 16, y * 32 + 16)
			sprite.z_index = -1
			_floor_root.add_child(sprite)


func _build_art() -> void:
	_clear_layer(_art_root)
	for placement_variant in draft.get("art_placements", []):
		var placement := placement_variant as Dictionary
		var asset := DraftModel.asset_record(String(placement.get("asset_id", "")))
		if asset.is_empty():
			continue
		var texture := ResourceLoader.load(String(asset.path)) as Texture2D
		if texture == null:
			continue
		var anchor := DraftModel._cell(placement.get("anchor_cell", []))
		var scale_values: Array = placement.get("scale", [1.0, 1.0])
		var scale := Vector2(float(scale_values[0]), float(scale_values[1]))
		var sprite := Sprite2D.new()
		sprite.name = String(placement.get("placement_id", "Placement"))
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(anchor.x * 32, anchor.y * 32) - Vector2(0.0, texture.get_height() * scale.y * 0.5)
		sprite.scale = scale
		sprite.z_index = int(placement.get("z_index", -10))
		sprite.z_as_relative = true
		sprite.set_meta("placement_id", String(placement.get("placement_id", "")))
		_art_root.add_child(sprite)


func _build_collision() -> void:
	_clear_layer(_collision_root)
	for shape_variant in draft.get("collision_shapes", []):
		var record := shape_variant as Dictionary
		var cells: Array = record.get("rect", [])
		if cells.size() != 4:
			continue
		var body := StaticBody2D.new()
		body.name = "Solid_%s" % String(record.get("id", ""))
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = Vector2(int(cells[2]), int(cells[3])) * 32.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = (Vector2(int(cells[0]), int(cells[1])) + Vector2(int(cells[2]), int(cells[3])) * 0.5) * 32.0
		body.add_child(collision)
		_collision_root.add_child(body)


func _clear_layer(layer: Node2D) -> void:
	if layer == null:
		return
	for child in layer.get_children():
		layer.remove_child(child)
		child.free()


func _process(_delta: float) -> void:
	if _overlay != null and _overlay.is_visible_in_tree():
		_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_begin_map_action(_mouse_cell())
			else:
				_end_map_action()
			get_viewport().set_input_as_handled()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			_erase_at(_mouse_cell())
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pointer_down:
		_update_map_action(_mouse_cell())
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_G:
			_show_grid = not _show_grid
			_overlay.queue_redraw()
			get_viewport().set_input_as_handled()
		elif key == KEY_TAB:
			_panel.visible = not _panel.visible
			get_viewport().set_input_as_handled()
		elif key == KEY_DELETE:
			_delete_selection()
			get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE:
			_pointer_down = false
			_drag_kind = ""
			_drag_rect = Rect2i()
			_overlay.queue_redraw()
			get_viewport().set_input_as_handled()


func _mouse_cell() -> Vector2i:
	if _game_camera == null:
		return Vector2i(-1, -1)
	var point := _game_camera.get_global_mouse_position()
	return Vector2i(floori(point.x / 32.0), floori(point.y / 32.0))


func _begin_map_action(cell: Vector2i) -> void:
	if not _cell_is_in_room(cell):
		return
	_pointer_down = true
	_drag_origin = cell
	match mapper_mode:
		"FLOOR":
			var state := String(_floor_select.get_item_metadata(_floor_select.selected))
			if DraftModel.paint_floor_cell(draft, cell, state):
				_commit_mutation()
		"PROPS":
			var hit := _placement_at_world(_game_camera.get_global_mouse_position())
			var chosen := _selected_placement
			if not hit.is_empty():
				chosen = hit
				_select_placement_id(chosen)
			if chosen.is_empty():
				var asset_id := String(_asset_select.get_item_metadata(_asset_select.selected))
				var id := _placement_id.text.strip_edges()
				if id.is_empty():
					_set_status("Give this art anchor a unique name before placing it.")
					return
				if not DraftModel.place_art(draft, id, asset_id, cell, Vector2(_scale_x.value, _scale_y.value), int(_z_index.value)):
					_set_status("Placement could not be created. Check its unique name and registered art ID.")
					return
				chosen = id
				_select_placement_id(chosen)
				_drag_kind = "art"
				_drag_art_id = chosen
				_commit_mutation()
			else:
				_drag_kind = "art"
				_drag_art_id = chosen
				var anchor := DraftModel._cell(_placement_record(chosen).get("anchor_cell", []))
				_drag_offset = anchor - cell
		"COLLISION":
			var point := _game_camera.get_global_mouse_position()
			_drag_shape_id = _collision_at(point)
			if not _drag_shape_id.is_empty():
				_selected_collision = _drag_shape_id
				var record := _collision_record(_drag_shape_id)
				var rect: Array = record.get("rect", [])
				_drag_offset = Vector2i(int(rect[0]), int(rect[1])) - cell
				_drag_kind = "move_collision"
			else:
				_drag_kind = "draw_collision"
				_drag_rect = Rect2i(cell, Vector2i.ONE)
		"PORTAL":
			if cell.y == int(draft.grid_wh[1]) - 1:
				_drag_kind = "portal"
				_set_portal_from_cell(cell)
		"WAYPOINTS":
			var name := _waypoint_id.text.strip_edges()
			if DraftModel.set_waypoint(draft, name, cell):
				_commit_mutation()
			else:
				_set_status("Enter a waypoint name before placing it.")
		"STORAGE":
			_set_status("Select an existing resource and a named registered art anchor, then use Bind.")
	_overlay.queue_redraw()


func _update_map_action(cell: Vector2i) -> void:
	if not _pointer_down:
		return
	match _drag_kind:
		"art":
			DraftModel.move_art(draft, _drag_art_id, cell + _drag_offset)
			_refresh_digest_and_art()
		"move_collision":
			DraftModel.move_collision_rect(draft, _drag_shape_id, cell + _drag_offset)
			_refresh_digest_and_collision()
		"draw_collision":
			var left := mini(_drag_origin.x, cell.x)
			var top := mini(_drag_origin.y, cell.y)
			_drag_rect = Rect2i(left, top, absi(cell.x - _drag_origin.x) + 1, absi(cell.y - _drag_origin.y) + 1)
			_overlay.queue_redraw()
		"portal":
			_set_portal_from_cell(cell)


func _end_map_action() -> void:
	if not _pointer_down:
		return
	if _drag_kind == "draw_collision" and _drag_rect.size != Vector2i.ZERO:
		var id := "solid_%02d" % _new_rect_serial
		_new_rect_serial += 1
		if DraftModel.add_collision_rect(draft, id, _drag_rect):
			_selected_collision = id
			_commit_mutation()
	_pointer_down = false
	_drag_kind = ""
	_drag_shape_id = ""
	_drag_art_id = ""
	_drag_rect = Rect2i()
	_overlay.queue_redraw()


func _set_portal_from_cell(cell: Vector2i) -> void:
	var grid_width := int(draft.grid_wh[0])
	var center := clampi(cell.x, 2, grid_width - 3)
	if DraftModel.set_portal_center(draft, center):
		_commit_mutation()


func _erase_at(cell: Vector2i) -> void:
	if not _cell_is_in_room(cell):
		return
	match mapper_mode:
		"FLOOR":
			DraftModel.erase_floor_cell(draft, cell)
			_commit_mutation()
		"PROPS":
			var id := _placement_at_world(_game_camera.get_global_mouse_position())
			if not id.is_empty():
				_selected_placement = id
				DraftModel.delete_art(draft, id)
				_commit_mutation()
		"COLLISION":
			var id := _collision_at(_game_camera.get_global_mouse_position())
			if not id.is_empty():
				_selected_collision = ""
				DraftModel.delete_collision_shape(draft, id)
				_commit_mutation()
		"WAYPOINTS":
			DraftModel.delete_waypoint(draft, _waypoint_id.text.strip_edges())
			_commit_mutation()
		"PORTAL":
			DraftModel.set_portal_center(draft, int(draft.grid_wh[0]) >> 1)
			_commit_mutation()
	_overlay.queue_redraw()


func _cell_is_in_room(cell: Vector2i) -> bool:
	var grid := Vector2i(int(draft.grid_wh[0]), int(draft.grid_wh[1]))
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid.x and cell.y < grid.y


func _placement_at_world(point: Vector2) -> String:
	for index in range(draft.get("art_placements", []).size() - 1, -1, -1):
		var placement: Dictionary = draft.art_placements[index]
		var asset := DraftModel.asset_record(String(placement.asset_id))
		if asset.is_empty():
			continue
		var anchor := DraftModel._cell(placement.anchor_cell)
		var size: Array = asset.frame_size
		var scale: Array = placement.get("scale", [1.0, 1.0])
		var bounds := Rect2(Vector2(anchor.x * 32, anchor.y * 32) - Vector2(float(size[0]) * float(scale[0]) * 0.5, float(size[1]) * float(scale[1])), Vector2(float(size[0]) * float(scale[0]), float(size[1]) * float(scale[1])))
		if bounds.has_point(point):
			return String(placement.placement_id)
	return ""


func _collision_at(point: Vector2) -> String:
	for index in range(draft.get("collision_shapes", []).size() - 1, -1, -1):
		var shape: Dictionary = draft.collision_shapes[index]
		var values: Array = shape.rect
		var bounds := Rect2(Vector2(int(values[0]), int(values[1])) * 32.0, Vector2(int(values[2]), int(values[3])) * 32.0)
		if bounds.has_point(point):
			return String(shape.id)
	return ""


func _placement_record(id: String) -> Dictionary:
	for value: Dictionary in draft.get("art_placements", []):
		if String(value.get("placement_id", "")) == id:
			return value
	return {}


func _collision_record(id: String) -> Dictionary:
	for value: Dictionary in draft.get("collision_shapes", []):
		if String(value.get("id", "")) == id:
			return value
	return {}


func _select_placement_id(id: String) -> void:
	_selected_placement = id
	_refresh_placement_controls()
	for index in range(_placement_select.item_count):
		if String(_placement_select.get_item_metadata(index)) == id:
			_placement_select.select(index)
			_on_placement_selected(index)
			return


func _refresh_placement_controls() -> void:
	if _placement_select == null:
		return
	_placement_select.clear()
	_placement_select.add_item("New placement")
	_placement_select.set_item_metadata(0, "")
	var records: Array = draft.get("art_placements", []).duplicate(true)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.placement_id) < String(b.placement_id))
	for value: Dictionary in records:
		_placement_select.add_item(String(value.placement_id))
		_placement_select.set_item_metadata(_placement_select.item_count - 1, String(value.placement_id))
	var selected := 0
	for index in range(_placement_select.item_count):
		if String(_placement_select.get_item_metadata(index)) == _selected_placement:
			selected = index
	_placement_select.select(selected)
	if _storage_art_select != null:
		_storage_art_select.clear()
		for value: Dictionary in records:
			_storage_art_select.add_item(String(value.placement_id))
			_storage_art_select.set_item_metadata(_storage_art_select.item_count - 1, String(value.placement_id))


func _refresh_storage_controls() -> void:
	if _storage_select == null:
		return
	_storage_select.clear()
	for value: Dictionary in draft.get("storage_anchors", []):
		_storage_select.add_item(String(value.display_name))
		_storage_select.set_item_metadata(_storage_select.item_count - 1, String(value.storage_id))
	if _storage_select.item_count > 0:
		_storage_select.select(0)


func _delete_selected_prop() -> void:
	if DraftModel.delete_art(draft, _selected_placement):
		_selected_placement = ""
		_commit_mutation()


func _delete_selection() -> void:
	if mapper_mode == "PROPS":
		_delete_selected_prop()
	elif mapper_mode == "COLLISION" and not _selected_collision.is_empty():
		DraftModel.delete_collision_shape(draft, _selected_collision)
		_selected_collision = ""
		_commit_mutation()


func _bind_selected_storage() -> void:
	if _storage_select.item_count == 0 or _storage_art_select.item_count == 0:
		_set_status("Add and name a registered art anchor before binding storage.")
		return
	var storage_id := String(_storage_select.get_item_metadata(_storage_select.selected))
	var art_id := String(_storage_art_select.get_item_metadata(_storage_art_select.selected))
	if DraftModel.bind_storage(draft, storage_id, art_id):
		_commit_mutation()


func _unbind_selected_storage() -> void:
	if _storage_select.item_count == 0:
		return
	var storage_id := String(_storage_select.get_item_metadata(_storage_select.selected))
	if DraftModel.unbind_storage(draft, storage_id):
		_commit_mutation()


func _arm_waypoint() -> void:
	mapper_mode = "WAYPOINTS"
	_mode_select.select(MODES.find(mapper_mode))
	_set_status("Click a room cell to add or move waypoint '%s'." % _waypoint_id.text.strip_edges())


func _delete_waypoint() -> void:
	if DraftModel.delete_waypoint(draft, _waypoint_id.text.strip_edges()):
		_commit_mutation()


func _commit_mutation() -> void:
	draft = DraftModel.with_digest(draft)
	_draft_cache[room_id] = draft.duplicate(true)
	var grid := Vector2i(int(draft.grid_wh[0]), int(draft.grid_wh[1]))
	_build_floor(grid)
	_build_art()
	_build_collision()
	_refresh_placement_controls()
	_refresh_storage_controls()
	if _overlay != null:
		_overlay.queue_redraw()


func _refresh_digest_and_art() -> void:
	draft = DraftModel.with_digest(draft)
	_build_art()
	_refresh_placement_controls()
	_refresh_storage_controls()
	if _overlay != null:
		_overlay.queue_redraw()


func _refresh_digest_and_collision() -> void:
	draft = DraftModel.with_digest(draft)
	_build_collision()
	if _overlay != null:
		_overlay.queue_redraw()


func _validate_current() -> Dictionary:
	var shape_node := _operator.get_node_or_null("CollisionShape2D") as CollisionShape2D if _operator != null else null
	var capsule := shape_node.shape as CapsuleShape2D if shape_node != null and shape_node.shape is CapsuleShape2D else null
	return DraftModel.validate(draft, capsule, shape_node.position if shape_node != null else Vector2.ZERO, shape_node.scale if shape_node != null else Vector2.ONE)


func _validate_draft() -> void:
	draft = DraftModel.with_digest(draft)
	_show_report(_validate_current())


func _save_draft() -> void:
	var path := DraftModel.draft_path(room_id)
	if _save_draft_at(path):
		_set_status("Saved draft only: %s\nNo production room or asset was written." % path)


func _save_draft_at(path: String) -> bool:
	draft = DraftModel.with_digest(draft)
	var report := _validate_current()
	if not bool(report.get("passed", false)):
		_show_report(report)
		return false
	if path.is_empty() or not DraftModel.is_safe_output_path(path):
		_set_status("Save blocked: draft path is outside ignored reports/carrow_layout_authoring/.")
		return false
	var directory := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK and not DirAccess.dir_exists_absolute(directory):
		_set_status("Save blocked: could not create the ignored draft directory.")
		return false
	var temp := path + ".tmp"
	var backup := path + ".bak"
	if FileAccess.file_exists(backup):
		_set_status("Save blocked: recovery backup already exists; preserve and inspect it first.")
		return false
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		_set_status("Save blocked: could not open temporary draft file.")
		return false
	file.store_string(DraftModel.serialize(draft))
	file.flush()
	file.close()
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(path, backup) != OK:
		_set_status("Save blocked: existing draft could not be moved to a recovery backup.")
		return false
	if DirAccess.rename_absolute(temp, path) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, path)
		_set_status("Save failed; the prior draft was restored if one existed.")
		return false
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	_draft_cache[room_id] = draft.duplicate(true)
	return true


func _load_draft() -> void:
	var path := DraftModel.draft_path(room_id)
	if not _load_draft_at(path):
		return
	_set_status("Loaded validated draft. Human layout approval is not implied.")


func _load_draft_at(path: String) -> bool:
	if path.is_empty() or not DraftModel.is_safe_output_path(path) or not FileAccess.file_exists(path):
		_set_status("No saved draft exists for %s. The in-memory layout was left unchanged." % room_id)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("Load blocked: draft file could not be read.")
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_set_status("Load blocked: draft JSON is malformed. Existing file was not overwritten.")
		return false
	var candidate := DraftModel.canonical_copy(parsed as Dictionary)
	var shape_node := _operator.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var report := DraftModel.validate(candidate, shape_node.shape as CapsuleShape2D, shape_node.position, shape_node.scale)
	if not bool(report.get("passed", false)):
		_show_report(report)
		return false
	draft = candidate
	_draft_cache[room_id] = draft.duplicate(true)
	_build_preview()
	_refresh_placement_controls()
	_refresh_storage_controls()
	return true


func _export_report() -> void:
	draft = DraftModel.with_digest(draft)
	var report := _validate_current()
	_show_report(report)
	if not bool(report.get("passed", false)):
		return
	var path := DraftModel.draft_path(room_id)
	if path.is_empty() or not DraftModel.is_safe_output_path(path):
		_set_status("Export blocked: report path is outside ignored reports/carrow_layout_authoring/.")
		return
	var report_path := path.trim_suffix(".draft.json") + ".validation.json"
	var payload := report.duplicate(true)
	payload["room_id"] = room_id
	payload["draft_only"] = true
	payload["human_layout_approved"] = false
	payload["draft_content_sha256"] = String(draft.content_sha256)
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		_set_status("Validation passed, but report could not be written.")
		return
	file.store_string(JSON.stringify(payload, "\t", true, true) + "\n")
	file.close()
	_set_status("Exported validation facts only: %s\nDraft remains unapproved and production was untouched." % report_path)


func _show_report(report: Dictionary) -> void:
	var lines: Array[String] = ["VALIDATION: %s" % String(report.get("status", "BLOCKED"))]
	for item in report.get("errors", []):
		lines.append("BLOCK: " + String(item))
	for item in report.get("warnings", []):
		lines.append("NOTE: " + String(item))
	for check_variant in report.get("checks", []):
		var check := check_variant as Dictionary
		if String(check.get("check", "")) == "operator_portal_clearance":
			lines.append("Operator capsule clears portal cell %s" % str(check.get("cell", [])))
		elif String(check.get("check", "")) == "operator_waypoint_clearance":
			lines.append("Operator capsule clears waypoint %s" % String(check.get("id", "")))
	_set_status("\n".join(lines))


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _update_help() -> void:
	if _hud == null:
		return
	_hud.text = "%s · MODE %s · 32px GRID · CAMERA 0.84\nLeft-click/drag edits; right-click erases; G toggles grid; Tab hides panel; Delete removes selection. Save/Validate/Export write draft reports only." % [room_id, mapper_mode]


func get_preview_state() -> Dictionary:
	return {
		"grid": Vector2i(int(draft.get("grid_wh", [0, 0])[0]), int(draft.get("grid_wh", [0, 0])[1])),
		"mode": mapper_mode,
		"show_grid": _show_grid,
		"collision_shapes": draft.get("collision_shapes", []),
		"selected_collision": _selected_collision,
		"portal_cells": draft.get("portal_cells", []),
		"waypoints": draft.get("waypoints", []),
		"drag_rect": _drag_rect,
	}
