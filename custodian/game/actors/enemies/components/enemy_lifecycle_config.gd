extends Resource
class_name EnemyLifecycleConfig

@export var starting_health: float = 50.0
@export var maximum_health: float = 50.0
@export var material_drop_min: int = 0
@export var material_drop_max: int = 0
@export var material_drop_fallback_enabled: bool = true
@export var loot_table_id: String = ""
@export var loot_table: Array[Dictionary] = []
@export var empty_corpse_min_lifetime_sec: float = 8.0
@export var corpse_offscreen_margin_px: float = 96.0
@export var empty_corpse_hard_lifetime_sec: float = 45.0
@export var corpse_loot_pickup_radius_px: float = 22.0
@export var corpse_loot_marker_offset: Vector2 = Vector2(0.0, -8.0)
