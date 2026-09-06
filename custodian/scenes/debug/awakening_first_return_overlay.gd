extends Node2D

## Debug draw for the Awakening blockout: zone envelopes, the critical path, the
## optional branch, collision, landmarks, camera reveals, encounter slots and
## future-art anchors. Reads AwakeningLayout only — it never authors geometry.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")

const COLOR_ENVELOPE := Color(0.65, 0.71, 0.72, 0.55)
const COLOR_OPTIONAL := Color(0.50, 0.42, 0.26, 0.65)
const COLOR_CRITICAL := Color(0.28, 0.45, 0.48, 0.9)
const COLOR_BRANCH := Color(0.50, 0.42, 0.26, 0.9)
const COLOR_COLLISION := Color(0.85, 0.25, 0.25, 0.35)
const COLOR_ENCOUNTER := Color(0.85, 0.35, 0.35, 0.95)
const COLOR_TRIGGER := Color(0.35, 0.75, 0.85, 0.95)
const COLOR_INTERACT := Color(0.95, 0.82, 0.35, 0.95)
const COLOR_MARKER := Color(0.75, 0.78, 0.78, 0.85)
const COLOR_REVEAL := Color(0.65, 0.45, 0.85, 0.95)

@export var show_zone_bounds := true
@export var show_landmarks := true
@export var show_collision := false

var awakening: Node = null


func _ready() -> void:
	z_index = 900
	z_as_relative = false


func _draw() -> void:
	if show_zone_bounds:
		_draw_envelopes()
	_draw_route()
	if show_collision:
		_draw_collision()
	if show_landmarks:
		_draw_landmarks()


func _draw_envelopes() -> void:
	for zone in Layout.ZONES:
		var envelope: Rect2 = zone["envelope"]
		var color := COLOR_OPTIONAL if bool(zone.get("optional", false)) else COLOR_ENVELOPE
		draw_rect(envelope, color, false, 3.0)
		draw_string(
			ThemeDB.fallback_font,
			envelope.position + Vector2(8, 28),
			"%02d %s" % [int(zone["index"]), String(zone["location"])],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color
		)


func _draw_route() -> void:
	for key in Layout.CONNECTORS:
		var color := COLOR_BRANCH if String(key).begins_with("09") else COLOR_CRITICAL
		draw_rect(Layout.CONNECTORS[key], color, false, 3.0)
	for key in Layout.THRESHOLDS:
		draw_rect(Layout.THRESHOLDS[key], COLOR_CRITICAL, false, 2.0)
	# Entry -> exit spine, so the critical path reads at a glance.
	for zone in Layout.ZONES:
		draw_line(zone["entry"], zone["exit"], COLOR_CRITICAL, 2.0)
		draw_circle(zone["entry"], 10.0, COLOR_CRITICAL)
		draw_circle(zone["exit"], 6.0, COLOR_CRITICAL)


func _draw_collision() -> void:
	for zone in Layout.ZONES:
		var zone_id := StringName(zone["id"])
		for area in Layout.floors_for(zone_id):
			var polygon := Layout.rect_to_polygon(area) if area is Rect2 else Layout.to_polygon(area as Array)
			draw_polyline(_closed(polygon), COLOR_COLLISION, 2.0)
		for hole in Layout.VOID_POLYGONS.get(zone_id, []):
			draw_polyline(_closed(Layout.to_polygon(hole as Array)), COLOR_COLLISION, 2.0)
		for piece in Layout.set_pieces_for(zone_id):
			if not bool(piece.get("blocking", false)): continue
			draw_rect(Layout.set_piece_rect(piece), COLOR_COLLISION, true)
	for rect in Layout.road_blocking_rects():
		draw_rect(rect, COLOR_COLLISION, false, 2.0)


func _draw_landmarks() -> void:
	for zone in Layout.ZONES:
		var zone_id := StringName(zone["id"])
		for marker in Layout.markers_for(zone_id):
			var position: Vector2 = marker.get("position", Vector2.ZERO)
			var color := _marker_color(String(marker.get("kind", "marker")))
			draw_circle(position, 9.0, color)
			draw_string(
				ThemeDB.fallback_font, position + Vector2(14, 6),
				String(marker.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color
			)
		# Future-art anchors: the underlay canvas each zone reserves.
		var envelope: Rect2 = zone["envelope"]
		draw_rect(envelope.grow(64.0), Color(0.35, 0.45, 0.48, 0.25), false, 1.0)
	for zone_id in Layout.CAMERA_REVEALS:
		var reveal: Dictionary = Layout.CAMERA_REVEALS[zone_id]
		var rect := Rect2(reveal["trigger"] - reveal["size"] * 0.5, reveal["size"])
		draw_rect(rect, COLOR_REVEAL, false, 3.0)
		draw_string(
			ThemeDB.fallback_font, rect.position + Vector2(0, -8),
			"REVEAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_REVEAL
		)
	draw_rect(Layout.south_reach_completion_rect(), COLOR_TRIGGER, false, 3.0)
	draw_rect(Layout.south_reach_barrier_rect(), COLOR_COLLISION, true)


func _marker_color(kind: String) -> Color:
	match kind:
		"encounter": return COLOR_ENCOUNTER
		"trigger": return COLOR_TRIGGER
		"interactable", "lift": return COLOR_INTERACT
		_: return COLOR_MARKER


func _closed(polygon: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array(polygon)
	if result.size() > 0: result.append(result[0])
	return result
