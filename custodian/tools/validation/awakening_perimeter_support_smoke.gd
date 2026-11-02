extends SceneTree

## Scene-level camera coverage ledger and absent-art contract for AP0.

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const LAYOUT := preload("res://game/world/awakening/awakening_layout.gd")
const SUPPORT := preload("res://game/world/awakening/awakening_perimeter_support.gd")
const REPORT_PATH := "res://docs/ai_context/reports/awakening_perimeter_support/camera_coverage_v1.json"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const CELL_SIZE := 16.0
const DEFAULT_ZOOM := Vector2(0.84, 0.84) * 2.25
const ZONE_PLATE_INDICES := [1, 2, 3, 6, 7, 8, 9]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	_check_support_host(scene)
	var plates := _resolve_plate_bounds(scene)
	var ledger := _build_coverage_ledger(plates)
	if ledger != _build_coverage_ledger(plates):
		failures.append("camera coverage ledger changed across identical scene snapshots")
	_check_coverage_ledger(ledger)
	_write_report(ledger)
	if failures.is_empty():
		print("awakening_perimeter_support_smoke: PASS zones=10 families=9 planned_states=27 samples=%d" % ledger["samples"].size())
		quit(0)
	else:
		for failure in failures:
			push_error("awakening_perimeter_support_smoke: " + failure)
		quit(1)


func _check_support_host(scene: Node) -> void:
	var host := scene.get_node_or_null("World/AwakeningPerimeterSupport") as Node2D
	if host == null:
		failures.append("presentation host is missing")
		return
	var state: Dictionary = host.call("get_debug_state")
	if int(state["zone_family_count"]) != 9 or int(state["planned_state_count"]) != 27:
		failures.append("expected nine generic families / 27 deterministic placements")
	if bool(state["zone05_registered"]):
		failures.append("Zone 05 Dust Lung was incorrectly included in generic perimeter support")
	if int(state["loaded_state_count"]) != 0:
		failures.append("unexpected perimeter art exists in this absent-art AP0 checkout")
	if host.z_index >= LAYOUT.Z_FLOOR:
		failures.append("support host must remain below canonical gameplay floor")
	if host.find_children("*", "CollisionObject2D", true, false).size() > 0:
		failures.append("support host acquired collision authority")
	var void_backdrop := scene.get_node_or_null("World/AwakeningVoidBackdrop") as Polygon2D
	if void_backdrop == null or not void_backdrop.visible:
		failures.append("neutral fallback backdrop must remain visible when support art is absent")
	var plan_a := SUPPORT.build_placement_plan(LAYOUT.ZONES)
	var plan_b := SUPPORT.build_placement_plan(LAYOUT.ZONES)
	if plan_a != plan_b:
		failures.append("support placement description is not deterministic")
	if SUPPORT.RUNTIME_STATE_PATHS.size() != 27:
		failures.append("runtime state path registration must match the 27 V2 states")
	for placement in plan_a:
		if not bool(placement["collision_free"]) or int(placement["zone_index"]) == 5:
			failures.append("placement plan contains collision ownership or Zone 05")
			break
		if not SUPPORT.RUNTIME_STATE_PATHS.has(String(placement["resource_path"])):
			failures.append("placement path is not in the Asset V2 runtime path contract")


func _resolve_plate_bounds(scene: Node) -> Array[Dictionary]:
	var bounds: Array[Dictionary] = []
	for zone_variant: Variant in LAYOUT.ZONES:
		var zone := zone_variant as Dictionary
		var index := int(zone["index"])
		if ZONE_PLATE_INDICES.has(index):
			var path := "World/AwakeningZones/%s/ArtUnderlay/Underlay" % String(zone["node"])
			var sprite := scene.get_node_or_null(path) as Sprite2D
			if sprite == null or sprite.texture == null:
				failures.append("zone %02d live underlay is missing for bounds measurement" % index)
				continue
			bounds.append({"zone_index": index, "zone_id": String(zone["id"]), "bounds": sprite.get_global_transform() * sprite.get_rect()})
		elif index == 4:
			var composition := scene.get_node_or_null(
				"World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05/DustLung"
			) as Sprite2D
			if composition == null or composition.texture == null:
				failures.append("registered 04→05 composition is missing for bounds measurement")
				continue
			bounds.append({"zone_index": index, "zone_id": String(zone["id"]), "bounds": composition.get_global_transform() * composition.get_rect()})
		elif index == 5:
			var composition := scene.get_node_or_null(
				"World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05/DustLung"
			) as Sprite2D
			if composition == null or composition.texture == null:
				failures.append("registered 04→05 composition is missing for Zone05 bounds measurement")
				continue
			bounds.append({"zone_index": index, "zone_id": String(zone["id"]), "bounds": composition.get_global_transform() * composition.get_rect()})
		elif index == 10:
			bounds.append({"zone_index": index, "zone_id": String(zone["id"]), "bounds": LAYOUT.road_world_bounds()})
	return bounds


