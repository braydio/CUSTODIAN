extends Node2D

const TILE_SIZE := 32.0
const MAP_SIZE_TILES := Vector2i(112, 80)
const SPAWN_TILE := Vector2i(56, 76)
const GAMEPLAY_CAMERA_ZOOM := Vector2(0.84, 0.84)
const UNDERLAY_BOUNDARY_RAIL_RADIUS := 18.0
const UNDERLAY_BOUNDARY_SEGMENTS := [
	[Vector2(1870.9, 2936.8), Vector2(1732.6, 2970.1)],
	[Vector2(1732.6, 2970.1), Vector2(1658.8, 2960.0)],
	[Vector2(1658.8, 2960.0), Vector2(1582.4, 2866.8)],
	[Vector2(1582.4, 2866.8), Vector2(1635.1, 2827.1)],
	[Vector2(1635.1, 2827.1), Vector2(1681.9, 2818.3)],
	[Vector2(1681.9, 2818.3), Vector2(1688.3, 2731.1)],
	[Vector2(1688.3, 2731.1), Vector2(1615.1, 2727.9)],
	[Vector2(1615.1, 2727.9), Vector2(1611.2, 2660.1)],
	[Vector2(1611.2, 2660.1), Vector2(1555.2, 2656.2)],
	[Vector2(1555.2, 2656.2), Vector2(1558.4, 2598.0)],
	[Vector2(1558.4, 2598.0), Vector2(1632.4, 2557.6)],
	[Vector2(1632.4, 2557.6), Vector2(1676.8, 2553.1)],
	[Vector2(1676.8, 2553.1), Vector2(1769.2, 2488.7)],
	[Vector2(1769.2, 2488.7), Vector2(1853.6, 2383.0)],
	[Vector2(1853.6, 2383.0), Vector2(1862.5, 2314.2)],
	[Vector2(1862.5, 2314.2), Vector2(1792.1, 2284.1)],
	[Vector2(1792.1, 2284.1), Vector2(1783.3, 2240.8)],
	[Vector2(1783.3, 2240.8), Vector2(1785.3, 2125.5)],
	[Vector2(1785.3, 2125.5), Vector2(1789.5, 1865.5)],
	[Vector2(1789.5, 1865.5), Vector2(1787.8, 1804.5)],
	[Vector2(1787.8, 1804.5), Vector2(1778.6, 1797.5)],
	[Vector2(1778.6, 1797.5), Vector2(1780.8, 1649.9)],
	[Vector2(1780.8, 1649.9), Vector2(1789.0, 1625.4)],
	[Vector2(1789.0, 1625.4), Vector2(1789.0, 1588.4)],
	[Vector2(1789.0, 1588.4), Vector2(1764.8, 1582.2)],
	[Vector2(1764.8, 1582.2), Vector2(1764.4, 1306.1)],
	[Vector2(1764.4, 1306.1), Vector2(1771.7, 1240.0)],
	[Vector2(1771.7, 1240.0), Vector2(1749.3, 1236.0)],
	[Vector2(1749.3, 1236.0), Vector2(1686.2, 1179.6)],
	[Vector2(1686.2, 1179.6), Vector2(1687.6, 1162.8)],
	[Vector2(1687.6, 1162.8), Vector2(1719.2, 1154.6)],
	[Vector2(1719.2, 1154.6), Vector2(1687.6, 1131.4)],
	[Vector2(1687.6, 1131.4), Vector2(1687.4, 1110.6)],
	[Vector2(1687.4, 1110.6), Vector2(1661.6, 1107.0)],
	[Vector2(1661.6, 1107.0), Vector2(1657.8, 1065.2)],
	[Vector2(1657.8, 1065.2), Vector2(1634.0, 1056.0)],
	[Vector2(1634.0, 1056.0), Vector2(1630.2, 965.0)],
	[Vector2(1630.2, 965.0), Vector2(1671.6, 958.2)],
	[Vector2(1671.6, 958.2), Vector2(1675.4, 909.5)],
	[Vector2(1675.4, 909.5), Vector2(1711.9, 902.1)],
	[Vector2(1711.9, 902.1), Vector2(1800.7, 900.7)],
	[Vector2(1800.7, 900.7), Vector2(1821.5, 911.3)],
	[Vector2(1821.5, 911.3), Vector2(1818.3, 990.3)],
	[Vector2(1818.3, 990.3), Vector2(1842.4, 986.1)],
	[Vector2(1842.4, 986.1), Vector2(1842.4, 1093.3)],
	[Vector2(1842.4, 1093.3), Vector2(1817.8, 1110.8)],
	[Vector2(1817.8, 1110.8), Vector2(1820.5, 1159.3)],
	[Vector2(1820.5, 1159.3), Vector2(1834.4, 1192.2)],
	[Vector2(1834.4, 1192.2), Vector2(1853.4, 1190.1)],
	[Vector2(1853.4, 1190.1), Vector2(1864.3, 1159.6)],
	[Vector2(1864.3, 1159.6), Vector2(1867.6, 1116.0)],
	[Vector2(1867.6, 1116.0), Vector2(1840.0, 1094.1)],
	[Vector2(1840.0, 1094.1), Vector2(1845.4, 986.0)],
	[Vector2(1845.4, 986.0), Vector2(1868.8, 988.1)],
	[Vector2(1868.8, 988.1), Vector2(1867.9, 953.4)],
	[Vector2(1867.9, 953.4), Vector2(1904.9, 953.1)],
	[Vector2(1904.9, 953.1), Vector2(1906.4, 880.3)],
	[Vector2(1906.4, 880.3), Vector2(2061.8, 879.1)],
	[Vector2(2061.8, 879.1), Vector2(2063.6, 954.6)],
	[Vector2(2063.6, 954.6), Vector2(2107.1, 954.6)],
	[Vector2(2107.1, 954.6), Vector2(2108.3, 996.7)],
	[Vector2(2108.3, 996.7), Vector2(2131.1, 994.3)],
	[Vector2(2131.1, 994.3), Vector2(2129.9, 1098.5)],
	[Vector2(2129.9, 1098.5), Vector2(2111.3, 1099.1)],
	[Vector2(2111.3, 1099.1), Vector2(2112.3, 1161.7)],
	[Vector2(2112.3, 1161.7), Vector2(2119.7, 1187.7)],
	[Vector2(2119.7, 1187.7), Vector2(2140.1, 1187.5)],
	[Vector2(2140.1, 1187.5), Vector2(2148.5, 1161.3)],
	[Vector2(2148.5, 1161.3), Vector2(2150.3, 1102.3)],
	[Vector2(2150.3, 1102.3), Vector2(2129.7, 1096.9)],
	[Vector2(2129.7, 1096.9), Vector2(2131.3, 997.1)],
	[Vector2(2131.3, 997.1), Vector2(2152.1, 990.3)],
	[Vector2(2152.1, 990.3), Vector2(2154.1, 914.1)],
	[Vector2(2154.1, 914.1), Vector2(2179.1, 901.2)],
	[Vector2(2179.1, 901.2), Vector2(2266.0, 900.2)],
	[Vector2(2266.0, 900.2), Vector2(2289.4, 912.0)],
	[Vector2(2289.4, 912.0), Vector2(2290.8, 964.8)],
	[Vector2(2290.8, 964.8), Vector2(2360.0, 964.6)],
	[Vector2(2360.0, 964.6), Vector2(2366.3, 1070.6)],
	[Vector2(2366.3, 1070.6), Vector2(2329.0, 1063.3)],
	[Vector2(2329.0, 1063.3), Vector2(2305.7, 1101.1)],
	[Vector2(2305.7, 1101.1), Vector2(2263.2, 1139.4)],
	[Vector2(2263.2, 1139.4), Vector2(2254.4, 1159.1)],
	[Vector2(2254.4, 1159.1), Vector2(2283.9, 1161.7)],
	[Vector2(2283.9, 1161.7), Vector2(2287.6, 1178.3)],
	[Vector2(2287.6, 1178.3), Vector2(2233.2, 1237.3)],
	[Vector2(2233.2, 1237.3), Vector2(2205.7, 1238.9)],
	[Vector2(2205.7, 1238.9), Vector2(2206.1, 1483.1)],
	[Vector2(2206.1, 1483.1), Vector2(2171.5, 1487.2)],
	[Vector2(2171.5, 1487.2), Vector2(2179.1, 1537.2)],
	[Vector2(2179.1, 1537.2), Vector2(2182.7, 1689.8)],
	[Vector2(2182.7, 1689.8), Vector2(2173.7, 1696.5)],
	[Vector2(2173.7, 1696.5), Vector2(2172.4, 1745.6)],
	[Vector2(2172.4, 1745.6), Vector2(2183.2, 1762.3)],
	[Vector2(2183.2, 1762.3), Vector2(2182.7, 1837.5)],
	[Vector2(2182.7, 1837.5), Vector2(2174.2, 1842.0)],
	[Vector2(2174.2, 1842.0), Vector2(2176.0, 1886.9)],
	[Vector2(2176.0, 1886.9), Vector2(2180.0, 1955.6)],
	[Vector2(2180.0, 1955.6), Vector2(2170.1, 1970.5)],
	[Vector2(2170.1, 1970.5), Vector2(2177.3, 2017.0)],
	[Vector2(2177.3, 2017.0), Vector2(2177.8, 2065.8)],
	[Vector2(2177.8, 2065.8), Vector2(2182.3, 2131.5)],
	[Vector2(2182.3, 2131.5), Vector2(2186.8, 2244.9)],
	[Vector2(2186.8, 2244.9), Vector2(2180.0, 2292.1)],
	[Vector2(2180.0, 2292.1), Vector2(2119.7, 2316.9)],
	[Vector2(2119.7, 2316.9), Vector2(2122.8, 2379.3)],
	[Vector2(2122.8, 2379.3), Vector2(2169.2, 2444.2)],
	[Vector2(2169.2, 2444.2), Vector2(2154.4, 2487.7)],
	[Vector2(2154.4, 2487.7), Vector2(2202.1, 2494.4)],
	[Vector2(2202.1, 2494.4), Vector2(2282.7, 2542.2)],
	[Vector2(2282.7, 2542.2), Vector2(2298.4, 2566.1)],
	[Vector2(2298.4, 2566.1), Vector2(2376.3, 2606.7)],
	[Vector2(2376.3, 2606.7), Vector2(2409.2, 2628.3)],
	[Vector2(2409.2, 2628.3), Vector2(2415.9, 2648.1)],
	[Vector2(2415.9, 2648.1), Vector2(2428.5, 2676.9)],
	[Vector2(2428.5, 2676.9), Vector2(2345.7, 2726.9)],
	[Vector2(2345.7, 2726.9), Vector2(2316.4, 2791.7)],
	[Vector2(2316.4, 2791.7), Vector2(2403.3, 2809.8)],
	[Vector2(2403.3, 2809.8), Vector2(2430.8, 2880.0)],
	[Vector2(2430.8, 2880.0), Vector2(2426.3, 2916.9)],
	[Vector2(2426.3, 2916.9), Vector2(2347.9, 2968.7)],
	[Vector2(2347.9, 2968.7), Vector2(2249.3, 2972.3)],
	[Vector2(2249.3, 2972.3), Vector2(2199.3, 2953.9)],
	[Vector2(2199.3, 2953.9), Vector2(2140.3, 2980.4)],
	[Vector2(2140.3, 2980.4), Vector2(2014.7, 2964.7)],
	[Vector2(2014.7, 2964.7), Vector2(1920.1, 2990.8)],
	[Vector2(1920.1, 2990.8), Vector2(1868.8, 2938.1)],
]

