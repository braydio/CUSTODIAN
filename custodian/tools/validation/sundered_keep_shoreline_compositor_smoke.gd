extends SceneTree

const COMPOSITOR := preload(
	"res://game/world/procgen/terrain/sundered_keep_shoreline_compositor.gd"
)
const LAB_SCENE := preload(
	"res://tools/visual_labs/sundered_keep_shoreline_lab.tscn"
)
const PROCGEN_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CLIFF_CATALOG := preload(
	"res://game/world/procgen/terrain/sundered_keep_cliff_asset_catalog.gd"
)
const FIXTURE_PATHS := [
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_001.json",
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_017.json",
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_071.json",
]

var _errors: Array[String] = []
var _centering_errors: Dictionary = {}
var _max_global_position_error := 0.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_catalog_contract()
	var production := PROCGEN_SCENE.instantiate() as Node2D
	var lab := LAB_SCENE.instantiate() as Node2D
	root.add_child(lab)
	await process_frame
	await process_frame
	var production_floor := production.get_node("NavigationRegion2D/Floor") as TileMapLayer
	var lab_floor := lab.get_node("PreviewRoot/Floor") as TileMapLayer
	var production_world_cell_size := _resolve_world_cell_size(production_floor)
	var lab_world_cell_size := _resolve_world_cell_size(lab_floor)
	_assert(
		absf(production_world_cell_size - lab_world_cell_size) <= 0.01,
		"production/lab transformed cell sizes diverged: %.3f vs %.3f" % [
			production_world_cell_size,
			lab_world_cell_size,
		]
	)
	var render_context := lab.call("get_render_context") as Dictionary
	_assert(
		absf(float(render_context.get("world_cell_size", 0.0)) - lab_world_cell_size) <= 0.01,
		"lab render telemetry disagreed with its transformed grid"
	)
	_assert(
		is_equal_approx(
			float(render_context.get("effective_cliff_samples_per_cell", 0.0)),
			lab_world_cell_size / 32.0
		),
		"lab cliff-density telemetry did not derive from transformed cell size: %s" % render_context
	)
	for preset in range(8):
		lab.set("shape_preset", preset)
		lab.set("seed", 17 + preset)
		await process_frame
		await process_frame
		var floor_cells := lab.call("get_floor_cells") as Dictionary
		var ocean_cells := lab.call("get_ocean_cells") as Dictionary
		var lab_plan := lab.call("get_shoreline_plan") as Dictionary
		var direct_plan := COMPOSITOR.build_plan(
			floor_cells,
			ocean_cells,
			17 + preset,
			_plan_options(lab_world_cell_size)
		)
		_assert(
			COMPOSITOR.plan_fingerprint(lab_plan) \
				== COMPOSITOR.plan_fingerprint(direct_plan),
			"lab diverged from production compositor for preset %d" % preset
		)
		_assert_plan_contract(
			direct_plan,
			floor_cells,
			ocean_cells,
			preset,
			lab_world_cell_size
		)
	await _assert_vocabulary_and_context(lab)
	for fixture_path in FIXTURE_PATHS:
		var file := FileAccess.open(fixture_path, FileAccess.READ)
		_assert(file != null, "missing production shoreline fixture %s" % fixture_path)
		if file == null:
			continue
		var fixture := COMPOSITOR.fixture_from_json(file.get_as_text())
		var fixture_plan := COMPOSITOR.build_plan(
			fixture.get("floor_cells", {}) as Dictionary,
			fixture.get("ocean_cells", {}) as Dictionary,
			int(fixture.get("seed", 0)),
			_plan_options(production_world_cell_size)
		)
		var repeated_plan := COMPOSITOR.build_plan(
			fixture.get("floor_cells", {}) as Dictionary,
			fixture.get("ocean_cells", {}) as Dictionary,
			int(fixture.get("seed", 0)),
			_plan_options(production_world_cell_size)
		)
		_assert(
			COMPOSITOR.plan_fingerprint(fixture_plan) \
				== COMPOSITOR.plan_fingerprint(repeated_plan),
			"production fixture plan was nondeterministic: %s" % fixture_path
		)
		lab.set("production_fixture_path", fixture_path)
		lab.set("shape_preset", 8)
		await process_frame
		await process_frame
		_assert(
			COMPOSITOR.plan_fingerprint(lab.call("get_shoreline_plan")) \
				== COMPOSITOR.plan_fingerprint(fixture_plan),
			"production fixture lab plan diverged: %s" % fixture_path
		)
		var centered_at := _global_cell_bounds_center(
			lab_floor,
			fixture.get("floor_cells", {}) as Dictionary,
			fixture.get("ocean_cells", {}) as Dictionary
		)
		_centering_errors[fixture_path.get_file()] = centered_at.distance_to(
			Vector2(640.0, 360.0)
		)
		_assert(
			centered_at.distance_to(Vector2(640.0, 360.0)) <= 2.0,
			"production fixture was not centered: %s center=%s" % [fixture_path, centered_at]
		)

	var parity_file := FileAccess.open(FIXTURE_PATHS[1], FileAccess.READ)
	_assert(parity_file != null, "missing seed 17 parity fixture")
	if parity_file != null:
		var parity_fixture := COMPOSITOR.fixture_from_json(parity_file.get_as_text())
		var parity_floor := parity_fixture.get("floor_cells", {}) as Dictionary
		var parity_ocean := parity_fixture.get("ocean_cells", {}) as Dictionary
		var parity_seed := int(parity_fixture.get("seed", 17))
		var production_plan := COMPOSITOR.build_plan(
			parity_floor,
			parity_ocean,
			parity_seed,
			_plan_options(production_world_cell_size)
		)
		var lab_plan := COMPOSITOR.build_plan(
			parity_floor,
			parity_ocean,
			parity_seed,
			_plan_options(lab_world_cell_size)
		)
		_assert_plan_parity(production_plan, lab_plan)
		_assert_rendered_cliff_parity(
			production_plan,
			lab_plan,
			production,
			lab
		)

	var fixture_text := COMPOSITOR.fixture_to_json(
		17,
		lab.call("get_floor_cells") as Dictionary,
		lab.call("get_ocean_cells") as Dictionary,
		{"fixture": true},
		{"gate_threshold": [4, 5]}
	)
	var fixture := COMPOSITOR.fixture_from_json(fixture_text)
	_assert(int(fixture.get("seed", -1)) == 17, "fixture seed did not round-trip")
	_assert((fixture.get("floor_cells", {}) as Dictionary).size() == (lab.call("get_floor_cells") as Dictionary).size(), "fixture floor cells did not round-trip")
	_assert((fixture.get("ocean_cells", {}) as Dictionary).size() == (lab.call("get_ocean_cells") as Dictionary).size(), "fixture ocean cells did not round-trip")
	var roundtrip_gate := (fixture.get("vista_context", {}) as Dictionary).get("gate_threshold", []) as Array
	_assert(roundtrip_gate.size() == 2 and int(roundtrip_gate[0]) == 4 and int(roundtrip_gate[1]) == 5, "fixture vista context did not round-trip")

	var presentation := lab.get_node("PreviewRoot/CliffPresentation") as Node2D
	for descendant in _all_descendants(presentation):
		_assert(not (descendant is CollisionObject2D or descendant is CollisionShape2D or descendant is NavigationRegion2D), "lab compositor introduced gameplay authority")
	var context_root := lab.get_node("ProductionContextRoot") as Node2D
	for descendant in _all_descendants(context_root):
		_assert(not (descendant is CollisionObject2D or descendant is CollisionShape2D or descendant is NavigationRegion2D or descendant is NavigationObstacle2D), "lab context introduced gameplay authority")

	lab.queue_free()
	production.free()
	await process_frame
	if _errors.is_empty():
		print(
			"[SunderedKeepShorelineCompositorSmoke] PASS "
			+ "presets=8 vocabulary=15 production_cell=%.2f lab_cell=%.2f " % [
				production_world_cell_size,
				lab_world_cell_size,
			]
			+ "transform_plan_render_center_parity=true"
		)
		print(
			"[SunderedKeepShorelineCompositorSmoke] metrics "
			+ "local_tile=%s samples_per_cell=%.2f center_errors=%s max_global_error=%.3f" % [
				render_context.get("local_tile_size", Vector2.ZERO),
				float(render_context.get("effective_cliff_samples_per_cell", 0.0)),
				_centering_errors,
				_max_global_position_error,
			]
		)
		quit(0)
		return
	for error in _errors:
		push_error("[SunderedKeepShorelineCompositorSmoke] %s" % error)
	quit(1)


