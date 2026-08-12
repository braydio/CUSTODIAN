extends SceneTree

const INTENT_BUILDER := preload(
	"res://game/world/procgen/intent/ascent_spine_builder.gd"
)
const ASCENT_FIELD_BUILDER := preload(
	"res://game/world/procgen/intent/ascent_field_builder.gd"
)
const KEEP_INTENT_BUILDER := preload(
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_landmark_intent_builder.gd"
)
const FRONTAGE_BUILDER := preload(
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_frontage_builder.gd"
)
const FRONTAGE_VALIDATOR := preload(
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_frontage_validator.gd"
)
const INGRESS_RESOLVER := preload(
	"res://game/world/levels/world_ingress_placement_resolver.gd"
)
const PROCGEN_MAP_SCENE := preload(
	"res://game/world/procgen/proc_gen_map.tscn"
)

const MAP_SIZE := Vector2i(176, 176)
const REVIEW_SEEDS := [
	1, 2, 3, 4, 5, 6, 7, 8,
	11, 17, 23, 31, 43, 59, 71, 89,
	101, 127, 149, 173, 197, 223, 251, 283,
]
const ROUTE_PATH := (
	"res://content/routes/sundered_keep/sundered_keep_route.json"
)
const PRODUCTION_PRESENTATION_PATH := (
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_procgen_vista_presentation.tscn"
)
const PRODUCTION_SPAWNER_PATH := (
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_frontage_visual_spawner.gd"
)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fingerprints := {}
	var gate_anchors := {}
	var side_pockets := {}
	for seed_value in REVIEW_SEEDS:
		var generation := _build_frontage(seed_value)
		var graph = generation.get("graph")
		var base_field: Dictionary = generation.get("base_field", {})
		var frontage: Dictionary = generation.get("frontage", {})
		var landmark_count := 0
		if graph != null:
			for node in graph.nodes:
				if node.id == "sundered_keep_frontage":
					landmark_count += 1
		_assert(
			landmark_count == 1,
			"seed %d should contain exactly one Keep landmark" % seed_value
		)
		var validation: Dictionary = FRONTAGE_VALIDATOR.new().call(
			"validate",
			frontage,
			base_field.get("main_route_cells", [])
		)
		_assert(
			bool(validation.get("ok", false)),
			"seed %d frontage invalid: %s"
			% [seed_value, "; ".join(validation.get("errors", []))]
		)
		_assert(
			int(validation.get("minimum_route_width", 0)) >= 7,
			"seed %d route is narrower than combat minimum" % seed_value
		)
		_assert(
			not frontage.has("rect") \
			and not frontage.has("footprint_rect") \
			and not frontage.has("authored_scene_rect"),
			"seed %d exposes rectangular authored footprint metadata"
			% seed_value
		)
		var hard: Dictionary = frontage.get("hard_clearance_cells", {})
		var presentation_clearance: Dictionary = frontage.get(
			"presentation_clearance_cells",
			{}
		)
		_assert(
			not presentation_clearance.is_empty(),
			"seed %d has no presentation clearance" % seed_value
		)
		var route_centerline: Array = frontage.get("route_centerline", [])
		if not route_centerline.is_empty():
			var gameplay_return_index := clampi(
				int(round(float(route_centerline.size() - 1) * 0.90)),
				0,
				route_centerline.size() - 1
			)
			_assert(
				presentation_clearance.has(
					route_centerline[gameplay_return_index]
				),
				"seed %d presentation clearance ends before gameplay return"
				% seed_value
			)
		var cliffs: Dictionary = frontage.get("cliff_cells", {})
		_assert(
			not (frontage.get("vista_commit_cells", {}) as Dictionary).is_empty(),
			"seed %d has no mandatory vista commit line" % seed_value
		)
		_assert(
			(frontage.get("terminal_apron_cells", {}) as Dictionary).has(
				frontage.get("gate_anchor")
			),
			"seed %d terminal apron does not own the gate" % seed_value
		)
		var claims: Array = frontage.get("surface_claims", [])
		_assert(claims.size() == 1, "seed %d must emit one ocean claim" % seed_value)
		if claims.size() == 1 and claims[0] is Dictionary:
			var claim := claims[0] as Dictionary
			_assert(StringName(claim.get("id", &"")) == &"sundered_keep_frontage_ocean", "seed %d ocean claim id mismatch" % seed_value)
			_assert(StringName(claim.get("kind", &"")) == &"ocean", "seed %d ocean claim kind mismatch" % seed_value)
			_assert(StringName(claim.get("profile", &"")) == &"sundered_keep_cosmic_ocean", "seed %d ocean claim profile mismatch" % seed_value)
			_assert(StringName(claim.get("seed_edge", &"")) == &"north", "seed %d ocean claim is not north seeded" % seed_value)
			var bounds: Variant = claim.get("bounds")
			_assert(bounds is Rect2i and (bounds as Rect2i).has_area() and (bounds as Rect2i).position.y == 0, "seed %d ocean claim bounds are invalid" % seed_value)
		for cell in hard.keys():
			if cliffs.has(cell):
				_errors.append(
					"seed %d cliff overlaps mandatory route at %s"
					% [seed_value, cell]
				)
				break
		var fingerprint := str(
			FRONTAGE_VALIDATOR.new().call(
				"stable_fingerprint",
				frontage
			)
		)
		fingerprints[fingerprint] = true
		gate_anchors[frontage.get("gate_anchor", Vector2i.ZERO)] = true
		var pocket_array: Array = frontage.get("side_pocket_anchors", [])
		if not pocket_array.is_empty():
			side_pockets[pocket_array[0]] = true

		var repeated := _build_frontage(seed_value)
		var repeated_fingerprint := str(
			FRONTAGE_VALIDATOR.new().call(
				"stable_fingerprint",
				repeated.get("frontage", {})
			)
		)
		_assert(
			fingerprint == repeated_fingerprint,
			"seed %d frontage is not deterministic" % seed_value
		)
		_assert_terminal_ingress(frontage, seed_value)

	_assert(
		fingerprints.size() >= 8,
		"reviewed seeds did not produce meaningful frontage variation"
	)
	_assert(
		gate_anchors.size() >= 4,
		"reviewed seeds did not vary the generated gate anchor"
	)
	_assert(
		side_pockets.size() >= 6,
		"reviewed seeds did not vary the side pocket"
	)
	_assert_production_file_exclusions()
	await _assert_integrated_procgen_result()

	if _errors.is_empty():
		print(
			(
				"[SunderedKeepProcgenFrontageSmoke] PASS seeds=%d "
				+ "fingerprints=%d gates=%d pockets=%d"
			)
			% [
				REVIEW_SEEDS.size(),
				fingerprints.size(),
				gate_anchors.size(),
				side_pockets.size(),
			]
		)
		quit(0)
		return
	for error in _errors:
		push_error("[SunderedKeepProcgenFrontageSmoke] %s" % error)
	quit(1)


