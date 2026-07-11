extends LevelStage

# Grand vista textures — expected paths for production art.
# These may not exist yet; the stage builds gracefully when they are missing.
const GRAND_VISTA_PANORAMA_PATH := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_panorama.png"
const GRAND_VISTA_FOG_OVERLAY_PATH := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_fog_overlay.png"
const GRAND_VISTA_FOREGROUND_PARAPET_PATH := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_parapet.png"
const GRAND_VISTA_SHADOW_VIGNETTE_PATH := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_shadow_vignette.png"
const GRAND_VISTA_OCEAN_SPRAY_PATH := "res://content/backgrounds/sundered_keep/grand_vista/grand_vista_ocean_spray_overlay.png"

const RECT_FULL_VISTA := Rect2(Vector2(-900.0, -700.0), Vector2(2100.0, 1400.0))
const RECT_CAMERA_BOUNDS := Rect2(Vector2(-1050.0, -760.0), Vector2(2450.0, 1650.0))
const BACKDROP_VOID_COLOR := Color(0.015, 0.018, 0.022, 1.0)

@export var duration_seconds := 5.0
@export var allow_skip := true

var _elapsed := 0.0


func _ready() -> void:
	stage_id = &"grand_vista"
	next_stage_id = &"causeway_approach"
	_build_grand_vista()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if allow_skip and Input.is_action_just_pressed("interact"):
		complete_stage()
		return
	if _elapsed >= duration_seconds:
		complete_stage()


func get_camera_bounds() -> Rect2:
	return RECT_CAMERA_BOUNDS


func _build_grand_vista() -> void:
	var root := Node2D.new()
	root.name = "GrandVistaRoot"
	root.z_as_relative = false
	root.z_index = -200
	add_child(root)

	_add_backdrop_fill(root, RECT_CAMERA_BOUNDS)
	_add_fitted_sprite(root, "GrandVistaPanorama", GRAND_VISTA_PANORAMA_PATH, RECT_FULL_VISTA, 0, Color.WHITE)
	_add_fitted_sprite(root, "GrandVistaFogOverlay", GRAND_VISTA_FOG_OVERLAY_PATH, RECT_FULL_VISTA, 1, Color.WHITE)
	_add_fitted_sprite(root, "GrandVistaForegroundParapet", GRAND_VISTA_FOREGROUND_PARAPET_PATH, RECT_FULL_VISTA, 2, Color.WHITE)
	_add_fitted_sprite(root, "GrandVistaShadowVignette", GRAND_VISTA_SHADOW_VIGNETTE_PATH, RECT_FULL_VISTA, 3, Color.WHITE)
	_add_fitted_sprite(root, "GrandVistaOceanSprayOverlay", GRAND_VISTA_OCEAN_SPRAY_PATH, RECT_FULL_VISTA, 4, Color.WHITE)


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
		push_warning("[SunderedKeepGrandVista] Texture not yet available: %s" % texture_path)
		return null

	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_as_relative = true
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint

	var tex_size := texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(rect.size.x / tex_size.x, rect.size.y / tex_size.y)

	parent.add_child(sprite)
	return sprite


func _add_backdrop_fill(parent: Node, rect: Rect2) -> Polygon2D:
	var fill := Polygon2D.new()
	fill.name = "BackdropVoidFill"
	fill.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	fill.color = BACKDROP_VOID_COLOR
	fill.z_as_relative = true
	fill.z_index = -1000
	parent.add_child(fill)
	return fill
