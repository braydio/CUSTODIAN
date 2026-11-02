extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const REQUIRED_REGIONS := [
	"TransitionArrival",
	"FirstVistaApproach",
	"ShoreParish",
	"NearVistaTraverse",
	"CausewayCheckpoint",
	"BeachApproach",
	"CausewayFootExit",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var approach := APPROACH_SCENE.instantiate()
	root.add_child(approach)
	await process_frame
	await process_frame
	for region_name in REQUIRED_REGIONS:
		_check(
			approach.get_node_or_null("AuthoredSubregions/%s" % region_name) != null,
			"missing continuous authored subregion %s" % region_name,
			errors
		)
	_check(
		approach.get_node_or_null("PlayableRoot/ApproachRouteMaster") != null,
		"authored route floor is unavailable",
		errors
	)
	_check(
		approach.get_node_or_null("EventRuntimeRoot/Exits/Exit_Continue") != null,
		"causeway-foot exit is unavailable",
		errors
	)
	_check(
		approach.get_node_or_null("EventRuntimeRoot/Exits/Exit_ReturnWorld") != null,
		"reverse traversal exit is unavailable",
		errors
	)
	_check(
		approach.find_children("*Stage*").is_empty(),
		"approach contains stage-scene lifecycle nodes",
		errors
	)
	_finish(errors)


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepApproachContinuitySmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepApproachContinuitySmoke] %s" % error)
	quit(1)
