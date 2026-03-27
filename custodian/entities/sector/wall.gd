extends StaticBody2D
class_name Wall

## Wall sized for 32x32 tile grid (1 tile = 32px)

@export var width: float = 32.0:
	set(value):
		width = value
		_rebuild()

@export var height: float = 32.0:
	set(value):
		height = value
		_rebuild()

@export var wall_color: Color = Color(0.4, 0.35, 0.3, 1):
	set(value):
		wall_color = value
		_update_color()

var _visual: ColorRect
var _collider: CollisionShape2D

func _ready():
	_build_wall()

func _build_wall():
	# Visual
	_visual = ColorRect.new()
	_visual.name = "Visual"
	_visual.color = wall_color
	_visual.offset_left = -width * 0.5
	_visual.offset_top = -height * 0.5
	_visual.offset_right = width * 0.5
	_visual.offset_bottom = height * 0.5
	add_child(_visual)
	
	# Collision
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	_collider = CollisionShape2D.new()
	_collider.shape = shape
	add_child(_collider)

func _rebuild():
	if _visual and _collider:
		_visual.offset_left = -width * 0.5
		_visual.offset_top = -height * 0.5
		_visual.offset_right = width * 0.5
		_visual.offset_bottom = height * 0.5
		_collider.shape.size = Vector2(width, height)

func _update_color():
	if _visual:
		_visual.color = wall_color
