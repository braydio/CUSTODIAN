extends Node2D

@export var speed: float = 15.0
@export var lifetime: float = 0.18

var age := 0.0
var direction := Vector2.RIGHT

@onready var arc = $Arc
@onready var slash = $Slash


func _ready():
	rotation = direction.angle()


func _process(delta):
	age += delta
	rotation = direction.angle()
	
	var progress = age / lifetime
	
	if arc:
		arc.modulate.a = 1.0 - progress
		arc.scale = Vector2(1.0 + progress * 0.18, 1.0)
	
	if slash:
		slash.modulate.a = 1.0 - progress
	
	if age >= lifetime:
		queue_free()


func set_direction(dir: Vector2):
	direction = dir.normalized()
