class_name CriticalWindowRingVfx
extends Node2D

const SPLIT_MASK_SHADER_SOURCE := """
shader_type canvas_item;

uniform float visible_min_y = 0.0;
uniform float visible_max_y = 1.0;
uniform float feather = 0.02;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float top_alpha = smoothstep(visible_min_y, visible_min_y + feather, UV.y);
	float bottom_alpha = 1.0 - smoothstep(visible_max_y - feather, visible_max_y, UV.y);
	tex.a *= top_alpha * bottom_alpha;
	COLOR = tex;
}
"""

static var _split_mask_shader: Shader = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _near_sprite: AnimatedSprite2D = null


func _ready() -> void:
	z_index = 0
	_configure_depth_split()


func configure_duration(duration: float) -> void:
	var resolved_duration := maxf(duration, 0.05)
	animated_sprite.speed_scale = 1.0 / resolved_duration
	animated_sprite.play(&"countdown")
	if _near_sprite != null:
		_near_sprite.speed_scale = animated_sprite.speed_scale
		_near_sprite.play(&"countdown")


func _configure_depth_split() -> void:
	animated_sprite.z_index = -1
	animated_sprite.material = _create_split_material(0.0, 0.52)

	_near_sprite = animated_sprite.duplicate() as AnimatedSprite2D
	if _near_sprite == null:
		return
	_near_sprite.name = "NearAnimatedSprite2D"
	_near_sprite.z_index = 1
	_near_sprite.material = _create_split_material(0.48, 1.0)
	add_child(_near_sprite)


func _create_split_material(visible_min_y: float, visible_max_y: float) -> ShaderMaterial:
	if _split_mask_shader == null:
		_split_mask_shader = Shader.new()
		_split_mask_shader.code = SPLIT_MASK_SHADER_SOURCE
	var material := ShaderMaterial.new()
	material.shader = _split_mask_shader
	material.set_shader_parameter("visible_min_y", visible_min_y)
	material.set_shader_parameter("visible_max_y", visible_max_y)
	return material
