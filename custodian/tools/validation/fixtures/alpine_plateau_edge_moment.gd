extends Node2D

## Moment Forge fixture for PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS. Generates a
## real seeded ProcGenTilemap under the production alpine_plateau Region Frame
## and parks the camera on the playable plateau's outer edge so the three-depth
## underlay (far world / fog / near cliff mist) can be reviewed at gameplay scale.
## Presentation review only: it never alters generation, collision or navigation.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const FIXTURE_SEED := 424242
const REVIEW_CANDIDATE_ROOT := "res://content/backgrounds/procgen/alpine_plateau/review_candidates/"
## Review-only final six-state candidate family: [layer][variant A/B] -> candidate file.
const FINAL_SIX := {
	"far": ["generation_02/alpine_ruins_among_fog_islands.png", "generation_03/snowy_custodian_ruins_above_the_clouds.png"],
	"fog": ["generation_03/misty_alpine_ruins_overlay.png", "generation_02/translucent_alpine_ruins_cloudscape.png"],
	"near": ["generation_03/floating_alpine_cliffs_in_mist.png", "generation_02/misty_ruined_alpine_plateau_cutout.png"],
}
const REVIEW_ZOOM := 0.74  # tightest ordinary gameplay zoom (camera.gd heavy_zoom)

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
var stack_scale := 1.0
var parallax_far_px := 0.0
var parallax_near_px := 0.0
var coverage_ok := false
var direction := ""
var review_combo := ""

var _map: ProcGenTilemap = null
var _operator: Node2D = null
var _camera: Camera2D = null
var _edge_tiles := {}


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
	_pick_edge_tiles()
	_apply_review_combo()
	_operator = Node2D.new()
	_operator.name = "Operator"
	_operator.z_index = 2
	_operator.add_to_group("player")
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)])
	body.color = Color(0.95, 0.35, 0.2, 1.0)
	_operator.add_child(body)
	add_child(_operator)
	_operator.global_position = _map.tile_to_global_position(_edge_tiles["north"])
	direction = "north"
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = false
	_camera.zoom = Vector2.ONE * REVIEW_ZOOM
	_operator.add_child(_camera)
	_camera.make_current()


## Review-only candidate wiring: when ALPINE_REVIEW_COMBO names a combination
## from review_candidates/UNDERLAY_REVIEW_MANIFEST.json, swap the backdrop's
## underlay for one temporary single-variant profile built from the accepted
## Alpine tuning. Candidates are loaded from disk (the directory carries a
## .gdignore, so they are never imported) and no production resource is touched.
func _apply_review_combo() -> void:
	var final_pick := OS.get_environment("ALPINE_REVIEW_FINAL").to_upper()
	if final_pick != "":
		_apply_final_six(final_pick)
		return
	var combo_id := OS.get_environment("ALPINE_REVIEW_COMBO")
	if combo_id == "":
		return
	var manifest_path := ProjectSettings.globalize_path(REVIEW_CANDIDATE_ROOT + "UNDERLAY_REVIEW_MANIFEST.json")
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary:
		push_error("[AlpineEdgeMoment] review manifest unreadable")
		return
	for combo_variant in (manifest as Dictionary).get("review_combinations", []):
		var combo := combo_variant as Dictionary
		if String(combo.get("combo_id", "")) != combo_id:
			continue
		var accepted: ProcgenUnderlayProfile = _map.depth_backdrop.underlay_profile
		var profile := accepted.duplicate() as ProcgenUnderlayProfile
		profile.profile_id = StringName("review_%s" % combo_id)
		profile.far_variants = [_load_candidate(String(combo["far"]))]
		profile.middle_variants = [_load_candidate(String(combo["fog"]))]
		profile.near_variants = [_load_candidate(String(combo["near"]))]
		_map.depth_backdrop.set_underlay_profile(profile, FIXTURE_SEED)
		review_combo = combo_id
		return
	push_error("[AlpineEdgeMoment] unknown review combo %s" % combo_id)


