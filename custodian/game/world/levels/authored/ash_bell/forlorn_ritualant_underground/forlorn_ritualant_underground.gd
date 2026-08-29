extends AuthoredLevel2D
class_name ForlornRitualantUnderground

const OPERATOR_PRESENTATION_RIG_SCENE := preload(
	"res://game/actors/operator/presentation/operator_presentation_rig_2d.tscn"
)
const LIFT_ASCENT_DISTANCE := 176.0
const LOWER_LIFT_TRAVEL_DISTANCE := 256.0
const ARRIVAL_BLACK_HOLD_SEC := 0.20
const ARRIVAL_BLACK_FADE_SEC := 0.50
const ARRIVAL_SHAFT_ESTABLISH_SEC := 0.15
const ARRIVAL_TRAVEL_SEC := 1.35
const ARRIVAL_SHAFT_FADE_SEC := 0.30
const DEPARTURE_PREMOVE_HOLD_SEC := 0.20
const DEPARTURE_VISIBLE_TRAVEL_SEC := 0.70
const DEPARTURE_FADE_TRAVEL_SEC := 0.75
const DEPARTURE_BLACK_FADE_SEC := 0.60
const DEPARTURE_BLACK_HOLD_SEC := 0.25
const AUTHORED_CELL_SIZE := 32.0
const MAP_SIZE_CELLS := Vector2i(112, 128)
const LEVEL_BOUNDS := Rect2(-1792.0, -2048.0, 3584.0, 4096.0)
const CHAPEL_ORIGIN := Vector2(0.0, -1120.0)
const RITUALANT_CHAMBER_BOUNDS := Rect2(-560.0, -1552.0, 1120.0, 864.0)
const LOWER_LIFT_DOCK := Vector2(0.0, 1696.0)
const LOWER_LIFT_ARRIVAL_START := Vector2(0.0, 1440.0)
const SPAWN_DESCENT_LANDING := Vector2(0.0, 1670.0)
const LANDING_CONNECTOR := Rect2(-128.0, 1312.0, 256.0, 128.0)
const CHAPEL_CONNECTOR := Rect2(-96.0, -768.0, 192.0, 128.0)
const CAVERN_DEEPER_DIRECTION := Vector2.UP
const LIFT_DESCENT_SCREEN_DIRECTION := Vector2.DOWN
const LIFT_ASCENT_SCREEN_DIRECTION := Vector2.UP

var PLAYABLE_BOUNDARY_LOOP := PackedVector2Array([
	Vector2(-128,1376), Vector2(-160,1280), Vector2(-288,1184), Vector2(-384,1024), Vector2(-416,832), Vector2(-352,640), Vector2(-224,480), Vector2(-64,320), Vector2(64,160), Vector2(96,-64), Vector2(32,-256), Vector2(-96,-416), Vector2(-224,-576), Vector2(-96,-704), Vector2(-304,-760), Vector2(-480,-896), Vector2(-512,-1152), Vector2(-456,-1384), Vector2(-320,-1496), Vector2(-112,-1536), Vector2(112,-1536), Vector2(320,-1496), Vector2(456,-1384), Vector2(512,-1152), Vector2(480,-896), Vector2(304,-760), Vector2(96,-704), Vector2(224,-576), Vector2(224,-352), Vector2(320,-192), Vector2(352,32), Vector2(320,224), Vector2(192,416), Vector2(32,576), Vector2(-96,736), Vector2(-128,928), Vector2(-64,1088), Vector2(64,1216), Vector2(128,1280), Vector2(128,1376), Vector2(224,1408), Vector2(320,1472), Vector2(352,1600), Vector2(352,1760), Vector2(288,1824), Vector2(-288,1824), Vector2(-352,1760), Vector2(-352,1600), Vector2(-320,1472), Vector2(-224,1408),
])
var CAVERN_CENTERLINE := PackedVector2Array([
	Vector2(0,1376), Vector2(-64,1280), Vector2(-224,1120), Vector2(-256,832), Vector2(-192,608), Vector2(-64,416), Vector2(128,192), Vector2(192,-64), Vector2(128,-320), Vector2(0,-544), Vector2(0,-704),
])

const WALKABLE_PROBES := [
	Vector2(0.0, 1600.0), Vector2(-256.0, 960.0), Vector2(160.0, -64.0), Vector2(0.0, -704.0), Vector2(0.0, -1120.0),
]
const VOID_PROBES := [
	Vector2(-640.0, 1600.0), Vector2(640.0, 1600.0), Vector2(-640.0, 800.0), Vector2(640.0, 0.0),
]

