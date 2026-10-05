extends Node2D

## Moment Forge fixture for PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS. Generates a
## real seeded ProcGenTilemap under the production alpine_plateau Region Frame
## and parks the camera on the playable plateau's outer edge so the three-depth
## underlay (far world / fog / near cliff mist) can be reviewed at gameplay scale.
## Presentation review only: it never alters generation, collision or navigation.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const FIXTURE_SEED := 424242
const INWARD_STEP_TILES := 10

var frame_id := ""
var underlay_profile_id := ""
var visual_fallback := true
var backdrop_visible := false
var backdrop_mode := ""
var edge_tile_x := 0
var edge_tile_y := 0
var variant_far := -1
var variant_middle := -1
var variant_near := -1

var _map: ProcGenTilemap = null
var _operator: Node2D = null
var _camera: Camera2D = null
var _edge_tile := Vector2i.ZERO
var _inward := Vector2i.ZERO


func _ready() -> void:
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
	_map.apply_planet_world_profile({"region_frame_profile_id": "alpine_plateau"})
	_map.enable_streaming_reveal = false
	_map.enable_final_foliage = false
	_map.enable_ruin_prop_spawning = false
	_map.interior_prop_spawning_enabled = false
	_map.auto_bake_nav = false
	_map.generate()
	_pick_edge_tile()
	_operator = Node2D.new()
	_operator.name = "Operator"
	_operator.z_index = 2
	_operator.add_to_group("player")
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)])
	body.color = Color(0.95, 0.35, 0.2, 1.0)
	_operator.add_child(body)
	add_child(_operator)
	_operator.global_position = _map.tile_to_global_position(_edge_tile)
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = false
	_camera.zoom = Vector2(0.75, 0.75)
	_operator.add_child(_camera)
	_camera.make_current()


## Floor cell nearest the map boundary: deterministic for a fixed seed.
func _pick_edge_tile() -> void:
	var size := Vector2i(224, 224)
	var floor_cells: Dictionary = _map.get("_generated_floor_cells")
	var best := Vector2i(-1, -1)
	var best_distance := 1 << 30
	var keys: Array = floor_cells.keys()
	keys.sort()
	for cell_variant in keys:
		var cell := cell_variant as Vector2i
		var distance := mini(mini(cell.x, cell.y), mini(size.x - 1 - cell.x, size.y - 1 - cell.y))
		if distance < best_distance:
			best_distance = distance
			best = cell
	_edge_tile = best
	_inward = Vector2i(signi(size.x / 2 - best.x), signi(size.y / 2 - best.y))
	edge_tile_x = best.x
	edge_tile_y = best.y


func _process(_delta: float) -> void:
	if _map == null:
		return
	var snap: Dictionary = _map.get_region_frame_debug_snapshot()
	frame_id = String(snap.get("frame_id", ""))
	underlay_profile_id = String(snap.get("underlay_profile_id", ""))
	visual_fallback = bool(snap.get("visual_fallback", true))
	backdrop_mode = String(snap.get("backdrop_mode", ""))
	backdrop_visible = _map.depth_backdrop != null and _map.depth_backdrop.visible
	if _map.depth_backdrop != null:
		var indices: Dictionary = _map.depth_backdrop.get_selected_variant_indices()
		variant_far = int(indices.get("far", -1))
		variant_middle = int(indices.get("middle", -1))
		variant_near = int(indices.get("near", -1))


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"at_edge":
			_operator.global_position = _map.tile_to_global_position(_edge_tile)
		"step_inward":
			_operator.global_position = _map.tile_to_global_position(_edge_tile + _inward * INWARD_STEP_TILES)
		_:
			return {"ok": false, "error": "unknown command %s" % command}
	return {"ok": true}
