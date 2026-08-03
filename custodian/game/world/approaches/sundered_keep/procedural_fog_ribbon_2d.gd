extends Sprite2D
class_name ProceduralFogRibbon2D

@export var ribbon_size := Vector2(1536.0, 384.0)
@export var fog_tint := Color(0.78, 0.84, 0.90, 0.22)
@export var density := 1.0
@export var noise_scale_a := 7.5
@export var noise_scale_b := 15.0
@export var scroll_a := Vector2(0.020, 0.0)
@export var scroll_b := Vector2(-0.035, 0.0)
@export var edge_softness_top := 0.28
@export var edge_softness_bottom := 0.34
@export var horizontal_breakup := 0.18
@export var time_scale := 1.0

const SHADER := preload(
	"res://game/world/approaches/sundered_keep/"
	+ "procedural_fog_ribbon_band.gdshader"
)


func _ready() -> void:
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	if texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		texture = ImageTexture.create_from_image(image)
	scale = ribbon_size
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	shader_material.set_shader_parameter("fog_color", fog_tint)
	shader_material.set_shader_parameter("density", density)
	shader_material.set_shader_parameter("noise_scale_a", noise_scale_a)
	shader_material.set_shader_parameter("noise_scale_b", noise_scale_b)
	shader_material.set_shader_parameter("scroll_a", scroll_a)
	shader_material.set_shader_parameter("scroll_b", scroll_b)
	shader_material.set_shader_parameter("edge_softness_top", edge_softness_top)
	shader_material.set_shader_parameter("edge_softness_bottom", edge_softness_bottom)
	shader_material.set_shader_parameter("horizontal_breakup", horizontal_breakup)
	shader_material.set_shader_parameter("time_scale", time_scale)
	material = shader_material