## ALPINE_REVIEW_FINAL = three letters (FAR, FOG, NEAR) each A or B, e.g. "ABA";
## optional ALPINE_REVIEW_BASEFILL = "r,g,b" (0..1) overrides the base fill tone.
func _apply_final_six(pick: String) -> void:
	if pick.length() != 3 or pick.replace("A", "").replace("B", "") != "":
		push_error("[AlpineEdgeMoment] ALPINE_REVIEW_FINAL must be three of A/B, got %s" % pick)
		return
	var accepted: ProcgenUnderlayProfile = _map.depth_backdrop.underlay_profile
	var profile := accepted.duplicate() as ProcgenUnderlayProfile
	profile.profile_id = StringName("review_final_%s" % pick)
	profile.far_variants = [_load_candidate(FINAL_SIX["far"][0 if pick[0] == "A" else 1])]
	profile.middle_variants = [_load_candidate(FINAL_SIX["fog"][0 if pick[1] == "A" else 1])]
	profile.near_variants = [_load_candidate(FINAL_SIX["near"][0 if pick[2] == "A" else 1])]
	var fill := OS.get_environment("ALPINE_REVIEW_BASEFILL")
	if fill != "":
		var parts := fill.split(",")
		if parts.size() == 3:
			profile.base_fill_color = Color(float(parts[0]), float(parts[1]), float(parts[2]), 1.0)
	_map.depth_backdrop.set_underlay_profile(profile, FIXTURE_SEED)
	review_combo = "final_%s" % pick


func _load_candidate(relative_path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(REVIEW_CANDIDATE_ROOT + relative_path))
	return ImageTexture.create_from_image(image)


## Outermost floor cell toward each compass direction among floor cells that
## touch the exterior CHASM mask (the cells the permanent underlay is for), so an
## enclosed interior room can never be picked as an "edge". Deterministic for a
## fixed seed (sorted scan, strict comparisons keep the first/lowest cell).
func _pick_edge_tiles() -> void:
	var floor_cells: Dictionary = _map.get("_generated_floor_cells")
	var exterior: Dictionary = _map.debug_get_exterior_chasm_cells()
	var keys: Array = floor_cells.keys()
	keys.sort()
	var candidates: Array[Vector2i] = []
	for cell_variant in keys:
		var cell := cell_variant as Vector2i
		for step in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if exterior.has(cell + (step as Vector2i)):
				candidates.append(cell)
				break
	if candidates.is_empty():
		candidates.append(keys[0] as Vector2i)
	var best := {"north": candidates[0], "south": candidates[0], "west": candidates[0], "east": candidates[0]}
	for cell in candidates:
		if cell.y < (best["north"] as Vector2i).y: best["north"] = cell
		if cell.y > (best["south"] as Vector2i).y: best["south"] = cell
		if cell.x < (best["west"] as Vector2i).x: best["west"] = cell
		if cell.x > (best["east"] as Vector2i).x: best["east"] = cell
	_edge_tiles = best
	edge_tile_x = (best["north"] as Vector2i).x
	edge_tile_y = (best["north"] as Vector2i).y


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
		var motion: Dictionary = _map.depth_backdrop.get_depth_motion_snapshot()
		stack_scale = float(motion.get("stack_scale", 1.0))
		var offsets: Dictionary = motion.get("offsets", {})
		parallax_far_px = (offsets.get("far", Vector2.ZERO) as Vector2).length()
		parallax_near_px = (offsets.get("near", Vector2.ZERO) as Vector2).length()
		var visible := get_viewport().get_visible_rect().size
		var margin := float(motion.get("parallax_max_px", 0.0))
		coverage_ok = 1536.0 * stack_scale >= visible.x / REVIEW_ZOOM + 2.0 * margin * stack_scale - 0.01 \
			and 1024.0 * stack_scale >= visible.y / REVIEW_ZOOM + 2.0 * margin * stack_scale - 0.01


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if not command.begins_with("at_"):
		return {"ok": false, "error": "unknown command %s" % command}
	var key := command.trim_prefix("at_")
	if not _edge_tiles.has(key):
		return {"ok": false, "error": "unknown direction %s" % key}
	direction = key
	_operator.global_position = _map.tile_to_global_position(_edge_tiles[key])
	return {"ok": true}