func _build_coverage_ledger(plate_records: Array[Dictionary]) -> Dictionary:
	var plate_bounds: Array[Rect2] = []
	for record in plate_records:
		plate_bounds.append(record["bounds"])
	var samples: Array[Dictionary] = []
	var zone_summary: Array[Dictionary] = []
	var sample_specs: Array[Dictionary] = [{
		"id": "wake", "center": LAYOUT.OPERATOR_WAKE_POSITION, "zoom": DEFAULT_ZOOM,
	}]
	for zone_variant: Variant in LAYOUT.ZONES:
		var zone := zone_variant as Dictionary
		var index := int(zone["index"])
		var envelope: Rect2 = zone["envelope"]
		sample_specs.append({"id": "zone%02d_center" % index, "center": envelope.get_center(), "zoom": DEFAULT_ZOOM})
		sample_specs.append({"id": "zone%02d_entry" % index, "center": zone["entry"], "zoom": DEFAULT_ZOOM})
		sample_specs.append({"id": "zone%02d_exit" % index, "center": zone["exit"], "zoom": DEFAULT_ZOOM})
	for reveal_variant: Variant in LAYOUT.CAMERA_REVEALS:
		var reveal_id := String(reveal_variant)
		var reveal: Dictionary = LAYOUT.CAMERA_REVEALS[reveal_variant]
		var reveal_zoom: Vector2 = reveal["zoom"] * 2.25
		sample_specs.append({
			"id": "reveal_%s" % reveal_id,
			"center": reveal["trigger"] + reveal["offset"],
			"zoom": reveal_zoom,
		})
	for spec in sample_specs:
		var sample := _measure_sample(spec, plate_bounds)
		samples.append(sample)
	for zone_variant: Variant in LAYOUT.ZONES:
		var zone := zone_variant as Dictionary
		var zone_id := String(zone["id"])
		var related: Array[Dictionary] = []
		for sample in samples:
			if String(sample["id"]).begins_with("zone%02d_" % int(zone["index"])):
				related.append(sample)
		zone_summary.append({
			"zone_id": zone_id,
			"optional": bool(zone["optional"]),
		"layout_envelope_world": _rect_data(zone["envelope"]),
			"camera_sample_count": related.size(),
			"samples": related.map(func(item: Dictionary) -> String: return String(item["id"])),
			"max_uncovered_visible_area_px2": _max_uncovered_area(related),
		})
	return {
		"schema": "custodian.awakening_perimeter_camera_coverage.v1",
		"viewport_px": VIEWPORT_SIZE,
		"default_camera_zoom": DEFAULT_ZOOM,
		"camera_reveal_zoom_scale": 2.25,
		"coverage_grid_px": CELL_SIZE,
		"zone_plate_bounds_world": _plate_bounds_data(plate_records),
		"zones": zone_summary,
		"samples": samples,
		"generic_perimeter_family_zone_indices": [1, 2, 3, 4, 6, 7, 8, 9, 10],
		"excluded_generic_zone_indices": [5],
	}


func _measure_sample(spec: Dictionary, plate_bounds: Array[Rect2]) -> Dictionary:
	var center: Vector2 = spec["center"]
	var zoom: Vector2 = spec["zoom"]
	var size := VIEWPORT_SIZE / zoom
	var footprint := Rect2(center - size * 0.5, size)
	var covered_cells := 0
	var uncovered_cells := 0
	var uncovered_bounds := Rect2()
	var has_uncovered := false
	var x0 := floori(footprint.position.x / CELL_SIZE)
	var y0 := floori(footprint.position.y / CELL_SIZE)
	var x1 := ceili(footprint.end.x / CELL_SIZE)
	var y1 := ceili(footprint.end.y / CELL_SIZE)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var point := Vector2((float(x) + 0.5) * CELL_SIZE, (float(y) + 0.5) * CELL_SIZE)
			var covered := false
			for plate in plate_bounds:
				if plate.has_point(point):
					covered = true
					break
			if covered:
				covered_cells += 1
			else:
				uncovered_cells += 1
				var cell_rect := Rect2(point - Vector2.ONE * CELL_SIZE * 0.5, Vector2.ONE * CELL_SIZE)
				uncovered_bounds = cell_rect if not has_uncovered else uncovered_bounds.merge(cell_rect)
				has_uncovered = true
	return {
		"id": spec["id"],
		"camera_center_world": center,
		"camera_zoom": zoom,
		"visible_world_rect": _rect_data(footprint),
		"plate_covered_grid_cells": covered_cells,
		"uncovered_visible_grid_cells": uncovered_cells,
		"uncovered_visible_area_px2": uncovered_cells * int(CELL_SIZE) * int(CELL_SIZE),
		"uncovered_visible_bounds_world": _rect_data(uncovered_bounds if has_uncovered else Rect2()),
	}


func _rect_data(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y,
	}


func _plate_bounds_data(records: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in records:
		result.append({
			"zone_index": record["zone_index"],
			"zone_id": record["zone_id"],
			"bounds": _rect_data(record["bounds"]),
		})
	return result


func _max_uncovered_area(samples: Array[Dictionary]) -> int:
	var result := 0
	for sample in samples:
		result = maxi(result, int(sample["uncovered_visible_area_px2"]))
	return result


func _check_coverage_ledger(ledger: Dictionary) -> void:
	if ledger["zones"].size() != 10 or ledger["zone_plate_bounds_world"].size() != 10 or ledger["samples"].size() != 34:
		failures.append("coverage ledger must measure ten zones and 34 authored camera samples")
	for zone in ledger["zones"]:
		if int(zone["camera_sample_count"]) != 3:
			failures.append("%s does not have center/entry/exit camera measurements" % zone["zone_id"])
	for sample in ledger["samples"]:
		if int(sample["uncovered_visible_grid_cells"]) < 0:
			failures.append("%s has an invalid negative uncovered-area measurement" % sample["id"])
	var uncovered_total := 0
	for sample in ledger["samples"]:
		uncovered_total += int(sample["uncovered_visible_area_px2"])
	if uncovered_total <= 0:
		failures.append("camera samples found no off-plate coverage gaps to ledger")


func _write_report(report: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(REPORT_PATH)
	var directory := absolute.get_base_dir()
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		failures.append("could not write camera coverage ledger: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
