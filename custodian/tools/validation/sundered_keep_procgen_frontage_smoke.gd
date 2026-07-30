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
		var cliffs: Dictionary = frontage.get("cliff_cells", {})
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
	var gate: Variant = frontage.get("gate_anchor")
	_assert(
		gate is Vector2i \
			and map.call("is_runtime_walkable_after_props", gate),
		"integrated gate anchor is not ordinary procgen walkable floor"
	)
	var hard: Dictionary = frontage.get("hard_clearance_cells", {})
	for cell in hard.keys():
		if map.call("has_runtime_prop_blocker_at_tile", cell):
			_errors.append(
				"integrated mandatory route has a runtime prop blocker at %s"
				% cell
			)
			break
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


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
