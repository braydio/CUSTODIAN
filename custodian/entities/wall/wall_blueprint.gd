extends Node2D
class_name WallBlueprint

## Ghost/blueprint version of a wall - no collision, shows where wall will be built

signal built  # Emitted when this blueprint is built

enum WallType {
	BARRICADE,    # Quick-deploy, low HP
	WALL,         # Standard wall
	REINFORCED,   # Heavy, high HP
	DOUBLE_WALL,  # Double thickness
}

const WALL_TYPE_DATA := {
	WallType.BARRICADE: {
		"name": "Barricade",
		"width": 32.0,
		"height": 32.0,
		"color": Color(0.6, 0.5, 0.3, 0.5),  # Brown, semi-transparent
		"build_time": 1.0,
		"hp": 50.0,
	},
	WallType.WALL: {
		"name": "Wall",
		"width": 32.0,
		"height": 64.0,
		"color": Color(0.4, 0.4, 0.45, 0.5),  # Gray, semi-transparent
		"build_time": 2.0,
		"hp": 150.0,
	},
	WallType.REINFORCED: {
		"name": "Reinforced",
		"width": 48.0,
		"height": 64.0,
		"color": Color(0.3, 0.35, 0.4, 0.5),  # Darker gray, semi-transparent
		"build_time": 4.0,
		"hp": 400.0,
	},
	WallType.DOUBLE_WALL: {
		"name": "Double Wall",
		"width": 64.0,
		"height": 64.0,
		"color": Color(0.35, 0.35, 0.5, 0.5),  # Blue-gray, semi-transparent
		"build_time": 5.0,
		"hp": 600.0,
	},
}

@export var wall_type: WallType = WallType.WALL:
	set(value):
		wall_type = value
		_update_visual()

var _visual: ColorRect
var _data: Dictionary

func _ready() -> void:
	_data = WALL_TYPE_DATA[wall_type]
	_build_blueprint()
	_update_visual()

func _build_blueprint() -> void:
	_visual = ColorRect.new()
	_visual.name = "Visual"
	add_child(_visual)
	
	# Add dashed border effect via style
	var style = StyleBoxFlat.new()
	style.bg_color = _data.color
	style.border_color = _data.color.darkened(0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	_visual.add_theme_stylebox_override("normal", style)

func _update_visual() -> void:
	if not _visual:
		return
	
	_data = WALL_TYPE_DATA[wall_type]
	
	_visual.offset_left = -_data.width * 0.5
	_visual.offset_top = -_data.height * 0.5
	_visual.offset_right = _data.width * 0.5
	_visual.offset_bottom = _data.height * 0.5
	
	# Pulsing effect
	var tween = create_tween().set_loops()
	tween.tween_property(_visual, "modulate:a", 0.3, 0.5)
	tween.tween_property(_visual, "modulate:a", 0.6, 0.5)

func get_build_time() -> float:
	return _data.build_time

func get_hp() -> float:
	return _data.hp

func get_size() -> Vector2:
	return Vector2(_data.width, _data.height)

func get_wall_type_name() -> String:
	return _data.name

func get_wall_scene_path() -> String:
	return "res://entities/sector/wall.tscn"

func build() -> void:
	emit_signal("built")
	queue_free()

func get_blueprint_data() -> Dictionary:
	return {
		"type": wall_type,
		"position": global_position,
		"build_time": _data.build_time,
		"hp": _data.hp,
	}