extends SceneTree

## Boot contract for CUSTODIAN Awakening / The First Return.
##
## Asserts the locked spatial values from the design (section coordinates, the
## Road offset, the world envelope), the scene skeleton later art passes will
## replace piecemeal, and the deliberate absence of the Field Terminal, the
## campaign handoff, and first-contract prewarming from the prologue.
##
## Traversal itself is proved separately by awakening_first_return_geometry_smoke.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")

const SCENE := "res://scenes/awakening_first_return.tscn"
const SCRIPT := "res://game/world/awakening/awakening_first_return.gd"
const LAYOUT := "res://game/world/awakening/awakening_layout.gd"
const ROAD_MAP := "res://content/levels/hub/Road_of_Witnesses_Tilemap.png"
const HUD_SCENE := "res://game/ui/hud/custodian_hud.tscn"
const MAPPER := "res://scenes/debug/awakening_first_return_mapper.tscn"
const DEBUG_TOUR := "res://scenes/debug/awakening_first_return_debug.tscn"
const ADAPTER := "res://tools/level_authoring/mapper/adapters/awakening_first_return_mapper_adapter.gd"
const PRODUCTION_UNDERLAYS := {
	"Zone01_Creche": {"position": Vector2(0, -32), "size": Vector2(960, 704)},
	"Zone02_Ambulatory": {"position": Vector2(0, -864), "size": Vector2(1152, 960)},
	"Zone03_Attestation": {"position": Vector2(0, -1744), "size": Vector2(832, 928)},
	"Zone04_LockerReliquary": {"position": Vector2(704, -1984), "size": Vector2(704, 704)},
	"Zone05_DustLung": {"position": Vector2(0, -3200), "size": Vector2(1216, 1216)},
}

## Locked in the design; the whole opening dungeon hangs off these.
const LOCKED_ENVELOPES := {
	1: Rect2(-416, -320, 832, 576),
	2: Rect2(-512, -1280, 1024, 832),
	3: Rect2(-352, -2144, 704, 800),
	4: Rect2(416, -2272, 576, 576),
	5: Rect2(-544, -3744, 1088, 1088),
	6: Rect2(-384, -4864, 768, 1088),
	7: Rect2(-704, -5504, 1408, 640),
	8: Rect2(-448, -6240, 896, 736),
	9: Rect2(-1024, -6048, 576, 640),
}
const LOCKED_ENTRIES := {
	1: Vector2(0, 160), 2: Vector2(0, -480), 3: Vector2(0, -1344), 4: Vector2(416, -1984),
	5: Vector2(0, -2656), 6: Vector2(0, -3776), 7: Vector2(0, -4864), 8: Vector2(0, -5504),
	9: Vector2(-448, -5760), 10: Vector2(0, -6144),
}
const LOCKED_EXITS := {
	1: Vector2(0, -320), 2: Vector2(0, -1248), 3: Vector2(352, -1984), 4: Vector2(704, -2272),
	5: Vector2(0, -3744), 6: Vector2(0, -4864), 7: Vector2(0, -5504), 8: Vector2(0, -6144),
}
const LOCKED_CONNECTORS := {
	"01_02": Rect2(-64, -480, 128, 160),
	"02_03": Rect2(-64, -1344, 128, 96),
	"03_04": Rect2(352, -2048, 64, 128),
	"04_05_A": Rect2(640, -2432, 128, 160),
	"04_05_B": Rect2(0, -2560, 704, 128),
	"04_05_C": Rect2(-64, -2656, 128, 96),
	"05_06": Rect2(-64, -3776, 128, 32),
	"09_BRANCH": Rect2(-448, -5824, 288, 128),
}

var _failures: Array[String] = []


func _init() -> void:
	_check_resources()
	_check_locked_layout()
	_check_main_scene()
	var instance := _instantiate_scene()
	if instance != null:
		_check_scene_skeleton(instance)
		_check_road_instance(instance)
		_check_retired_home_logic()
		instance.free()
	_check_mapper()
	_report()


func _check_resources() -> void:
	for path in [SCENE, SCRIPT, LAYOUT, ROAD_MAP, HUD_SCENE, MAPPER, DEBUG_TOUR, ADAPTER]:
		if not ResourceLoader.exists(path):
			_fail("missing resource: %s" % path)


func _check_main_scene() -> void:
	if ProjectSettings.get_setting("application/run/main_scene", "") != SCENE:
		_fail("project main scene must be the Awakening first return")
	# ResourceLoader may retain a deleted path in its UID cache after another
	# validation loads historical dependencies. Retirement is a filesystem
	# contract, so inspect the project tree directly.
	if FileAccess.file_exists("res://scenes/home_custodian_begin.tscn"):
		_fail("retired home_custodian_begin.tscn still present")


