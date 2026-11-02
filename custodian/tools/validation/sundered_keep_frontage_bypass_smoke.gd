extends SceneTree

const INTENT_BUILDER := preload(
	"res://game/world/procgen/intent/ascent_spine_builder.gd"
)
const FIELD_BUILDER := preload(
	"res://game/world/procgen/intent/ascent_field_builder.gd"
)
const KEEP_INTENT := preload(
	"res://game/world/procgen/landmarks/sundered_keep/sundered_keep_landmark_intent_builder.gd"
)
const FRONTAGE_BUILDER := preload(
	"res://game/world/procgen/landmarks/sundered_keep/sundered_keep_frontage_builder.gd"
)
const FRONTAGE_VALIDATOR := preload(
	"res://game/world/procgen/landmarks/sundered_keep/sundered_keep_frontage_validator.gd"
)
const MAP_SIZE := Vector2i(176, 176)
const REVIEW_SEEDS := [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233]

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for seed_value in REVIEW_SEEDS:
		var graph = INTENT_BUILDER.new().call("build", {
			"seed": seed_value,
			"map_size": MAP_SIZE,
			"origin_cell": Vector2i(MAP_SIZE.x / 2, MAP_SIZE.y - 12),
			"route_beat_count": 7,
		})
		KEEP_INTENT.new().call(
			"add_sundered_keep_intent",
			graph,
			{"seed": seed_value, "map_size": MAP_SIZE}
		)
		var field: Dictionary = FIELD_BUILDER.new().call(
			"build_field", graph, MAP_SIZE, seed_value
		)
		var frontage: Dictionary = FRONTAGE_BUILDER.new().call(
			"build_frontage", graph, field, MAP_SIZE, seed_value
		)
		var validation: Dictionary = FRONTAGE_VALIDATOR.new().call(
			"validate",
			frontage,
			field.get("main_route_cells", []) as Array[Vector2i]
		)
		if not bool(validation.get("ok", false)):
			_errors.append(
				"seed %d: %s" % [
					seed_value,
					"; ".join(validation.get("errors", [])),
				]
			)
	if _errors.is_empty():
		print("[SunderedKeepFrontageBypassSmoke] PASS seeds=%d" % REVIEW_SEEDS.size())
		quit(0)
		return
	for error in _errors:
		push_error("[SunderedKeepFrontageBypassSmoke] %s" % error)
	quit(1)
