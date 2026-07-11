extends LevelStage

const OCEAN_UNDERLAY_PATH := "res://content/backgrounds/sundered_keep/ocean_underlay.png"
const CLIFF_DEPTH_UNDERLAY_PATH := "res://content/backgrounds/sundered_keep/cliff_depth_underlay.png"

const RECT_OCEAN_UNDERLAY := Rect2(Vector2(-900.0, -700.0), Vector2(2100.0, 1400.0))
const RECT_CLIFF_DEPTH_UNDERLAY := Rect2(Vector2(-500.0, -440.0), Vector2(520.0, 540.0))
const RECT_CAMERA_BOUNDS := Rect2(Vector2(-1050.0, -760.0), Vector2(2450.0, 1650.0))
const BACKDROP_VOID_COLOR := Color(0.015, 0.018, 0.022, 1.0)


func _ready() -> void:
	stage_id = &"pre_level"
	next_stage_id = &"grand_vista"
	_build_backdrop()

	var trigger := get_node_or_null("ExitToGrandVistaTrigger") as Area2D
	if trigger != null:
		trigger.body_entered.connect(_on_exit_body_entered)


func _on_exit_body_entered(body: Node) -> void:
	if actor != null and body == actor:
		complete_stage()


func get_camera_bounds() -> Rect2:
	return RECT_CAMERA_BOUNDS


func _build_backdrop() -> void:
	var underlay := get_node_or_null("UnderlayBackdrop")
	if underlay == null:
		underlay = Node2D.new()
		underlay.name = "UnderlayBackdrop"
		underlay.z_as_relative = false
		underlay.z_index = -300
		add_child(underlay)

	_add_backdrop_fill(underlay, RECT_CAMERA_BOUNDS)
	_add_fitted_sprite(underlay, "OceanUnderlay", OCEAN_UNDERLAY_PATH, RECT_OCEAN_UNDERLAY, 0, Color.WHITE)
	_add_fitted_sprite(underlay, "CliffDepthUnderlay", CLIFF_DEPTH_UNDERLAY_PATH, RECT_CLIFF_DEPTH_UNDERLAY, 1, Color.WHITE)


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
		push_error("[SunderedKeepPreLevel] Missing texture: %s" % texture_path)
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
	fill.z_as_relative = false
	fill.z_index = -1000
	parent.add_child(fill)
	return fill