func _assert_plan_contract(
	plan: Dictionary,
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	preset: int,
	cell_world_size: float
) -> void:
	var segments := plan.get("segments", []) as Array
	var runs := plan.get("runs", []) as Array
	var cliffs := plan.get("cliffs", []) as Array
	var foam := plan.get("foam", []) as Array
	var floor_band := plan.get("floor_band", []) as Array
	_assert(not segments.is_empty(), "preset %d emitted no boundary segments" % preset)
	_assert(not runs.is_empty(), "preset %d emitted no ordered runs" % preset)
	_assert(not cliffs.is_empty(), "preset %d emitted no arc-distance cliffs" % preset)
	_assert(not foam.is_empty(), "preset %d emitted no shared-boundary foam" % preset)
	_assert(not floor_band.is_empty(), "preset %d emitted no coastal floor band" % preset)
	for segment_variant in segments:
		var segment := segment_variant as Dictionary
		_assert(floor_cells.has(segment["floor_cell"]), "segment floor cell lacks floor authority")
		_assert(ocean_cells.has(segment["ocean_cell"]), "segment ocean cell lacks ocean authority")
		_assert(is_equal_approx(float(segment["length_px"]), cell_world_size), "segment length did not derive from actual cell size")
	for run_variant in runs:
		var run := run_variant as Dictionary
		var run_segments := run.get("segments", []) as Array
		var expected_arc := 0.0
		for segment_variant in run_segments:
			var segment := segment_variant as Dictionary
			_assert(is_equal_approx(float(segment["cumulative_arc_distance"]), expected_arc), "run cumulative arc distance is discontinuous")
			expected_arc += float(segment["length_px"])
		_assert(is_equal_approx(float(run["length_px"]), expected_arc), "run length does not equal ordered segment arc")
	for cliff_variant in cliffs:
		var cliff := cliff_variant as Dictionary
		_assert(String(cliff["facing"]) in ["n", "e", "s", "w"], "cliff facing is not cardinal")
		_assert(String(cliff.get("kind", "")) in ["edge", "face_slice", "inner_corner", "outer_corner"], "cliff kind is invalid")
		_assert(not String(cliff.get("asset_key", "")).is_empty(), "cliff asset key is missing")
	for foam_variant in foam:
		var foam_entry := foam_variant as Dictionary
		_assert(ocean_cells.has(foam_entry["cell"]), "foam escaped authoritative ocean")
	if preset in [2, 3]:
		var has_corner_foam := false
		for foam_variant in foam:
			for topology_key in (foam_variant as Dictionary).get("topology_keys", []):
				if "corner" in String(topology_key):
					has_corner_foam = true
		_assert(has_corner_foam, "corner preset lost topology-aware corner foam")
	for floor_variant in floor_band:
		var floor_entry := floor_variant as Dictionary
		_assert(floor_cells.has(floor_entry["cell"]), "shore band escaped authoritative floor")
		_assert(int(floor_entry["source_id"]) in [129, 130, 131], "shore band used an unapproved source")


