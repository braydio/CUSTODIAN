extends SceneTree

## Covers PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md (RF1): exterior vs
## internal CHASM derivation (boundary flood over CHASM only), OCEAN exclusion,
## explicit starting-region frame selection without planet_key inference,
## alternate-frame passthrough, explicit visual-fallback telemetry (cleared for
## the bound Alpine Plateau art, still reported for unresolved frames), Drowned
## Basilica override parity, DepthBackdrop activation from the exterior mask
## only, deterministic seed A/B selection, ocean-pocket exclusion (RFR1 R0-02)
## and a real generated production-scene frame assertion (RFR1 R0-01).

const CLASSIFIER := preload("res://game/world/procgen/terrain/nonwalkable_surface_classifier.gd")
const CONTRACT_MAP_SCENE := preload("res://game/world/procgen/custodian_contract_map.tscn")
const CONTRACT_MAP_SCRIPT := preload("res://game/world/procgen/custodian_contract_map.gd")
const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const ALPINE_PROFILE := preload("res://game/world/procgen/presentation/region_frames/alpine_plateau.tres")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_classifier_exterior_vs_internal()
	_test_ocean_never_exterior()
	_test_ocean_pocket_not_chasm_conduit()
	await _test_contract_map_frame_selection()
	await _test_tilemap_frame_and_backdrop()
	_test_alpine_underlay_binding_and_seed_selection()
	await _test_production_scene_frame_binding()
	if _errors.is_empty():
		print("[ProcgenRegionFrameSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenRegionFrameSmoke] %s" % error)
	quit(1)