const AUTHORING_MARKERS := {
	"descent_landing": {
		"node_name": "Spawn_DescentLanding",
		"label": "LOWER DESCENT LANDING",
		"kind": "spawn",
		"position": SPAWN_DESCENT_LANDING,
	},
	"return_world": {
		"node_name": "Exit_ReturnWorld",
		"label": "ASCEND TO SURFACE",
		"kind": "level_exit",
		"position": LOWER_LIFT_DOCK,
	},
	"encounter_origin": {
		"node_name": "ForlornRitualantSite",
		"label": "RITUALANT ENCOUNTER ORIGIN",
		"kind": "encounter",
		"position": CHAPEL_ORIGIN,
	},
}

@onready var lower_lift: AshBellLiftPlatformAssembly = $PropsRoot/LowerLiftAssembly
@onready var ritualant_site: ForlornRitualantSite = $PlayableRoot/ForlornRitualantSite
@onready var departure_black: ColorRect = $DepartureOverlay/Black
@onready var departure_epilogue: Label = $DepartureOverlay/Epilogue
@onready var landing_shelf_apron: Sprite2D = $BackgroundRoot/LandingShelfApron
@onready var playable_ground: Polygon2D = $BackgroundRoot/PlayableGround
@onready var distant_chapel_proxy: Sprite2D = $UnderlayRoot/DistantChapelProxy
@onready var shaft_arrival_back: Sprite2D = $ArrivalDescentRoot/ShaftArrivalBack
@onready var shaft_arrival_fore: Sprite2D = $ArrivalDescentRoot/ShaftArrivalFore
@onready var landing_mouth: Sprite2D = $ArrivalDescentRoot/LandingMouth
@onready var landing_dust: Sprite2D = $ArrivalDescentRoot/LandingDust
@onready var camera_zone_director: AuthoredCameraZoneDirector2D = (
	$CameraPresentation/AuthoredCameraZoneDirector2D
)

var _departure_running := false
var _departure_actor: Node = null
var _departure_rig: OperatorPresentationRig2D = null
var _departure_lift_start := Vector2.ZERO
var _actor_process_snapshot: Dictionary = {}
var _bound_operator: Node = null
var _arrival_running := false
var _arrival_actor: Node = null
var _arrival_rig: OperatorPresentationRig2D = null
var _distant_proxy_tween: Tween


func _ready() -> void:
	_build_playable_ground()
	distant_chapel_proxy.modulate.a = 0.0
	if camera_zone_director != null:
		camera_zone_director.active_profile_changed.connect(
			_on_camera_profile_changed
		)
		call_deferred("_refresh_initial_camera_profile")
	call_deferred("_bind_active_operator")


func _refresh_initial_camera_profile() -> void:
	if camera_zone_director != null:
		camera_zone_director.refresh_now()


func _build_playable_ground() -> void:
	playable_ground.polygon = PLAYABLE_BOUNDARY_LOOP
	var ground_uv := PackedVector2Array()
	for point in PLAYABLE_BOUNDARY_LOOP:
		ground_uv.append(point - LEVEL_BOUNDS.position)
	playable_ground.uv = ground_uv


func _on_camera_profile_changed(
	_previous_profile: StringName,
	current_profile: StringName
) -> void:
	match current_profile:
		&"LANDING_VISTA", &"UPPER_DESCENT":
			_fade_distant_chapel(0.88, 0.45)
		&"DEEP_CAVERN", &"CHAPEL_APPROACH", &"CHAPEL_GAMEPLAY_RELEASE":
			_fade_distant_chapel(0.0, 0.65)


func _fade_distant_chapel(target_alpha: float, seconds: float) -> void:
	if distant_chapel_proxy == null:
		return
	if _distant_proxy_tween != null and _distant_proxy_tween.is_valid():
		_distant_proxy_tween.kill()
	_distant_proxy_tween = create_tween()
	_distant_proxy_tween.set_trans(Tween.TRANS_SINE)
	_distant_proxy_tween.set_ease(Tween.EASE_IN_OUT)
	_distant_proxy_tween.tween_property(
		distant_chapel_proxy,
		"modulate:a",
		target_alpha,
		seconds
	)


func activate_route_node(actor: Node, spawn_id: StringName) -> bool:
	if not super.activate_route_node(actor, spawn_id):
		return false
	if spawn_id == &"Spawn_DescentLanding":
		call_deferred("_begin_arrival_sequence", actor)
	return true


