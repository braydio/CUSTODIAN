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


func _init() -> void:
	var awakening := SCENE.instantiate()
	root.add_child(awakening)
	await physics_frame
	await process_frame

	_check_console(awakening)
	await _check_locker(awakening)
	await _check_lift(awakening)
	await _check_zone_volumes(awakening)
	_check_camera_reveals(awakening)
	await _check_south_reach(awakening)
	_check_encounters_disabled(awakening)
	_report()


# --- Crèche console ----------------------------------------------------------

func _check_console(awakening: Node) -> void:
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
	console.interact(awakening.get_node("World/Operator"))
	if not bool(awakening.get("opening_console_acknowledged")):
		_fail("console interaction did not advance progression")
	if not String(console.readout).contains("RETURN TO SERVICE"):
		_fail("console readout does not carry the locked opening state")


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
	operator.global_position = locker.position + Vector2(-64, 0)
	await physics_frame
	# The locker opens on the first interaction and only yields the P-9 once its
	# opening animation has finished.
	locker.interact(operator)
	for i in 300:
		await process_frame
		if int(locker.get("_state")) == 1: break
	locker.interact(operator)
	for i in 60:
		await process_frame
		if bool(awakening.get("p9_recovered")): break
	if not bool(awakening.get("p9_recovered")):
		_fail("recovering the sidearm did not advance progression")


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

	var lower := Vector2(lift.get("lower_station"))
	var upper := Vector2(lift.get("upper_station"))
	operator.global_position = lower
	await physics_frame
	if not bool(lift.call("ride", operator)):
		_fail("lift refused a ride from the lower station")
	await _wait_for_lift(lift)
	if operator.global_position.distance_to(upper) > 1.0:
		_fail("lift did not deliver to the upper station: %s" % str(operator.global_position))

	if not bool(lift.call("ride", operator)):
		_fail("lift refused the return ride from the upper station")
	await _wait_for_lift(lift)
	if operator.global_position.distance_to(lower) > 1.0:
		_fail("lift did not return to the lower station: %s" % str(operator.global_position))

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


# --- Completion --------------------------------------------------------------

func _check_south_reach(awakening: Node) -> void:
	var operator := awakening.get_node("World/Operator") as Node2D
	operator.global_position = Layout.SOUTH_REACH_COMPLETION_CENTER
	await physics_frame
	await physics_frame
	if not bool(awakening.get("completed")):
		_fail("reaching %s did not complete the first pass" % str(Layout.SOUTH_REACH_COMPLETION_CENTER))
	var barrier := awakening.get_node_or_null(
		"World/AwakeningZones/Zone10_RoadSouthReach/SetPieces/SouthReachCollapse"
	)
	if barrier == null:
		_fail("temporary South Reach ruin is not a visible set piece")


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