var _camera_bounds := Rect2(Vector2.ZERO, Vector2(MAP_SIZE_TILES) * TILE_SIZE)

@onready var _operator: Node2D = $World/Operator
@onready var _camera: Camera2D = $World/Camera2D


func _ready() -> void:
	_build_underlay_boundary_collision()

	if _operator != null:
		_operator.global_position = minimap_tile_to_global(SPAWN_TILE)
	if _camera != null:
		_camera.zoom = GAMEPLAY_CAMERA_ZOOM
		if _has_property(_camera, "base_zoom"):
			_camera.set("base_zoom", GAMEPLAY_CAMERA_ZOOM)
		if _has_property(_camera, "target_zoom"):
			_camera.set("target_zoom", GAMEPLAY_CAMERA_ZOOM)
		if _has_property(_camera, "auto_zoom_enabled"):
			_camera.set("auto_zoom_enabled", true)

	await get_tree().process_frame

	if _camera != null and _camera.has_method("set_runtime_map"):
		_camera.call("set_runtime_map", self)
	elif _camera != null and _operator != null:
		_camera.global_position = _operator.global_position


func get_camera_bounds() -> Rect2:
	return _camera_bounds


func get_entry_position() -> Vector2:
	return minimap_tile_to_global(SPAWN_TILE)


