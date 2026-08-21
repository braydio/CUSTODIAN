extends AuthoredLevel2D
class_name ForlornRitualantUnderground

const OPERATOR_PRESENTATION_RIG_SCENE := preload(
	"res://game/actors/operator/presentation/operator_presentation_rig_2d.tscn"
)
const LIFT_ASCENT_DISTANCE := 176.0
const RITUALANT_CHAMBER_BOUNDS := Rect2(-560.0, -432.0, 1120.0, 864.0)

const BOUNDARY_SEGMENTS := [
	[Vector2(-320.0, -376.0), Vector2(-112.0, -416.0)],
	[Vector2(-112.0, -416.0), Vector2(112.0, -416.0)],
	[Vector2(112.0, -416.0), Vector2(320.0, -376.0)],
	[Vector2(-320.0, -376.0), Vector2(-456.0, -264.0)],
	[Vector2(-456.0, -264.0), Vector2(-512.0, -32.0)],
	[Vector2(-512.0, -32.0), Vector2(-480.0, 224.0)],
	[Vector2(-480.0, 224.0), Vector2(-304.0, 360.0)],
	[Vector2(-304.0, 360.0), Vector2(-96.0, 416.0)],
	[Vector2(320.0, -376.0), Vector2(456.0, -264.0)],
	[Vector2(456.0, -264.0), Vector2(512.0, -32.0)],
	[Vector2(512.0, -32.0), Vector2(480.0, 224.0)],
	[Vector2(480.0, 224.0), Vector2(304.0, 360.0)],
	[Vector2(304.0, 360.0), Vector2(96.0, 416.0)],
]

const WALKABLE_PROBES := [
	Vector2(0.0, 0.0),
	Vector2(0.0, 300.0),
	Vector2(-280.0, 120.0),
	Vector2(280.0, 120.0),
]
const VOID_PROBES := [
	Vector2(-528.0, -300.0),
	Vector2(528.0, -300.0),
	Vector2(-520.0, 300.0),
	Vector2(520.0, 300.0),
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
var _departure_actor: Node = null
var _departure_rig: OperatorPresentationRig2D = null
var _departure_lift_start := Vector2.ZERO
var _actor_process_snapshot: Dictionary = {}
var _bound_operator: Node = null


func _ready() -> void:
	call_deferred("_bind_active_operator")


func _bind_active_operator() -> void:
	var actor := get_tree().get_first_node_in_group("player")
	if actor == null or not actor.has_signal("weapon_feedback_event"):
		return
	_bound_operator = actor
	var callback := Callable(self, "_on_operator_weapon_feedback")
	if not actor.is_connected("weapon_feedback_event", callback):
		actor.connect("weapon_feedback_event", callback)


func _on_operator_weapon_feedback(event_id: StringName, _snapshot: Dictionary) -> void:
	if ritualant_site == null or not (_bound_operator is Node2D):
		return
	if not RITUALANT_CHAMBER_BOUNDS.has_point(
		to_local((_bound_operator as Node2D).global_position)
	):
		return
	match event_id:
		&"fire":
			ritualant_site.player_fired_weapon_in_room()
		&"melee_attack_committed":
			ritualant_site.player_attacked_in_room()


func begin_lift_departure(actor: Node, exit: InteractableLevelExit2D) -> void:
	if _departure_running or actor == null or exit == null:
		return
	if ritualant_site != null and not ritualant_site.can_depart_site():
		return
	if not (actor is Node2D) or not lower_lift.is_actor_boarded(actor as Node2D):
		return
	_departure_running = true
	_departure_actor = actor
	_departure_lift_start = lower_lift.position
	if not _capture_departure_rider(actor):
		_departure_running = false
		_departure_actor = null
		return
	_suspend_departure_actor(actor)
	lower_lift.set_vibrating(true)
	await get_tree().create_timer(0.25).timeout
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		lower_lift,
		"position:y",
		lower_lift.position.y - LIFT_ASCENT_DISTANCE,
		0.75
	)
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
	_restore_departure_actor_processing(actor)
	var transition_started := exit.request_transition(actor)
	if not transition_started:
		await _rollback_failed_departure()