func _build_frontage(seed_value: int) -> Dictionary:
	var graph = INTENT_BUILDER.new().call("build", {
		"seed": seed_value,
		"map_size": MAP_SIZE,
		"origin_cell": Vector2i(MAP_SIZE.x / 2, MAP_SIZE.y - 12),
		"route_beat_count": 7,
	})
	KEEP_INTENT_BUILDER.new().call(
		"add_sundered_keep_intent",
		graph,
		{"seed": seed_value, "map_size": MAP_SIZE}
	)
	var base_field: Dictionary = ASCENT_FIELD_BUILDER.new().call(
		"build_field",
		graph,
		MAP_SIZE,
		seed_value
	)
	var frontage: Dictionary = FRONTAGE_BUILDER.new().call(
		"build_frontage",
		graph,
		base_field,
		MAP_SIZE,
		seed_value
	)
	return {
		"graph": graph,
		"base_field": base_field,
		"frontage": frontage,
	}


func _assert_terminal_ingress(
	frontage: Dictionary,
	seed_value: int
) -> void:
	var floor_cells: Array[Vector2i] = []
	for cell in (frontage.get("floor_cells", {}) as Dictionary).keys():
		if cell is Vector2i:
			floor_cells.append(cell as Vector2i)
	var level_data := {
		"map_size": MAP_SIZE,
		"floor_cells": floor_cells,
		"sundered_keep_frontage": frontage,
	}
	var result: Dictionary = INGRESS_RESOLVER.new().call(
		"resolve",
		{
			"strategy": "procgen_landmark_terminal",
			"landmark_data_key": "sundered_keep_frontage",
			"minimum_spacing_tiles": 10,
		},
		level_data,
		null,
		[] as Array[Vector2i]
	)
	_assert(
		bool(result.get("ok", false)),
		"seed %d generated terminal ingress did not resolve" % seed_value
	)
	_assert(
		result.get("tile") == frontage.get("gate_anchor"),
		"seed %d ingress does not use the generated gate anchor"
		% seed_value
	)
	_assert(
		not bool(result.get("requires_authored_pocket", true)),
		"seed %d ingress still requests an authored pocket" % seed_value
	)


