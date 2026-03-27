extends Node2D
class_name WallPlacer

## Manages wall blueprint placement from terminal UI

signal blueprint_placed(blueprint: WallBlueprint)
signal placement_mode_changed(active: bool)

const WALL_BLUEPRINT_SCENE := preload("res://entities/wall/wall_blueprint.tscn")
const GRID_SIZE := 16.0  # 16px fine grid

var _placement_active := false
var _current_wall_type: WallBlueprint.WallType = WallBlueprint.WallType.WALL
var _blueprints: Array[WallBlueprint] = []
var _ghost: WallBlueprint = null
var _can_place := true

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
			KEY_ESCAPE: exit_placement_mode()

func _update_ghost_position() -> void:
	if not _ghost:
		return
	
	var mouse_pos = get_global_mouse_position()
	var snapped = _snap_to_grid(mouse_pos)
	_ghost.global_position = snapped
	
	# Color based on placement validity
	if _can_place:
		_ghost.modulate = Color(1, 1, 1, 0.5)
	else:
		_ghost.modulate = Color(1, 0.3, 0.3, 0.5)

func _update_can_place() -> void:
	if not _ghost:
		return
	
	var pos = _ghost.global_position
	var size = _ghost.get_size()
	
	# Check collision with existing walls
	for bp in _blueprints:
		if bp.global_position == pos:
			_can_place = false
			return
	
	# Check bounds (could add more validation here)
	_can_place = true

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / GRID_SIZE) * GRID_SIZE,
		round(pos.y / GRID_SIZE) * GRID_SIZE
	)

func _place_blueprint() -> void:
	if not _can_place:
		return
	
	var blueprint = WALL_BLUEPRINT_SCENE.instantiate()
	blueprint.wall_type = _current_wall_type
	blueprint.global_position = _ghost.global_position
	blueprint.built.connect(_on_blueprint_built)
	
	get_parent().add_child(blueprint)
	_blueprints.append(blueprint)
	
	emit_signal("blueprint_placed", blueprint)
	print("Wall blueprint placed: ", blueprint.get_wall_type_name())

func _on_blueprint_built() -> void:
	pass  # Handled elsewhere

func enter_placement_mode() -> void:
	_placement_active = true
	_set_ghost()
	_set_placement_mode(true)
	emit_signal("placement_mode_changed", true)

func exit_placement_mode() -> void:
	_placement_active = false
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
	_ghost.set_process(false)  # Ghost doesn't need process
	add_child(_ghost)

func _clear_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func set_wall_type(type: WallBlueprint.WallType) -> void:
	_current_wall_type = type
	if _ghost:
		_ghost.wall_type = type
	print("Wall type set to: ", WallBlueprint.WALL_TYPE_DATA[type].name)

func get_blueprints() -> Array[WallBlueprint]:
	return _blueprints

func get_nearest_blueprint(pos: Vector2, max_dist: float = 48.0) -> WallBlueprint:
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