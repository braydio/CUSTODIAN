extends SceneTree

const COMPOSITOR := preload(
	"res://game/world/procgen/terrain/sundered_keep_shoreline_compositor.gd"
)
const LAB_SCENE := preload(
	"res://tools/visual_labs/sundered_keep_shoreline_lab.tscn"
)
const FIXTURE_PATHS := [
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_001.json",
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_017.json",
	"res://tools/visual_labs/fixtures/sundered_keep_shorelines/seed_071.json",
]

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := LAB_SCENE.instantiate() as Node2D
	root.add_child(lab)
	await process_frame
	await process_frame
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
			{
				"cell_world_size": 32.0,
				"cliff_spacing_px": 32.0,
				"cliff_overlap_px": 16.0,
				"foam_alpha": 0.22,
				"shore_band_width_cells": 2,
				"cliff_modulate": Color(0.72, 0.77, 0.84, 0.96),
			}
		)
		_assert(
			COMPOSITOR.plan_fingerprint(lab_plan) \
				== COMPOSITOR.plan_fingerprint(direct_plan),
			"lab diverged from production compositor for preset %d" % preset
		)
		_assert_plan_contract(direct_plan, floor_cells, ocean_cells, preset)
	for fixture_path in FIXTURE_PATHS:
		var file := FileAccess.open(fixture_path, FileAccess.READ)
		_assert(file != null, "missing production shoreline fixture %s" % fixture_path)
		if file == null:
			continue
		var fixture := COMPOSITOR.fixture_from_json(file.get_as_text())
		var fixture_plan := COMPOSITOR.build_plan(
			fixture.get("floor_cells", {}) as Dictionary,
			fixture.get("ocean_cells", {}) as Dictionary,
			int(fixture.get("seed", 0))
		)
		var repeated_plan := COMPOSITOR.build_plan(
			fixture.get("floor_cells", {}) as Dictionary,
			fixture.get("ocean_cells", {}) as Dictionary,
			int(fixture.get("seed", 0))
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

	var fixture_text := COMPOSITOR.fixture_to_json(
		17,
		lab.call("get_floor_cells") as Dictionary,
		lab.call("get_ocean_cells") as Dictionary,
		{"fixture": true}
	)
	var fixture := COMPOSITOR.fixture_from_json(fixture_text)
	_assert(int(fixture.get("seed", -1)) == 17, "fixture seed did not round-trip")
	_assert((fixture.get("floor_cells", {}) as Dictionary).size() == (lab.call("get_floor_cells") as Dictionary).size(), "fixture floor cells did not round-trip")
	_assert((fixture.get("ocean_cells", {}) as Dictionary).size() == (lab.call("get_ocean_cells") as Dictionary).size(), "fixture ocean cells did not round-trip")

	var presentation := lab.get_node("PreviewRoot/CliffPresentation") as Node2D
	for descendant in _all_descendants(presentation):
		_assert(not (descendant is CollisionObject2D or descendant is CollisionShape2D or descendant is NavigationRegion2D), "lab compositor introduced gameplay authority")

	lab.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[SunderedKeepShorelineCompositorSmoke] PASS presets=8 shared_plan=true")
		quit(0)
		return
	for error in _errors:
		push_error("[SunderedKeepShorelineCompositorSmoke] %s" % error)
	quit(1)


func _assert_plan_contract(
	plan: Dictionary,
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	preset: int
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
		_assert(is_equal_approx(float(segment["length_px"]), 32.0), "segment length did not derive from actual cell size")
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


func _all_descendants(root_node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root_node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
