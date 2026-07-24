extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var heatmap := root.get_node_or_null("/root/SectorHeatmap")
	if heatmap == null:
		_fail("SectorHeatmap autoload missing.")
		return

	for method_name in [
		"clear",
		"add",
		"add_event",
		"get_summary",
		"export_snapshot",
	]:
		if not heatmap.has_method(method_name):
			_fail("SectorHeatmap missing required API: %s" % method_name)
			return

	heatmap.call("clear")
	heatmap.call("add", Vector2(64.0, 64.0), &"presence", 1.0)
	heatmap.call("add", Vector2(70.0, 72.0), &"damage_taken", 5.0)
	heatmap.call("add_event", Vector2(128.0, 64.0), &"player_death", 10.0, {
		"ignored_runtime_metadata": true,
	})

	var snapshot: Variant = heatmap.call("export_snapshot")
	if not snapshot is Dictionary:
		_fail("SectorHeatmap export_snapshot did not return Dictionary.")
		return

	var export := snapshot as Dictionary
	if String(export.get("schema", "")) != "custodian.sector_heatmap.v1":
		_fail("SectorHeatmap snapshot schema mismatch.")
		return
	if int(export.get("cell_count", 0)) != 2:
		_fail("SectorHeatmap snapshot did not aggregate into two cells.")
		return
	if int(export.get("total_samples", 0)) != 3:
		_fail("SectorHeatmap snapshot sample count mismatch.")
		return

	var counts := export.get("event_type_counts", {}) as Dictionary
	if not is_equal_approx(float(counts.get("damage_taken", 0.0)), 5.0):
		_fail("SectorHeatmap missing damage_taken weight.")
		return
	if not is_equal_approx(float(counts.get("player_death", 0.0)), 10.0):
		_fail("SectorHeatmap missing player_death weight.")
		return

	var cells := export.get("cells", {}) as Dictionary
	if not cells.has("1,1") or not cells.has("2,1"):
		_fail("SectorHeatmap cell keys are not JSON-safe x,y strings.")
		return
	var shared_cell := cells["1,1"] as Dictionary
	if int(shared_cell.get("sample_count", 0)) != 2:
		_fail("SectorHeatmap same-cell samples were not aggregated.")
		return
	if (
		float(shared_cell.get("last_seen_sec", -1.0))
		< float(shared_cell.get("first_seen_sec", 0.0))
	):
		_fail("SectorHeatmap timestamps are not monotonic.")
		return

	var summary: Variant = heatmap.call("get_summary")
	if not summary is Dictionary:
		_fail("SectorHeatmap get_summary did not return Dictionary.")
		return
	if (summary as Dictionary).get("top_cells", []).is_empty():
		_fail("SectorHeatmap summary did not include top cells.")
		return

	var observatory := root.get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("_get_heatmap_snapshot"):
		_fail("Developer Observatory heatmap export hook is missing.")
		return
	var embedded: Variant = observatory.call("_get_heatmap_snapshot")
	if (
		not embedded is Dictionary
		or int((embedded as Dictionary).get("total_samples", 0)) != 3
	):
		_fail("Developer Observatory did not collect the heatmap snapshot.")
		return
	var payload := observatory.call(
		"_build_export_payload",
		"user://sector_heatmap_smoke_session.json"
	) as Dictionary
	if not payload.has("heatmap"):
		_fail("Developer Observatory export payload omitted the heatmap.")
		return
	var exported_heatmap := payload.get("heatmap", {}) as Dictionary
	if int(exported_heatmap.get("cell_count", 0)) != 2:
		_fail("Developer Observatory export payload heatmap is incomplete.")
		return

	if float(heatmap.call(
		"get_value",
		Vector2(70.0, 72.0),
		"damage_taken"
	)) < 4.99:
		_fail("SectorHeatmap legacy channel query regressed.")
		return

	heatmap.call("clear")
	var cleared := heatmap.call("export_snapshot") as Dictionary
	if int(cleared.get("cell_count", -1)) != 0:
		_fail("SectorHeatmap clear did not remove cells.")
		return

	print("SectorHeatmap smoke passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
