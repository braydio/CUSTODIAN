extends Node2D

## Moment Forge fixture for PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT (AR4).
## Production ProcGenTilemap streaming + ArchiveResolveVeil at gameplay camera
## scale. The Operator walks at gameplay speed so the review shows a persistent
## unresolved frontier on screen, wall/turn curtains, and a forced
## unload/reacquire leg. The start tile is chosen only for review framing (wall
## density nearby); it never affects gameplay spawn selection.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const FIXTURE_SEED := 424242
const GAMEPLAY_ZOOM := Vector2(0.84, 0.84)
const WALK_SPEED_PX := 230.0

var onscreen_tiles := 0
var onscreen_unresolved := 0
var onscreen_unresolved_pct := 0.0
var active_instances := 0
var frontier_eligible := 0
var frontier_ineligible_distance := 0
var frontier_ineligible_occlusion := 0
var frontier_ineligible_camera := 0
var mask_rebuilds := 0
var mask_rebuild_usec := 0
var started_total := 0
var burst_max := 0
var halo_blocked := 0
var halo_visible_veiled := 0
var settled_count := 0
var reacq_settled := 0
var reacq_age_max := 0.0
var reacq_total := 0
var near_ready := 0
var near_ready_eligible := 0
var near_requested := 0
var operator_in_wall := false
var presentation_time := 0.0
var actor_above_veil := false
var operator_tile_x := 0
var operator_tile_y := 0

var _map: ProcGenTilemap = null
var _operator: Node2D = null
var _camera: Camera2D = null
var _walk_dir := Vector2.ZERO


func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.045, 1.0)
	backdrop.size = Vector2(1280, 720)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = -4000
	add_child(backdrop)
	var runtime := Node2D.new()
	runtime.name = "ProcGenRuntime"
	add_child(runtime)
	_map = PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	runtime.add_child(_map)
	_map.z_index = -100
	var duplicate := _map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
	var generator := _map.get_node("ProcGen2") as Node
	generator.set("generate_seed", false)
	generator.set("seed", FIXTURE_SEED)
	generator.set("map_size", Vector2i(224, 224))
	_map.enable_streaming_reveal = true
	_map.enable_final_foliage = false
	_map.enable_ruin_prop_spawning = false
	_map.interior_prop_spawning_enabled = false
	_map.auto_bake_nav = false
	_map.generate()
	_operator = Node2D.new()
	_operator.name = "Operator"
	_operator.z_index = 2
	_operator.add_to_group("player")
	_operator.global_position = _map.tile_to_global_position(_pick_walled_start())
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)])
	body.color = Color(0.95, 0.35, 0.2, 1.0)
	_operator.add_child(body)
	add_child(_operator)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = false
	_camera.zoom = GAMEPLAY_ZOOM
	_operator.add_child(_camera)
	_camera.make_current()


## Review framing only: valid floor tile with the most wall cells 6..11 tiles
## out, so walls/turns act as curtains in frame.
func _pick_walled_start() -> Vector2i:
	var floor_cells: Array = (_map.get("_generated_floor_cells") as Dictionary).keys()
	floor_cells.sort()
	var walls := _map.get("_generated_wall_cells") as Dictionary
	var best := _map.get_player_spawn()
	var best_score := -1
	for i in range(0, floor_cells.size(), 29):
		var tile: Vector2i = floor_cells[i]
		if not _map.is_valid_spawn_cell(tile):
			continue
		var score := 0
		for dx in range(-11, 12, 2):
			for dy in range(-11, 12, 2):
				if maxi(absi(dx), absi(dy)) >= 6 and walls.has(tile + Vector2i(dx, dy)):
					score += 1
		if score > best_score:
			best_score = score
			best = tile
	return best


func _physics_process(delta: float) -> void:
	if _operator == null or _walk_dir == Vector2.ZERO:
		return
	# The fixture Operator has no collision: keep it on open floor, sliding along
	# walls so the walk stays a plausible gameplay path.
	for dir: Vector2 in [_walk_dir, _walk_dir.rotated(PI * 0.5), _walk_dir.rotated(-PI * 0.5)]:
		var next: Vector2 = _operator.global_position + dir * WALK_SPEED_PX * delta
		var tile: Vector2i = _map._global_to_tile(next + dir * 20.0)
		if _map.floor_tilemap.get_cell_source_id(tile) >= 0 and not _map.is_archive_resolve_occluder_tile(tile):
			_operator.global_position = next
			return


func _process(_delta: float) -> void:
	_refresh_snapshot()


