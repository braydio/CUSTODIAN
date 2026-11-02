extends Node2D
## Read-only geometry presentation. No collision, events, loot, persistence, or navigation.
const GARDENS := preload("res://game/world/hub/first_set/sepulcher_gardens_geometry_v1.gd")
const OBSTACLE_COLORS := {
    "water": Color("29495e"),
    "debris": Color("594b47"),
    "sealed": Color("504750"),
    "collapse": Color("292930"),
}

func _ready() -> void:
    z_index = 12
    queue_redraw()

func _draw() -> void:
    # Colliders derive ONLY from the original walkable mask, never these polygons.
    for feature in GARDENS.OBSTACLES:
        var points := PackedVector2Array()
        for raw_point in feature["world_polygon"]:
            points.append(raw_point as Vector2)
        draw_colored_polygon(points, OBSTACLE_COLORS.get(feature["kind"], Color("3f4344")))
        var outline := points.duplicate()
        outline.append(points[0])
        draw_polyline(outline, Color("c4b5a3"), 3.0)
    for route in GARDENS.ROUTES:
        var points := PackedVector2Array()
        for raw_point in route["world_waypoints"]:
            points.append(raw_point as Vector2)
        draw_polyline(points, Color("b7a77b", 0.58), float(route["clear_width_cells"]) * 24.0)
        draw_polyline(points, Color("dfc898", 0.85), 2.5)
    for feature in GARDENS.LANDMARKS:
        var p: Vector2 = feature["world"]
        draw_circle(p, 16.0, Color("d8c79a"))
        draw_circle(p, 11.0, Color("303a34"))
        if ThemeDB.fallback_font != null:
            draw_string(ThemeDB.fallback_font, p + Vector2(22.0, 7.0),
                str(feature["id"]) + " " + str(feature["name"]),
                HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("f1e9c9"))
    # Development hint markers only. Not actual inventory items or discovery triggers.
    for secret in GARDENS.SECRETS:
        var p: Vector2 = secret["world"]
        draw_circle(p, 7.0, Color("efc879"))
        if ThemeDB.fallback_font != null:
            draw_string(ThemeDB.fallback_font, p + Vector2(10.0, -5.0),
                str(secret["id"]) + " · PROPOSED", HORIZONTAL_ALIGNMENT_LEFT,
                -1.0, 16, Color("efcf92"))
