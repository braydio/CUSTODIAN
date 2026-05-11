extends Resource
class_name PropDefinition

@export var id: StringName
@export var base_texture: Texture2D

# Pixel-space anchor. Use bottom-center for most floor props after adding transparent padding.
@export var anchor_offset: Vector2 = Vector2.ZERO
@export var allow_flip_h: bool = true

@export_range(-1.0, 1.0, 0.01) var hue_shift_min: float = -0.015
@export_range(-1.0, 1.0, 0.01) var hue_shift_max: float = 0.015
@export_range(0.0, 2.0, 0.01) var brightness_min: float = 0.88
@export_range(0.0, 2.0, 0.01) var brightness_max: float = 1.12
@export_range(0.0, 2.0, 0.01) var saturation_min: float = 0.85
@export_range(0.0, 2.0, 0.01) var saturation_max: float = 1.10

@export var moss_overlays: Array[Texture2D] = []
@export var crack_overlays: Array[Texture2D] = []
@export var chip_overlays: Array[Texture2D] = []
@export var dirt_overlays: Array[Texture2D] = []
@export var rubble_textures: Array[Texture2D] = []
@export var variant_layers: Array[PropVariantLayer] = []

@export_range(0, 8, 1) var min_overlay_count: int = 0
@export_range(0, 8, 1) var max_overlay_count: int = 3
@export_range(0, 12, 1) var min_rubble_count: int = 0
@export_range(0, 12, 1) var max_rubble_count: int = 4

@export var rubble_spawn_rect: Rect2 = Rect2(Vector2(-24, -4), Vector2(48, 18))
@export var overlay_spawn_rect: Rect2 = Rect2(Vector2(-20, -48), Vector2(40, 48))
@export var allow_overlay_flip_h: bool = true

# Collision is authored per prop type and remains stable across visual variants.
@export var collision_scene: PackedScene
@export var collision_shape_size: Vector2 = Vector2.ZERO
@export var collision_shape_offset: Vector2 = Vector2.ZERO
@export var collision_shape_rotation_degrees: float = 0.0

# Optional local depth sorting for tall props. The prop root z-index is flipped
# around the player so the sprite can sit behind the operator when appropriate.
@export var depth_sort_enabled: bool = false
@export var depth_sort_base_y_offset: float = 0.0
@export var depth_sort_behind_z_index: int = 1
@export var depth_sort_front_z_index: int = 3
@export var occlusion_bounds_size: Vector2 = Vector2.ZERO
@export var occlusion_bounds_offset: Vector2 = Vector2.ZERO
@export var occlusion_front_padding: float = 2.0
@export var occlusion_side_padding: float = 8.0
@export var portal_platform_enabled: bool = false
@export var portal_platform_trigger_offset: Vector2 = Vector2(0, -56)
@export var portal_platform_bottom_offset: Vector2 = Vector2(0, 34)
@export var portal_platform_top_offset: Vector2 = Vector2(0, -10)
@export var portal_platform_lane_half_width: float = 16.0
@export var portal_platform_bottom_width: float = 64.0
@export var portal_platform_top_width: float = 30.0
@export var portal_platform_side_block_width: float = 28.0
@export var portal_platform_side_block_height: float = 44.0
@export var portal_platform_required_elevation: float = 18.0
@export var portal_platform_max_elevation: float = 24.0
@export var portal_platform_speed_multiplier: float = 0.82
@export var portal_platform_dual_approach: bool = false