func _plan_options(cell_world_size: float) -> Dictionary:
	return {
		"cell_world_size": cell_world_size,
		"cliff_spacing_px": 32.0,
		"cliff_overlap_px": 16.0,
		"foam_alpha": 0.22,
		"shore_band_width_cells": 2,
		"cliff_modulate": Color(0.72, 0.77, 0.84, 0.96),
	}


func _assert_catalog_contract() -> void:
	var specs := CLIFF_CATALOG.all_specs()
	_assert(specs.size() == 15, "cliff catalog must expose exactly the existing 15-piece vocabulary")
	var counts := {"edge": 0, "face_slice": 0, "inner_corner": 0, "outer_corner": 0}
	for key in CLIFF_CATALOG.KEYS:
		var spec := specs.get(key, {}) as Dictionary
		_assert(not spec.is_empty(), "missing catalog spec %s" % key)
		_assert(spec.get("texture") is Texture2D, "catalog texture failed to load: %s" % key)
		_assert((spec.get("canvas_px", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(64, 96)), "catalog canvas drifted: %s" % key)
		_assert((spec.get("pivot_px", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(32, 94)), "catalog pivot drifted: %s" % key)
		var kind := String(spec.get("kind", ""))
		counts[kind] = int(counts.get(kind, 0)) + 1
	_assert(counts == {"edge": 4, "face_slice": 3, "inner_corner": 4, "outer_corner": 4}, "catalog kind counts mismatch: %s" % counts)


func _assert_vocabulary_and_context(lab: Node2D) -> void:
	lab.set("shape_preset", 9)
	lab.set("seed", 17)
	await process_frame
	await process_frame
	var plan := lab.call("get_shoreline_plan") as Dictionary
	var corners := {"inner_corner": {}, "outer_corner": {}}
	var slices: Dictionary = {}
	for cliff_variant in plan.get("cliffs", []):
		var cliff := cliff_variant as Dictionary
		var kind := String(cliff.get("kind", ""))
		var key := String(cliff.get("asset_key", ""))
		if kind in corners:
			(corners[kind] as Dictionary)[key.get_slice("_", 2)] = true
		if kind == "face_slice":
			slices[key] = true
			_assert(String(cliff.get("facing", "")) in ["n", "s"], "face slice appeared on E/W run")
	for kind in corners:
		_assert((corners[kind] as Dictionary).size() == 4, "%s did not exercise all orientations: %s" % [kind, corners[kind]])
	for seed_value in range(1, 65):
		var varied := COMPOSITOR.build_plan(
			lab.call("get_floor_cells") as Dictionary,
			lab.call("get_ocean_cells") as Dictionary,
			seed_value,
			_plan_options(float((lab.call("get_render_context") as Dictionary).get("world_cell_size", 32.0)))
		)
		for cliff_variant in varied.get("cliffs", []):
			var cliff := cliff_variant as Dictionary
			if String(cliff.get("kind", "")) == "face_slice":
				slices[String(cliff.get("asset_key", ""))] = true
	_assert(slices.size() == 3, "deterministic seed range did not exercise all face slices: %s" % slices)
	var length_by_run: Dictionary = {}
	for run_variant in plan.get("runs", []):
		var run := run_variant as Dictionary
		length_by_run[int(run.get("index", 0))] = float(run.get("length_px", 0.0))
	for corner_variant in plan.get("cliffs", []):
		var corner := corner_variant as Dictionary
		if not String(corner.get("kind", "")).ends_with("corner"):
			continue
		for sample_variant in plan.get("cliffs", []):
			var sample := sample_variant as Dictionary
			if String(sample.get("kind", "")) in ["inner_corner", "outer_corner"] \
					or int(sample.get("run_index", -1)) != int(corner.get("run_index", -2)):
				continue
			var delta := absf(float(sample["arc_distance_px"]) - float(corner["arc_distance_px"]))
			var run_length := float(length_by_run.get(int(corner["run_index"]), 0.0))
			delta = minf(delta, maxf(0.0, run_length - delta))
			_assert(delta >= 24.0 - 0.01, "straight sample entered corner exclusion: %s vs %s" % [corner, sample])
	var fingerprint_before := COMPOSITOR.plan_fingerprint(plan)
	var positions_before := _cliff_global_positions(lab)
	lab.set("production_context_mode", 1)
	await process_frame
	await process_frame
	_assert(COMPOSITOR.plan_fingerprint(lab.call("get_shoreline_plan")) == fingerprint_before, "context changed shoreline fingerprint")
	_assert(_cliff_global_positions(lab) == positions_before, "context moved cliff presentation")
	var floor_cells := lab.call("get_floor_cells") as Dictionary
	var ocean_cells := lab.call("get_ocean_cells") as Dictionary
	var floor_sample := floor_cells.keys()[0] as Vector2i
	var ocean_sample := ocean_cells.keys()[0] as Vector2i
	_assert(is_zero_approx(float(lab.call("get_ocean_mask_alpha", floor_sample))), "storm mask leaked onto floor")
	_assert(is_equal_approx(float(lab.call("get_ocean_mask_alpha", ocean_sample)), 1.0), "storm mask omitted ocean")
	_assert(lab.get_node_or_null("ProductionContextRoot/VistaArtBundle") != null, "lab does not instance shared vista bundle")
	lab.set("production_fixture_path", FIXTURE_PATHS[0])
	lab.set("shape_preset", 8)
	lab.set("production_context_mode", 2)
	await process_frame
	await process_frame
	var full_context := lab.call("get_render_context") as Dictionary
	_assert(String(full_context.get("context_warning", "")).is_empty(), "production fixture did not enable authoritative Full Vista")
	_assert((lab.get_node("ProductionContextRoot/VistaArtBundle/ExteriorVistaClip/FortressPresentation") as Node2D).visible, "Full Vista did not expose shared Keep context")
	lab.set("production_context_mode", 0)


func _cliff_global_positions(lab: Node2D) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var root_node := lab.get_node("PreviewRoot/CliffPresentation") as Node2D
	for child in root_node.get_children():
		if child is Sprite2D:
			result.append((child as Sprite2D).global_position)
	return result


func _resolve_world_cell_size(tilemap: TileMapLayer) -> float:
	var origin_world := tilemap.to_global(tilemap.map_to_local(Vector2i.ZERO))
	var right_world := tilemap.to_global(tilemap.map_to_local(Vector2i.RIGHT))
	return origin_world.distance_to(right_world)


func _assert_plan_parity(production_plan: Dictionary, lab_plan: Dictionary) -> void:
	_assert(
		COMPOSITOR.plan_fingerprint(production_plan) == COMPOSITOR.plan_fingerprint(lab_plan),
		"production/lab plan fingerprints diverged"
	)
	var production_segments := production_plan.get("segments", []) as Array
	var lab_segments := lab_plan.get("segments", []) as Array
	_assert(production_segments.size() == lab_segments.size(), "segment counts diverged")
	for index in range(mini(production_segments.size(), lab_segments.size())):
		_assert(
			is_equal_approx(
				float((production_segments[index] as Dictionary).get("length_px", 0.0)),
				float((lab_segments[index] as Dictionary).get("length_px", 0.0))
			),
			"segment length diverged at %d" % index
		)
	var production_runs := production_plan.get("runs", []) as Array
	var lab_runs := lab_plan.get("runs", []) as Array
	_assert(production_runs.size() == lab_runs.size(), "run counts diverged")
	for run_index in range(mini(production_runs.size(), lab_runs.size())):
		var production_run_segments := (production_runs[run_index] as Dictionary).get("segments", []) as Array
		var lab_run_segments := (lab_runs[run_index] as Dictionary).get("segments", []) as Array
		_assert(production_run_segments.size() == lab_run_segments.size(), "run segment counts diverged")
		for segment_index in range(mini(production_run_segments.size(), lab_run_segments.size())):
			_assert(
				is_equal_approx(
					float((production_run_segments[segment_index] as Dictionary).get("cumulative_arc_distance", 0.0)),
					float((lab_run_segments[segment_index] as Dictionary).get("cumulative_arc_distance", 0.0))
				),
				"run cumulative arc diverged at %d/%d" % [run_index, segment_index]
			)
	var production_cliffs := production_plan.get("cliffs", []) as Array
	var lab_cliffs := lab_plan.get("cliffs", []) as Array
	_assert(production_cliffs.size() == lab_cliffs.size(), "cliff counts diverged")
	for index in range(mini(production_cliffs.size(), lab_cliffs.size())):
		var production_cliff := production_cliffs[index] as Dictionary
		var lab_cliff := lab_cliffs[index] as Dictionary
		_assert(is_equal_approx(float(production_cliff["arc_distance_px"]), float(lab_cliff["arc_distance_px"])), "cliff arc distance diverged at %d" % index)
		_assert((production_cliff["position_grid"] as Vector2).is_equal_approx(lab_cliff["position_grid"] as Vector2), "cliff grid position diverged at %d" % index)
		_assert(production_cliff["facing"] == lab_cliff["facing"], "cliff facing diverged at %d" % index)
	_assert(production_plan.get("foam", []) == lab_plan.get("foam", []), "foam plans diverged")
	_assert(production_plan.get("floor_band", []) == lab_plan.get("floor_band", []), "floor-band plans diverged")


func _assert_rendered_cliff_parity(
	production_plan: Dictionary,
	lab_plan: Dictionary,
	production: Node2D,
	lab: Node2D
) -> void:
	var production_root := Node2D.new()
	var lab_root := Node2D.new()
	production_root.scale = production.global_transform.get_scale()
	lab_root.scale = (lab.get_node("PreviewRoot") as Node2D).global_transform.get_scale()
	root.add_child(production_root)
	root.add_child(lab_root)
	var production_presentation := Node2D.new()
	var lab_presentation := Node2D.new()
	production_root.add_child(production_presentation)
	lab_root.add_child(lab_presentation)
	var production_floor := production.get_node("NavigationRegion2D/Floor") as TileMapLayer
	var lab_floor := lab.get_node("PreviewRoot/Floor") as TileMapLayer
	COMPOSITOR.build_cliff_presentation(
		production_plan,
		production_presentation,
		Vector2(production_floor.tile_set.tile_size),
		production_root.global_transform.get_scale(),
		false,
		true
	)
	COMPOSITOR.build_cliff_presentation(
		lab_plan,
		lab_presentation,
		Vector2(lab_floor.tile_set.tile_size),
		lab_root.global_transform.get_scale(),
		false,
		true
	)
	var production_cliffs := production_presentation.get_children()
	var lab_cliffs := lab_presentation.get_children()
	_assert(production_cliffs.size() == lab_cliffs.size(), "rendered cliff counts diverged")
	for index in range(mini(production_cliffs.size(), lab_cliffs.size())):
		var production_sprite := production_cliffs[index] as Sprite2D
		var lab_sprite := lab_cliffs[index] as Sprite2D
		var global_position_error := production_sprite.global_position.distance_to(
			lab_sprite.global_position
		)
		_max_global_position_error = maxf(_max_global_position_error, global_position_error)
		_assert(global_position_error <= 0.1, "rendered cliff global position diverged at %d" % index)
		_assert(production_sprite.global_transform.get_scale().is_equal_approx(lab_sprite.global_transform.get_scale()), "rendered cliff global scale diverged at %d" % index)
		_assert(production_sprite.get_meta("facing") == lab_sprite.get_meta("facing"), "rendered cliff facing diverged at %d" % index)
		_assert(is_equal_approx(float(production_sprite.get_meta("arc_distance_px")), float(lab_sprite.get_meta("arc_distance_px"))), "rendered cliff arc metadata diverged at %d" % index)
	production_root.queue_free()
	lab_root.queue_free()


func _global_cell_bounds_center(
	tilemap: TileMapLayer,
	floor_cells: Dictionary,
	ocean_cells: Dictionary
) -> Vector2:
	var initialized := false
	var minimum := Vector2i.ZERO
	var maximum := Vector2i.ZERO
	for cells in [floor_cells, ocean_cells]:
		for cell_variant in (cells as Dictionary).keys():
			var cell := cell_variant as Vector2i
			if not initialized:
				minimum = cell
				maximum = cell
				initialized = true
			else:
				minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
				maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	var center_grid := (Vector2(minimum) + Vector2(maximum) + Vector2.ONE) * 0.5
	return tilemap.to_global(center_grid * Vector2(tilemap.tile_set.tile_size))


func _all_descendants(root_node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root_node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
