extends Node2D

@export var base_radius: Vector2 = Vector2(11.0, 5.5)
@export var shadow_alpha: float = 0.24
@export var stretch_per_speed: float = 0.0012
@export var max_stretch: float = 0.22
@export var squash_per_speed: float = 0.00045
@export_range(8, 48, 1) var point_count: int = 20
@export var shadow_texture: Texture2D
@export var shadow_tint: Color = Color(0.15, 0.19, 0.26, 1.0)

var _current_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	show_behind_parent = true
	z_index = -1
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	self.material = material
	queue_redraw()


func _process(_delta: float) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var next_velocity := Vector2.ZERO
	var velocity_value: Variant = parent_node.get("velocity")
	if velocity_value is Vector2:
		next_velocity = velocity_value

	if next_velocity == _current_velocity:
		return
	_current_velocity = next_velocity
	queue_redraw()


func _draw() -> void:
	var speed := _current_velocity.length()
	var stretch: float = min(speed * stretch_per_speed, max_stretch)
	var squash: float = min(speed * squash_per_speed, max_stretch * 0.5)
	var radii := Vector2(
		base_radius.x * (1.0 + stretch),
		base_radius.y * max(0.7, 1.0 - squash)
	)
	if shadow_texture != null:
		draw_texture_rect(
			shadow_texture,
			Rect2(-radii, radii * 2.0),
			false,
			Color(shadow_tint.r, shadow_tint.g, shadow_tint.b, shadow_alpha)
		)
		return
	draw_colored_polygon(_build_ellipse_points(radii), Color(shadow_tint.r, shadow_tint.g, shadow_tint.b, shadow_alpha))


func _build_ellipse_points(radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_point_count: int = max(point_count, 8)
	for index in range(safe_point_count):
		var t := TAU * float(index) / float(safe_point_count)
		points.append(Vector2(cos(t) * radii.x, sin(t) * radii.y))
	return points
