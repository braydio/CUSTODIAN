extends SceneTree

const VALIDATOR := preload("res://game/infrastructure/construction_placement_validator.gd")
const DEFINITION := preload("res://content/infrastructure/definitions/power/capacitor_bank_mk1.tres")
const TILESET := preload("res://content/tiles/tilesets/procgen_world_tileset.tres")

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var validator := VALIDATOR.new() as ConstructionPlacementValidator
	_require(validator.get_rotated_footprint_tiles(DEFINITION, 0) == Vector2i(3, 2), "0-degree footprint is not 3x2")
	_require(validator.get_rotated_footprint_tiles(DEFINITION, 90) == Vector2i(2, 3), "90-degree footprint is not 2x3")
	_require(validator.get_footprint_world_rect(Vector2.ZERO, DEFINITION, 0).size == Vector2(96, 64), "0-degree world footprint is not 96x64")
	_require(validator.get_footprint_world_rect(Vector2.ZERO, DEFINITION, 90).size == Vector2(64, 96), "90-degree world footprint is not 64x96")
	_require(validator.snap_world_origin(Vector2(47, 49), DEFINITION) == Vector2(32, 64), "origin did not snap to 32px grid")

	var fixture := Node2D.new()
	root.add_child(fixture)
	var zone := ConstructionZone2D.new()
	zone.zone_id = &"TEST_YARD"
	zone.size = Vector2(192, 160)
	zone.global_position = Vector2(96, 80)
	zone.site_tags = [&"compound", &"fabrication"]
	zone.allowed_categories = [&"power"]
	fixture.add_child(zone)
	var floor := TileMapLayer.new()
	floor.tile_set = TILESET
	fixture.add_child(floor)
	for x in range(8):
		for y in range(8):
			floor.set_cell(Vector2i(x, y), 10, Vector2i.ZERO, 0)
	var zones: Array[Node] = [zone]
	var valid := validator.validate(Vector2(32, 32), DEFINITION, 0, self, floor, zones)
	_require(bool(valid.get("valid", false)), "free complete footprint was not valid: %s" % valid)
	var partial := validator.validate(Vector2(160, 64), DEFINITION, 0, self, floor, zones)
	_require(str(partial.get("reason")) == "outside_construction_zone", "center-inside partial footprint was accepted")
	floor.erase_cell(Vector2i(2, 2))
	var missing := validator.validate(Vector2(32, 32), DEFINITION, 0, self, floor, zones)
	_require(str(missing.get("reason")) == "invalid_floor", "one missing floor cell did not invalidate footprint")
	floor.set_cell(Vector2i(2, 2), 10, Vector2i.ZERO, 0)
	var blocker := Node2D.new()
	blocker.global_position = Vector2(80, 64)
	blocker.add_to_group("structure")
	fixture.add_child(blocker)
	var occupied := validator.validate(Vector2(32, 32), DEFINITION, 0, self, floor, zones)
	_require(str(occupied.get("reason")) == "occupied", "overlapping structure did not invalidate footprint")
	blocker.global_position = Vector2(300, 300)
	var free_again := validator.validate(Vector2(32, 32), DEFINITION, 0, self, floor, zones)
	_require(bool(free_again.get("valid", false)), "non-overlapping structure invalidated free site")
	zone.allowed_categories = [&"fabrication"]
	var wrong_zone := validator.validate(Vector2(32, 32), DEFINITION, 0, self, floor, zones)
	_require(str(wrong_zone.get("reason")) == "unsupported_zone", "wrong category did not reject placement")
	fixture.queue_free()
	await process_frame
	_finish()


func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("[ConstructionPlacementValidatorSmoke] %s" % message)


func _finish() -> void:
	if failed:
		quit(1)
		return
	print("[ConstructionPlacementValidatorSmoke] PASS")
	quit(0)
