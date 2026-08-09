extends SceneTree

const CLASSIFIER := preload(
	"res://game/world/procgen/terrain/nonwalkable_surface_classifier.gd"
)
const MAP_SIZE := Vector2i(8, 8)
const CLAIM_ID := &"sundered_keep_frontage_ocean"

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_cells: Dictionary = {}
	for y in range(3, 6):
		for x in range(3, 6):
			floor_cells[Vector2i(x, y)] = true
	var claims: Array[Dictionary] = [{
		"id": CLAIM_ID,
		"kind": &"ocean",
		"profile": &"sundered_keep_cosmic_ocean",
		"bounds": Rect2i(Vector2i(1, 0), Vector2i(6, 5)),
		"seed_edge": &"north",
	}]
	var classifier := CLASSIFIER.new()
	var first: Dictionary = classifier.classify(MAP_SIZE, floor_cells, claims)
	var second: Dictionary = classifier.classify(MAP_SIZE, floor_cells, claims)
	var ocean := first.get("ocean_cells", {}) as Dictionary
	var chasm := first.get("chasm_cells", {}) as Dictionary
	var kinds := first.get("kind_by_cell", {}) as Dictionary
	var claim_cells := first.get("claim_cells_by_id", {}) as Dictionary

	for cell_variant in floor_cells.keys():
		var cell := cell_variant as Vector2i
		_assert(not ocean.has(cell), "authoritative floor overlaps ocean at %s" % cell)
		_assert(not chasm.has(cell), "authoritative floor overlaps chasm at %s" % cell)
	for cell_variant in ocean.keys():
		_assert(not chasm.has(cell_variant), "ocean overlaps chasm at %s" % cell_variant)
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			if floor_cells.has(cell):
				continue
			_assert(
				ocean.has(cell) != chasm.has(cell),
				"non-floor cell lacks exactly one surface at %s" % cell
			)
			_assert(kinds.has(cell), "surface kind missing at %s" % cell)
	_assert(ocean.has(Vector2i(1, 0)), "ocean does not touch north seed edge")
	_assert(not ocean.has(Vector2i(3, 3)), "ocean flooded through floor island")
	_assert(chasm.has(Vector2i(0, 0)), "cell outside claim bounds is not chasm")
	_assert(
		_fingerprint(first) == _fingerprint(second),
		"same classifier inputs are not deterministic"
	)
	# Wall-like overlay data is deliberately irrelevant and is never passed.
	var arbitrary_walls := {Vector2i(2, 1): true, Vector2i(4, 2): true}
	var with_irrelevant_walls: Dictionary = classifier.classify(
		MAP_SIZE, floor_cells, claims
	)
	_assert(not arbitrary_walls.is_empty(), "wall overlay fixture is empty")
	_assert(
		_fingerprint(first) == _fingerprint(with_irrelevant_walls),
		"irrelevant wall overlay changed surface classification"
	)
	_assert(
		claim_cells.get(CLAIM_ID, {}) == ocean,
		"claim_cells_by_id does not exactly match resolved ocean"
	)

	if _errors.is_empty():
		print("[ProcgenNonwalkableSurfaceSmoke] PASS ocean=%d chasm=%d" % [ocean.size(), chasm.size()])
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenNonwalkableSurfaceSmoke] %s" % error)
	quit(1)


func _fingerprint(result: Dictionary) -> String:
	var rows := PackedStringArray()
	for kind_name in ["chasm_cells", "ocean_cells"]:
		var cells := result.get(kind_name, {}) as Dictionary
		for cell_variant in cells.keys():
			var cell := cell_variant as Vector2i
			rows.append("%s:%d,%d" % [kind_name, cell.x, cell.y])
	rows.sort()
	return "|".join(rows)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
