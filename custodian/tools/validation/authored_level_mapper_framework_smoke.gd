extends SceneTree

func _initialize() -> void:
	var polylines: Array = [
		[Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)],
		[Vector2(100, 100), Vector2(120, 100)],
	]
	var compiled := LevelCollisionPoiMapper.compile_polylines(polylines)
	var expected := [[Vector2(0, 0), Vector2(10, 0)], [Vector2(10, 0), Vector2(10, 10)], [Vector2(100, 100), Vector2(120, 100)]]
	if compiled != expected or compiled.any(func(pair: Array) -> bool: return pair[0] == Vector2(10, 10) and pair[1] == Vector2(100, 100)):
		push_error("disconnected polylines compiled with an unintended bridge")
		quit(1)
	var reconstructed := LevelCollisionPoiMapper.reconstruct_polylines(compiled)
	if LevelCollisionPoiMapper.compile_polylines(reconstructed) != compiled:
		push_error("collision segment round-trip changed geometry")
		quit(1)
	print("authored_level_mapper_framework_smoke: PASS")
	quit(0)

