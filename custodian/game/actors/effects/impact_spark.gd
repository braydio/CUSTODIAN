extends Node2D

@export var strip_texture: Texture2D
@export var frame_size: Vector2i = Vector2i(64, 64)
@export var total_frames: int = 4
@export var used_frames: int = 4
@export var fps: float = 24.0
@onready var visual: Sprite2D = get_node_or_null("Visual")

var _elapsed: float = 0.0
var _duration: float = 0.0

func _ready():
	if visual == null:
		queue_free()
		return
	if strip_texture == null:
		queue_free()
		return

	total_frames = max(1, total_frames)
	used_frames = clamp(used_frames, 1, total_frames)
	fps = max(1.0, fps)
	_duration = float(used_frames) / fps

	visual.texture = strip_texture
	visual.centered = true
	visual.region_enabled = true
	_set_frame(0)


func _process(delta: float) -> void:
	if visual == null:
		return
	_elapsed += delta
	var frame: int = min(used_frames - 1, int(floor(_elapsed * fps)))
	_set_frame(frame)
	if _elapsed >= _duration:
		queue_free()


func _set_frame(frame: int) -> void:
	var safe_frame: int = clamp(frame, 0, used_frames - 1)
	var fx: int = safe_frame % total_frames
	var region: Rect2 = Rect2(
		float(frame_size.x * fx),
		0.0,
		float(frame_size.x),
		float(frame_size.y)
	)
	visual.region_rect = region
