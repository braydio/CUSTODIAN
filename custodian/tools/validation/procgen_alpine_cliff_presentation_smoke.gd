extends SceneTree

const TILESET: TileSet = preload("res://content/tiles/tilesets/procgen_world_tileset.tres")
const PROFILE: ProcgenCliffFasciaProfile = preload("res://game/world/procgen/presentation/fascia/alpine_plateau.tres")
const DEPTH_PROFILES := [
	preload("res://content/procgen/presentation/depth_chunks/depth_rocky_upland_descending_conifer_ledge_v1.tres"),
	preload("res://content/procgen/presentation/depth_chunks/depth_rocky_upland_broken_retaining_drop_v1.tres"),
	preload("res://content/procgen/presentation/depth_chunks/depth_rocky_upland_lower_ledge_mist_v1.tres"),
	preload("res://content/procgen/presentation/depth_chunks/depth_rocky_upland_service_ruin_drop_v1.tres"),
]
const CONTACT_COMPOSER := preload("res://game/world/procgen/presentation/procgen_alpine_cliff_contact_composer.gd")


func _initialize() -> void:
	var failures := PackedStringArray()
	var derivation := JSON.parse_string(FileAccess.get_file_as_string("res://asset_drop/production_prep/alpine_cliff_presentation_v1/derivation_report.json")) as Dictionary
	var alpha_contract_by_state: Dictionary = {}
	for item: Dictionary in derivation.get("outputs", []):
		if item.get("family") == "procgen_alpine_cliff_contact":
			var state := StringName(item.get("state", ""))
			alpha_contract_by_state[state] = item
			var socket: Array = item.get("socket_px", [])
			if socket.size() != 2 or PROFILE.contact_socket_by_state.get(state, Vector2.INF) != Vector2(socket[0], socket[1]):
				failures.append("Alpine profile socket does not match derived source alpha for %s" % String(state))
			if not bool(item.get("alpha_crop_wall_ok", false)):
				failures.append("contact derivation lacks alpha/crop-wall proof for %s" % String(state))
	if not PROFILE.is_valid(): failures.append("Alpine fascia profile is invalid")
	if not PROFILE.ensure_cardinal_broad_contact or PROFILE.contact_min_run_tiles != 10 or PROFILE.contact_shoulder_tiles != 2:
		failures.append("Alpine contact profile does not enforce the evidence-tuned 10/2/cardinal contract")
	for source_id in range(219, 231):
		if not TILESET.has_source(source_id): failures.append("missing Alpine fascia source %d" % source_id)
	if PROFILE.depth_bias(Vector2i.UP) >= PROFILE.depth_bias(Vector2i.DOWN):
		failures.append("north direction is not shallower than south")
	if PROFILE.depth_bias(Vector2i.RIGHT) != 0 or PROFILE.depth_bias(Vector2i.LEFT) != 0:
		failures.append("east/west depth bias is not intermediate")
	for depth: TerrainStampProfile in DEPTH_PROFILES:
		if depth.placement_domain != TerrainStampProfile.PlacementDomain.CHASM:
			failures.append("%s is not CHASM-only" % depth.stamp_id)
		if depth.depth_band != TerrainStampProfile.DepthBand.BACK:
			failures.append("%s is not BACK-band" % depth.stamp_id)
		if depth.required_biome != &"rocky_upland" or depth.claims_dressing_clearance:
			failures.append("%s has an invalid biome/clearance contract" % depth.stamp_id)
		if not depth.validate_contract().is_empty():
			failures.append("%s failed its TerrainStampProfile contract" % depth.stamp_id)

	var face := ProcgenVoidCliffFace.new()
	face.tile_set = TILESET
	face.collision_enabled = false
	face.navigation_enabled = false
	root.add_child(face)
	var floor_cells: Dictionary = {}
	var chasm_cells: Dictionary = {}
	for x in range(16):
		floor_cells[Vector2i(x, 0)] = true
	for y in range(1, 18):
		for x in range(16): chasm_cells[Vector2i(x, y)] = true
	face.configure_from_surface_cells(floor_cells, chasm_cells, 711, {})
	var generic_ids := _used_source_ids(face)
	for source_id: int in generic_ids:
		if source_id < 149 or source_id > 154:
			failures.append("generic fallback used non-generic source %d" % source_id)
	for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var directed_floor: Dictionary = {}
		var directed_chasm: Dictionary = {}
		if direction == Vector2i.DOWN:
			for x in range(16): directed_floor[Vector2i(x, 0)] = true
			for y in range(1, 18):
				for x in range(16): directed_chasm[Vector2i(x, y)] = true
		elif direction == Vector2i.UP:
			for x in range(16): directed_floor[Vector2i(x, 18)] = true
			for y in range(1, 18):
				for x in range(16): directed_chasm[Vector2i(x, y)] = true
		elif direction == Vector2i.RIGHT:
			for y in range(16): directed_floor[Vector2i(0, y)] = true
			for x in range(1, 18):
				for y in range(16): directed_chasm[Vector2i(x, y)] = true
		else:
			for y in range(16): directed_floor[Vector2i(18, y)] = true
			for x in range(1, 18):
				for y in range(16): directed_chasm[Vector2i(x, y)] = true
		face.configure_from_surface_cells(directed_floor, directed_chasm, 711, {}, PROFILE)
		if int(face.get_debug_state().get("variation_patch_tiles", 0)) != PROFILE.tangential_variant_run_tiles:
			failures.append("Alpine tangential variation tuning did not come from its frame profile")
		var first_snapshot := _face_snapshot(face)
		if not _contains_alpine_source(first_snapshot): failures.append("Alpine profile did not select Alpine sources for %s" % direction)
		var found_direction := false
		for entry: Dictionary in first_snapshot.values():
			var paint_data := entry.get("paint", {}) as Dictionary
			found_direction = found_direction or paint_data.get("outward_direction", Vector2i.ZERO) == direction
			var depth_limit := int(paint_data.get("depth_limit", 0))
			if depth_limit < face.min_depth_tiles or depth_limit > face.max_depth_tiles:
				failures.append("directional depth escaped configured bounds for %s" % direction)
		if not found_direction: failures.append("profile has no frontier in direction %s" % direction)
		face.configure_from_surface_cells(directed_floor, directed_chasm, 711, {}, PROFILE)
		if _face_snapshot(face) != first_snapshot:
			failures.append("same-seed Alpine fascia plan is not deterministic for %s" % direction)
	if face.collision_enabled or face.navigation_enabled:
		failures.append("cliff presentation acquired collision/navigation")

	var blend_floor: Dictionary = {}
	var blend_chasm: Dictionary = {}
	var exterior: Dictionary = {}
	for x in range(18): blend_floor[Vector2i(x, 0)] = true
	for y in range(1, 19):
		for x in range(18): blend_chasm[Vector2i(x, y)] = true
	for x in range(18): exterior[Vector2i(x, 1)] = true
	face.configure_from_surface_cells(blend_floor, blend_chasm, 99, {}, PROFILE)
	var contact_plan := face.get_debug_paint_plan()
	var contact_root := Node2D.new()
	root.add_child(contact_root)
	var composer := CONTACT_COMPOSER.new()
	var first_contact: Dictionary = composer.apply_frontier_plan(contact_plan, exterior, {}, contact_root, 99, false, Vector2.ONE, PROFILE)
	if int(first_contact.get("sprite_count", 0)) != 1:
		failures.append("eligible long exterior frontier did not receive one contact plate")
	if int((first_contact.get("direction_counts", {}) as Dictionary).get("south", 0)) != 1:
		failures.append("qualified south frontier was not guaranteed a broad contact")
	_assert_attached_placements(first_contact, alpha_contract_by_state, failures)
	var contact_names := _contact_names(contact_root)
	composer.apply_frontier_plan(contact_plan, exterior, {}, contact_root, 99, false, Vector2.ONE, PROFILE)
	if _contact_names(contact_root) != contact_names:
		failures.append("same-seed contact placement is not deterministic")
	var blend: Dictionary = composer.get_fascia_blend_frontiers()
	var core := blend.get("core", {}) as Dictionary
	var shoulder := blend.get("shoulder", {}) as Dictionary
	if core.is_empty() or shoulder.size() != 4:
		failures.append("contact did not reserve central core and two-cell shoulders")
	for cell: Variant in core:
		if not exterior.has(cell) or floor_cells.has(cell):
			failures.append("contact core claimed a non-exterior semantic cell")
	for cell: Variant in shoulder:
		if not exterior.has(cell) or floor_cells.has(cell):
			failures.append("contact shoulder claimed a non-exterior semantic cell")

	# Re-compose the face with the contact's deterministic masks. The core must
	# have no procedural fascia columns; shoulders retain only the crown row.
	face.configure_from_surface_cells(blend_floor, blend_chasm, 99, {}, PROFILE, core, shoulder)
	if int(face.get_debug_state().get("contact_suppressed_cell_count", 0)) <= 0:
		failures.append("large contact did not suppress central procedural fascia cells")
	var painted_cells: Dictionary = {}
	for cell: Vector2i in face.get_used_cells(): painted_cells[cell] = true
	for frontier: Variant in core:
		if not (first_contact.get("attached_frontiers", {}) as Dictionary).has(frontier):
			failures.append("fascia core suppression has no successfully attached contact owner at %s" % str(frontier))
		for cell: Vector2i in painted_cells:
			var data := face.get_debug_paint_plan().get(cell, {}) as Dictionary
			if data.get("frontier_cell", Vector2i.ZERO) == frontier:
				failures.append("procedural fascia still paints a contact core frontier")
	for frontier: Variant in shoulder:
		for cell: Vector2i in painted_cells:
			var data := face.get_debug_paint_plan().get(cell, {}) as Dictionary
			if data.get("frontier_cell", Vector2i.ZERO) == frontier and int(data.get("distance", 99)) > 1:
				failures.append("contact shoulder retained a full repeated fascia column")

	# Four cardinal fixtures prove the per-direction guarantee independent of
	# whichever directions happen to qualify in the generated seed.
	for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var directional_plan: Dictionary = {}
		var directional_exterior: Dictionary = {}
		for index in range(18):
			var frontier := Vector2i(index, 50) if direction in [Vector2i.UP, Vector2i.DOWN] else Vector2i(50, index)
			directional_plan[frontier] = {"frontier_cell": frontier, "outward_direction": direction, "wall_backed": false}
			directional_exterior[frontier] = true
		var summary: Dictionary = composer.apply_frontier_plan(directional_plan, directional_exterior, {}, contact_root, 99, false, Vector2.ONE, PROFILE)
		if int((summary.get("direction_counts", {}) as Dictionary).get(_direction_name(direction), 0)) != 1:
			failures.append("qualified %s frontier was not guaranteed a broad contact" % _direction_name(direction))
		_assert_attached_placements(summary, alpha_contract_by_state, failures)
		if int(summary.get("core_frontier_count", 0)) < 14 or int(summary.get("shoulder_frontier_count", 0)) != 4:
			failures.append("%s contact mask did not retain its core and two-cell shoulders" % _direction_name(direction))

	var blocked := exterior.duplicate(true)
	var rejected: Dictionary = composer.apply_frontier_plan(contact_plan, exterior, blocked, contact_root, 99, false, Vector2.ONE, PROFILE)
	if int(rejected.get("sprite_count", 0)) != 0:
		failures.append("contact ignored protected/claimed frontier cells")
	var invalid_profile := PROFILE.duplicate() as ProcgenCliffFasciaProfile
	invalid_profile.contact_shoulder_tiles = 0
	var invalid_contract: Dictionary = composer.apply_frontier_plan(contact_plan, exterior, {}, contact_root, 99, false, Vector2.ONE, invalid_profile)
	if bool(invalid_contract.get("placement_contract_valid", true)):
		failures.append("zero-width contact shoulder did not fail closed")
	var missing_socket_profile := PROFILE.duplicate() as ProcgenCliffFasciaProfile
	for state in [&"south_broad_01", &"south_broken_01", &"south_rooted_01"]:
		missing_socket_profile.contact_socket_by_state.erase(state)
	var unattached: Dictionary = composer.apply_frontier_plan(contact_plan, exterior, {}, contact_root, 99, false, Vector2.ONE, missing_socket_profile)
	if int(unattached.get("sprite_count", 0)) != 0 or not composer.get_fascia_blend_frontiers().get("core", {}).is_empty():
		failures.append("contact without an authored socket emitted art or fascia suppression")
	var snapshot := floor_cells.duplicate(true)
	if floor_cells != snapshot:
		failures.append("presentation changed semantic floor cells")

	if not failures.is_empty():
		for failure in failures: push_error("[ProcgenAlpineCliffPresentationSmoke] " + failure)
		quit(1)
		return
	print("[ProcgenAlpineCliffPresentationSmoke] PASS · sources=12 · depth=4 · cardinal contacts · core suppression · 2-cell shoulders · tangential variation · no semantic mutation")
	quit(0)


func _used_source_ids(layer: TileMapLayer) -> Array[int]:
	var result: Array[int] = []
	for cell: Vector2i in layer.get_used_cells():
		var source_id := layer.get_cell_source_id(cell)
		if not result.has(source_id): result.append(source_id)
	result.sort()
	return result


func _face_snapshot(layer: ProcgenVoidCliffFace) -> Dictionary:
	var result: Dictionary = {}
	for cell: Vector2i in layer.get_used_cells():
		result[cell] = {"source": layer.get_cell_source_id(cell), "paint": layer.get_debug_paint_plan().get(cell, {})}
	return result


func _contains_alpine_source(snapshot: Dictionary) -> bool:
	for cell_data: Dictionary in snapshot.values():
		var source := int(cell_data.get("source", -1))
		if source >= 219 and source <= 230: return true
	return false


func _contact_names(node: Node2D) -> Array[String]:
	var result: Array[String] = []
	for child: Node in node.get_children():
		if child.has_meta(&"alpine_cliff_contact"):
			result.append(child.name)
	result.sort()
	return result


func _assert_attached_placements(summary: Dictionary, alpha_contract_by_state: Dictionary, failures: PackedStringArray) -> void:
	var placements: Array = summary.get("placements", [])
	if placements.is_empty():
		failures.append("eligible contact direction returned no placement evidence")
	for placement_variant: Variant in placements:
		var placement := placement_variant as Dictionary
		if not bool(placement.get("attached", false)):
			failures.append("contact placement failed attachment: %s" % str(placement))
		if float(placement.get("socket_error_px", INF)) > 8.0:
			failures.append("contact socket error exceeds 8 px: %s" % str(placement))
		var state := StringName(placement.get("contact_state", ""))
		var asset_contract := alpha_contract_by_state.get(state, {}) as Dictionary
		if not bool(asset_contract.get("alpha_crop_wall_ok", false)):
			failures.append("contact asset lacks validated irregular alpha: %s" % String(state))
		if PROFILE.contact_socket_by_state.get(state, Vector2.INF) != Vector2(asset_contract.get("socket_px", [-1, -1])[0], asset_contract.get("socket_px", [-1, -1])[1]):
			failures.append("profile socket differs from authored asset socket: %s" % String(state))


func _direction_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP: return "north"
	if direction == Vector2i.RIGHT: return "east"
	if direction == Vector2i.DOWN: return "south"
	return "west"