func _begin_arrival_sequence(actor: Node) -> void:
	if _arrival_running or actor == null or not (actor is Node2D):
		return
	_arrival_running = true
	_arrival_actor = actor
	if not _capture_arrival_rider(actor):
		_arrival_running = false
		_arrival_actor = null
		return
	_suspend_arrival_actor(actor)
	departure_black.modulate.a = 1.0
	shaft_arrival_back.visible = true
	shaft_arrival_fore.visible = true
	shaft_arrival_back.modulate.a = 1.0
	shaft_arrival_fore.modulate.a = 1.0
	shaft_arrival_back.region_rect.position.y = 0.0
	shaft_arrival_fore.region_rect.position.y = 0.0
	lower_lift.position = LOWER_LIFT_ARRIVAL_START
	lower_lift.set_vibrating(true)
	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.has_method("set_presentation_framing"):
		camera.call("set_presentation_framing", true, Vector2(0.0, -224.0), Vector2(0.62, 0.62))
	await get_tree().create_timer(ARRIVAL_BLACK_HOLD_SEC).timeout
	var black_fade := create_tween()
	black_fade.set_trans(Tween.TRANS_SINE)
	black_fade.set_ease(Tween.EASE_OUT)
	black_fade.tween_property(
		departure_black, "modulate:a", 0.0, ARRIVAL_BLACK_FADE_SEC
	)
	await black_fade.finished
	await get_tree().create_timer(ARRIVAL_SHAFT_ESTABLISH_SEC).timeout
	var lift_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift_tween.tween_property(lower_lift, "position", LOWER_LIFT_DOCK, ARRIVAL_TRAVEL_SEC)
	lift_tween.tween_property(shaft_arrival_back, "region_rect:position:y", 448.0, ARRIVAL_TRAVEL_SEC)
	lift_tween.tween_property(shaft_arrival_fore, "region_rect:position:y", 576.0, ARRIVAL_TRAVEL_SEC)
	await lift_tween.finished
	lower_lift.set_vibrating(false)
	landing_dust.visible = true
	var shaft_fade := create_tween().set_parallel(true)
	shaft_fade.tween_property(shaft_arrival_back, "modulate:a", 0.0, ARRIVAL_SHAFT_FADE_SEC)
	shaft_fade.tween_property(shaft_arrival_fore, "modulate:a", 0.0, ARRIVAL_SHAFT_FADE_SEC)
	await shaft_fade.finished
	shaft_arrival_back.visible = false
	shaft_arrival_fore.visible = false
	landing_dust.visible = false
	_finish_arrival_sequence()


func _capture_arrival_rider(actor: Node) -> bool:
	_arrival_rig = OPERATOR_PRESENTATION_RIG_SCENE.instantiate() as OperatorPresentationRig2D
	if _arrival_rig == null:
		return false
	lower_lift.rider_anchor.add_child(_arrival_rig)
	_arrival_rig.position = Vector2.ZERO
	if not _arrival_rig.capture_from_operator(actor):
		_arrival_rig.queue_free()
		_arrival_rig = null
		return false
	_arrival_rig.hide_source_visuals()
	_arrival_rig.play_pose(&"lift_braced")
	return true


func _suspend_arrival_actor(actor: Node) -> void:
	_actor_process_snapshot = {
		"process": actor.is_processing(), "physics": actor.is_physics_processing(),
		"input": actor.is_processing_input(), "unhandled_input": actor.is_processing_unhandled_input(),
		"unhandled_key_input": actor.is_processing_unhandled_key_input(),
	}
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.set_process_input(false)
	actor.set_process_unhandled_input(false)
	actor.set_process_unhandled_key_input(false)
	if actor is CharacterBody2D:
		(actor as CharacterBody2D).velocity = Vector2.ZERO


func _finish_arrival_sequence() -> void:
	if _arrival_actor != null and is_instance_valid(_arrival_actor):
		_restore_departure_actor_processing(_arrival_actor)
	if _arrival_rig != null and is_instance_valid(_arrival_rig):
		_arrival_rig.restore_source_visuals()
		_arrival_rig.queue_free()
	_arrival_rig = null
	_arrival_actor = null
	_actor_process_snapshot.clear()
	_arrival_running = false


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
	if ritualant_site.suppresses_encounter_hazards():
		return
	match event_id:
		&"fire":
			ritualant_site.player_fired_weapon_in_room()
		&"melee_attack_committed":
			ritualant_site.player_attacked_in_room()