func _floor_rect(rect: Rect2i, holes: Array[Vector2i] = []) -> Dictionary:
	var floor_cells: Dictionary = {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			floor_cells[Vector2i(x, y)] = true
	for hole in holes:
		floor_cells.erase(hole)
	return floor_cells


func _test_classifier_exterior_vs_internal() -> void:
	var size := Vector2i(12, 12)
	var enclosed := Vector2i(5, 5)
	var floor_cells := _floor_rect(Rect2i(3, 3, 6, 6), [enclosed])
	var result: Dictionary = CLASSIFIER.new().classify(size, floor_cells, [])
	var exterior: Dictionary = result["exterior_chasm_cells"]
	var internal: Dictionary = result["internal_chasm_cells"]
	var chasm: Dictionary = result["chasm_cells"]
	var kinds: Dictionary = result["kind_by_cell"]
	_check(exterior.has(Vector2i(0, 0)) and exterior.has(Vector2i(11, 11)), "map-edge-connected chasm is not in the exterior mask")
	_check(not exterior.has(enclosed), "an enclosed chasm leaked into the exterior mask")
	_check(internal.has(enclosed) and internal.size() == 1, "the enclosed chasm is not the sole internal chasm cell")
	_check(exterior.size() + internal.size() == chasm.size(), "exterior + internal does not partition the chasm cells")
	_check(chasm.size() == size.x * size.y - floor_cells.size(), "chasm count changed from the pre-RF1 definition")
	_check(StringName(kinds.get(enclosed, &"")) == &"chasm", "the enclosed chasm stopped being structurally CHASM")
	_check(StringName(kinds.get(Vector2i(0, 0), &"")) == &"chasm", "the exterior chasm stopped being structurally CHASM")
	var summary: Dictionary = result["summary"]
	_check(int(summary.get("exterior_chasm_cells", -1)) == exterior.size(), "summary exterior count is wrong")
	_check(int(summary.get("internal_chasm_cells", -1)) == internal.size(), "summary internal count is wrong")
	# A channel from the map edge into the floor is exterior, not internal.
	var channel_floor := _floor_rect(Rect2i(3, 3, 6, 6), [Vector2i(3, 5), Vector2i(3, 6)])
	var channel: Dictionary = CLASSIFIER.new().classify(size, channel_floor, [])
	_check((channel["exterior_chasm_cells"] as Dictionary).has(Vector2i(3, 5)), "an edge-connected channel cell was classified internal")
	# Deterministic: identical input, identical masks.
	var again: Dictionary = CLASSIFIER.new().classify(size, floor_cells, [])
	_check((again["exterior_chasm_cells"] as Dictionary).keys() == exterior.keys(), "exterior mask is not deterministic")


func _test_ocean_never_exterior() -> void:
	var size := Vector2i(12, 12)
	var floor_cells := _floor_rect(Rect2i(4, 2, 7, 8))
	var claims: Array[Dictionary] = [{
		"id": &"rf1_test_ocean", "kind": &"ocean",
		"bounds": Rect2i(0, 0, 3, 12), "seed_edge": &"west",
	}]
	var result: Dictionary = CLASSIFIER.new().classify(size, floor_cells, claims)
	var ocean: Dictionary = result["ocean_cells"]
	var exterior: Dictionary = result["exterior_chasm_cells"]
	var internal: Dictionary = result["internal_chasm_cells"]
	_check(not ocean.is_empty(), "ocean fixture produced no ocean cells")
	for cell in ocean.keys():
		if exterior.has(cell) or internal.has(cell):
			_check(false, "ocean cell %s leaked into a chasm mask" % str(cell))
			break
	_check(
		exterior.size() + internal.size() == (result["chasm_cells"] as Dictionary).size(),
		"ocean fixture broke the exterior/internal partition"
	)


func _test_ocean_pocket_not_chasm_conduit() -> void:
	# RFR1 R0-02: an ocean pocket touching/bisecting exterior chasm must neither
	# become a chasm flood conduit nor corrupt the exterior/internal partition.
	var size := Vector2i(16, 16)
	var floor_cells := _floor_rect(Rect2i(5, 5, 6, 6))
	# A closed ocean-claim band enclosing a chasm pocket that touches no map edge
	# except through ocean, plus an ocean arm that reaches the exterior chasm.
	var claims: Array[Dictionary] = [{
		"id": &"rf_r002_ocean", "kind": &"ocean",
		"bounds": Rect2i(0, 3, 16, 2), "seed_edge": &"west",
	}]
	var result: Dictionary = CLASSIFIER.new().classify(size, floor_cells, claims)
	var ocean: Dictionary = result["ocean_cells"]
	var exterior: Dictionary = result["exterior_chasm_cells"]
	var internal: Dictionary = result["internal_chasm_cells"]
	var chasm: Dictionary = result["chasm_cells"]
	_check(not ocean.is_empty(), "R0-02 fixture produced no ocean cells")
	_check(ocean.has(Vector2i(0, 3)) and ocean.has(Vector2i(15, 4)), "R0-02 ocean band does not touch the map boundary")
	# The band bisects the exterior chasm: north strip (y<3) is separated from
	# the south chasm (y>=5) by ocean, yet both touch the map edge themselves.
	_check(exterior.has(Vector2i(0, 0)) and exterior.has(Vector2i(0, 15)), "bisected exterior chasm halves lost exterior status")
	for cell in ocean.keys():
		_check(not exterior.has(cell) and not internal.has(cell) and not chasm.has(cell), "ocean cell %s leaked into a chasm mask" % str(cell))
	_check(exterior.size() + internal.size() == chasm.size(), "R0-02 fixture broke the exterior/internal partition")
	# An enclosed chasm pocket reachable only through ocean is internal, never exterior.
	var pocket_floor := _floor_rect(Rect2i(2, 2, 12, 12), [Vector2i(7, 7)])
	var pocket_claims: Array[Dictionary] = [{
		"id": &"rf_r002_pocket", "kind": &"ocean",
		"bounds": Rect2i(6, 6, 3, 3), "seed_edge": &"north",
	}]
	var pocket: Dictionary = CLASSIFIER.new().classify(size, pocket_floor, pocket_claims)
	_check((pocket["exterior_chasm_cells"] as Dictionary).size() + (pocket["internal_chasm_cells"] as Dictionary).size() == (pocket["chasm_cells"] as Dictionary).size(), "ocean pocket broke the partition")
	_check(not (pocket["exterior_chasm_cells"] as Dictionary).has(Vector2i(7, 7)), "an ocean-adjacent enclosed cell became exterior")
	var again: Dictionary = CLASSIFIER.new().classify(size, floor_cells, claims)
	_check((again["exterior_chasm_cells"] as Dictionary).keys() == exterior.keys(), "R0-02 exterior mask is not deterministic")


func _test_contract_map_frame_selection() -> void:
	var map := CONTRACT_MAP_SCENE.instantiate()
	map.set("auto_generate_on_ready", false)
	root.add_child(map)
	await process_frame
	_check(
		StringName(map.get("region_frame_profile_id")) == &"alpine_plateau",
		"the production starting-region scene does not explicitly select alpine_plateau"
	)
	for key in ["terran_wet", "terran_dry", "islands", "ice_world", "lava_world", "gas_giant"]:
		var profile: Dictionary = map.call("_build_planet_world_profile", key, 1234)
		_check(
			String(profile.get("region_frame_profile_id", "")) == "alpine_plateau",
			"starting-region profile for %s did not carry alpine_plateau" % key
		)
	for key in CONTRACT_MAP_SCRIPT.PLANET_WORLD_PROFILES.keys():
		_check(
			not (CONTRACT_MAP_SCRIPT.PLANET_WORLD_PROFILES[key] as Dictionary).has("region_frame_profile_id"),
			"PLANET_WORLD_PROFILES[%s] must stay frame-agnostic" % str(key)
		)
	# Explicit alternate frame passes through; planet_key never overrides it.
	map.set("region_frame_profile_id", &"future_frame")
	for key in ["terran_wet", "lava_world"]:
		var alt: Dictionary = map.call("_build_planet_world_profile", key, 99)
		_check(String(alt.get("region_frame_profile_id", "")) == "future_frame", "explicit alternate frame was overwritten for %s" % key)
	# Reusable class default is neutral: no frame key at all.
	var neutral := CONTRACT_MAP_SCRIPT.new()
	neutral.set("auto_generate_on_ready", false)
	_check(StringName(neutral.get("region_frame_profile_id")) == &"", "reusable generator default is not frame-neutral")
	var neutral_profile: Dictionary = neutral.call("_build_planet_world_profile", "ice_world", 7)
	_check(not neutral_profile.has("region_frame_profile_id"), "a neutral generator emitted a frame id")
	neutral.free()
	map.queue_free()
	await process_frame


func _test_tilemap_frame_and_backdrop() -> void:
	_check(ALPINE_PROFILE.is_valid() and ALPINE_PROFILE.profile_id == &"alpine_plateau", "alpine_plateau profile resource is invalid")
	_check(not ALPINE_PROFILE.visual_fallback and ALPINE_PROFILE.fallback_reason == "", "alpine profile still reports a visual fallback after Alpine art was bound")
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	await process_frame
	var size := Vector2i(24, 24)

	# --- exterior mask drives the backdrop; frame resolves with fallback ---
	map.apply_planet_world_profile({"region_frame_profile_id": "alpine_plateau"})
	map.set("_generated_floor_cells", _floor_rect(Rect2i(4, 4, 16, 16), [Vector2i(10, 10), Vector2i(11, 10)]))
	map.call("_rebuild_nonwalkable_surface_regions", size)
	var snapshot: Dictionary = map.get_region_frame_debug_snapshot()
	_check(snapshot["frame_id"] == "alpine_plateau" and snapshot["frame_resolved"] == true, "alpine frame did not resolve")
	_check(snapshot["visual_fallback"] == false and String(snapshot["fallback_reason"]) == "", "bound Alpine art still reported a fallback")
	_check(snapshot["underlay_profile_id"] == "alpine_plateau", "alpine frame is not using the Alpine underlay profile (Endless Forest stand-in?)")
	_check(snapshot["underlay_source"] == "region_frame", "underlay was not selected by the region frame")
	_check(snapshot["underlay_profile_id"] == String(ALPINE_PROFILE.underlay_profile.profile_id), "frame underlay profile id mismatch")
	_check(int(snapshot["exterior_chasm_count"]) > 0 and int(snapshot["internal_chasm_count"]) == 2, "exterior/internal counts are wrong for the fixture")
	_check(snapshot["backdrop_mode"] == "chasm_camera_follow" and map.depth_backdrop.visible, "exterior chasm did not activate the depth backdrop")
	_check(map.depth_backdrop.get_underlay_profile_id() == ALPINE_PROFILE.underlay_profile.profile_id, "backdrop is not using the frame's underlay")
	var stack_meta := map.depth_backdrop.get_node("ChasmPresentationRoot/CameraDepthBackdrop") as Node2D
	var bounds: Rect2i = stack_meta.get_meta("chasm_cell_bounds")
	_check(stack_meta.get_meta("chasm_cell_count") == int(snapshot["exterior_chasm_count"]), "backdrop was bounded by more than the exterior mask")
	_check(bounds.position == Vector2i.ZERO and bounds.end == size, "backdrop bounds did not come from the exterior (map-edge) cells")
	var level_frame: Dictionary = map.get_region_frame_debug_snapshot()
	_check(level_frame == snapshot, "frame snapshot is not stable across reads")
	var chasm_before := (map.debug_get_chasm_cells() as Dictionary).size()
	var kinds_before := (map.get("_surface_kind_by_cell") as Dictionary).size()

	# --- internal-only chasm must not activate the global underlay ---
	map.set("_generated_floor_cells", _floor_rect(Rect2i(0, 0, size.x, size.y), [Vector2i(10, 10)]))
	map.call("_rebuild_nonwalkable_surface_regions", size)
	var internal_only: Dictionary = map.get_region_frame_debug_snapshot()
	_check(int(internal_only["exterior_chasm_count"]) == 0 and int(internal_only["internal_chasm_count"]) == 1, "internal-only fixture counts are wrong")
	_check(not map.depth_backdrop.visible, "an internal-only chasm activated the global lower-world underlay")
	_check(internal_only["backdrop_mode"] == "no_exterior_chasm", "internal-only fixture did not report the no_exterior_chasm mode")

	# --- explicit alternate frame id without a resource: reported, not final ---
	map.set("_generated_floor_cells", _floor_rect(Rect2i(4, 4, 16, 16), [Vector2i(10, 10)]))
	map.apply_planet_world_profile({"region_frame_profile_id": "future_frame", "planet_key": "lava_world"})
	map.call("_rebuild_nonwalkable_surface_regions", size)
	var alt: Dictionary = map.get_region_frame_debug_snapshot()
	_check(alt["frame_id"] == "future_frame" and alt["frame_resolved"] == false, "alternate frame id was rewritten or falsely resolved")
	_check(alt["visual_fallback"] == true, "an unresolved frame must report a visual fallback")
	_check(alt["underlay_source"] == "default", "unresolved frame did not fall back to the default underlay")

	# --- frame-less profile keeps the legacy default ---
	map.apply_planet_world_profile({"planet_key": "terran_dry"})
	var plain: Dictionary = map.get_region_frame_debug_snapshot()
	_check(plain["frame_id"] == "" and plain["visual_fallback"] == false and plain["underlay_source"] == "default", "frame-less profile did not keep the legacy underlay")

	# --- Drowned Basilica explicit override: wins, no semantic mutation ---
	map.apply_planet_world_profile({"region_frame_profile_id": "alpine_plateau"})
	map.set("_generated_floor_cells", _floor_rect(Rect2i(4, 4, 16, 16), [Vector2i(10, 10), Vector2i(11, 10)]))
	map.call("_rebuild_nonwalkable_surface_regions", size)
	var chasm_ref := (map.debug_get_chasm_cells() as Dictionary).size()
	var kinds_ref := (map.get("_surface_kind_by_cell") as Dictionary).size()
	_check(chasm_ref == chasm_before and kinds_ref == kinds_before, "fixture re-run changed chasm/surface counts")
	map.set_underlay_profile_override("DROWNED_BASILICA")
	var drowned: Dictionary = map.get_region_frame_debug_snapshot()
	_check(drowned["underlay_source"] == "drowned_basilica_override" and drowned["underlay_profile_id"] == "drowned_basilica", "Drowned Basilica override no longer wins")
	_check(map.depth_backdrop.get_underlay_profile_id() == &"drowned_basilica", "backdrop ignored the Drowned Basilica override")
	_check((map.debug_get_chasm_cells() as Dictionary).size() == chasm_ref, "the Drowned override mutated chasm semantics")
	_check((map.get("_surface_kind_by_cell") as Dictionary).size() == kinds_ref, "the Drowned override mutated surface semantics")
	map.set_underlay_profile_override("ENDLESS_FOREST")
	_check(map.get_region_frame_debug_snapshot()["underlay_source"] == "region_frame", "clearing the override did not restore the region frame underlay")

	map.queue_free()
	await process_frame


func _test_alpine_underlay_binding_and_seed_selection() -> void:
	var profile: ProcgenUnderlayProfile = ALPINE_PROFILE.underlay_profile
	_check(profile.is_valid() and profile.profile_id == &"alpine_plateau", "alpine underlay profile is invalid or misnamed")
	_check(profile.far_variants.size() == 2 and profile.middle_variants.size() == 2 and profile.near_variants.size() == 2, "alpine underlay must bind A/B for FAR, MIDDLE and NEAR")
	for texture in profile.far_variants + profile.middle_variants + profile.near_variants:
		_check(texture.get_size() == Vector2(1536, 1024), "alpine underlay texture is not 1536x1024: %s" % texture.resource_path)
		_check(texture.resource_path.begins_with("res://content/backgrounds/procgen/alpine_plateau/"), "alpine underlay texture is outside its runtime domain: %s" % texture.resource_path)
		_check(not texture.resource_path.contains("endless_forest") and not texture.resource_path.contains("archive_resolve"), "alpine underlay reuses a foreign/Archive Resolve asset")
	var backdrop := ProcgenDepthBackdrop.new()
	var seen := {"far": {}, "middle": {}, "near": {}}
	for seed_value in range(1, 25):
		backdrop.set_underlay_profile(profile, seed_value)
		var first: Dictionary = backdrop.get_selected_variant_indices()
		backdrop.set_underlay_profile(profile, seed_value)
		_check(backdrop.get_selected_variant_indices() == first, "seed %d did not select deterministically" % seed_value)
		for layer in seen.keys():
			(seen[layer] as Dictionary)[int(first[layer])] = true
	for layer in seen.keys():
		_check((seen[layer] as Dictionary).size() == 2, "seed sweep never selected both %s variants" % layer)
	backdrop.free()
	_test_depth_motion_coverage(profile)


## Continuation acceptance: supported viewport/zoom/parallax combinations can
## never expose unpainted plate canvas; displacement is bounded; non-Alpine
## underlays keep the pre-continuation (zero-motion, no-coverage-scaling) defaults.
func _test_depth_motion_coverage(profile: ProcgenUnderlayProfile) -> void:
	_check(profile.guarantee_viewport_coverage and profile.has_depth_motion(), "alpine underlay must enable bounded depth motion and coverage")
	_check(profile.parallax_max_px > 0.0 and profile.parallax_max_px <= 128.0, "alpine parallax bound is outside the intended subtle range")
	_check(profile.base_fill_color.a == 1.0, "alpine underlay needs an opaque base fill so transparent plate gaps never show the engine clear colour")
	for other_path in [
		"res://game/world/procgen/presentation/underlays/drowned_basilica_underlay.tres",
		"res://game/world/procgen/presentation/underlays/endless_forest_underlay.tres",
	]:
		var other := load(other_path) as ProcgenUnderlayProfile
		_check(other != null and other.base_fill_color.a == 0.0, "%s gained a base fill" % other_path)
		_check(other != null and not other.has_depth_motion() and not other.guarantee_viewport_coverage, "%s must keep zero depth motion/default coverage" % other_path)
		_check(other.far_parallax == 0.0 and other.middle_parallax == 0.0 and other.near_parallax == 0.0 and other.parallax_max_px == 0.0, "%s gained parallax" % other_path)
	var texture_size := Vector2(1536.0, 1024.0)
	var margin := profile.parallax_max_px
	var worst_scale := 0.0
	for visible: Vector2 in [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080), Vector2(2560, 1080)]:
		for zoom_value: float in [0.74, 0.84, 0.94, 1.0, 1.25, 1.5]:
			var zoom: Vector2 = Vector2.ONE * zoom_value
			var scale_value := ProcgenDepthBackdrop.required_cover_scale(visible, zoom, texture_size, margin)
			worst_scale = maxf(worst_scale, scale_value)
			var half_painted: Vector2 = texture_size * scale_value * 0.5
			var half_needed: Vector2 = visible / zoom * 0.5 + Vector2.ONE * margin * scale_value
			_check(scale_value >= 1.0 and half_painted.x >= half_needed.x - 0.01 and half_painted.y >= half_needed.y - 0.01,
				"plate does not cover %s at zoom %.2f (scale %.3f)" % [str(visible), zoom_value, scale_value])
	_check(worst_scale <= ProcgenDepthBackdrop.MAX_COVER_SCALE, "supported combinations exceeded the cover scale cap")
	_check(ProcgenDepthBackdrop.required_cover_scale(Vector2(1280, 720), Vector2.ZERO, texture_size, margin) == ProcgenDepthBackdrop.MAX_COVER_SCALE, "degenerate zoom must clamp to the cover cap")
	# Parallax: zero by default, bounded for any travel, deterministic, direction-opposed.
	_check(ProcgenDepthBackdrop.parallax_offset(Vector2(5000, 5000), 0.0, 64.0) == Vector2.ZERO, "zero strength displaced a layer")
	_check(ProcgenDepthBackdrop.parallax_offset(Vector2(5000, 5000), 0.1, 0.0) == Vector2.ZERO, "zero bound displaced a layer")
	for travel: Vector2 in [Vector2(10, 0), Vector2(-4000, 300), Vector2(1.0e6, -1.0e6), Vector2(0, 2500)]:
		for strength: float in [profile.far_parallax, profile.middle_parallax, profile.near_parallax]:
			var offset: Vector2 = ProcgenDepthBackdrop.parallax_offset(travel, strength, margin)
			_check(offset.length() <= margin + 0.001, "parallax exceeded its bound for travel %s" % str(travel))
			_check(offset == ProcgenDepthBackdrop.parallax_offset(travel, strength, margin), "parallax is not deterministic")
			if offset != Vector2.ZERO:
				_check(offset.dot(travel) < 0.0, "parallax did not oppose camera travel")


func _test_production_scene_frame_binding() -> void:
	# RFR1 R0-01: a real generated starting scene reports the Alpine frame and
	# the bound Alpine underlay after integration.
	var contract_map := CONTRACT_MAP_SCENE.instantiate() as CustodianContractMap
	contract_map.auto_generate_on_ready = false
	contract_map.randomize_seed_on_ready = false
	contract_map.map_generation_attempts = 1
	root.add_child(contract_map)
	await process_frame
	contract_map.generate_contract(424242)
	var tilemap: ProcGenTilemap = null
	var frames := 0
	while tilemap == null and frames < 1800:
		frames += 1
		await process_frame
		if not contract_map.get_latest_contract().is_empty():
			tilemap = _find_tilemap(contract_map)
	_check(tilemap != null, "production starting scene produced no ProcGenTilemap")
	if tilemap != null:
		var snapshot: Dictionary = tilemap.get_region_frame_debug_snapshot()
		_check(snapshot["frame_id"] == "alpine_plateau" and snapshot["frame_resolved"] == true, "generated production scene did not resolve the alpine_plateau frame")
		_check(snapshot["visual_fallback"] == false, "generated production scene still reports a visual fallback")
		_check(snapshot["underlay_source"] == "region_frame" and snapshot["underlay_profile_id"] == "alpine_plateau", "generated production scene is not bound to the Alpine underlay")
		_check(tilemap.depth_backdrop.get_underlay_profile_id() == &"alpine_plateau", "generated production backdrop is not using the Alpine underlay")
		_check(bool(tilemap.depth_backdrop.get_depth_motion_snapshot()["base_fill"]), "production backdrop has no base fill under the plates")
		_check(not (tilemap.depth_backdrop.get_selected_variant_indices() as Dictionary).is_empty() and int(tilemap.depth_backdrop.get_selected_variant_indices()["far"]) >= 0, "production backdrop has no deterministic variant selection")
	await contract_map._clear_previous_instances()
	contract_map.queue_free()
	await process_frame


func _find_tilemap(node: Node) -> ProcGenTilemap:
	if node is ProcGenTilemap:
		return node as ProcGenTilemap
	for child in node.get_children():
		var found := _find_tilemap(child)
		if found != null:
			return found
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
