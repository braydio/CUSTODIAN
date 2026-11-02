extends Node2D

## Moment Forge fixture for PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO. Production
## ProcGenTilemap streaming + ArchiveResolveVeil at the gameplay camera scale:
## a one-time ingress resolve around the Operator (the same
## `begin_archive_resolve_ingress` call the contract-world loader makes after
## final placement), a first-contact chunk crossing (semantic echo + normal
## frontier), and a forced unload/reacquisition for the lighter/shorter compare.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const FIXTURE_SEED := 424242
const CHUNK_STEP_PX := 16 * 32 * 2
const GAMEPLAY_ZOOM := Vector2(0.84, 0.84)

var ingress_pending := 0
var ingress_begin_count := 0
var ingress_owned := 0
var resolving := 0
var active_instances := 0
var presentation_time := 0.0
var echo_writes := 0
var echo_natural := 0
var echo_road := 0
var echo_constructed := 0
var echo_wall_cliff := 0
var echo_landmark := 0
var first_resolve_age_max := 0.0
var first_resolve_age_avg := 0.0
var reacq_settled := 0
var reacq_age_max := 0.0
var reacq_age_avg := 0.0
var reacq_echo_writes_delta := 0
var actor_above_veil := false
var pocket_veiled_committed := 0

var _map: ProcGenTilemap = null
var _operator: Node2D = null
var _ingress_center := Vector2i.ZERO
var _echo_before_reacq := 0


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
	_operator.global_position = _map.tile_to_global_position(_pick_varied_start())
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)])
	body.color = Color(0.95, 0.35, 0.2, 1.0)
	_operator.add_child(body)
	add_child(_operator)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = false
	camera.zoom = GAMEPLAY_ZOOM
	_operator.add_child(camera)
	camera.make_current()


## Review framing only: a deterministic floor tile whose neighbourhood mixes
## road, wall/cliff, and constructed cells so one pass shows several classes.
## Never used for gameplay spawn selection.
func _pick_varied_start() -> Vector2i:
	var floor_cells: Array = (_map.get("_generated_floor_cells") as Dictionary).keys()
	floor_cells.sort()
	var best := _map.get_player_spawn()
	var best_score := -1
	for i in range(0, floor_cells.size(), 37):
		var tile: Vector2i = floor_cells[i]
		if not _map.is_valid_spawn_cell(tile):
			continue
		var seen := [0, 0, 0, 0, 0]
		for dx in range(-18, 19, 3):
			for dy in range(-18, 19, 3):
				var kind := _map.get_archive_resolve_presentation_class(tile + Vector2i(dx, dy))
				seen[kind] += 1
		var score := mini(seen[1], 6) + mini(seen[3], 6) + mini(seen[2], 6) + mini(seen[4], 3) * 2
		if score > best_score:
			best_score = score
			best = tile
	return best


func _process(_delta: float) -> void:
	_refresh_snapshot()


func _refresh_snapshot() -> void:
	if _map == null:
		return
	var veil := _map.debug_get_reveal_presentation()
	if veil == null:
		return
	var snap := veil.get_snapshot()
	ingress_pending = int(snap.get("ingress_pending_count", 0))
	ingress_begin_count = int(snap.get("ingress_begin_count", 0))
	resolving = int(snap.get("resolving_count", 0))
	active_instances = int(snap.get("active_instance_count", 0))
	presentation_time = float(snap.get("presentation_time", 0.0))
	echo_writes = int(snap.get("echo_write_count", 0))
	var counts: Array = snap.get("echo_class_counts", [0, 0, 0, 0, 0])
	echo_natural = int(counts[0])
	echo_road = int(counts[1])
	echo_constructed = int(counts[2])
	echo_wall_cliff = int(counts[3])
	echo_landmark = int(counts[4])
	first_resolve_age_max = snappedf(float(snap.get("first_resolve_age_max", 0.0)), 0.001)
	first_resolve_age_avg = snappedf(float(snap.get("first_resolve_age_avg", 0.0)), 0.001)
	reacq_settled = int(snap.get("reacquisition_settle_count", 0))
	reacq_age_max = snappedf(float(snap.get("reacquisition_age_max", 0.0)), 0.001)
	reacq_age_avg = snappedf(float(snap.get("reacquisition_age_avg", 0.0)), 0.001)
	reacq_echo_writes_delta = echo_writes - _echo_before_reacq if _echo_before_reacq > 0 else 0
	actor_above_veil = _operator != null and _absolute_z(_operator) > _absolute_z(veil)
	var pocket := maxi(veil.ingress_pocket_tiles, veil.safety_halo_tiles)
	var bad := 0
	if ingress_begin_count > 0:
		for x in range(_ingress_center.x - pocket, _ingress_center.x + pocket + 1):
			for y in range(_ingress_center.y - pocket, _ingress_center.y + pocket + 1):
				var tile := Vector2i(x, y)
				if veil.has_veil(tile) and veil.get_tile_state(tile) != ProcGenRevealPresentation.TileState.REQUESTED:
					bad += 1
	pocket_veiled_committed = bad


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
			var result := _map.begin_archive_resolve_ingress(_operator.global_position)
			_ingress_center = result.get("center_tile", Vector2i.ZERO)
			ingress_owned = int(result.get("owned_cells", 0))
		"step_east":
			_operator.global_position += Vector2(CHUNK_STEP_PX, 0.0)
		"step_west":
			_operator.global_position -= Vector2(CHUNK_STEP_PX, 0.0)
		"mark_reacq_baseline":
			_echo_before_reacq = maxi(1, int(veil.get_snapshot().get("echo_write_count", 0)))
		"unload_adjacent_west_chunk":
			var chunk := _map._tile_to_chunk(_map._global_to_tile(_operator.global_position)) + Vector2i(-1, 0)
			_map.debug_force_unload_chunk(chunk)
		_:
			return {"ok": false, "error": "unknown command: %s" % command}
	_refresh_snapshot()
	return {"ok": true, "snapshot": veil.get_snapshot()}
