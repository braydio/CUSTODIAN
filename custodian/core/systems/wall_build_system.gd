extends Node
class_name WallBuildSystem

## Handles building walls from blueprints when player interacts

signal wall_built(wall: StaticBody2D, blueprint: WallBlueprint)
signal build_started(blueprint: WallBlueprint, time_remaining: float)
signal build_progress(blueprint: WallBlueprint, progress: float)
signal build_cancelled(blueprint: WallBlueprint)

const WALL_SCENE := preload("res://entities/sector/wall.tscn")
const INTERACTION_RANGE := 48.0

var _current_build: WallBlueprint = null
var _build_progress := 0.0
var _is_building := false

func _process(delta: float) -> void:
	if not _is_building or _current_build == null:
		return
	
	_build_progress -= delta
	emit_signal("build_progress", _current_build, 1.0 - (_build_progress / _current_build.get_build_time()))
	
	if _build_progress <= 0:
		_complete_build()

func start_build(blueprint: WallBlueprint) -> bool:
	if _is_building:
		return false
	
	_current_build = blueprint
	_build_progress = blueprint.get_build_time()
	_is_building = true
	
	emit_signal("build_started", blueprint, _build_progress)
	return true

func cancel_build() -> void:
	if not _is_building:
		return
	
	emit_signal("build_cancelled", _current_build)
	_is_building = false
	_current_build = null
	_build_progress = 0.0

func complete_build_immediate() -> void:
	if _current_build:
		_build_progress = 0.0
		_complete_build()

func _complete_build() -> void:
	if _current_build == null:
		return
	
	var blueprint = _current_build
	var world = get_parent()
	
	# Create real wall at blueprint position
	var wall = WALL_SCENE.instantiate()
	wall.global_position = blueprint.global_position
	
	# Apply wall type properties
	var type_data = WallBlueprint.WALL_TYPE_DATA[blueprint.wall_type]
	wall.width = type_data.width
	wall.height = type_data.height
	wall.wall_color = type_data.color.darkened(0.2)  # Slightly darker than blueprint
	
	# Add to world
	world.add_child(wall)
	
	# Remove blueprint
	var index = world.get_node_or_null("WallPlacer").get_blueprints().find(blueprint) if world.has_node("WallPlacer") else -1
	if world.has_node("WallPlacer"):
		world.get_node("WallPlacer").remove_blueprint(blueprint)
	else:
		blueprint.queue_free()
	
	_is_building = false
	_current_build = null
	_build_progress = 0.0
	
	emit_signal("wall_built", wall, blueprint)
	print("Wall built: ", type_data.name)

func is_building() -> bool:
	return _is_building

func get_current_blueprint() -> WallBlueprint:
	return _current_build

func get_build_progress() -> float:
	if _current_build == null:
		return 0.0
	return 1.0 - (_build_progress / _current_build.get_build_time())