extends SceneTree

## Covers PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md (RF1): exterior vs
## internal CHASM derivation (boundary flood over CHASM only), OCEAN exclusion,
## explicit starting-region frame selection without planet_key inference,
## alternate-frame passthrough, explicit visual-fallback telemetry, Drowned
## Basilica override parity, and DepthBackdrop activation from the exterior
## mask only.

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
	await _test_contract_map_frame_selection()
	await _test_tilemap_frame_and_backdrop()
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
	_check(ALPINE_PROFILE.visual_fallback, "alpine profile must report its stand-in underlay as a visual fallback")
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
	_check(snapshot["visual_fallback"] == true and String(snapshot["fallback_reason"]) != "", "missing Alpine art was not reported as a fallback")
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


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
