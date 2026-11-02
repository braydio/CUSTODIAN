extends StaticBody2D

var is_open := false

@onready var visual_closed = $VisualClosed
@onready var collision_closed = $CollisionClosed
@onready var collision_open = $CollisionOpen

func _ready():
	update_visuals()

func toggle():
	is_open = !is_open
	update_visuals()

func update_visuals():
	if is_open:
		visual_closed.color = Color(0.3, 0.5, 0.3, 1)  # Green when open
		collision_closed.disabled = true
		collision_open.disabled = false
	else:
		visual_closed.color = Color(0.6, 0.3, 0.2, 1)  # Brown when closed
		collision_closed.disabled = false
		collision_open.disabled = true

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle()
