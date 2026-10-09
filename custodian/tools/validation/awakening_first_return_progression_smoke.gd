extends SceneTree

## Functional contract for the Awakening first-return pass.
##
## Drives the live scene: the Crèche console advances progression, the existing
## SidearmLocker grants the P-9, the Dust Lung lift transports both ways, zone
## volumes update state, the authored camera reveals fire exactly once, and the
## Operator can still be placed at the South Reach completion trigger.
##
## Encounter markers must be present and disabled — this pass implements no
## combat.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const SCENE := preload("res://scenes/awakening_first_return.tscn")

var _failures: Array[String] = []
var _camera_calls: Array[Dictionary] = []
var _awakening_completion_events: Array[Dictionary] = []
var _legacy_completion_count := 0


func _init() -> void:
	var awakening := SCENE.instantiate()
	root.add_child(awakening)
	await physics_frame
	await process_frame

	await _check_console(awakening)
	_check_gate_presentation(awakening)
	await _check_locker(awakening)
	await _check_lift(awakening)
	await _check_zone_volumes(awakening)
	_check_camera_reveals(awakening)
	await _check_south_reach(awakening)
	_check_encounters_disabled(awakening)
	await _check_reveal_lifecycle_and_reset(awakening)
	_report()


func _check_gate_presentation(awakening: Node) -> void:
	var art := awakening.get_node_or_null(
		"World/AwakeningZones/Zone07_GateOfDust/SetPieces/GateOfDustProductionArt"
	)
	if art == null:
		_fail("Gate of Dust production composition is missing")
		return
	var expected_sizes := {
		"BodyIdleSealed": Vector2(768, 512),
		"WestPylon": Vector2(256, 512),
		"EastPylon": Vector2(256, 512),
		"SealedAperture": Vector2(512, 512),
		"RestThreshold": Vector2(128, 160),
	}
	for child_name in expected_sizes:
		var sprite := art.get_node_or_null(child_name) as Sprite2D
		if sprite == null or sprite.texture == null:
			_fail("Gate of Dust component missing: %s" % child_name)
		elif sprite.texture.get_size() != expected_sizes[child_name]:
			_fail("Gate of Dust %s size drifted: %s" % [child_name, str(sprite.texture.get_size())])
	var collision := awakening.get_node("World/AwakeningZones/Zone07_GateOfDust/Collision")
	for piece in Layout.set_pieces_for(&"zone07_gate_of_dust"):
		if not String(piece["id"]).begins_with("gate_pylon_"):
			continue
		var shape := collision.get_node_or_null(String(piece["id"]) + "_body") as CollisionShape2D
		if shape == null or not shape.shape is RectangleShape2D:
			_fail("Gate pylon collision missing: %s" % piece["id"])
		elif shape.position != piece["position"] or (shape.shape as RectangleShape2D).size != piece["size"]:
			_fail("Gate pylon collision differs from Layout: %s" % piece["id"])


# --- Crèche console ----------------------------------------------------------