func _assert_production_file_exclusions() -> void:
	var route_text := _read_text(ROUTE_PATH)
	var presentation_text := _read_text(PRODUCTION_PRESENTATION_PATH)
	var spawner_text := _read_text(PRODUCTION_SPAWNER_PATH)
	_assert(
		route_text.contains("\"strategy\": \"procgen_landmark_terminal\""),
		"production route does not request the generated terminal anchor"
	)
	for forbidden in [
		"SpecialRoomRuntimeInserter",
		"claim_procgen_floor_rect_for_authored_scene_tiles",
		"sundered_keep_approach_route_master.png",
	]:
		_assert(
			not route_text.contains(forbidden) \
			and not presentation_text.contains(forbidden) \
			and not spawner_text.contains(forbidden),
			"production frontage references forbidden authority: %s"
			% forbidden
		)


func _assert_integrated_procgen_result() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	if procgen == null:
		procgen = map.find_child("ProcGen", true, false) as ProcGen
	_assert(procgen != null, "integrated procgen fixture has no generator")
	if procgen == null:
		map.queue_free()
		return
	procgen.generate_seed = false
	procgen.seed = 20260730
	procgen.map_size = Vector2i(160, 160)
	map.world_shape_mode = ProcGenTilemap.WorldShapeMode.ASCENT_FIELD
	map.worldgen_intent_enabled = true
	map.world_progression_enabled = true
	map.generate()
	for _frame in range(120):
		await process_frame
	var level_data: Dictionary = map.get_level_data()
	var frontage: Dictionary = level_data.get(
		"sundered_keep_frontage",
		{}
	)
	_assert(not frontage.is_empty(), "integrated level data omitted frontage")
	var ocean := _cell_lookup(level_data.get("ocean_cells", []))
	var chasm := _cell_lookup(level_data.get("chasm_cells", []))
	_assert(not ocean.is_empty(), "integrated level data omitted ocean cells")
	_assert(not chasm.is_empty(), "integrated level data omitted chasm cells")
	var gate: Variant = frontage.get("gate_anchor")
	_assert(
		gate is Vector2i \
			and map.call("is_runtime_walkable_after_props", gate),
		"integrated gate anchor is not ordinary procgen walkable floor"
	)
	if gate is Vector2i:
		_assert(not ocean.has(gate), "integrated gate anchor overlaps ocean")
		_assert(not chasm.has(gate), "integrated gate anchor overlaps chasm")
	var hard: Dictionary = frontage.get("hard_clearance_cells", {})
	for cell in hard.keys():
		if ocean.has(cell) or chasm.has(cell):
			_errors.append("hard-clearance floor overlaps non-walkable surface at %s" % cell)
			break
		if not bool(map.call("is_sundered_keep_frontage_protected", cell)):
			_errors.append("canonical frontage protection omitted %s" % cell)
			break
		if bool(map.call("debug_can_place_foliage_at", cell)):
			_errors.append("foliage candidate admitted protected frontage %s" % cell)
			break
		if map.call("has_runtime_prop_blocker_at_tile", cell):
			_errors.append(
				"integrated mandatory route has a runtime prop blocker at %s"
				% cell
			)
			break
	for cell in (frontage.get("terminal_apron_cells", {}) as Dictionary).keys():
		if ocean.has(cell) or chasm.has(cell):
			_errors.append("terminal apron overlaps non-walkable surface at %s" % cell)
			break
	var frontage_ocean := frontage.get("ocean_cells", {}) as Dictionary
	_assert(not frontage_ocean.is_empty(), "integrated frontage has no resolved ocean")
	var ocean_base := map.get_node_or_null(
		"NavigationRegion2D/NonWalkableSurfaceBase"
	) as TileMapLayer
	var ocean_overlay := map.get_node_or_null(
		"NavigationRegion2D/NonWalkableSurfaceOverlay"
	) as TileMapLayer
	_assert(ocean_base != null and not ocean_base.get_used_cells().is_empty(), "integrated near-field ocean fill was not painted")
	_assert(ocean_overlay != null and not ocean_overlay.get_used_cells().is_empty(), "integrated cardinal shore foam was not painted")
	var coastline := map.get_node_or_null(
		"NavigationRegion2D/NonWalkableSurfaceOverlay/"
		+ "SunderedKeepCoastlinePresentation"
	) as Node2D
	_assert(coastline != null and coastline.get_child_count() > 0, "integrated frontage did not build the authored cliff coastline")
	_assert(ocean_overlay != null and is_equal_approx(ocean_overlay.self_modulate.a, 0.34), "integrated shore foam is not subordinate to the cliff coastline")
	var touches_north := false
	for cell_variant in frontage_ocean.keys():
		var cell := cell_variant as Vector2i
		if not ocean.has(cell):
			_errors.append("frontage ocean cell missing from global ocean at %s" % cell)
			break
		if cell.y == 0:
			touches_north = true
		_assert(not bool(map.call("debug_can_place_foliage_at", cell)), "foliage admitted ocean at %s" % cell)
		if ocean_base != null:
			_assert(ocean_base.get_cell_source_id(cell) >= 0, "resolved ocean lacks fill visual at %s" % cell)
	for floor_cell_variant in map.debug_get_generated_floor_cells().keys():
		var floor_cell := floor_cell_variant as Vector2i
		if ocean_base != null and ocean_base.get_cell_source_id(floor_cell) >= 0:
			_errors.append("ocean visual painted authoritative floor at %s" % floor_cell)
			break
	_assert(touches_north, "frontage ocean does not touch its north seed edge")
	for spawn_cell in map.call("get_corridor_spawn_points", 256):
		if ocean.has(spawn_cell) or chasm.has(spawn_cell):
			_errors.append("ordinary corridor spawn overlaps non-walkable surface at %s" % spawn_cell)
			break
		if bool(map.call("is_sundered_keep_frontage_protected", spawn_cell)):
			_errors.append(
				"ordinary corridor spawn overlaps protected frontage at %s"
				% spawn_cell
			)
			break
	var summary: Dictionary = frontage.get("debug_summary", {})
	for key in [
		"frontage_required_floor_cell_missing_visual",
		"frontage_required_floor_cell_blocked",
		"frontage_required_floor_cell_surface_overlap",
		"frontage_required_floor_cell_ocean_overlap",
		"frontage_required_floor_cell_chasm_overlap",
	]:
		_assert(int(summary.get(key, -1)) == 0, "%s remained after frontage floor audit" % key)
	for site_key in ["faction_activity_sites", "story_room_sites"]:
		for site_variant in level_data.get(site_key, []):
			var site := site_variant as Dictionary
			var site_cell: Variant = site.get("cell")
			if site_cell is Vector2i and (
				frontage.get(
					"fortress_exclusion_cells",
					{}
				) as Dictionary
			).has(site_cell):
				_errors.append(
					"%s overlaps fortress exclusion at %s"
					% [site_key, site_cell]
				)
	var special_rooms: Array = level_data.get("special_room_sites", [])
	for site_variant in special_rooms:
		var site := site_variant as Dictionary
		if str(site.get("id", "")).contains("sundered_keep"):
			_errors.append("special-room inserter owns the Keep frontage")
	var audit: Dictionary = level_data.get("route_playability_audit", {})
	_assert(
		bool(audit.get("ok", false)),
		"integrated post-dressing route playability audit failed: %s"
		% audit
	)
	var border_wall_count := 0
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	for cell_variant in level_data.get("wall_cells", []):
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if cell.x == 0 or cell.y == 0 \
				or cell.x == map_size.x - 1 \
				or cell.y == map_size.y - 1:
			border_wall_count += 1
	_assert(
		border_wall_count < maxi(map_size.x, map_size.y),
		"integrated frontage retained a visible rectangular border wall"
	)
	map.queue_free()


func _cell_lookup(cells: Array) -> Dictionary:
	var result: Dictionary = {}
	for cell_variant in cells:
		if cell_variant is Vector2i:
			result[cell_variant] = true
	return result


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
