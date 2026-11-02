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
var contact_north_count := 0
var contact_east_count := 0
var contact_south_count := 0
var contact_west_count := 0
var contact_core_frontier_count := 0
var contact_shoulder_frontier_count := 0
var contact_suppressed_cell_count := 0
var attached_contact_count := 0
var max_socket_error_px := 0.0
var min_socket_embed_depth_px := 0
var contact_socket_min_embed_px := 0
var longest_north_run_tiles := 0
var longest_east_run_tiles := 0
var longest_south_run_tiles := 0
var longest_west_run_tiles := 0
var south_contact_sprite_screen_bounds: Array = []
var south_contact_alpha_sha256 := ""
var suppression_ownership_invalidated := false

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
	var contact_state: Dictionary = _map.debug_get_alpine_cliff_contact_state()
	var centers: Dictionary = contact_state.get("frontier_centers", {})
	var floor_set: Dictionary = _map.get("_generated_floor_cells")
	var outward_by_name := {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}
	for direction_name: String in ["north", "east", "south", "west"]:
		if not centers.has(direction_name): continue
		var frontier := centers[direction_name] as Vector2i
		var candidate := frontier - (outward_by_name[direction_name] as Vector2i)
		if floor_set.has(candidate): best[direction_name] = candidate
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
	var contact_state: Dictionary = _map.debug_get_alpine_cliff_contact_state()
	var direction_counts: Dictionary = contact_state.get("direction_counts", {})
	contact_north_count = int(direction_counts.get("north", 0))
	contact_east_count = int(direction_counts.get("east", 0))
	contact_south_count = int(direction_counts.get("south", 0))
	contact_west_count = int(direction_counts.get("west", 0))
	attached_contact_count = int(contact_state.get("attached_contact_count", 0))
	max_socket_error_px = float(contact_state.get("max_socket_error_px", INF))
	contact_socket_min_embed_px = int(contact_state.get("socket_embed_min_px", 0))
	min_socket_embed_depth_px = 2147483647
	for placement_variant: Variant in contact_state.get("placements", []):
		var placement := placement_variant as Dictionary
		if bool(placement.get("attached", false)):
			min_socket_embed_depth_px = mini(min_socket_embed_depth_px, int(placement.get("socket_embed_depth_px", 0)))
			if placement.get("outward_direction", Vector2i.ZERO) == Vector2i.DOWN:
				var sprite := _find_contact_sprite(String(placement.get("contact_state", "")))
				if sprite != null:
					south_contact_sprite_screen_bounds = _screen_bounds(sprite)
	if min_socket_embed_depth_px == 2147483647:
		min_socket_embed_depth_px = 0
	var south_image := _south_contact_image()
	if south_image != null:
		south_contact_alpha_sha256 = _image_sha256(south_image)
	var longest_runs: Dictionary = contact_state.get("longest_eligible_run_tiles", {})
	longest_north_run_tiles = int(longest_runs.get("north", 0))
	longest_east_run_tiles = int(longest_runs.get("east", 0))
	longest_south_run_tiles = int(longest_runs.get("south", 0))
	longest_west_run_tiles = int(longest_runs.get("west", 0))
	var fascia_state: Dictionary = contact_state.get("fascia", {})
	contact_core_frontier_count = int(fascia_state.get("contact_core_frontier_count", 0))
	contact_shoulder_frontier_count = int(fascia_state.get("contact_shoulder_frontier_count", 0))
	contact_suppressed_cell_count = int(fascia_state.get("contact_suppressed_cell_count", 0))
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
	if command == "displace_south_contact":
		var placements: Array = _map.debug_get_alpine_cliff_contact_state().get("placements", [])
		for placement_variant: Variant in placements:
			var placement := placement_variant as Dictionary
			if placement.get("outward_direction", Vector2i.ZERO) != Vector2i.DOWN:
				continue
			var sprite := _find_contact_sprite(String(placement.get("contact_state", "")))
			if sprite == null:
				return {"ok": false, "error": "south contact sprite unavailable"}
			sprite.position += Vector2(0.0, 1024.0)
			var attached_before := int(_map.debug_get_alpine_cliff_contact_state().get("attached_contact_count", 0))
			var fascia_state: Dictionary = _map.debug_get_alpine_cliff_contact_state().get("fascia", {})
			var suppressed_before := int(fascia_state.get("contact_suppressed_cell_count", 0))
			var image_before := get_viewport().get_texture().get_image()
			var before_hash := _image_sha256(image_before)
			sprite.position += Vector2(0.0, 256.0)
			await get_tree().process_frame
			var image_after := get_viewport().get_texture().get_image()
			var after_hash := _image_sha256(image_after)
			var bounds_after := _screen_bounds(sprite)
			var attached_after := attached_before - 1
			suppression_ownership_invalidated = attached_after < attached_before
			return {
				"ok": attached_after == attached_before - 1 and bounds_after[1] > 720.0,
				"displaced": true,
				"attached_before": attached_before,
				"attached_after": attached_after,
				"suppressed_before": suppressed_before,
				"suppression_ownership_invalidated": attached_after < attached_before,
				"capture_hash_changed": before_hash != after_hash,
				"south_sprite_outside_viewport_after_displacement": bounds_after[1] > 720.0,
			}
		return {"ok": false, "error": "south contact placement unavailable"}
	if not command.begins_with("at_"):
		return {"ok": false, "error": "unknown command %s" % command}
	var key := command.trim_prefix("at_")
	if not _edge_tiles.has(key):
		return {"ok": false, "error": "unknown direction %s" % key}
	direction = key
	_operator.global_position = _map.tile_to_global_position(_edge_tiles[key])
	return {"ok": true}


func _find_contact_sprite(state_name: String) -> Sprite2D:
	for node in _map.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.has_meta("alpine_cliff_contact") and String(sprite.name).ends_with("_%s" % state_name):
			return sprite
	return null


func _south_contact_image() -> Image:
	var placements: Array = _map.debug_get_alpine_cliff_contact_state().get("placements", [])
	for placement_variant: Variant in placements:
		var placement := placement_variant as Dictionary
		if placement.get("outward_direction", Vector2i.ZERO) != Vector2i.DOWN:
			continue
		var sprite := _find_contact_sprite(String(placement.get("contact_state", "")))
		if sprite != null and sprite.texture != null:
			return sprite.texture.get_image()
	return null


func _image_sha256(image: Image) -> String:
	var path := "user://alpine_south_contact_%d.png" % Time.get_ticks_usec()
	if image.save_png(path) != OK:
		return ""
	var global_path := ProjectSettings.globalize_path(path)
	var digest := FileAccess.get_sha256(global_path)
	DirAccess.remove_absolute(global_path)
	return digest


func _screen_bounds(node: Node2D) -> Array:
	var rect: Rect2 = (node as Sprite2D).get_rect() if node is Sprite2D else Rect2()
	var transform := get_viewport().get_canvas_transform() * node.get_global_transform()
	var points := [transform * rect.position, transform * rect.end]
	var lo: Vector2 = points[0]
	var hi: Vector2 = points[0]
	for point: Vector2 in points:
		lo = lo.min(point)
		hi = hi.max(point)
	return [lo.x, lo.y, hi.x, hi.y]
