extends Node2D

@export var text: String = ""
@export var lifetime: float = 0.7
@export var rise_speed: float = 42.0
@export var text_color: Color = Color(0.8, 1.0, 0.8, 1.0)

@onready var label = get_node_or_null("Label")
var _age := 0.0

func _ready():
	if label:
		label.text = text
		label.modulate = text_color

func _process(delta):
	_age += delta
	position.y -= rise_speed * delta
	if label:
		var t = clamp(1.0 - (_age / max(0.001, lifetime)), 0.0, 1.0)
		var c = label.modulate
		c.a = t
		label.modulate = c
	if _age >= lifetime:
		queue_free()