func begin_lift_departure(actor: Node, exit: InteractableLevelExit2D) -> void:
	if exit == null or not can_begin_lift_departure(actor, exit):
		return
	_departure_running = true
	_departure_actor = actor
	_departure_lift_start = lower_lift.position
	if not _capture_departure_rider(actor):
		_departure_running = false
		_departure_actor = null
		return
	_suspend_departure_actor(actor)
	shaft_arrival_back.visible = true
	shaft_arrival_fore.visible = true
	shaft_arrival_back.modulate.a = 1.0
	shaft_arrival_fore.modulate.a = 1.0
	shaft_arrival_back.region_rect.position.y = 448.0
	shaft_arrival_fore.region_rect.position.y = 576.0
	lower_lift.set_vibrating(true)
	await get_tree().create_timer(DEPARTURE_PREMOVE_HOLD_SEC).timeout
	var halfway_y := _departure_lift_start.y - 128.0
	var visible_ascent := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	visible_ascent.tween_property(lower_lift, "position:y", halfway_y, DEPARTURE_VISIBLE_TRAVEL_SEC)
	visible_ascent.tween_property(shaft_arrival_back, "region_rect:position:y", 224.0, DEPARTURE_VISIBLE_TRAVEL_SEC)
	visible_ascent.tween_property(shaft_arrival_fore, "region_rect:position:y", 288.0, DEPARTURE_VISIBLE_TRAVEL_SEC)
	await visible_ascent.finished
	var ascent_target_y := _departure_lift_start.y - LOWER_LIFT_TRAVEL_DISTANCE
	var final_ascent := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	final_ascent.tween_property(lower_lift, "position:y", ascent_target_y, DEPARTURE_FADE_TRAVEL_SEC)
	final_ascent.tween_property(shaft_arrival_back, "region_rect:position:y", 0.0, DEPARTURE_FADE_TRAVEL_SEC)
	final_ascent.tween_property(shaft_arrival_fore, "region_rect:position:y", 0.0, DEPARTURE_FADE_TRAVEL_SEC)
	var black_fade := create_tween()
	black_fade.tween_interval(DEPARTURE_FADE_TRAVEL_SEC - DEPARTURE_BLACK_FADE_SEC)
	black_fade.tween_property(departure_black, "modulate:a", 1.0, DEPARTURE_BLACK_FADE_SEC)
	await final_ascent.finished
	await black_fade.finished
	await get_tree().create_timer(DEPARTURE_BLACK_HOLD_SEC).timeout
	var lines: Array[String] = ritualant_site.get_departure_lines() if ritualant_site != null else []
	for line in lines:
		departure_epilogue.text = "Forlorn-Ritualant: %s" % line
		departure_epilogue.visible = true
		await get_tree().create_timer(0.9).timeout
	departure_epilogue.visible = false
	if not lines.is_empty():
		await get_tree().create_timer(0.35).timeout
	var transition_started := exit.request_transition(actor)
	if not transition_started:
		await _rollback_failed_departure()


func can_begin_lift_departure(
	actor: Node,
	_exit: InteractableLevelExit2D = null
) -> bool:
	if _departure_running or not (actor is Node2D):
		return false
	if lower_lift == null or not lower_lift.is_actor_boarded(actor as Node2D):
		return false
	if ritualant_site != null and not ritualant_site.can_depart_site():
		return false
	return true


func _capture_departure_rider(actor: Node) -> bool:
	var rider_anchor := lower_lift.rider_anchor
	if rider_anchor == null:
		return false
	_departure_rig = OPERATOR_PRESENTATION_RIG_SCENE.instantiate() \
		as OperatorPresentationRig2D
	if _departure_rig == null:
		return false
	rider_anchor.add_child(_departure_rig)
	_departure_rig.z_as_relative = false
	_departure_rig.z_index = 2
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
	if _arrival_running:
		_finish_arrival_sequence()


func debug_is_departure_running() -> bool:
	return _departure_running


func get_boundary_segments() -> Array:
	var segments: Array = []
	for index in PLAYABLE_BOUNDARY_LOOP.size():
		segments.append([
			PLAYABLE_BOUNDARY_LOOP[index],
			PLAYABLE_BOUNDARY_LOOP[(index + 1) % PLAYABLE_BOUNDARY_LOOP.size()],
		])
	return segments


func get_walkable_probes() -> Array:
	return WALKABLE_PROBES


func get_void_probes() -> Array:
	return VOID_PROBES


