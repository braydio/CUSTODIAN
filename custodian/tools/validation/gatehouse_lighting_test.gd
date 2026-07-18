extends Node2D

const DUST_SHEET_PATH := "res://content/sprites/world/lighting/lightshaft_dust_96x192.png"
const DUST_ANIMATION := &"drift"
const DUST_FRAME_SIZE := Vector2i(96, 192)
const DUST_FRAME_COUNT := 8

@onready var dust_sprite: AnimatedSprite2D = get_node_or_null("WindowDust") as AnimatedSprite2D


func _ready() -> void:
	_build_dust_animation()


func _build_dust_animation() -> void:
	if dust_sprite == null or not ResourceLoader.exists(DUST_SHEET_PATH):
		return
	var texture := load(DUST_SHEET_PATH) as Texture2D
	if texture == null or texture.get_size() != Vector2(DUST_FRAME_SIZE.x * DUST_FRAME_COUNT, DUST_FRAME_SIZE.y):
		return
	var frames := SpriteFrames.new()
	frames.add_animation(DUST_ANIMATION)
	frames.set_animation_loop(DUST_ANIMATION, true)
	frames.set_animation_speed(DUST_ANIMATION, 10.0)
	for frame_index in range(DUST_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * DUST_FRAME_SIZE.x, 0, DUST_FRAME_SIZE.x, DUST_FRAME_SIZE.y)
		frames.add_frame(DUST_ANIMATION, atlas)
	dust_sprite.sprite_frames = frames
	dust_sprite.play(DUST_ANIMATION)
