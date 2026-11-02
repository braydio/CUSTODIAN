extends StaticBody2D
class_name Wall

## Wall sized for 32x32 tile grid (1 tile = 32px)

enum Orientation {
	VERTICAL,
	HORIZONTAL,
}

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
@export_enum("Vertical", "Horizontal") var orientation: int = Orientation.VERTICAL:
	set(value):
		orientation = value
		_rebuild()

var _visual: ColorRect
var _collider: CollisionShape2D

func _ready():
	_build_wall()

func _build_wall():
	# Visual
	_visual = ColorRect.new()
	_visual.name = "Visual"
	_visual.color = wall_color
	add_child(_visual)
	
	# Collision
	var shape = RectangleShape2D.new()
	_collider = CollisionShape2D.new()
	_collider.shape = shape
	add_child(_collider)
	_rebuild()

func _rebuild():
	if _visual and _collider:
		var size := _get_oriented_size()
		_visual.offset_left = -size.x * 0.5
		_visual.offset_top = -size.y * 0.5
		_visual.offset_right = size.x * 0.5
		_visual.offset_bottom = size.y * 0.5
		_collider.shape.size = size

func _update_color():
	if _visual:
		_visual.color = wall_color


func _get_oriented_size() -> Vector2:
	if orientation == Orientation.HORIZONTAL:
		return Vector2(height, width)
	return Vector2(width, height)