func get_authoring_debug_geometry() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_append_level_debug_geometry(out)
	_append_encounter_debug_geometry(out)
	_append_camera_debug_geometry(out)
	_append_transition_debug_geometry(out)
	_append_art_debug_geometry(out)
	return out


func _append_level_debug_geometry(out: Array[Dictionary]) -> void:
	out.append(AuthoringDebugGeometry.polygon_record(
		"playable.boundary", "boundary", "PLAYABLE AREA",
		PLAYABLE_BOUNDARY_LOOP, "Runtime walkability boundary", self
	))
	for record in [
		AuthoringDebugGeometry.rect_record("traversal.landing_connector", "traversal", "LANDING CONNECTOR", LANDING_CONNECTOR, "Authored route connector", self),
		AuthoringDebugGeometry.rect_record("traversal.chapel_connector", "traversal", "CHAPEL CONNECTOR", CHAPEL_CONNECTOR, "Authored route connector", self),
		AuthoringDebugGeometry.rect_record("encounter.ritualant_chamber", "encounter", "RITUALANT CHAMBER", RITUALANT_CHAMBER_BOUNDS, "1120x864 current chapel; resize deferred", self),
		AuthoringDebugGeometry.point_record("traversal.lower_lift_dock", "traversal", "LOWER LIFT DOCK", LOWER_LIFT_DOCK, "Lift boarding and departure origin", lower_lift),
		AuthoringDebugGeometry.point_record("traversal.spawn_descent", "traversal", "DESCENT LANDING SPAWN", SPAWN_DESCENT_LANDING, "Route entry spawn", get_node_or_null("Markers/Spawn_DescentLanding")),
		AuthoringDebugGeometry.point_record("transition.return_world", "transition", "RETURN WORLD EXIT", LOWER_LIFT_DOCK, "Interaction distance 96 px", get_node_or_null("Exits/Exit_ReturnWorld")),
	]:
		out.append(record)


func _append_encounter_debug_geometry(out: Array[Dictionary]) -> void:
	if ritualant_site == null:
		return
	var collision_specs := [
		["encounter.combat_bounds", "encounter", "COMBAT BOUNDS", "CombatBounds/CollisionShape2D", "Ritualant movement / combat containment"],
		["encounter.thread_hazard", "hazard", "WHITE THREAD HAZARD", "Props/WhiteThreadHazard/CollisionShape2D", "+1 entry; ticks every 0.75 sec; walk +3, run +7, dodge +12"],
		["encounter.thread_warning", "hazard", "THREAD WARNING", "Triggers/ThreadWarningZone/CollisionShape2D", "Ambient warning only"],
		["encounter.intro", "encounter", "INTRO RADIUS", "Triggers/ProximityIntroTrigger/CollisionShape2D", "Proximity introduction trigger"],
		["encounter.fountain_zone", "hazard", "DRY FOUNTAIN ZONE", "Triggers/DryFountainZone/CollisionShape2D", "Pressure tick every %.1f sec" % ritualant_site.fountain_pressure_tick_seconds],
		["interaction.ritualant", "interaction", "RITUALANT INTERACTION", "NPCs/RitualantInteract/CollisionShape2D", "Interaction distance 84 px"],
		["interaction.touch_thread", "interaction", "TOUCH THREAD", "NPCs/TouchThreadInteract/CollisionShape2D", "Thread interaction"],
		["interaction.cut_thread", "interaction", "CUT THREAD", "NPCs/CutThreadInteract/CollisionShape2D", "Thread interaction"],
		["interaction.stilling_pin", "interaction", "STILLING PIN", "Props/StillingPinPickup/CollisionShape2D", "Pickup interaction"],
		["interaction.fountain", "interaction", "DRY FOUNTAIN INTERACTION", "Props/DryFountainInteract/CollisionShape2D", "Inspect dry fountain"],
		["interaction.set_pin", "interaction", "SET STILLING PIN", "Props/SetStillingPinInteract/CollisionShape2D", "Set pin in basin"],
		["interaction.anchor_west", "interaction", "THREAD ANCHOR WEST", "Props/ThreadAnchorWest/CollisionShape2D", "Hostile resolution anchor WEST"],
		["interaction.anchor_north", "interaction", "THREAD ANCHOR NORTH", "Props/ThreadAnchorNorth/CollisionShape2D", "Hostile resolution anchor NORTH"],
		["interaction.anchor_east", "interaction", "THREAD ANCHOR EAST", "Props/ThreadAnchorEast/CollisionShape2D", "Hostile resolution anchor EAST"],
	]
	for spec: Array in collision_specs:
		var collision := ritualant_site.get_node_or_null(spec[3]) as CollisionShape2D
		var record := AuthoringDebugGeometry.collision_shape_record(
			self, collision, spec[0], spec[1], spec[2], spec[4]
		)
		if not record.is_empty():
			out.append(record)
	var ritualant := ritualant_site.get_node_or_null("NPCs/ForlornRitualant") as Node2D
	if ritualant != null:
		out.append(AuthoringDebugGeometry.point_record(
			"encounter.ritualant", "encounter", "RITUALANT",
			to_local(ritualant.global_position),
			"Last hostility: %s" % String(ritualant_site.debug_get_last_hostility_reason()), ritualant
		))


