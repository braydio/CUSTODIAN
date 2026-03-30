extends Node2D
class_name WallPlacer

## Manages wall blueprint placement from terminal UI

signal blueprint_placed(blueprint: WallBlueprint)
signal placement_mode_changed(active: bool)

const WALL_BLUEPRINT_SCENE := preload("res://entities/wall/wall_blueprint.tscn")
const GRID_SIZE := 32.0
const SNAP_NEIGHBOR_DISTANCE := 96.0

var _placement_active := false
var _current_wall_type: WallBlueprint.WallType = WallBlueprint.WallType.WALL
var _current_orientation: int = WallBlueprint.Orientation.VERTICAL
var _blueprints: Array[WallBlueprint] = []
var _ghost: WallBlueprint = null
var _can_place := true
var _preview_override_active := false
var _preview_override_world_pos := Vector2.ZERO

func _ready() -> void:
	_set_ghost()

func _process(_delta: float) -> void:
	if not _placement_active:
		return
	
	_update_ghost_position()
	_update_can_place()

func _input(event: InputEvent) -> void:
	if not _placement_active:
		return
	
	# Left click to place
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_place_blueprint()
	
	# Right click to cancel
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			exit_placement_mode()
	
	# Number keys to switch wall type
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: set_wall_type(WallBlueprint.WallType.BARRICADE)
			KEY_2: set_wall_type(WallBlueprint.WallType.WALL)
			KEY_3: set_wall_type(WallBlueprint.WallType.REINFORCED)
			KEY_4: set_wall_type(WallBlueprint.WallType.DOUBLE_WALL)
			KEY_TAB: toggle_orientation()
			KEY_ESCAPE: exit_placement_mode()

func _update_ghost_position() -> void:
	if not _ghost:
		return
	
	var mouse_pos = _preview_override_world_pos if _preview_override_active else get_global_mouse_position()
	var snapped = _get_structured_snap_position(mouse_pos)
	_ghost.global_position = snapped
	
	# Color based on placement validity
	if _can_place:
		_ghost.modulate = Color(1, 1, 1, 0.5)
	else:
		_ghost.modulate = Color(1, 0.3, 0.3, 0.5)

func _update_can_place() -> void:
	if not _ghost:
		return
	
	_can_place = _can_place_blueprint(_ghost.global_position, _ghost.get_size())

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / GRID_SIZE) * GRID_SIZE,
		round(pos.y / GRID_SIZE) * GRID_SIZE
	)


func _get_structured_snap_position(pos: Vector2) -> Vector2:
	var snapped := _snap_to_grid(pos)
	var anchor := _get_nearest_blueprint(snapped, SNAP_NEIGHBOR_DISTANCE)
	if anchor == null:
		return snapped
	var anchor_size := anchor.get_size()
	var candidate_size := _get_current_wall_size()
	var delta := snapped - anchor.global_position
	if delta.length_squared() <= 0.001:
		return anchor.global_position + _get_orientation_step(_current_orientation, anchor_size, candidate_size)
	if absf(delta.x) >= absf(delta.y):
		_current_orientation = WallBlueprint.Orientation.HORIZONTAL
		var step_x := _get_snap_step_size(anchor_size.x, candidate_size.x)
		step_x = step_x if delta.x >= 0.0 else -step_x
		return anchor.global_position + Vector2(step_x, 0.0)
	_current_orientation = WallBlueprint.Orientation.VERTICAL
	var step_y := _get_snap_step_size(anchor_size.y, candidate_size.y)
	step_y = step_y if delta.y >= 0.0 else -step_y
	return anchor.global_position + Vector2(0.0, step_y)

func _place_blueprint() -> void:
	if not _can_place:
		return
	
	var blueprint = WALL_BLUEPRINT_SCENE.instantiate()
	blueprint.wall_type = _current_wall_type
	blueprint.orientation = _current_orientation
	blueprint.global_position = _ghost.global_position
	blueprint.built.connect(_on_blueprint_built)
	
	get_parent().add_child(blueprint)
	_blueprints.append(blueprint)
	
	emit_signal("blueprint_placed", blueprint)
	print("Wall blueprint placed: ", blueprint.get_wall_type_name())


func place_blueprint_at(world_pos: Vector2) -> bool:
	if not _placement_active:
		return false
	var snapped := _get_structured_snap_position(world_pos)
	if _ghost:
		_ghost.global_position = snapped
	_update_can_place()
	if not _can_place:
		return false
	_place_blueprint()
	return true

func _on_blueprint_built() -> void:
	pass  # Handled elsewhere

func enter_placement_mode() -> void:
	_placement_active = true
	_set_ghost()
	_set_placement_mode(true)
	emit_signal("placement_mode_changed", true)

func exit_placement_mode() -> void:
	_placement_active = false
	_preview_override_active = false
	_clear_ghost()
	_set_placement_mode(false)
	emit_signal("placement_mode_changed", false)

func _set_placement_mode(active: bool) -> void:
	# Show/hide cursor hint or other UI elements
	pass

func _set_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
	_ghost = WALL_BLUEPRINT_SCENE.instantiate()
	_ghost.wall_type = _current_wall_type
	_ghost.orientation = _current_orientation
	_ghost.set_process(false)  # Ghost doesn't need process
	add_child(_ghost)


func set_preview_world_position(world_pos: Vector2) -> bool:
	if not _placement_active or _ghost == null:
		return false
	_preview_override_active = true
	_preview_override_world_pos = world_pos
	_ghost.global_position = _get_structured_snap_position(world_pos)
	_update_can_place()
	return _can_place


func clear_preview_world_override() -> void:
	_preview_override_active = false

func _clear_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func set_wall_type(type: WallBlueprint.WallType) -> void:
	_current_wall_type = type
	if _ghost:
		_ghost.wall_type = type
	print("Wall type set to: ", WallBlueprint.WALL_TYPE_DATA[type].name)


func toggle_orientation() -> void:
	_current_orientation = WallBlueprint.Orientation.HORIZONTAL if _current_orientation == WallBlueprint.Orientation.VERTICAL else WallBlueprint.Orientation.VERTICAL
	if _ghost:
		_ghost.orientation = _current_orientation
	print("Wall orientation set to: ", "Horizontal" if _current_orientation == WallBlueprint.Orientation.HORIZONTAL else "Vertical")

func get_blueprints() -> Array[WallBlueprint]:
	return _blueprints

func get_nearest_blueprint(pos: Vector2, max_dist: float = 48.0) -> WallBlueprint:
	return _get_nearest_blueprint(pos, max_dist)


func _get_nearest_blueprint(pos: Vector2, max_dist: float) -> WallBlueprint:
	var nearest: WallBlueprint = null
	var nearest_dist := max_dist
	
	for bp in _blueprints:
		var dist = pos.distance_to(bp.global_position)
		if dist < nearest_dist:
			nearest = bp
			nearest_dist = dist
	
	return nearest

func remove_blueprint(blueprint: WallBlueprint) -> void:
	_blueprints.erase(blueprint)
	blueprint.queue_free()

func get_placement_active() -> bool:
	return _placement_active


func get_preview_world_position() -> Vector2:
	if _ghost == null:
		return Vector2.ZERO
	return _ghost.global_position


func _can_place_blueprint(pos: Vector2, size: Vector2) -> bool:
	var candidate_rect := Rect2(pos - size * 0.5, size)
	for bp in _blueprints:
		var existing_rect := Rect2(bp.global_position - bp.get_size() * 0.5, bp.get_size())
		if candidate_rect.intersects(existing_rect.grow(-2.0)):
			return false
	return true


func _get_orientation_step(orientation: int, anchor_size: Vector2, candidate_size: Vector2) -> Vector2:
	if orientation == WallBlueprint.Orientation.HORIZONTAL:
		return Vector2(_get_snap_step_size(anchor_size.x, candidate_size.x), 0.0)
	return Vector2(0.0, _get_snap_step_size(anchor_size.y, candidate_size.y))


func _get_current_wall_size() -> Vector2:
	var data: Dictionary = WallBlueprint.WALL_TYPE_DATA[_current_wall_type]
	if _current_orientation == WallBlueprint.Orientation.HORIZONTAL:
		return Vector2(data.height, data.width)
	return Vector2(data.width, data.height)


func _get_snap_step_size(anchor_extent: float, candidate_extent: float) -> float:
	var raw_step := (anchor_extent + candidate_extent) * 0.5
	return maxf(GRID_SIZE, round(raw_step / GRID_SIZE) * GRID_SIZE)