func _check_console(awakening: Node) -> void:
	var alcove := awakening.get_node_or_null(
		"World/AwakeningZones/Zone01_Creche/SetPieces/RecoveryAlcove"
	) as AnimatedSprite2D
	if alcove == null:
		_fail("production recovery alcove is not present")
	elif alcove.animation != &"idle":
		_fail("recovery alcove does not start idle: %s" % String(alcove.animation))
	var console := awakening.get_node_or_null(
		"World/AwakeningZones/Zone01_Creche/Interactables/CrecheConsole"
	)
	if console == null:
		_fail("Crèche console is not present")
		return
	if console.position != Vector2(112, 144):
		_fail("Crèche console drifted from (112, 144): %s" % str(console.position))
	if bool(awakening.get("opening_console_acknowledged")):
		_fail("console reads as acknowledged before any interaction")
	var activation := awakening.get_node_or_null(
		"World/AwakeningZones/Zone01_Creche/SetPieces/CrecheConsoleActivation"
	) as AnimatedSprite2D
	if activation == null:
		_fail("Crèche console activation effect is missing")
	else:
		if activation.visible or activation.is_playing():
			_fail("console activation effect is visible or playing before acknowledgement")
		if activation.position != Vector2(112, 144) or activation.z_index != Layout.Z_WORLD_PROPS:
			_fail("console activation effect drifted from the marker or world-prop layer")
		if activation.sprite_frames == null or activation.sprite_frames.get_frame_count(&"activate") != 8:
			_fail("console activation effect does not have exactly eight frames")
		elif activation.sprite_frames.get_animation_speed(&"activate") != 8.0 or activation.sprite_frames.get_animation_loop(&"activate"):
			_fail("console activation effect speed/loop contract drifted")
	var operator := awakening.get_node("World/Operator")
	operator.set("interaction_target", console)
	awakening.call("_update_interaction_prompt")
	var hud: CustodianHUD = awakening.get("hud") as CustodianHUD
	var prompt: Control = hud.get_node("Root/BottomLeftPrompt/BlackReliquaryPrompt") as Control
	if not prompt.visible:
		_fail("valid Crèche interaction target did not show its prompt")
	for i in 120:
		await process_frame
		operator.set("interaction_target", console)
		awakening.call("_update_interaction_prompt")
	if not prompt.visible:
		_fail("valid Crèche interaction prompt expired during continuous presentation")
	operator.set("global_position", console.global_position)
	await physics_frame
	console.interact(awakening.get_node("World/Operator"))
	if not bool(awakening.get("opening_console_acknowledged")):
		_fail("console interaction did not advance progression")
	if not String(console.readout).contains("RETURN TO SERVICE"):
		_fail("console readout does not carry the locked opening state")
	if alcove != null and alcove.animation != &"wake":
		_fail("console acknowledgement did not start the recovery wake animation")
	if activation != null and (not activation.visible or not activation.is_playing()):
		_fail("first console acknowledgement did not start the activation effect")
	if activation != null:
		var body_label := hud.get_node("Root/BottomLeftPrompt/BlackReliquaryPrompt/Stack/BodyPlaque/BodyRow/Body") as Label
		var acknowledged_readout := body_label.text
		var observed_frames := {}
		observed_frames[activation.frame] = true
		for i in 34:
			await create_timer(0.04).timeout
			if activation.visible:
				observed_frames[activation.frame] = true
		await create_timer(2.4).timeout
		if not prompt.visible or body_label.text != acknowledged_readout:
			_fail("proximity refresh replaced or expired the latched console readout")
		if float(hud.get("_latched_readout_remaining")) <= 0.0:
			_fail("console readout did not retain its four-second minimum dwell")
		for frame_index in 8:
			if not observed_frames.has(frame_index):
				_fail("console activation playback did not render frame %d" % frame_index)
		hud.call("set_context_active", false)
		if prompt.visible:
			_fail("context suppression left the latched console readout visible")
		hud.call("set_context_active", true)
		await create_timer(0.45).timeout
		if not prompt.visible or body_label.text == acknowledged_readout:
			_fail("expired readout did not return to the valid proximity prompt")
		operator.set("interaction_target", null)
		awakening.call("_update_interaction_prompt")
		if prompt.visible:
			_fail("lost interaction target left a stale proximity prompt visible")
		if activation.visible or activation.is_playing():
			_fail("console activation effect did not stop and hide after its full animation (visible=%s playing=%s frame=%d remaining=%.3f)" % [activation.visible, activation.is_playing(), activation.frame, float(awakening.get("_console_activation_remaining"))])
		var finished_frame := activation.frame
		console.interact(operator)
		await process_frame
		if activation.visible or activation.is_playing() or activation.frame != finished_frame:
			_fail("re-reading the console replayed its one-shot activation effect")


# --- P-9 recovery ------------------------------------------------------------

func _check_locker(awakening: Node) -> void:
	var locker := awakening.get_node_or_null(
		"World/AwakeningZones/Zone04_LockerReliquary/SidearmLocker"
	)
	if locker == null:
		_fail("SidearmLocker is not instanced in the Locker Reliquary")
		return
	if locker.position != Vector2(832, -1952):
		_fail("SidearmLocker drifted from (832, -1952): %s" % str(locker.position))
	var operator := awakening.get_node("World/Operator") as Node2D
	var registered_parent := awakening.get_node_or_null(
		"World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05"
	) as CanvasItem
	var registered_locker := awakening.get_node_or_null(
		"World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05/LockerReliquary"
	) as CanvasItem
	operator.global_position = locker.position + Vector2(-64, 0)
	awakening.call("_update_zone_art_visibility")
	_check_registered_locker_presentation(registered_parent, registered_locker, "closed")
	await physics_frame
	# The locker opens on the first interaction and only yields the P-9 once its
	# opening animation has finished.
	locker.interact(operator)
	for i in 300:
		await process_frame
		_check_registered_locker_presentation(registered_parent, registered_locker, "authorize_open")
		if int(locker.get("_state")) == 1: break
	_check_registered_locker_presentation(registered_parent, registered_locker, "open_loaded")
	locker.interact(operator)
	_check_registered_locker_presentation(registered_parent, registered_locker, "empty")
	for i in 60:
		await process_frame
		if bool(awakening.get("p9_recovered")): break
	if not bool(awakening.get("p9_recovered")):
		_fail("recovering the sidearm did not advance progression")


func _check_registered_locker_presentation(parent: CanvasItem, locker: CanvasItem, state: String) -> void:
	if parent == null or locker == null:
		_fail("registered Locker Reliquary art is missing during %s" % state)
		return
	if not parent.visible or not is_equal_approx(parent.modulate.a, 1.0):
		_fail("registered composition parent changed during locker %s" % state)
	if not locker.visible or not is_equal_approx(locker.modulate.a, 1.0):
		_fail("registered Locker Reliquary art was not stable during locker %s (visible=%s alpha=%0.3f)" % [state, locker.visible, locker.modulate.a])


# --- Dust Lung lift ----------------------------------------------------------

func _check_lift(awakening: Node) -> void:
	var lift: Node = awakening.call("get_transit_lift")
	if lift == null:
		_fail("Dust Lung transit lift is missing")
		return
	if Vector2(lift.get("lower_station")) != Vector2(384, -3008):
		_fail("lift lower station drifted: %s" % str(lift.get("lower_station")))
	if Vector2(lift.get("upper_station")) != Vector2(384, -3424):
		_fail("lift upper station drifted: %s" % str(lift.get("upper_station")))
	var operator := awakening.get_node("World/Operator") as Node2D
	var lift_sprite := lift.get_node_or_null("ProductionLift") as Sprite2D
	if lift_sprite == null or lift_sprite.texture == null:
		_fail("Dust Lung production lift sprite is missing")
	elif lift_sprite.texture.get_size() != Vector2(192, 256):
		_fail("Dust Lung lift texture has unexpected size: %s" % str(lift_sprite.texture.get_size()))

	var lower := Vector2(lift.get("lower_station"))
	var upper := Vector2(lift.get("upper_station"))
	operator.global_position = lower
	await physics_frame
	if not bool(lift.call("ride", operator)):
		_fail("lift refused a ride from the lower station")
	await _wait_for_lift(lift)
	if operator.global_position.distance_to(upper) > 1.0:
		_fail("lift did not deliver to the upper station: %s" % str(operator.global_position))
	if lift_sprite != null and lift_sprite.position.distance_to(upper) > 1.0:
		_fail("production lift art did not travel to the upper station: %s" % str(lift_sprite.position))

	if not bool(lift.call("ride", operator)):
		_fail("lift refused the return ride from the upper station")
	await _wait_for_lift(lift)
	if operator.global_position.distance_to(lower) > 1.0:
		_fail("lift did not return to the lower station: %s" % str(operator.global_position))
	if lift_sprite != null and lift_sprite.position.distance_to(lower) > 1.0:
		_fail("production lift art did not return to the lower station: %s" % str(lift_sprite.position))

	# Off-station requests must be refused rather than teleporting the Operator.
	operator.global_position = lower + Vector2(400, 0)
	if bool(lift.call("ride", operator)):
		_fail("lift accepted a ride from off-station")
	if operator.has_method("set_portal_transition_locked") and bool(operator.get("_portal_transition_locked")):
		_fail("lift left the Operator input-locked")


func _wait_for_lift(lift: Node) -> void:
	for i in 240:
		await process_frame
		if not bool(lift.call("is_busy")): return
	_fail("lift never finished its cycle")


# --- Zone volumes ------------------------------------------------------------

func _check_zone_volumes(awakening: Node) -> void:
	var operator := awakening.get_node("World/Operator") as Node2D
	for index in [3, 6, 8]:
		var zone := Layout.zone_by_index(index)
		# Entries sit on the threshold line two sections share, so step just
		# inside the envelope the way walking through it would.
		var envelope: Rect2 = zone["envelope"]
		var entry: Vector2 = zone["entry"]
		operator.global_position = entry + (envelope.get_center() - entry).normalized() * 64.0
		for i in 12:
			await physics_frame
			if int(awakening.get("current_zone_index")) == index: break
		if int(awakening.get("current_zone_index")) != index:
			_fail("entering %s did not update the current zone (got %d)" % [
				String(zone["id"]), int(awakening.get("current_zone_index"))
			])


# --- Camera reveals ----------------------------------------------------------