func _append_camera_debug_geometry(out: Array[Dictionary]) -> void:
	if camera_zone_director == null:
		return
	for child: Node in camera_zone_director.get_children():
		if not child is AuthoredCameraZone2D:
			continue
		var zone := child as AuthoredCameraZone2D
		out.append(AuthoringDebugGeometry.rect_record(
			"camera.%s" % String(zone.profile_id).to_lower(), "camera",
			String(zone.profile_id), zone.region,
			"priority %d; zoom %s; offset %s; transition %.2fs" % [zone.priority, zone.framing_zoom, zone.framing_offset, zone.transition_sec], zone
		))


func _append_transition_debug_geometry(out: Array[Dictionary]) -> void:
	for spec in [
		["transition.cosmic_underlay", "COSMIC UNDERLAY 0→1", "CameraPresentation/ChapelCosmicBlend"],
		["transition.temporal_haze", "TEMPORAL HAZE 0→0.65", "CameraPresentation/ChapelTemporalHazeBlend"],
	]:
		var blend := get_node_or_null(spec[2])
		if blend == null:
			continue
		out.append(AuthoringDebugGeometry.band_record(
			spec[0], "transition", spec[1], float(blend.get("south_y")),
			float(blend.get("north_y")), LEVEL_BOUNDS.size.x,
			"Runtime threshold blend", blend
		))


func _append_art_debug_geometry(out: Array[Dictionary]) -> void:
	var art_paths := [
		"UnderlayRoot/DistantChapelProxy", "BackgroundRoot/LandingShelfApron",
		"BackgroundRoot/CavernRimSouth", "BackgroundRoot/CavernRimMiddle",
		"BackgroundRoot/CavernRimNorth", "BackgroundRoot/ChapelConnectorApron",
		"BackgroundRoot/ChapelOuterBlend", "OcclusionRoot/ChapelThreshold",
		"PlayableRoot/ForlornRitualantSite/Floor",
		"PlayableRoot/ForlornRitualantSite/PerimeterRubble",
		"PlayableRoot/ForlornRitualantSite/Props/DryFountainBasin",
		"PlayableRoot/ForlornRitualantSite/Props/WhiteThreadVisual",
		"PlayableRoot/ForlornRitualantSite/Props/EmptyBellFrame/BrokenBell",
	]
	for path: String in art_paths:
		var sprite := get_node_or_null(path) as Sprite2D
		if sprite == null:
			continue
		var record := AuthoringDebugGeometry.sprite_record(
			self, sprite, "art.%s" % sprite.name.to_snake_case(), "art",
			sprite.name, "Gameplay-aligned art; z %d" % sprite.z_index
		)
		if not record.is_empty():
			out.append(record)
	var parallax_paths := [
		"UnderlayRoot/FarVoidParallax/FarVoid",
		"UnderlayRoot/MidDepthSouthParallax/MidDepthSouth",
		"UnderlayRoot/MidDepthMiddleParallax/MidDepthMiddle",
		"UnderlayRoot/MidDepthNorthParallax/MidDepthNorth",
		"UnderlayRoot/MineralHazeParallax/MineralHaze",
		"UnderlayRoot/ChapelHazeParallax/ChapelHaze",
	]
	for path: String in parallax_paths:
		var sprite := get_node_or_null(path) as Sprite2D
		if sprite == null:
			continue
		var parallax := sprite.get_parent() as Parallax2D
		var record := AuthoringDebugGeometry.sprite_record(
			self, sprite, "art.parallax.%s" % sprite.name.to_snake_case(), "art",
			"%s — PARALLAX" % sprite.name,
			"PARALLAX PRESENTATION; NOT GAMEPLAY ALIGNMENT AUTHORITY; scroll_scale %s" % parallax.scroll_scale
		)
		if not record.is_empty():
			record["parallax"] = true
			out.append(record)


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS
