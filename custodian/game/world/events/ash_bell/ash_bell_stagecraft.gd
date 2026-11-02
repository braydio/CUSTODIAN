class_name AshBellStagecraft
extends Node2D

@export var site_path: NodePath = NodePath("..")

@export_group("Local Layout")
@export var room_rect: Rect2 = Rect2(Vector2(-240, -160), Vector2(480, 320))
@export var fountain_center: Vector2 = Vector2(0, -12)
@export var fountain_radius: float = 58.0
@export var thread_y: float = 42.0
@export var thread_half_width: float = 168.0
@export var bell_anchor: Vector2 = Vector2(0, -132.0)
@export var entry_y: float = 126.0

@export_group("Rendering")
@export var draw_room_veil: bool = true
@export var draw_bell_shadow: bool = true
@export var draw_thread: bool = true
@export var draw_fountain_ring: bool = true
@export var draw_entry_threshold: bool = true

@onready var site: ForlornRitualantSite = get_node_or_null(site_path)

var _time: float = 0.0


func _ready() -> void:
	z_index = 40
	y_sort_enabled = false


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pressure := 0.0
	var tension := 0.0
	var fountain_state := AshBellEventState.FountainState.ABSENT
	var resolution := AshBellEventState.Resolution.UNSEEN
	var hostile := false

	if site != null and site.event_state != null:
		pressure = clampf(float(site.event_state.silence_pressure) / 100.0, 0.0, 1.0)
		tension = clampf(float(site.event_state.thread_tension) / 100.0, 0.0, 1.0)
		fountain_state = site.event_state.fountain_state
		resolution = site.event_state.resolution
		hostile = site.event_state.ritualant_hostile

	if draw_room_veil:
		_draw_room_veil(pressure, hostile)

	if draw_bell_shadow:
		_draw_bell_shadow(pressure)

	if draw_fountain_ring:
		_draw_fountain(fountain_state, pressure)

	if draw_thread:
		_draw_white_thread(resolution, tension)

	if draw_entry_threshold:
		_draw_entry_threshold(pressure)


func _draw_room_veil(pressure: float, hostile: bool) -> void:
	var alpha := lerpf(0.08, 0.28, pressure)
	if hostile:
		alpha = maxf(alpha, 0.36)

	draw_rect(room_rect, Color(0.01, 0.015, 0.02, alpha), true)

	var top_shadow := Rect2(room_rect.position, Vector2(room_rect.size.x, 56.0))
	draw_rect(top_shadow, Color(0.0, 0.0, 0.0, lerpf(0.18, 0.48, pressure)), true)


func _draw_bell_shadow(pressure: float) -> void:
	var chain_color := Color(0.58, 0.50, 0.36, lerpf(0.22, 0.72, pressure))
	var shadow_color := Color(0.0, 0.0, 0.0, lerpf(0.25, 0.62, pressure))

	draw_line(bell_anchor, fountain_center + Vector2(0, -38), chain_color, 2.0)
	draw_circle(bell_anchor + Vector2(0, -8), 10.0, shadow_color)
	draw_arc(bell_anchor + Vector2(0, 10), 28.0, PI * 0.05, PI * 0.95, 18, shadow_color, 3.0)


func _draw_fountain(fountain_state: int, pressure: float) -> void:
	if fountain_state == AshBellEventState.FountainState.ABSENT:
		draw_arc(fountain_center, fountain_radius, 0.0, TAU, 48, Color(0.16, 0.15, 0.13, 0.28), 2.0)
		return

	var pulse := 0.5 + 0.5 * sin(_time * 2.4)

	var color := Color(0.40, 0.62, 1.0, lerpf(0.25, 0.72, pressure))
	match fountain_state:
		AshBellEventState.FountainState.GHOST:
			color = Color(0.42, 0.62, 1.0, lerpf(0.28, 0.72, maxf(pressure, pulse * 0.35)))
		AshBellEventState.FountainState.BLACK_WATER:
			color = Color(0.02, 0.035, 0.055, lerpf(0.70, 0.95, pressure))
			draw_circle(fountain_center, fountain_radius - 8.0, color)
			color = Color(0.10, 0.18, 0.28, 0.85)
		AshBellEventState.FountainState.CRACKED_ANCHORED:
			color = Color(0.95, 0.77, 0.38, 0.78)

	draw_arc(fountain_center, fountain_radius, 0.0, TAU, 64, color, 3.0)
	draw_arc(fountain_center, fountain_radius - 14.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, color.a * 0.55), 2.0)

	## Cracks / broken basin lines.
	draw_line(fountain_center + Vector2(-28, -8), fountain_center + Vector2(-6, 15), color, 1.0)
	draw_line(fountain_center + Vector2(12, -22), fountain_center + Vector2(30, 10), color, 1.0)
	draw_line(fountain_center + Vector2(-8, 24), fountain_center + Vector2(18, 36), color, 1.0)


func _draw_white_thread(resolution: int, tension: float) -> void:
	if resolution < AshBellEventState.Resolution.SEEN:
		return

	var pulse := 0.5 + 0.5 * sin(_time * lerpf(2.0, 8.0, tension))
	var alpha := lerpf(0.35, 0.98, tension)
	alpha = maxf(alpha, pulse * 0.28)

	var y := thread_y + sin(_time * 1.7) * lerpf(0.5, 2.5, tension)
	var left := Vector2(-thread_half_width, y)
	var right := Vector2(thread_half_width, y)

	draw_line(left, right, Color(0.78, 0.90, 1.0, alpha), 2.0)
	draw_line(left + Vector2(0, 3), right + Vector2(0, 3), Color(0.35, 0.50, 0.70, alpha * 0.30), 1.0)

	## Thread anchor knots.
	draw_circle(left, 4.0, Color(0.78, 0.90, 1.0, alpha))
	draw_circle(right, 4.0, Color(0.78, 0.90, 1.0, alpha))


func _draw_entry_threshold(pressure: float) -> void:
	var y := entry_y
	var color := Color(0.62, 0.56, 0.42, lerpf(0.25, 0.55, pressure))
	draw_line(Vector2(-112, y), Vector2(112, y), color, 3.0)
	draw_line(Vector2(-72, y + 8), Vector2(72, y + 8), Color(0.0, 0.0, 0.0, 0.28), 2.0)