func _refresh_snapshot() -> void:
	if _map == null:
		return
	var veil := _map.debug_get_reveal_presentation()
	if veil == null:
		return
	var snap := veil.get_snapshot()
	var fr: Dictionary = snap.get("frontier", {})
	frontier_eligible = int(fr.get("eligible", 0))
	frontier_ineligible_distance = int(fr.get("ineligible_distance", 0))
	frontier_ineligible_occlusion = int(fr.get("ineligible_occlusion", 0))
	frontier_ineligible_camera = int(fr.get("ineligible_camera", 0))
	mask_rebuilds = int(fr.get("mask_rebuilds", 0))
	mask_rebuild_usec = int(fr.get("mask_rebuild_usec", 0))
	started_total = int(snap.get("frontier_started_count", 0))
	burst_max = int(snap.get("frontier_burst_max", 0))
	halo_blocked = int(snap.get("frontier_halo_blocked_count", 0))
	settled_count = int(snap.get("settled_count", 0))
	reacq_settled = int(snap.get("reacquisition_settle_count", 0))
	reacq_total = int(snap.get("reacquisition_count", 0))
	reacq_age_max = snappedf(float(snap.get("reacquisition_age_max", 0.0)), 0.001)
	presentation_time = float(snap.get("presentation_time", 0.0))
	active_instances = int(snap.get("active_instance_count", 0))
	var op_tile := _map._global_to_tile(_operator.global_position)
	operator_tile_x = op_tile.x
	operator_tile_y = op_tile.y
	actor_above_veil = _absolute_z(_operator) > _absolute_z(veil)
	var rect := _map.get_archive_resolve_camera_tile_rect()
	var total := 0
	var veiled := 0
	var hazard := 0
	var frontier := veil.get_frontier()
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			if _map.floor_tilemap.get_cell_source_id(tile) < 0:
				continue
			total += 1
			var state := veil.get_tile_state(tile)
			if state != 0 and state != ProcGenRevealPresentation.TileState.REQUESTED:
				veiled += 1
			elif state == ProcGenRevealPresentation.TileState.REQUESTED:
				veiled += 1
			if state != 0 and maxi(absi(x - op_tile.x), absi(y - op_tile.y)) <= veil.safety_halo_tiles \
					and state != ProcGenRevealPresentation.TileState.REQUESTED and frontier.is_visible_from_center(tile):
				hazard += 1
	var nr := 0
	var nre := 0
	var nq := 0
	for x in range(op_tile.x - 11, op_tile.x + 12):
		for y in range(op_tile.y - 11, op_tile.y + 12):
			var t := Vector2i(x, y)
			var st := veil.get_tile_state(t)
			if st == ProcGenRevealPresentation.TileState.REQUESTED:
				nq += 1
			elif st == ProcGenRevealPresentation.TileState.READY:
				nr += 1
				if frontier.is_visible_from_center(t):
					nre += 1
	near_ready = nr
	near_ready_eligible = nre
	near_requested = nq
	operator_in_wall = _map.is_archive_resolve_occluder_tile(op_tile)
	onscreen_tiles = total
	onscreen_unresolved = veiled
	onscreen_unresolved_pct = snappedf(100.0 * float(veiled) / maxf(1.0, float(total)), 0.1)
	halo_visible_veiled = hazard


## Adjacent resident chunk with the most generated floor, so the unload leg
## always has terrain to reacquire. Review framing only.
func _richest_adjacent_chunk() -> Vector2i:
	var here := _map._tile_to_chunk(_map._global_to_tile(_operator.global_position))
	var floor_cells := _map.get("_generated_floor_cells") as Dictionary
	var size := _map.streaming_chunk_size_tiles
	var best := here + Vector2i(-1, 0)
	var best_count := -1
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1)]:
		var chunk: Vector2i = here + d
		var count := 0
		for x in range(chunk.x * size, chunk.x * size + size):
			for y in range(chunk.y * size, chunk.y * size + size):
				if floor_cells.has(Vector2i(x, y)):
					count += 1
		if count > best_count:
			best_count = count
			best = chunk
	return best


func _absolute_z(node: Node2D) -> int:
	var total := 0
	var current: Node = node
	while current is Node2D:
		total += (current as Node2D).z_index
		if not (current as Node2D).z_as_relative:
			break
		current = current.get_parent()
	return total


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	var veil := _map.debug_get_reveal_presentation() if _map != null else null
	if veil == null:
		return {"ok": false, "error": "veil unavailable"}
	match command:
		"begin_ingress":
			_map.begin_archive_resolve_ingress(_operator.global_position)
		"walk_east":
			_walk_dir = Vector2.RIGHT
		"walk_south":
			_walk_dir = Vector2.DOWN
		"walk_west":
			_walk_dir = Vector2.LEFT
		"stop":
			_walk_dir = Vector2.ZERO
		"unload_adjacent_west_chunk":
			_map.debug_force_unload_chunk(_richest_adjacent_chunk())
		_:
			return {"ok": false, "error": "unknown command: %s" % command}
	_refresh_snapshot()
	return {"ok": true, "snapshot": veil.get_snapshot()}
