extends SceneTree

const ELEVATION_MAP_SCRIPT := preload("res://game/world/elevation/elevation_map.gd")


func _init() -> void:
	var elevation_map := ELEVATION_MAP_SCRIPT.new()
	elevation_map.stamp_platform(Rect2i(Vector2i(4, 4), Vector2i(5, 5)), 1, Vector2i(6, 8), ELEVATION_MAP_SCRIPT.DIRECTION_SOUTH)

	var interior := Vector2i(6, 7)
	var ramp := Vector2i(6, 8)
	var approach := Vector2i(6, 9)
	var edge := Vector2i(4, 6)

	assert(elevation_map.get_height(interior) == 1)
	assert(elevation_map.get_height(approach) == 0)
	assert(elevation_map.get_traversal_type(ramp) == ELEVATION_MAP_SCRIPT.TRAVERSAL_RAMP)
	assert(elevation_map.get_traversal_type(edge) == ELEVATION_MAP_SCRIPT.TRAVERSAL_EDGE)
	assert(elevation_map.can_traverse(approach, ramp))
	assert(elevation_map.can_traverse(ramp, interior))
	assert(not elevation_map.can_traverse(approach, edge))
	assert(not elevation_map.can_traverse(Vector2i(0, 0), interior))

	print("[ElevationMapSmoke] ok cells=%d" % elevation_map.get_serialized_cells().size())
	quit(0)