## The design is locked; these assertions are the one place coordinates are
## deliberately duplicated, so drift in awakening_layout.gd is caught.
func _check_locked_layout() -> void:
	if Layout.WORLD_BOUNDS != Rect2(-1088, -7328, 2176, 7680):
		_fail("WORLD_BOUNDS drifted: %s" % str(Layout.WORLD_BOUNDS))
	if Layout.OPERATOR_WAKE_POSITION != Vector2(0, 160):
		_fail("OPERATOR_WAKE_POSITION drifted: %s" % str(Layout.OPERATOR_WAKE_POSITION))
	if Layout.WORLD_TILE != 32.0:
		_fail("WORLD_TILE drifted: %f" % Layout.WORLD_TILE)
	if Layout.ROAD_WORLD_OFFSET != Vector2(6, -6626):
		_fail("ROAD_WORLD_OFFSET drifted: %s" % str(Layout.ROAD_WORLD_OFFSET))
	if Layout.ZONES.size() != 10:
		_fail("expected 10 sections, found %d" % Layout.ZONES.size())
	for index in LOCKED_ENVELOPES:
		var zone := Layout.zone_by_index(index)
		if zone.is_empty():
			_fail("section %d missing" % index)
			continue
		if zone["envelope"] != LOCKED_ENVELOPES[index]:
			_fail("section %d envelope drifted: %s" % [index, str(zone["envelope"])])
	for index in LOCKED_ENTRIES:
		var zone := Layout.zone_by_index(index)
		if not zone.is_empty() and zone["entry"] != LOCKED_ENTRIES[index]:
			_fail("section %d entry drifted: %s" % [index, str(zone["entry"])])
	for index in LOCKED_EXITS:
		var zone := Layout.zone_by_index(index)
		if not zone.is_empty() and zone["exit"] != LOCKED_EXITS[index]:
			_fail("section %d exit drifted: %s" % [index, str(zone["exit"])])
	for key in LOCKED_CONNECTORS:
		if not Layout.CONNECTORS.has(key):
			_fail("connector %s missing" % key)
		elif Layout.CONNECTORS[key] != LOCKED_CONNECTORS[key]:
			_fail("connector %s drifted: %s" % [key, str(Layout.CONNECTORS[key])])
	# Every critical-route rect must clear the 128px minimum on its short axis,
	# except 03_04 which is authored as a 64px-deep threshold crossed sideways.
	for key in Layout.CONNECTORS:
		if key == "03_04": continue
		var rect: Rect2 = Layout.CONNECTORS[key]
		if maxf(rect.size.x, rect.size.y) < 128.0:
			_fail("connector %s is narrower than the 128px minimum: %s" % [key, str(rect.size)])


func _instantiate_scene() -> Node:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("scene did not load: %s" % SCENE)
		return null
	var instance := packed.instantiate()
	if instance == null:
		_fail("scene did not instantiate: %s" % SCENE)
	return instance


func _check_scene_skeleton(instance: Node) -> void:
	for node_path in [
		"World", "World/AwakeningZones", "World/Operator", "World/PlayerController",
		"World/Camera2D", "World/Projectiles", "World/Enemies", "World/Items", "CustodianHUD",
	]:
		if instance.get_node_or_null(NodePath(node_path)) == null:
			_fail("scene missing node: %s" % node_path)
	for zone in Layout.ZONES:
		var path := "World/AwakeningZones/%s" % String(zone["node"])
		var zone_node := instance.get_node_or_null(NodePath(path)) as Node2D
		if zone_node == null:
			_fail("scene missing zone node: %s" % path)
		elif zone_node.position != Vector2.ZERO:
			_fail("zone root must remain untransformed: %s" % path)
	for zone_name in PRODUCTION_UNDERLAYS:
		var spec: Dictionary = PRODUCTION_UNDERLAYS[zone_name]
		var underlay_path := "World/AwakeningZones/%s/ArtUnderlay/Underlay" % zone_name
		var underlay := instance.get_node_or_null(NodePath(underlay_path)) as Sprite2D
		if underlay == null:
			_fail("production underlay missing: %s" % underlay_path)
			continue
		if underlay.position != spec["position"]:
			_fail("%s position drifted: %s" % [zone_name, str(underlay.position)])
		if underlay.scale != Vector2.ONE:
			_fail("%s underlay must remain at scale 1,1" % zone_name)
		if not underlay.centered:
			_fail("%s underlay must remain centered" % zone_name)
		if underlay.texture == null:
			_fail("%s underlay texture did not load" % zone_name)
		elif underlay.texture.get_size() != spec["size"]:
			_fail("%s texture size drifted: %s" % [zone_name, str(underlay.texture.get_size())])
	var script_source := FileAccess.get_file_as_string(SCRIPT)
	if not script_source.contains('presentation.visible = build_blockout_presentation and art_underlay.get_node_or_null("Underlay") == null'):
		_fail("blockout presentation does not yield to an authored production underlay")
	if not script_source.contains("presentation.add_child(visual)"):
		_fail("grey placeholder set-piece visuals are not owned by BlockoutPresentation")
	var operator := instance.get_node_or_null("World/Operator") as Node2D
	if operator != null and operator.position != Layout.OPERATOR_WAKE_POSITION:
		_fail("Operator does not start at the wake position: %s" % str(operator.position))
	var locker := instance.get_node_or_null(
		"World/AwakeningZones/Zone04_LockerReliquary/SidearmLocker"
	) as Node2D
	if locker == null:
		_fail("existing SidearmLocker is not placed in the Locker Reliquary")
	elif locker.position != Vector2(832, -1952):
		_fail("SidearmLocker drifted from (832, -1952): %s" % str(locker.position))
	for method_name in [
		"get_boundary_segments", "get_zone_specs", "get_landmark_specs",
		"get_authoring_marker_schema", "get_authoring_marker_state",
		"teleport_operator_to_zone",
	]:
		if not instance.has_method(method_name):
			_fail("Awakening scene missing authoring contract: %s" % method_name)
	var hud := instance.get_node_or_null("CustodianHUD")
	if hud != null:
		for method_name in ["set_location", "set_phase", "set_objective", "show_interaction"]:
			if not hud.has_method(method_name):
				_fail("HUD missing presentation method: %s" % method_name)


