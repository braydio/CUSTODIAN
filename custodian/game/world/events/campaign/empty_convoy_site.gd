class_name EmptyConvoySite
extends Node2D

const MANIFEST_TEXT := "IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED"

var inspect_count := 0


func _ready() -> void:
	add_to_group("interactable")
	queue_redraw()


func can_interact(_actor: Node = null) -> bool:
	return true


func get_interaction_prompt() -> String:
	return "INSPECT CONVOY MANIFEST"


func get_interaction_prompt_body() -> String:
	return MANIFEST_TEXT


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return 72.0


func interact(_actor: Node = null) -> void:
	inspect_count += 1


func _draw() -> void:
	var metal := Color("53616a")
	var shadow := Color("202a31")
	var edge := Color("87949a")
	_draw_wreck(Vector2(-58.0, -42.0), -0.48, metal, shadow, edge)
	_draw_wreck(Vector2(58.0, -42.0), 0.48, metal, shadow, edge)
	_draw_wreck(Vector2(0.0, 62.0), PI, metal, shadow, edge)
	# Empty central cargo cradle with an open side facing the manifest.
	draw_rect(Rect2(Vector2(-25.0, -10.0), Vector2(50.0, 38.0)), shadow, false, 4.0)
	draw_line(Vector2(-20.0, 14.0), Vector2(20.0, 14.0), edge, 3.0)
	# A physical receipt plate; inspecting it has no campaign-state side effects.
	draw_rect(Rect2(Vector2(-39.0, 35.0), Vector2(78.0, 20.0)), Color("b9ae8e"), true)
	var ink := Color("30383a")
	draw_string(ThemeDB.fallback_font, Vector2(-36.0, 43.0), "IN TRANSIT / DISPATCH ABSENT", HORIZONTAL_ALIGNMENT_LEFT, 72.0, 4, ink)
	draw_string(ThemeDB.fallback_font, Vector2(-36.0, 51.0), "RECEIPT UNACKNOWLEDGED", HORIZONTAL_ALIGNMENT_LEFT, 72.0, 4, ink)


func _draw_wreck(origin: Vector2, rotation: float, metal: Color, shadow: Color, edge: Color) -> void:
	var transform := Transform2D(rotation, origin)
	var hull := PackedVector2Array([
		transform * Vector2(-25.0, -10.0),
		transform * Vector2(12.0, -14.0),
		transform * Vector2(27.0, -3.0),
		transform * Vector2(8.0, 12.0),
		transform * Vector2(-21.0, 9.0),
	])
	draw_colored_polygon(hull, metal)
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[0]]), edge, 2.0)
	draw_line(transform * Vector2(-9.0, -4.0), transform * Vector2(12.0, 5.0), shadow, 4.0)