func global_to_minimap_tile(global_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(floori(global_position.x / TILE_SIZE), 0, MAP_SIZE_TILES.x - 1),
		clampi(floori(global_position.y / TILE_SIZE), 0, MAP_SIZE_TILES.y - 1)
	)


func minimap_tile_to_global(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) + 0.5, float(tile.y) + 0.5) * TILE_SIZE


func get_underlay_debug_state() -> Dictionary:
	return {
		"map_size_tiles": MAP_SIZE_TILES,
		"spawn_tile": SPAWN_TILE,
		"entry_position": get_entry_position(),
		"camera_bounds": _camera_bounds,
		"camera_zoom": _camera.zoom if _camera != null else Vector2.ZERO,
		"operator_position": _operator.global_position if _operator != null else Vector2.ZERO,
		"tiles_enabled": false,
		"underlay_boundary_segments": UNDERLAY_BOUNDARY_SEGMENTS.size(),
	}


func _build_underlay_boundary_collision() -> void:
	var world := get_node_or_null("World") as Node2D
	if world == null:
		return

	var bounds_root := world.get_node_or_null("MappedUnderlayBounds") as Node2D
	if bounds_root == null:
		bounds_root = Node2D.new()
		bounds_root.name = "MappedUnderlayBounds"
		world.add_child(bounds_root)
	_clear_children(bounds_root)

	var body := StaticBody2D.new()
	body.name = "UnderlayBoundaryCollision"
	body.collision_layer = 1
	body.collision_mask = 1
	bounds_root.add_child(body)

	var index := 1
	for segment_variant: Variant in UNDERLAY_BOUNDARY_SEGMENTS:
		var segment := segment_variant as Array
		if segment.size() < 2:
			continue
		_add_underlay_boundary_segment(
			body,
			"UnderlayBoundarySegment_%03d" % index,
			segment[0] as Vector2,
			segment[1] as Vector2
		)
		index += 1


func _add_underlay_boundary_segment(parent: StaticBody2D, node_name: String, a: Vector2, b: Vector2) -> CollisionShape2D:
	var direction := b - a
	var length := direction.length()
	var rail := CapsuleShape2D.new()
	rail.radius = UNDERLAY_BOUNDARY_RAIL_RADIUS
	rail.height = maxf(length + UNDERLAY_BOUNDARY_RAIL_RADIUS * 2.0, UNDERLAY_BOUNDARY_RAIL_RADIUS * 2.0)

	var col := CollisionShape2D.new()
	col.name = node_name
	col.shape = rail
	col.position = (a + b) * 0.5
	if length > 0.001:
		col.rotation = direction.angle() - PI * 0.5
	col.set_meta("boundary_a", a)
	col.set_meta("boundary_b", b)
	parent.add_child(col)
	return col


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false
