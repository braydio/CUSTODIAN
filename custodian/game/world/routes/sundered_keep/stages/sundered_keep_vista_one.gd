extends LevelStage

const HORIZON_SKY_PATH := "res://content/backgrounds/sundered_keep/horizon_sky.png"
const FAR_SEA_PATH := "res://content/backgrounds/sundered_keep/far_sea.png"
const DISTANT_KEEP_PATH := "res://content/backgrounds/sundered_keep/distant_sundered_keep.png"
const VISTA_FOG_BAND_PATH := "res://content/backgrounds/sundered_keep/vista_fog_band.png"

const RECT_HORIZON_SKY := Rect2(Vector2(-900.0, -700.0), Vector2(2100.0, 380.0))
const RECT_FAR_SEA := Rect2(Vector2(-900.0, -520.0), Vector2(2100.0, 260.0))
const RECT_DISTANT_KEEP := Rect2(Vector2(-260.0, -670.0), Vector2(540.0, 250.0))
const RECT_VISTA_FOG_BAND := Rect2(Vector2(-900.0, -380.0), Vector2(2100.0, 160.0))

@export var duration_seconds := 4.0

var _elapsed := 0.0


func _ready() -> void:
	stage_id = &"vista_one"
	next_stage_id = &"pre_level"
	_build_vista()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration_seconds:
		complete_stage()


func _build_vista() -> void:
	_add_fitted_sprite(self, "HorizonSky", HORIZON_SKY_PATH, RECT_HORIZON_SKY, -10, Color.WHITE)
	_add_fitted_sprite(self, "FarSea", FAR_SEA_PATH, RECT_FAR_SEA, -9, Color.WHITE)
	_add_fitted_sprite(self, "DistantSunderedKeep", DISTANT_KEEP_PATH, RECT_DISTANT_KEEP, -8, Color.WHITE)
	_add_fitted_sprite(self, "VistaFogBand", VISTA_FOG_BAND_PATH, RECT_VISTA_FOG_BAND, -7, Color.WHITE)


func _add_fitted_sprite(
	parent: Node,
	node_name: String,
	texture_path: String,
	rect: Rect2,
	z: int,
	tint: Color
) -> Sprite2D:
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("[SunderedKeepVistaOne] Missing texture: %s" % texture_path)
		return null

	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_as_relative = false
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint

	var tex_size := texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(rect.size.x / tex_size.x, rect.size.y / tex_size.y)

	parent.add_child(sprite)
	return sprite
