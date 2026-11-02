extends SceneTree

const PROCGEN_TILEMAP := preload(
	"res://game/world/procgen/proc_gen_tilemap.gd"
)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var map = PROCGEN_TILEMAP.new()
	host.add_child(map)
	var walls := TileMapLayer.new()
	walls.name = "Walls"
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	walls.tile_set = tile_set
	map.add_child(walls)
	map.walls_tilemap = walls
	var floor_cells: Dictionary = {}
	for y in range(3):
		for x in range(3):
			floor_cells[Vector2i(x, y)] = {"source_id": 0}
	map.set("_generated_floor_cells", floor_cells)
	map.call("_rebuild_runtime_walkable_boundary")
	await physics_frame

	var boundary := walls.get_node_or_null("RuntimeWalkableBoundary") as StaticBody2D
	_assert(boundary != null, "walkable frontier did not create collision authority")
	if boundary != null:
		_assert(
			boundary.get_child_count() == 4,
			"merged 3x3 frontier should contain four collision segments"
		)
		_assert(
			bool(boundary.get_meta("non_destructible_traversal_boundary", false)),
			"walkable frontier must be explicitly non-destructible"
		)

	var actor := CharacterBody2D.new()
	var actor_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.0
	actor_shape.shape = circle
	actor.add_child(actor_shape)
	host.add_child(actor)
	await physics_frame
	var center := walls.map_to_local(Vector2i(1, 1))
	for motion in [
		Vector2(-48.0, 0.0),
		Vector2(48.0, 0.0),
		Vector2(0.0, -48.0),
		Vector2(0.0, 48.0),
	]:
		actor.global_position = walls.to_global(center)
		var collision := actor.move_and_collide(motion)
		_assert(
			collision != null,
			"ground actor crossed sampled walkable frontier motion=%s" % motion
		)

	host.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[ProcgenWalkableBoundarySmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenWalkableBoundarySmoke] %s" % error)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
