extends AuthoredLevel2D
class_name ForlornRitualantUnderground

const BOUNDARY_SEGMENTS := [
	[Vector2(-544.0, -416.0), Vector2(544.0, -416.0)],
	[Vector2(-544.0, -416.0), Vector2(-544.0, 416.0)],
	[Vector2(544.0, -416.0), Vector2(544.0, 416.0)],
	[Vector2(-544.0, 416.0), Vector2(-96.0, 416.0)],
	[Vector2(96.0, 416.0), Vector2(544.0, 416.0)],
]

const AUTHORING_MARKERS := {
	"descent_landing": {
		"node_name": "Spawn_DescentLanding",
		"label": "LOWER DESCENT LANDING",
		"kind": "spawn",
		"position": Vector2(0.0, 332.0),
	},
	"return_world": {
		"node_name": "Exit_ReturnWorld",
		"label": "ASCEND TO SURFACE",
		"kind": "level_exit",
		"position": Vector2(0.0, 358.0),
	},
	"encounter_origin": {
		"node_name": "ForlornRitualantSite",
		"label": "RITUALANT ENCOUNTER ORIGIN",
		"kind": "encounter",
		"position": Vector2(0.0, 0.0),
	},
}

@onready var lower_lift: AshBellLiftPlatformAssembly = $PropsRoot/LowerLiftAssembly
@onready var ritualant_site: ForlornRitualantSite = $PlayableRoot/ForlornRitualantSite
@onready var departure_black: ColorRect = $DepartureOverlay/Black
@onready var departure_epilogue: Label = $DepartureOverlay/Epilogue

var _departure_running := false


func begin_lift_departure(actor: Node, exit: InteractableLevelExit2D) -> void:
	if _departure_running or actor == null or exit == null:
		return
	if ritualant_site != null and not ritualant_site.can_depart_site():
		return
	_departure_running = true
	lower_lift.set_vibrating(true)
	await get_tree().create_timer(0.25).timeout
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(lower_lift, "position:y", lower_lift.position.y - 80.0, 0.75)
	tween.tween_property(departure_black, "modulate:a", 1.0, 0.65)
	await tween.finished
	var lines: Array[String] = ritualant_site.get_departure_lines() if ritualant_site != null else []
	for line in lines:
		departure_epilogue.text = "Forlorn-Ritualant: %s" % line
		departure_epilogue.visible = true
		await get_tree().create_timer(0.9).timeout
	departure_epilogue.visible = false
	if not lines.is_empty():
		await get_tree().create_timer(0.35).timeout
	exit.request_transition(actor)


func debug_is_departure_running() -> bool:
	return _departure_running


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS
