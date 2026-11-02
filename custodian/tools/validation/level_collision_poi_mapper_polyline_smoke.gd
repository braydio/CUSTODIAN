extends SceneTree

const Mapper := preload("res://scenes/debug/level_collision_poi_mapper.gd")


func _initialize() -> void:
	var a := Vector2(10, 10)
	var b := Vector2(30, 10)
	var c := Vector2(30, 40)
	var d := Vector2(100, 100)
	var e := Vector2(140, 100)
	var source := [[a, b], [d, e], [b, c]]
	var polylines := Mapper.reconstruct_polylines(source)
	_assert(polylines.size() == 2, "disconnected chains remain separate")
	var compiled := Mapper.compile_polylines(polylines)
	_assert(_segments_equal(compiled, [[a, b], [b, c], [d, e]]), "polyline round-trip preserves segments")
	_assert(not _contains_segment(compiled, c, d), "no bridge segment is introduced")
	var active := [[Vector2(200, 200), Vector2(220, 200)]]
	_assert(Mapper.compile_polylines(active).size() == 1, "active chain compiles only after two points")
	print("level_collision_poi_mapper_polyline_smoke: PASS")
	quit(0)


func _segments_equal(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in actual.size():
		var got := actual[index] as Array
		var want := expected[index] as Array
		if not (got[0] as Vector2).is_equal_approx(want[0] as Vector2):
			return false
		if not (got[1] as Vector2).is_equal_approx(want[1] as Vector2):
			return false
	return true


func _contains_segment(segments: Array, a: Vector2, b: Vector2) -> bool:
	for segment_variant: Variant in segments:
		var segment := segment_variant as Array
		if (segment[0] as Vector2).is_equal_approx(a) and (segment[1] as Vector2).is_equal_approx(b):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("level_collision_poi_mapper_polyline_smoke: %s" % message)
		quit(1)
