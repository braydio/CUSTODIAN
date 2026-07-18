extends Node2D
class_name LightRig2D

@export var light_color: Color = Color(1.0, 0.82, 0.45, 1.0):
	set(value):
		light_color = value
		_apply_light_settings()
@export_range(0.0, 8.0, 0.01) var energy: float = 1.0:
	set(value):
		energy = value
		_apply_light_settings()
@export var pulse_enabled: bool = false
@export_range(0.0, 20.0, 0.01) var pulse_speed: float = 2.0
@export_range(0.0, 1.0, 0.01) var pulse_amount: float = 0.12
@export_range(0.1, 8.0, 0.01) var glow_scale: float = 1.0
@export var light_texture: Texture2D:
	set(value):
		light_texture = value
		if is_node_ready():
			_ensure_glow_texture()
			_apply_light_settings()
@export var glow_texture: Texture2D:
	set(value):
		glow_texture = value
		if is_node_ready():
			_ensure_glow_texture()
			_apply_light_settings()
@export var shadows_enabled: bool = true:
	set(value):
		shadows_enabled = value
		_apply_light_settings()
@export_range(0.0, 256.0, 1.0) var light_height: float = 32.0:
	set(value):
		light_height = value
		_apply_light_settings()
@export var light_texture_scale: Vector2 = Vector2.ONE:
	set(value):
		light_texture_scale = value
		_apply_light_settings()
@export var glow_texture_scale: Vector2 = Vector2.ONE:
	set(value):
		glow_texture_scale = value
		_apply_light_settings()

@onready var point_light: PointLight2D = get_node_or_null("PointLight2D") as PointLight2D
@onready var glow_sprite: Sprite2D = get_node_or_null("GlowSprite") as Sprite2D

var _pulse_time := 0.0


func _ready() -> void:
	_ensure_glow_texture()
	_apply_light_settings()
	set_process(pulse_enabled)


func _process(delta: float) -> void:
	if not pulse_enabled:
		return
	_pulse_time += delta * pulse_speed
	var pulse := 1.0 + sin(_pulse_time) * pulse_amount
	_apply_light_settings(pulse)


func _apply_light_settings(pulse_multiplier: float = 1.0) -> void:
	if point_light != null:
		point_light.color = light_color
		point_light.energy = energy * pulse_multiplier
		point_light.shadow_enabled = shadows_enabled
		point_light.height = light_height
		point_light.scale = light_texture_scale
		if light_texture != null:
			point_light.texture = light_texture
	if glow_sprite != null:
		glow_sprite.modulate = Color(light_color.r, light_color.g, light_color.b, clampf(0.2 + energy * 0.22, 0.0, 1.0))
		glow_sprite.scale = glow_texture_scale * glow_scale * pulse_multiplier
		if glow_texture != null:
			glow_sprite.texture = glow_texture


func _ensure_glow_texture() -> void:
	var fallback_texture := _get_or_create_glow_texture()
	if point_light != null:
		point_light.texture = light_texture if light_texture != null else fallback_texture
	if glow_sprite != null:
		glow_sprite.texture = glow_texture if glow_texture != null else fallback_texture
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow_sprite.material = material


func _get_or_create_glow_texture() -> Texture2D:
	var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(31.5, 31.5)
	for y in range(64):
		for x in range(64):
			var distance := center.distance_to(Vector2(x, y)) / 31.5
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