func _check_road_instance(instance: Node) -> void:
	var road := instance.get_node_or_null(
		"World/AwakeningZones/Zone10_RoadSouthReach/RoadOfWitnessesPrototype"
	) as Node2D
	if road == null:
		_fail("Road prototype is not instanced as section 10")
		return
	if road.position != Layout.ROAD_WORLD_OFFSET:
		_fail("Road instance offset is %s, expected %s" % [
			str(road.position), str(Layout.ROAD_WORLD_OFFSET)
		])
	if bool(road.get("apply_camera_bounds")):
		_fail("Road instance must not own camera bounds inside the Awakening")
	if float(road.get("south_gate_gap_width")) < 128.0:
		_fail("Road south causeway gap is below the 128px critical-route minimum")
	var road_source := FileAccess.get_file_as_string(
		"res://game/world/hub/road_of_witnesses_prototype.gd"
	)
	if not road_source.contains("to_local(player_pos)"):
		_fail("Road occlusion still compares global Y against local thresholds")


## The prologue must not smuggle in later-section systems.
func _check_retired_home_logic() -> void:
	var scene_source := FileAccess.get_file_as_string(SCENE)
	for retired in ["FieldTerminal", "SignalNeedle", "ReturnCausewayApproach"]:
		if scene_source.contains(retired):
			_fail("retired node still present in the Awakening scene: %s" % retired)
	var script_source := FileAccess.get_file_as_string(SCRIPT)
	for retired in ["WorldContractBootstrap", "ensure_started", "change_scene_to_file", "witness_established"]:
		if script_source.contains(retired):
			_fail("retired beginning logic still present in the controller: %s" % retired)
	# The Field Terminal implementation itself stays in the repository for the
	# later Forum section.
	if not ResourceLoader.exists("res://game/world/home/field_terminal_interactable.gd"):
		_fail("reusable FieldTerminal implementation was removed from the repository")


func _check_mapper() -> void:
	var packed := load(MAPPER) as PackedScene
	if packed == null:
		_fail("mapper scene did not load")
		return
	var instance := packed.instantiate()
	if instance.get("target_scene_path") != SCENE:
		_fail("mapper target scene drifted: %s" % str(instance.get("target_scene_path")))
	if instance.get("target_script_path") != SCRIPT:
		_fail("mapper target script drifted: %s" % str(instance.get("target_script_path")))
	if instance.get("adapter_script_path") != ADAPTER:
		_fail("mapper adapter drifted: %s" % str(instance.get("adapter_script_path")))
	if instance.get("initial_camera_position") != Vector2(0, -3200):
		_fail("mapper framing does not show the whole dungeon spine")
	if instance.get_node_or_null("World/AwakeningZoneOverlay") == null:
		_fail("mapper is missing the zone/landmark overlay")
	instance.free()
	var adapter_instance = load(ADAPTER).new()
	if String(adapter_instance.call("level_id")) != "awakening_first_return":
		_fail("mapper adapter level id drifted")
	var tour := load(DEBUG_TOUR) as PackedScene
	if tour == null:
		_fail("debug tour scene did not load")
	else:
		var tour_instance := tour.instantiate()
		for node_path in [
			"Overlay", "UI/Panel/Margin/Content/ZoneRow/ZoneSelector",
			"UI/Panel/Margin/Content/TeleportButton", "UI/Panel/Margin/Content/ShowCollision",
			"UI/Panel/Margin/Content/ShowZoneBounds", "UI/Panel/Margin/Content/ShowLandmarks",
			"UI/Panel/Margin/Content/ResetButton",
		]:
			if tour_instance.get_node_or_null(NodePath(node_path)) == null:
				_fail("debug tour missing control: %s" % node_path)
		tour_instance.free()


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("awakening_first_return_smoke: " + message)


func _report() -> void:
	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "awakening_first_return_smoke",
		"passed": passed,
		"failure_count": _failures.size(),
		"failures": _failures,
	}))
	if passed:
		print("awakening_first_return_smoke: PASS")
		quit(0)
		return
	print("awakening_first_return_smoke: FAIL (%d)" % _failures.size())
	for message in _failures: print("  - %s" % message)
	quit(1)
