extends Node2D

## Moment Forge fixture for PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1. Drives the
## production ProcGenTilemap streaming + ArchiveResolveVeil path (no generation
## or scheduling changes): the Operator stand-in crosses chunk boundaries so new
## chunks go REQUESTED -> READY -> RESOLVING -> settled under the real shader.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const FIXTURE_SEED := 424242
const CHUNK_STEP_PX := 16 * 32 * 2

var requested := 0
var ready_count := 0
var resolving := 0
var settled := 0
var active_instances := 0
var presentation_time := 0.0
var reduced_effects := false
var tree_paused := false
var shader_enabled := false
var shared_material_count := 0
var actor_above_veil := false
var unloaded_chunks := 0
var reacquisitions := 0
var operator_chunk_x := 0
var operator_chunk_y := 0

var _map: ProcGenTilemap = null
var _operator: Node2D = null
var _home := Vector2.ZERO
var _camera: Camera2D = null


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
	_map.z_index = -100  # same as ContractWorldLoader._attach_procgen_map
	var duplicate := _map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
	var generator := _map.get_node("ProcGen2") as Node
	generator.set("generate_seed", false)
	generator.set("seed", FIXTURE_SEED)
	generator.set("map_size", Vector2i(224, 224))  # production contract-map max
	_map.enable_streaming_reveal = true
	_map.enable_final_foliage = false
	_map.enable_ruin_prop_spawning = false
	_map.interior_prop_spawning_enabled = false
	_map.auto_bake_nav = false
	_map.generate()
	_home = _map.tile_to_global_position(_map.get_player_spawn())
	_operator = Node2D.new()
	_operator.name = "Operator"
	_operator.z_index = 2
	_operator.add_to_group("player")
	_operator.global_position = _home
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)])
	body.color = Color(0.95, 0.35, 0.2, 1.0)
	_operator.add_child(body)
	add_child(_operator)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = false
	_camera.zoom = Vector2(0.5, 0.5)  # review framing: keep the leading reveal band in view
	_operator.add_child(_camera)
	_camera.make_current()


func _process(_delta: float) -> void:
	_refresh_snapshot()


func _refresh_snapshot() -> void:
	if _map == null:
		return
	var veil := _map.debug_get_reveal_presentation()
	if veil == null:
		return
	var snap := veil.get_snapshot()
	requested = int(snap.get("requested_uncommitted_count", 0))
	ready_count = int(snap.get("committed_ready_count", 0))
	resolving = int(snap.get("resolving_count", 0))
	settled = int(snap.get("settled_count", 0))
	active_instances = int(snap.get("active_instance_count", 0))
	presentation_time = float(snap.get("presentation_time", 0.0))
	reduced_effects = bool(snap.get("reduced_effects", false))
	shader_enabled = bool(snap.get("shader_enabled", false))
	shared_material_count = int(snap.get("shared_material_count", 0))
	reacquisitions = int(snap.get("reacquisition_count", 0))
	tree_paused = get_tree().paused
	if _operator != null:
		var chunk := _map._tile_to_chunk(_map._global_to_tile(_operator.global_position))
		operator_chunk_x = chunk.x
		operator_chunk_y = chunk.y
	actor_above_veil = _operator != null and _absolute_z(_operator) > _absolute_z(veil)


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
		"step_east":
			_operator.global_position += Vector2(CHUNK_STEP_PX, 0.0)
		"step_west":
			_operator.global_position -= Vector2(CHUNK_STEP_PX, 0.0)
		"step_north":
			_operator.global_position -= Vector2(0.0, CHUNK_STEP_PX)
		"unload_adjacent_west_chunk":
			var chunk := _map._tile_to_chunk(_map._global_to_tile(_operator.global_position)) + Vector2i(-1, 0)
			_map.debug_force_unload_chunk(chunk)
			unloaded_chunks += 1
		"pause_tree":
			get_tree().paused = true
		"resume_tree":
			get_tree().paused = false
		"reduced_on":
			veil.reduced_effects = true
		"reduced_off":
			veil.reduced_effects = false
		_:
			return {"ok": false, "error": "unknown command: %s" % command}
	_refresh_snapshot()
	return {"ok": true, "snapshot": veil.get_snapshot()}
