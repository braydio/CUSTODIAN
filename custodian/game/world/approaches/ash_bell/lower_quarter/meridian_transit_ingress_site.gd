class_name MeridianTransitIngressSite
extends WorldIngressSite

const CLEARANCE_RECT := Rect2(-176.0, -144.0, 352.0, 288.0)


func _init() -> void:
	requires_explicit_interaction = true


func _ready() -> void:
	super._ready()
	queue_redraw()


func _ensure_visual() -> void:
	# First-pass Meridian municipal transit blockout; no production art authority.
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-144, -112, 288, 224), Color("252b31"), true)
	draw_rect(Rect2(-128, -96, 256, 192), Color("515860"), false, 8.0)
	draw_rect(Rect2(-54, -48, 108, 96), Color("10161b"), true)
	draw_rect(Rect2(-42, -36, 84, 72), Color("c68731"), false, 4.0)
	for index in 9:
		var x := -96.0 + float(index) * 24.0
		var color := Color(0.72, 0.82, 0.86, 0.72) if index < 8 else Color(0.12, 0.14, 0.16, 1.0)
		draw_circle(Vector2(x, -76), 6.0, color)
		if index == 8:
			draw_line(Vector2(x - 7, -83), Vector2(x + 7, -69), Color("8f4d35"), 3.0)
			draw_line(Vector2(x + 7, -83), Vector2(x - 7, -69), Color("8f4d35"), 3.0)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * 116.0 - 8.0, 54.0, 16.0, 36.0), Color("b77a2b"), true)


func get_procgen_dressing_clearance_world_rect() -> Rect2:
	return Rect2(to_global(CLEARANCE_RECT.position), CLEARANCE_RECT.size)
