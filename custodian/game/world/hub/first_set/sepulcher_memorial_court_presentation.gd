class_name SepulcherMemorialCourtPresentation
extends Node2D

## Visual-only production presentation for L04. Geometry, interactions, save
## state, collision and navigation remain owned by their existing systems.
const GRAVE_POSITION := Vector2(-1984.0, -3200.0)
const FLOOR_TEXTURE: Texture2D = preload(
	"res://content/tiles/hub/sepulcher_gardens/hub_first_set_sepulcher_floor_materials_v2_memorial_court_worn_512.png"
)
const RING_TEXTURE: Texture2D = preload(
	"res://content/sprites/environment/props/hub/sepulcher_gardens/hub_first_set_sepulcher_landmark_architecture_v2/runtime/overlay/hub_first_set_sepulcher_landmark_architecture_v2__overlay__landmark__memorial_court_index_ring__omni__1f__512.png"
)
const WALL_MODULE_PREVIEW_TEXTURE: Texture2D = preload(
	"res://content/sprites/environment/props/hub/sepulcher_gardens/hub_first_set_sepulcher_landmark_architecture_v2/runtime/structure/hub_first_set_sepulcher_landmark_architecture_v2__structure__landmark__memorial_court_low_side_wall_module_preview__omni__1f__256x128.png"
)

const FLOOR_RECT := Rect2(GRAVE_POSITION - Vector2(256.0, 256.0), Vector2(512.0, 512.0))
# The wall module's bottom edge contacts the north court edge. It is placed at
# native 256x128 scale, with a 128px gap from the north-west P4 approach.
const WALL_MODULE_CENTER := Vector2(-1856.0, -3520.0)
const WALL_CONTACT_Y := -3456.0
const GRAVE_INSPECTION_POSITIONS: Array[Vector2] = [
	Vector2(-2304.0, -3200.0),
	Vector2(-1536.0, -3200.0),
	Vector2(-1536.0, -2688.0),
]
const GRAVE_RESOLUTION_POSITIONS: Array[Vector2] = [
	Vector2(-2076.0, -3088.0),
	Vector2(-1892.0, -3088.0),
]

var _floor: Sprite2D
var _ring: Sprite2D
var _wall_module_preview: Sprite2D


func _ready() -> void:
	name = "SepulcherMemorialCourtPresentation"
	position = Vector2.ZERO
	_floor = _add_sprite("MemorialCourtWornFloor", FLOOR_TEXTURE, GRAVE_POSITION, 0)
	_ring = _add_sprite("MemorialCourtIndexRing", RING_TEXTURE, GRAVE_POSITION, 0)
	_wall_module_preview = _add_sprite(
		"MemorialCourtLowSideWallModulePreview",
		WALL_MODULE_PREVIEW_TEXTURE,
		WALL_MODULE_CENTER,
		1
	)


func get_visual_contract() -> Dictionary:
	return {
		"grave_position": GRAVE_POSITION,
		"floor_rect": FLOOR_RECT,
		"floor_texture": FLOOR_TEXTURE,
		"ring_texture": RING_TEXTURE,
		"wall_module_texture": WALL_MODULE_PREVIEW_TEXTURE,
		"wall_module_center": WALL_MODULE_CENTER,
		"wall_contact_y": WALL_CONTACT_Y,
		"inspection_positions": GRAVE_INSPECTION_POSITIONS.duplicate(),
		"resolution_positions": GRAVE_RESOLUTION_POSITIONS.duplicate(),
	}


func get_presentation_sprites() -> Array[Sprite2D]:
	return [_floor, _ring, _wall_module_preview]


func _add_sprite(
	sprite_name: String,
	texture: Texture2D,
	world_position: Vector2,
	depth: int
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = world_position
	sprite.z_index = depth
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite
