extends SceneTree
const VEHICLE := preload("res://game/vehicles/pilotable_vehicle.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _case_basic_clearance_and_turning()
	await _case_a_immediate_side_blocked()
	await _case_b_expanded_radius_reachable()
	await _case_c_geometrically_clear_but_walled_off()
	await _case_d_emergency_fallback_to_entry()
	await _case_e_pathological_total_blockage()
	print("vehicle_exit_clearance_smoke: PASS")
	quit(0)


func _make_vehicle() -> PilotableVehicle:
	var vehicle := VEHICLE.new() as PilotableVehicle
	root.add_child(vehicle)
	vehicle.movement_profile = {"max_speed": 100.0, "acceleration": 1000.0, "turn_response": 1.0, "reverse_multiplier": 0.45}
	return vehicle


func _make_pilot() -> CharacterBody2D:
	var pilot := CharacterBody2D.new()
	var pilot_shape := CollisionShape2D.new()
	pilot_shape.name = "CollisionShape2D"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 24.0
	pilot_shape.shape = capsule
	pilot.add_child(pilot_shape)
	root.add_child(pilot)
	return pilot


func _make_box_blocker(position: Vector2, size: Vector2) -> StaticBody2D:
	var blocker := StaticBody2D.new()
	blocker.collision_layer = 1
	blocker.position = position
	var blocker_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	blocker_shape.shape = box
	blocker.add_child(blocker_shape)
	root.add_child(blocker)
	return blocker


func _case_basic_clearance_and_turning() -> void:
	var vehicle := _make_vehicle()
	var pilot := _make_pilot()
	vehicle.pilot = pilot
	vehicle.control_state = PilotableVehicle.ControlState.PILOTED
	vehicle._pilot_collision_mask = 1
	var blocker := _make_box_blocker(Vector2(56, 0), Vector2(30, 30))
	assert(not vehicle.call("_is_exit_position_clear", Vector2(56, 0)))
	assert(vehicle.call("_is_exit_position_clear", Vector2(-56, 0)))
	assert((vehicle.call("_find_exit_position") as Vector2).is_equal_approx(Vector2(-56, 0)))
	vehicle.velocity = Vector2.DOWN * 30.0
	vehicle.facing_direction = Vector2.DOWN
	vehicle.call("_apply_movement", Vector2.RIGHT, false, 0.016)
	var slow_turn_x := vehicle.velocity.x
	vehicle.velocity = Vector2.DOWN * 30.0
	vehicle.movement_profile["turn_response"] = 30.0
	vehicle.call("_apply_movement", Vector2.RIGHT, false, 0.016)
	assert(vehicle.velocity.x > slow_turn_x)
	blocker.queue_free()
	pilot.queue_free()
	vehicle.queue_free()
	await process_frame
	await process_frame


## A. Immediate right side blocked, left side clear: exit picks the clear
## near-radius candidate rather than searching further.
func _case_a_immediate_side_blocked() -> void:
	var vehicle := _make_vehicle()
	var pilot := _make_pilot()
	vehicle.pilot = pilot
	vehicle.control_state = PilotableVehicle.ControlState.PILOTED
	vehicle._pilot_collision_mask = 1
	vehicle.facing_direction = Vector2.DOWN
	var blocker := _make_box_blocker(Vector2(-56, 0), Vector2(30, 30))
	await physics_frame
	var exit_position := vehicle.call("_find_exit_position") as Vector2
	assert(exit_position.is_equal_approx(Vector2(56, 0)))
	assert(vehicle._last_exit_candidate_count > 0)
	assert(not vehicle._last_exit_used_emergency_fallback)
	blocker.queue_free()
	pilot.queue_free()
	vehicle.queue_free()
	await process_frame
	await process_frame


## B. Every 56px candidate is blocked but a reachable 128-192px candidate
## exists: exit succeeds via the expanded deterministic ring search rather
## than trapping the player.
func _case_b_expanded_radius_reachable() -> void:
	var vehicle := _make_vehicle()
	var pilot := _make_pilot()
	vehicle.pilot = pilot
	vehicle.control_state = PilotableVehicle.ControlState.PILOTED
	vehicle._pilot_collision_mask = 1
	vehicle.facing_direction = Vector2.DOWN
	# A wide, thin ring of blockers covering every ~56-104px candidate but
	# leaving the outer 128px+ ring open.
	var near_blocker := _make_box_blocker(Vector2.ZERO, Vector2(220, 220))
	await physics_frame
	var exit_position := vehicle.call("_find_exit_position") as Vector2
	assert(exit_position != Vector2.INF)
	assert(exit_position.length() >= 110.0)
	assert(vehicle.call("_is_exit_position_clear", exit_position))
	near_blocker.queue_free()
	pilot.queue_free()
	vehicle.queue_free()
	await process_frame
	await process_frame


## C. A candidate can be geometrically clear (no collision overlap) while
## still lying across an impassable wall from the vehicle's local area. The
## reachability gate must reject it using real navigation-graph connectivity,
## not just a point-in-space collision check.
func _case_c_geometrically_clear_but_walled_off() -> void:
	var vehicle := _make_vehicle()
	var pilot := _make_pilot()
	vehicle.pilot = pilot
	vehicle.control_state = PilotableVehicle.ControlState.PILOTED
	vehicle._pilot_collision_mask = 1

	# Tile coordinates are kept non-negative: NavigationSystem's Vector2i -> id
	# hashing is not exercised with negative cells anywhere else in the
	# codebase, and is out of scope for this vehicle-exit repair.
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var navigation := _build_walled_navigation_system(Vector2i(0, 0), Vector2i(8, 8), 3, game_root)
	await process_frame

	var open_far_side := Vector2(176, 48)
	var open_near_side := Vector2(48, 48)
	assert(vehicle.call("_is_exit_position_clear", open_far_side))
	assert(not vehicle.call("_is_exit_candidate_reachable", open_far_side))
	assert(vehicle.call("_is_exit_position_clear", open_near_side))
	assert(vehicle.call("_is_exit_candidate_reachable", open_near_side))

	navigation.queue_free()
	game_root.queue_free()
	pilot.queue_free()
	vehicle.queue_free()
	await process_frame


## D. No local exit is available anywhere in the deterministic search, but
## the pilot's saved entry position is still safe: the emergency fallback
## must return the player there rather than leaving them trapped.
func _case_d_emergency_fallback_to_entry() -> void:
	var vehicle := _make_vehicle()
	var pilot := _make_pilot()
	vehicle.control_state = PilotableVehicle.ControlState.UNOCCUPIED
	var entry_position := Vector2(30, 0)
	pilot.global_position = entry_position
	var entered := vehicle.enter_vehicle(pilot)
	assert(entered)
	vehicle._pilot_collision_mask = 1
	vehicle.facing_direction = Vector2.DOWN
	# Simulate having driven the vehicle away from its (safe) boarding spot
	# into a tight pocket before the player tries to exit.
	vehicle.global_position = Vector2(1000, 1000)
	var trap := _make_box_blocker(Vector2(1000, 1000), Vector2(700, 700))
	await physics_frame
	var exit_position := vehicle.call("_find_exit_position") as Vector2
	assert(exit_position.is_equal_approx(entry_position))
	assert(vehicle._last_exit_used_emergency_fallback)
	assert(vehicle.exit_vehicle())
	assert(vehicle.control_state == PilotableVehicle.ControlState.UNOCCUPIED)
	assert(pilot.global_position.is_equal_approx(entry_position))
	trap.queue_free()
	pilot.queue_free()
	vehicle.queue_free()
	await process_frame
	await process_frame


## E. Pathological: absolutely no safe candidate exists anywhere, and the
## saved entry position is itself now invalid (e.g. it got swallowed by
## the same blockage). Exit must fail cleanly, with telemetry recording the
## failure, rather than crashing or silently teleporting through geometry.
func _case_e_pathological_total_blockage() -> void:
	var vehicle := _make_vehicle()
	var pilot := _make_pilot()
	vehicle.control_state = PilotableVehicle.ControlState.UNOCCUPIED
	pilot.global_position = Vector2.ZERO
	var entered := vehicle.enter_vehicle(pilot)
	assert(entered)
	vehicle._pilot_collision_mask = 1
	vehicle.facing_direction = Vector2.DOWN
	var trap := _make_box_blocker(Vector2.ZERO, Vector2(4000, 4000))
	await physics_frame
	assert(not vehicle.exit_vehicle())
	assert(vehicle.control_state == PilotableVehicle.ControlState.PILOTED)
	assert(vehicle.pilot == pilot)
	trap.queue_free()
	pilot.queue_free()
	vehicle.queue_free()


## Builds a minimal but real TileMapLayer-backed NavigationSystem: an open
## floor rect with a one-tile-thick wall column splitting it in half, so
## graph-based reachability (not mere point clearance) actually gets
## exercised. Registers itself at /root/GameRoot/NavigationSystem.
func _build_walled_navigation_system(
	origin: Vector2i,
	size: Vector2i,
	wall_column_x: int,
	parent: Node
) -> Node:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	var source := TileSetAtlasSource.new()
	var texture := ImageTexture.create_from_image(
		Image.create(32, 32, false, Image.FORMAT_RGBA8)
	)
	source.texture = texture
	source.texture_region_size = Vector2i(32, 32)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)

	var floor_tilemap := TileMapLayer.new()
	floor_tilemap.name = "Floor"
	floor_tilemap.tile_set = tile_set
	var walls_tilemap := TileMapLayer.new()
	walls_tilemap.name = "Walls"
	walls_tilemap.tile_set = tile_set

	var navigation := Node.new()
	navigation.name = "NavigationSystem"
	navigation.set_script(load("res://game/systems/core/systems/navigation_system.gd"))
	navigation.add_child(floor_tilemap)
	navigation.add_child(walls_tilemap)
	# Must be inside the tree before set_runtime_tilemaps/rebuild since
	# _initialize_navigation() calls get_tree().
	parent.add_child(navigation)

	for x in range(origin.x, origin.x + size.x):
		for y in range(origin.y, origin.y + size.y):
			floor_tilemap.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
			if x == wall_column_x:
				walls_tilemap.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

	navigation.call("set_runtime_tilemaps", floor_tilemap, walls_tilemap, null)
	navigation.call("rebuild")
	return navigation