func _capture_departure_rider(actor: Node) -> bool:
	var rider_anchor := lower_lift.rider_anchor
	if rider_anchor == null:
		return false
	_departure_rig = OPERATOR_PRESENTATION_RIG_SCENE.instantiate() \
		as OperatorPresentationRig2D
	if _departure_rig == null:
		return false
	rider_anchor.add_child(_departure_rig)
	_departure_rig.position = Vector2.ZERO
	if not _departure_rig.capture_from_operator(actor):
		_departure_rig.queue_free()
		_departure_rig = null
		return false
	_departure_rig.hide_source_visuals()
	_departure_rig.play_pose(&"lift_braced")
	return true


func _suspend_departure_actor(actor: Node) -> void:
	_actor_process_snapshot = {
		"process": actor.is_processing(),
		"physics": actor.is_physics_processing(),
		"input": actor.is_processing_input(),
		"unhandled_input": actor.is_processing_unhandled_input(),
		"unhandled_key_input": actor.is_processing_unhandled_key_input(),
	}
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.set_process_input(false)
	actor.set_process_unhandled_input(false)
	actor.set_process_unhandled_key_input(false)
	if actor is CharacterBody2D:
		(actor as CharacterBody2D).velocity = Vector2.ZERO


func _restore_departure_actor_processing(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor) or _actor_process_snapshot.is_empty():
		return
	actor.set_process(bool(_actor_process_snapshot.get("process", true)))
	actor.set_physics_process(bool(_actor_process_snapshot.get("physics", true)))
	actor.set_process_input(bool(_actor_process_snapshot.get("input", true)))
	actor.set_process_unhandled_input(bool(_actor_process_snapshot.get("unhandled_input", true)))
	actor.set_process_unhandled_key_input(bool(_actor_process_snapshot.get("unhandled_key_input", true)))


func _rollback_failed_departure() -> void:
	_restore_departure_actor_processing(_departure_actor)
	if _departure_rig != null and is_instance_valid(_departure_rig):
		_departure_rig.restore_source_visuals()
		_departure_rig.queue_free()
	_departure_rig = null
	departure_epilogue.visible = false
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(lower_lift, "position", _departure_lift_start, 0.35)
	tween.tween_property(departure_black, "modulate:a", 0.0, 0.25)
	await tween.finished
	lower_lift.set_vibrating(false)
	_departure_actor = null
	_actor_process_snapshot.clear()
	_departure_running = false


func _cleanup_departure_immediate() -> void:
	_restore_departure_actor_processing(_departure_actor)
	if _departure_rig != null and is_instance_valid(_departure_rig):
		_departure_rig.restore_source_visuals()
		_departure_rig.queue_free()
	_departure_rig = null
	if lower_lift != null:
		lower_lift.position = _departure_lift_start
		lower_lift.set_vibrating(false)
	if departure_black != null:
		departure_black.modulate.a = 0.0
	if departure_epilogue != null:
		departure_epilogue.visible = false
	_departure_actor = null
	_actor_process_snapshot.clear()
	_departure_running = false


func capture_route_state() -> Dictionary:
	return {
		"encounter": ritualant_site.capture_encounter_state() \
			if ritualant_site != null else {},
	}


func restore_route_state(state: Dictionary) -> bool:
	if ritualant_site == null:
		return false
	return ritualant_site.restore_encounter_state(
		state.get("encounter", {}) as Dictionary
	)


func _exit_tree() -> void:
	if _bound_operator != null and is_instance_valid(_bound_operator):
		var callback := Callable(self, "_on_operator_weapon_feedback")
		if _bound_operator.is_connected("weapon_feedback_event", callback):
			_bound_operator.disconnect("weapon_feedback_event", callback)
	if _departure_running:
		_cleanup_departure_immediate()


func debug_is_departure_running() -> bool:
	return _departure_running


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_walkable_probes() -> Array:
	return WALKABLE_PROBES


func get_void_probes() -> Array:
	return VOID_PROBES


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS
