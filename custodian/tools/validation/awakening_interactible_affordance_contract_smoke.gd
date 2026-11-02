extends SceneTree

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const SCENE := preload("res://scenes/awakening_first_return.tscn")

const EXPECTED_MARKER_KINDS := {
	"zone01_creche.operator_wake": &"spawn",
	"zone01_creche.creche_console": &"interactable",
	"zone02_ambulatory.hidden_reliquary": &"marker",
	"zone02_ambulatory.lore_plaque": &"marker",
	"zone03_attestation.central_aisle_trigger": &"trigger",
	"zone03_attestation.sentinel_spawn_a": &"encounter",
	"zone03_attestation.sentinel_spawn_b": &"encounter",
	"zone03_attestation.attestation_dais": &"marker",
	"zone03_attestation.sigil_fragment": &"marker",
	"zone04_locker_reliquary.p9_locker": &"interactable",
	"zone05_dust_lung.lift_lower": &"lift",
	"zone05_dust_lung.lift_upper": &"lift",
	"zone05_dust_lung.lift_mechanism": &"marker",
	"zone05_dust_lung.scavenger_nest": &"encounter",
	"zone05_dust_lung.central_shaft": &"marker",
	"zone06_undergate.port_status_plaque": &"interactable",
	"zone06_undergate.register_of_departures": &"marker",
	"zone07_gate_of_dust.gate_aperture": &"marker",
	"zone07_gate_of_dust.south_wasteland_vista": &"marker",
	"zone07_gate_of_dust.rest_checkpoint": &"marker",
	"zone08_custodian_approach.return_to_post_beacon": &"trigger",
	"zone08_custodian_approach.approach_sentinel": &"encounter",
	"zone08_custodian_approach.road_reveal_trigger": &"trigger",
	"zone08_custodian_approach.road_anchor": &"marker",
	"zone09_chapel_late_service.reward_cache": &"marker",
	"zone09_chapel_late_service.route_leech": &"encounter",
	"zone10_road_south_reach.south_reach_completion": &"trigger",
}

const EXPECTED_MOUNTS := {
	"creche_console": {
		"zone_id": &"zone01_creche",
		"marker_id": &"creche_console",
		"owner_path": "World/AwakeningZones/Zone01_Creche/Interactables/CrecheConsole",
	},
	"p9_locker": {
		"zone_id": &"zone04_locker_reliquary",
		"marker_id": &"p9_locker",
		"owner_path": "World/AwakeningZones/Zone04_LockerReliquary/SidearmLocker",
	},
	"lift_lower": {
		"zone_id": &"zone05_dust_lung",
		"marker_id": &"lift_lower",
		"owner_path": "World/AwakeningZones/Zone05_DustLung/Interactables/TransitLift",
	},
	"lift_upper": {
		"zone_id": &"zone05_dust_lung",
		"marker_id": &"lift_upper",
		"owner_path": "World/AwakeningZones/Zone05_DustLung/Interactables/TransitLift",
	},
	"port_status_plaque": {
		"zone_id": &"zone06_undergate",
		"marker_id": &"port_status_plaque",
		"owner_path": "World/AwakeningZones/Zone06_Undergate/Interactables/PortStatusPlaque",
	},
}

var _failures: Array[String] = []


func _init() -> void:
	_check_marker_audit()
	var awakening := SCENE.instantiate()
	root.add_child(awakening)
	await physics_frame
	await process_frame
	var presenter := awakening.get_node_or_null("AffordancePresentation")
	if presenter == null:
		_fail("scene is missing the visual-only affordance presenter")
		_report()
		return
	_check_live_mounts(awakening, presenter)
	_check_phantom_and_missing_art(awakening, presenter)
	_check_focus_and_status(awakening, presenter)
	await _check_lift_status_transitions(awakening, presenter)
	awakening.call("_mount_interactible_affordances")
	if presenter.call("diagnostic_snapshot").size() != 5:
		_fail("repeated presenter bind duplicated visual mounts")
	_check_no_scan_or_interaction_owner(presenter)
	_report()


func _check_marker_audit() -> void:
	var observed := {}
	for zone_id in Layout.MARKERS:
		for marker in Layout.markers_for(zone_id):
			var marker_id := StringName(marker.get("id", &""))
			var key := "%s.%s" % [String(zone_id), String(marker_id)]
			if observed.has(key):
				_fail("duplicate Layout marker identity: %s" % key)
			observed[key] = StringName(marker.get("kind", &""))
	for key in EXPECTED_MARKER_KINDS:
		if not observed.has(key):
			_fail("audited Layout marker disappeared: %s" % key)
		elif observed[key] != EXPECTED_MARKER_KINDS[key]:
			_fail("Layout marker kind drifted at %s (expected %s, got %s)" % [key, EXPECTED_MARKER_KINDS[key], observed[key]])
	for key in observed:
		if not EXPECTED_MARKER_KINDS.has(key):
			_fail("unreviewed Layout marker was added: %s" % key)
	if observed.size() != EXPECTED_MARKER_KINDS.size():
		_fail("marker audit did not cover all authored Layout markers")


func _check_live_mounts(awakening: Node, presenter: Node) -> void:
	var snapshot: Array = presenter.call("diagnostic_snapshot")
	if snapshot.size() != 5:
		_fail("expected five affordance anchors for four gameplay owners, found %d" % snapshot.size())
	var owner_ids := {}
	var mount_ids := {}
	for row in snapshot:
		var mount_id := StringName(row.get("mount_id", &""))
		mount_ids[mount_id] = true
		var expected: Dictionary = EXPECTED_MOUNTS.get(String(mount_id), {})
		if expected.is_empty():
			_fail("unexpected affordance mount: %s" % String(mount_id))
			continue
		var mount := presenter.call("get_mount_for_marker", expected["zone_id"], expected["marker_id"]) as Node2D
		var owner := presenter.call("get_owner_for_mount", mount_id) as Node
		var actual_owner := awakening.get_node_or_null(NodePath(expected["owner_path"])) as Node
		if mount == null or owner == null or owner != actual_owner:
			_fail("mount %s is not bound to its declared live owner" % String(mount_id))
		elif not owner.is_in_group("interactable"):
			_fail("mount %s owner is not an existing interactable" % String(mount_id))
		else:
			owner_ids[owner.get_instance_id()] = true
		var marker_position := _marker_position(expected["zone_id"], expected["marker_id"])
		if mount != null and mount.position != marker_position:
			_fail("mount %s moved from its Layout marker" % String(mount_id))
		if row.get("status") != &"available" or bool(row.get("focused", true)):
			_fail("mount %s has an invalid initial status/focus" % String(mount_id))
		if int(row.get("collision_node_count", -1)) != 0:
			_fail("visual mount %s introduced collision" % String(mount_id))
		if int(row.get("visual_part_count", -1)) != 0:
			_fail("source-pending optional art unexpectedly created visual parts")
		if mount != null and (mount.is_in_group("interactable") or mount is CollisionObject2D):
			_fail("affordance mount %s became a gameplay interaction/collision owner" % String(mount_id))
	if owner_ids.size() != 4:
		_fail("five visual anchors do not resolve to exactly four existing gameplay owners")
	if mount_ids.size() != EXPECTED_MOUNTS.size():
		_fail("visual mount identifiers are duplicated")
	var lift_lower: Node = presenter.call("get_owner_for_mount", &"lift_lower") as Node
	var lift_upper: Node = presenter.call("get_owner_for_mount", &"lift_upper") as Node
	if lift_lower == null or lift_lower != lift_upper:
		_fail("the two lift stations do not share the single existing TransitLift owner")


func _check_phantom_and_missing_art(awakening: Node, presenter: Node) -> void:
	var phantom: Node2D = presenter.call("get_mount_for_marker", &"zone05_dust_lung", &"lift_mechanism") as Node2D
	if phantom != null:
		_fail("inert lift_mechanism marker received an actionable affordance mount")
	var mechanism_marker := _find_marker(&"zone05_dust_lung", &"lift_mechanism")
	if mechanism_marker.get("position", Vector2.ZERO) != Vector2(448, -2944):
		_fail("lift_mechanism decorative marker moved from its authored placement")
	var fake_texture_ok := bool(presenter.call("attach_visual_part", &"creche_console", &"near", &"pending_probe", &"awakening_interact_support", &"beacon_cyan", null))
	if fake_texture_ok:
		_fail("missing optional V2 art was accepted as a visual part")
	var snapshot: Array = presenter.call("diagnostic_snapshot")
	for row in snapshot:
		if int(row.get("visual_part_count", -1)) != 0:
			_fail("missing optional art created an unexpected scene part")
	# The mounts and presenter are presentation-only and cannot enter the
	# Operator's existing group-based target-selection surface.
	if presenter.is_in_group("interactable"):
		_fail("affordance presenter entered the interactable group")
	for mount_id in EXPECTED_MOUNTS:
		var binding: Dictionary = EXPECTED_MOUNTS[mount_id]
		var mount := presenter.call("get_mount_for_marker", binding["zone_id"], binding["marker_id"]) as Node2D
		if mount != null and mount.is_in_group("interactable"):
			_fail("affordance mount entered the interactable group")
	var before_count := awakening.get_tree().get_nodes_in_group("interactable").size()
	awakening.call("_mount_interactible_affordances")
	var after_count := awakening.get_tree().get_nodes_in_group("interactable").size()
	if after_count != before_count:
		_fail("idempotent visual binding changed the gameplay interactable group")


func _check_focus_and_status(awakening: Node, presenter: Node) -> void:
	var operator := awakening.get_node("World/Operator") as Node
	var console := presenter.call("get_owner_for_mount", &"creche_console") as Node
	operator.set("interaction_target", console)
	presenter.call("set_focus_target", console)
	var mount := presenter.call("get_mount_for_marker", &"zone01_creche", &"creche_console") as Node2D
	if mount == null or not bool(mount.get_meta("focused", false)) or not bool(mount.get_meta("near_indicator_active", false)):
		_fail("existing selected target did not drive the near focus/status state")
	if mount != null and mount.get_meta("presentation_status") != &"available":
		_fail("initially available console received the wrong status")
	console.call("interact", operator)
	if mount != null and mount.get_meta("presentation_status") != &"used":
		_fail("console acknowledgement did not update the presentation status")
	awakening.call("reset_progression")
	if mount != null and mount.get_meta("presentation_status") != &"available":
		_fail("existing progression reset did not restore the console presentation status")
	operator.set("interaction_target", null)
	presenter.call("set_focus_target", null)
	if mount != null and (bool(mount.get_meta("focused", true)) or bool(mount.get_meta("near_indicator_active", true))):
		_fail("clearing the gameplay target left a stale near focus/status state")
	var port := presenter.call("get_owner_for_mount", &"port_status_plaque") as Node
	port.call("interact", operator)
	var port_mount := presenter.call("get_mount_for_marker", &"zone06_undergate", &"port_status_plaque") as Node2D
	if port_mount != null and port_mount.get_meta("presentation_status") != &"used":
		_fail("damaged Port readout acknowledgement did not update presentation status")


func _check_lift_status_transitions(awakening: Node, presenter: Node) -> void:
	var lift := presenter.call("get_owner_for_mount", &"lift_lower") as Node
	var operator := awakening.get_node("World/Operator") as Node2D
	var lower_mount := presenter.call("get_mount_for_marker", &"zone05_dust_lung", &"lift_lower") as Node2D
	var upper_mount := presenter.call("get_mount_for_marker", &"zone05_dust_lung", &"lift_upper") as Node2D
	operator.global_position = lift.get("lower_station")
	operator.set("interaction_target", lift)
	presenter.call("set_focus_target", lift)
	if lower_mount == null or not bool(lower_mount.get_meta("focused", false)) or upper_mount == null or bool(upper_mount.get_meta("focused", true)):
		_fail("shared lift owner focus did not resolve to the active Layout station")
	if not bool(lift.call("ride", operator)):
		_fail("live TransitLift refused its authored lower station")
	if lower_mount.get_meta("presentation_status") != &"disabled" or upper_mount.get_meta("presentation_status") != &"disabled":
		_fail("transit_started did not mark both shared lift mounts disabled")
	for _tick in 30:
		await create_timer(0.04).timeout
	if lower_mount.get_meta("presentation_status") != &"available" or upper_mount.get_meta("presentation_status") != &"available":
		_fail("transit_finished did not restore both shared lift mounts")
	operator.set("interaction_target", null)
	presenter.call("set_focus_target", null)


func _check_no_scan_or_interaction_owner(presenter: Node) -> void:
	var script_text := FileAccess.get_file_as_string("res://game/world/awakening/awakening_interactible_affordance_presenter.gd")
	if script_text.contains("func _process(") or script_text.contains("get_nodes_in_group"):
		_fail("presenter polls/scans the scene instead of consuming bounded owner focus updates")
	if script_text.contains("add_to_group(\"interactable\")"):
		_fail("presenter source adds another gameplay interaction owner")
	if presenter.is_in_group("interactable"):
		_fail("scene presenter entered the existing gameplay target-selection group")


func _marker_position(zone_id: StringName, marker_id: StringName) -> Vector2:
	return _find_marker(zone_id, marker_id).get("position", Vector2.ZERO)


func _find_marker(zone_id: StringName, marker_id: StringName) -> Dictionary:
	for marker in Layout.markers_for(zone_id):
		if StringName(marker.get("id", &"")) == marker_id:
			return marker
	return {}


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("AWAKENING_INTERACTIBLE_AFFORDANCE_CONTRACT_SMOKE: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
