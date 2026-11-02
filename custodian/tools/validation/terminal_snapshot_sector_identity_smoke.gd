extends SceneTree

const SECTOR_SCRIPT := preload("res://game/actors/sector/sector.gd")
const SNAPSHOT_SCRIPT := preload("res://game/ui/terminal/terminal_snapshot.gd")
const OVERVIEW_SCRIPT := preload("res://game/ui/terminal/terminal_overview_view_model.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var ui := Node.new()
	ui.name = "UI"
	game_root.add_child(ui)
	for index in range(6):
		var sector: Sector = SECTOR_SCRIPT.new()
		sector.name = "Sector%02d" % index
		sector.sector_name = "SECTOR %02d" % index
		sector.global_position = Vector2(float(index) * 200.0, 0.0)
		world.add_child(sector)
	for index in range(5):
		var turret := Node2D.new()
		turret.name = "TurretSniper%02d" % index
		turret.global_position = Vector2(1000.0 + float(index), 0.0)
		turret.add_to_group("turret")
		turret.add_to_group("structure")
		world.add_child(turret)
	var operator := Node2D.new()
	operator.name = "Operator"
	operator.global_position = Vector2(1000.0, 0.0)
	world.add_child(operator)
	await process_frame
	var snapshot_builder = SNAPSHOT_SCRIPT.new()
	var sectors: Array[Dictionary] = snapshot_builder.collect_sectors(ui)
	_require(sectors.size() == 6, "Expected six sectors; broad structure members leaked into the snapshot.")
	for sector in sectors:
		_require(not String(sector.get("name", "")).to_upper().contains("TURRET"), "A turret name appeared in terminal sector records.")
	var operator_context: Dictionary = snapshot_builder.collect_operator_context(ui, sectors)
	_require(String(operator_context.get("operator_location", "")).begins_with("SECTOR"), "Operator location did not resolve to a Sector.")
	var overview: Dictionary = OVERVIEW_SCRIPT.new().build({
		"operator_location": operator_context.get("operator_location", "FIELD"),
		"sectors": sectors,
		"power_status": {"net_per_second": 0.0},
	})
	for candidate_variant in overview.get("priority_sectors", []):
		var candidate: Dictionary = candidate_variant
		_require(not String(candidate.get("name", "")).to_upper().contains("TURRET"), "A turret entered Overview priority candidates.")
	game_root.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[TerminalSnapshotSectorIdentitySmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[TerminalSnapshotSectorIdentitySmoke] PASS")
	quit(0)