func _check_camera_reveals(awakening: Node) -> void:
	for zone_id in Layout.CAMERA_REVEALS:
		var reveal: Dictionary = Layout.CAMERA_REVEALS[zone_id]
		var zone := Layout.zone_by_id(zone_id)
		var triggers_path := "World/AwakeningZones/%s/Triggers/CameraReveal" % String(zone["node"])
		if awakening.get_node_or_null(NodePath(triggers_path)) == null:
			_fail("camera reveal trigger missing for %s" % String(zone_id))
		if not awakening.call("play_camera_reveal", zone_id):
			_fail("camera reveal did not run for %s" % String(zone_id))
	var camera := awakening.get_node_or_null("World/Camera2D")
	if camera != null and not bool(camera.call("has_presentation_framing")):
		_fail("camera reveal did not engage presentation framing")
	# Reveals are one-shot: the trigger callback must not re-fire.
	var fired: Array = awakening.get_awakening_state().get("fired_reveals", [])
	awakening.call("_on_reveal_triggered", awakening.get_node("World/Operator"), &"zone07_gate_of_dust")
	awakening.call("_on_reveal_triggered", awakening.get_node("World/Operator"), &"zone07_gate_of_dust")
	var fired_after: Array = awakening.get_awakening_state().get("fired_reveals", [])
	if fired_after.size() != fired.size() + 1:
		_fail("camera reveal is not one-shot (%d -> %d)" % [fired.size(), fired_after.size()])


func _check_reveal_lifecycle_and_reset(awakening: Node) -> void:
	var camera := awakening.get_node("World/Camera2D")
	awakening.call("play_camera_reveal", &"zone05_dust_lung")
	await create_timer(0.1).timeout
	awakening.call("play_camera_reveal", &"zone08_custodian_approach")
	await create_timer(2.1).timeout
	if not bool(camera.call("has_presentation_framing")):
		_fail("earlier reveal timeout cleared the newer reveal")
	var expected_zoom: Vector2 = Layout.CAMERA_REVEALS[&"zone08_custodian_approach"]["zoom"] * awakening.CAMERA_ZOOM_SCALE
	if not (camera.get("_presentation_zoom") as Vector2).is_equal_approx(expected_zoom):
		_fail("Awakening reveal lost its authored pullback relative to local camera framing")
	await create_timer(1.2).timeout
	if bool(camera.call("has_presentation_framing")):
		_fail("newer reveal did not release its framing")
	awakening.call("play_camera_reveal", &"zone05_dust_lung")
	var lift: Node = awakening.call("get_transit_lift")
	var operator := awakening.get_node("World/Operator") as Node2D
	operator.global_position = lift.lower_station
	if not bool(lift.call("ride", operator)):
		_fail("lift did not begin a ride for reset regression")
	awakening.call("reset_progression")
	if not bool(awakening.get("p9_recovered")):
		_fail("debug reset falsely rewound the persistent P-9 grant")
	var console := awakening.get_node("World/AwakeningZones/Zone01_Creche/Interactables/CrecheConsole")
	var activation := awakening.get_node("World/AwakeningZones/Zone01_Creche/SetPieces/CrecheConsoleActivation") as AnimatedSprite2D
	if bool(console.get("is_acknowledged")) or bool(awakening.get("opening_console_acknowledged")):
		_fail("debug reset did not rearm the Crèche console acknowledgement")
	if activation != null and (activation.visible or activation.is_playing() or activation.frame != 0):
		_fail("debug reset did not restore the console activation effect to hidden frame zero")
	if bool(camera.call("has_presentation_framing")) or bool(awakening.get("_reveal_release_pending")):
		_fail("debug reset left camera reveal state active")
	if lift != null and (bool(lift.call("is_busy")) or lift.current_station != 0):
		_fail("debug reset left transit lift state active")
	if operator.global_position != Layout.OPERATOR_WAKE_POSITION:
		_fail("debug reset did not return Operator to wake")
	await create_timer(2.2).timeout
	if bool(camera.call("has_presentation_framing")):
		_fail("cancelled reveal timer restored framing after reset")
	if operator.global_position != Layout.OPERATOR_WAKE_POSITION or bool(lift.call("is_busy")):
		_fail("cancelled lift cycle changed state after reset")


# --- Completion --------------------------------------------------------------

func _check_south_reach(awakening: Node) -> void:
	var operator := awakening.get_node("World/Operator") as Node2D
	if not awakening.has_signal("awakening_completed"):
		_fail("production Awakening completion signal is missing")
	else:
		awakening.awakening_completed.connect(_on_awakening_completed)
	if not awakening.has_signal("blockout_completed"):
		_fail("legacy completion compatibility signal is missing")
	else:
		awakening.blockout_completed.connect(_on_legacy_completion)
	operator.global_position = Layout.SOUTH_REACH_COMPLETION_CENTER
	var prerequisites := [
		{"console": false, "p9": false, "expected": false, "objective": "Wake and read the crèche console"},
		{"console": true, "p9": false, "expected": false, "objective": "Recover the assigned P-9"},
		{"console": false, "p9": true, "expected": false, "objective": "Wake and read the crèche console"},
		{"console": true, "p9": true, "expected": true, "objective": "RETURN TO POST"},
	]
	for entry in prerequisites:
		awakening.set("completed", false)
		awakening.set("opening_console_acknowledged", entry["console"])
		awakening.set("p9_recovered", entry["p9"])
		awakening.call("_on_south_reach_reached", operator)
		if bool(awakening.get("completed")) != bool(entry["expected"]):
			_fail("South Reach completion gate mismatch for console=%s P-9=%s" % [entry["console"], entry["p9"]])
		if not bool(entry["expected"]) and str(awakening.get("current_objective_text")) != str(entry["objective"]):
			_fail("missing prerequisite feedback is not useful: %s" % str(awakening.get("current_objective_text")))
	if not bool(awakening.get("completed")):
		_fail("both authored prerequisites did not permit South Reach completion")
	if _awakening_completion_events.size() != 1 or _legacy_completion_count != 1:
		_fail("completion signals did not emit exactly once: production=%d legacy=%d" % [
			_awakening_completion_events.size(), _legacy_completion_count,
		])
	else:
		var snapshot: Dictionary = _awakening_completion_events[0]
		var expected_snapshot := {
			"completed": true,
			"opening_console_acknowledged": true,
			"p9_recovered": true,
			"final_zone_id": &"zone10_road_south_reach",
			"operator_global_position": Layout.SOUTH_REACH_COMPLETION_CENTER,
		}
		if snapshot != expected_snapshot:
			_fail("completion snapshot does not match the data-only handoff contract: %s" % str(snapshot))
		for value in snapshot.values():
			if value is Object:
				_fail("completion snapshot contains an Object/Node reference")
	awakening.call("_on_south_reach_reached", operator)
	if _awakening_completion_events.size() != 1 or _legacy_completion_count != 1:
		_fail("repeated South Reach arrival re-emitted completion")
	var barrier := awakening.get_node_or_null(
		"World/AwakeningZones/Zone10_RoadSouthReach/SetPieces/SouthReachCollapse"
	)
	if barrier == null:
		_fail("temporary South Reach ruin is not a visible set piece")


func _on_awakening_completed(snapshot: Dictionary) -> void:
	_awakening_completion_events.append(snapshot.duplicate(true))


func _on_legacy_completion() -> void:
	_legacy_completion_count += 1


# --- Encounters stay disabled ------------------------------------------------

func _check_encounters_disabled(awakening: Node) -> void:
	var expected := {
		"zone03_attestation": ["sentinel_spawn_a", "sentinel_spawn_b"],
		"zone05_dust_lung": ["scavenger_nest"],
		"zone08_custodian_approach": ["approach_sentinel"],
		"zone09_chapel_late_service": ["route_leech"],
	}
	for zone_key in expected:
		var zone := Layout.zone_by_id(StringName(zone_key))
		for marker_id in expected[zone_key]:
			var path := "World/AwakeningZones/%s/Markers/%s" % [String(zone["node"]), marker_id]
			var marker := awakening.get_node_or_null(NodePath(path))
			if marker == null:
				_fail("encounter marker missing: %s" % path)
			elif String(marker.get_meta("kind", "")) != "encounter":
				_fail("marker %s is not registered as a disabled encounter slot" % marker_id)
	if awakening.get_node("World/Enemies").get_child_count() != 0:
		_fail("this pass must implement no combat, but Enemies is populated")


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("awakening_first_return_progression_smoke: " + message)


func _report() -> void:
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "awakening_first_return_progression_smoke",
		"passed": passed,
		"failure_count": _failures.size(),
		"failures": _failures,
	}))
	if passed:
		print("awakening_first_return_progression_smoke: PASS")
		quit(0)
		return
	print("awakening_first_return_progression_smoke: FAIL (%d)" % _failures.size())
	for message in _failures: print("  - %s" % message)
	quit(1)
