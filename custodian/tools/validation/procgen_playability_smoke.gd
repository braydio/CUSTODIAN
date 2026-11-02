extends SceneTree

const PLAYABILITY_SCRIPT := preload(
	"res://game/world/procgen/playability/route_playability_field.gd"
)


func _init() -> void:
	var floor_cells: Dictionary = {}
	for y in range(2, 28):
		for x in range(2, 38):
			floor_cells[Vector2i(x, y)] = true

	var route: Array[Vector2i] = []
	var centerline: Array[Vector2i] = []
	for y in range(4, 26):
		centerline.append(Vector2i(20, y))
		for x in range(16, 25):
			route.append(Vector2i(x, y))

	var reservations: Array[Dictionary] = [
		{
			"id": "spawn",
			"kind": "spawn",
			"rect": Rect2i(Vector2i(12, 18), Vector2i(16, 8)),
			"center": Vector2i(20, 22),
			"required": true,
		},
		{
			"id": "arena",
			"kind": "faction_site",
			"rect": Rect2i(Vector2i(4, 4), Vector2i(18, 14)),
			"center": Vector2i(13, 11),
			"required": true,
		},
	]

	var field: Dictionary = PLAYABILITY_SCRIPT.new().build(
		floor_cells,
		route,
		centerline,
		reservations
	)
	var hard: Dictionary = field.get("hard_clearance_cells", {})
	var shoulder: Dictionary = field.get("shoulder_cells", {})
	var sparse: Dictionary = field.get("sparse_dressing_cells", {})
	var deep: Dictionary = field.get("deep_dressing_cells", {})
	assert(hard.has(Vector2i(20, 10)))
	assert(hard.has(Vector2i(26, 10)))
	assert(shoulder.has(Vector2i(29, 10)))
	assert(sparse.has(Vector2i(33, 10)))
	assert(deep.has(Vector2i(37, 10)))
	assert((field.get("pockets", []) as Array).size() == 2)
	assert(not (field.get("encounter_clearance_cells", {}) as Dictionary).is_empty())

	var blockers := {Vector2i(20, 10): true}
	var blocked_audit: Dictionary = PLAYABILITY_SCRIPT.new().audit(
		floor_cells,
		blockers,
		route,
		centerline,
		[Vector2i(20, 22), Vector2i(20, 4)]
	)
	assert(not bool(blocked_audit.get("ok", true)))

	var clean_audit: Dictionary = PLAYABILITY_SCRIPT.new().audit(
		floor_cells,
		{},
		route,
		centerline,
		[Vector2i(20, 22), Vector2i(20, 4)]
	)
	assert(bool(clean_audit.get("ok", false)))
	assert(int(clean_audit.get("minimum_route_width", 0)) >= 7)

	print("procgen_playability_smoke: PASS")
	quit(0)
