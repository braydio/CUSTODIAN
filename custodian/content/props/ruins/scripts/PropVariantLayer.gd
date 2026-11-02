extends Resource
class_name PropVariantLayer

enum LayerType {
	MOSS,
	CRACK,
	CHIP,
	DIRT,
	VINE,
	HIGHLIGHT,
	SHADOW,
	RUBBLE
}

@export var layer_type: LayerType = LayerType.MOSS
@export var texture: Texture2D
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.5
@export var spawn_rect: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
@export var allow_flip_h: bool = true
@export_range(0.0, 1.0, 0.01) var alpha_min: float = 0.75
@export_range(0.0, 1.0, 0.01) var alpha_max: float = 1.0
@export var z_index: int = 1
