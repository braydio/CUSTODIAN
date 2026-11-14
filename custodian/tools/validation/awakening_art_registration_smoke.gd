extends SceneTree

## Derives ordinary plate registration from Layout and proves the reviewed
## shared 04→05 composition as an explicit exception.

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const LAYOUT := preload("res://game/world/awakening/awakening_layout.gd")
const COMPOSITION_REPORT_PATH := "res://docs/ai_context/reports/assets/awakening_04_05_registered_composition_v1.json"
const COMPOSITION_CENTER := Vector2(349, -2585)
const COMPOSITION_CANVAS := Vector2i(1502, 2048)
const COMPOSITION_LAYER_NAMES := ["DustLung", "Connector", "LockerReliquary"]
const COMPOSITION_SOURCE_IDS := ["dust_lung", "connector_04_05", "locker_reliquary"]
const COMPOSITION_SOURCE_PATHS := [
	"res://content/levels/awakening/05_dust_lung/awakening_dust_lung_underlay_1502x2048.png",
	"res://content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png",
	"res://content/levels/awakening/04_locker_reliquary/awakening_locker_reliquary_underlay_1502x2048.png",
]

var _failures: Array[String] = []

func _init() -> void:
	var scene := SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await _check_standalone_plates(scene)
	await _check_registered_composition(scene)
	_check_failure_sentinels(scene)
	if _failures.is_empty():
		print("awakening_art_registration_smoke: PASS ordinary_zones=7 composition_exception=04_05")
		quit(0)
	else:
		for failure in _failures:
			push_error("awakening_art_registration_smoke: " + failure)
		quit(1)


func _check_standalone_plates(scene: Node) -> void:
	var operator := scene.get_node("World/Operator") as Node2D
	var ordinary_count := 0
	for zone in LAYOUT.ZONES:
		var zone_index := int(zone["index"])
		if zone_index == 10:
			continue # Zone 10 is the Road prototype, not a room plate.
		var zone_path := "World/AwakeningZones/%s" % zone["node"]
		if zone_index in [4, 5]:
			_assert_composite_zone_exception(scene, zone_path, zone)
			continue
		ordinary_count += 1
		var underlay := scene.get_node_or_null("%s/ArtUnderlay/Underlay" % zone_path) as Sprite2D
		var foreground := scene.get_node_or_null("%s/Occlusion/Foreground" % zone_path) as Sprite2D
		_check_ordinary_registration(zone, underlay, foreground, _failures)
		if underlay == null:
			continue
		operator.global_position = underlay.global_position
		scene.call("_update_zone_art_visibility")
		await process_frame
		var underlay_parent := underlay.get_parent() as CanvasItem
		if not underlay.visible or underlay.modulate.a < 0.999 or not underlay_parent.is_visible_in_tree():
			_failures.append("%s underlay was not admitted visibly at its Layout-derived center" % zone["node"])
	if ordinary_count != 7:
		_failures.append("expected seven ordinary Layout zones, found %d" % ordinary_count)


func _check_ordinary_registration(zone: Dictionary, underlay: Sprite2D,
		foreground: Sprite2D, failures: Array[String]) -> void:
	var node_name := String(zone["node"])
	var envelope: Rect2 = zone["envelope"]
	var expected_rect := envelope.grow(64.0)
	if underlay == null or underlay.texture == null:
		failures.append("%s underlay texture is missing" % node_name)
		return
	if foreground == null or foreground.texture == null:
		failures.append("%s foreground texture is missing" % node_name)
		return
	for role_sprite in [underlay, foreground]:
		var role := "underlay" if role_sprite == underlay else "foreground"
		var canvas := Vector2i(role_sprite.texture.get_size())
		var global_rect: Rect2 = role_sprite.get_global_transform() * role_sprite.get_rect()
		if canvas != Vector2i(expected_rect.size):
			failures.append("%s %s canvas %s != Layout envelope grown 64 %s" % [
				node_name, role, str(canvas), str(expected_rect.size),
			])
		if not global_rect.position.is_equal_approx(expected_rect.position) \
				or not global_rect.size.is_equal_approx(expected_rect.size):
			failures.append("%s %s global bounds %s != Layout grown-64 rect %s" % [
				node_name, role, str(global_rect), str(expected_rect),
			])
		if not role_sprite.global_position.is_equal_approx(expected_rect.get_center()) \
				or not role_sprite.global_scale.is_equal_approx(Vector2.ONE) \
				or not is_zero_approx(role_sprite.global_rotation) \
				or not role_sprite.centered or role_sprite.offset != Vector2.ZERO:
			failures.append("%s %s registration/scale/rotation/anchor drifted" % [node_name, role])
	if Vector2i(underlay.texture.get_size()) != Vector2i(foreground.texture.get_size()) \
			or not underlay.global_transform.is_equal_approx(foreground.global_transform):
		failures.append("%s underlay/foreground canvas or registration parity failed" % node_name)
	if foreground.z_index != 10:
		failures.append("%s foreground z-index is %d, expected 10" % [node_name, foreground.z_index])


func _assert_composite_zone_exception(scene: Node, zone_path: String, zone: Dictionary) -> void:
	var underlay := scene.get_node_or_null("%s/ArtUnderlay/Underlay" % zone_path) as Sprite2D
	var foreground := scene.get_node_or_null("%s/Occlusion/Foreground" % zone_path) as Sprite2D
	if underlay == null or underlay.visible or underlay.is_visible_in_tree():
		_failures.append("%s legacy underlay must remain hidden for the approved shared composition" % zone["node"])
	if zone["index"] == 4:
		if foreground != null:
			_failures.append("Zone04 Locker foreground must remain intentionally unbound")
	elif foreground == null or foreground.visible or foreground.is_visible_in_tree():
		_failures.append("Zone05 legacy foreground must remain hidden for the approved shared composition")


func _check_registered_composition(scene: Node) -> void:
	var composition := scene.get_node_or_null(
		"World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05"
	) as Node2D
	if composition == null:
		_failures.append("registered 04→05 composition is missing")
		return
	if composition.position != COMPOSITION_CENTER or composition.scale != Vector2.ONE \
			or not is_zero_approx(composition.rotation) or composition.z_index != -4:
		_failures.append("registered 04→05 root transform/layer changed from the approved exception")
	if not composition.visible or composition.modulate.a < 0.999:
		_failures.append("registered 04→05 root is not fully visible and opaque")
	var production_art := composition.get_parent() as CanvasItem
	if production_art == null or production_art.z_index != 1:
		_failures.append("registered 04→05 production-art layer changed")

	var report := _load_composition_report()
	var source_layers: Array = report.get("layers_bottom_to_top", [])
	if source_layers.size() != COMPOSITION_LAYER_NAMES.size():
		_failures.append("04→05 source report does not contain exactly three ordered layers")
		return
	for index in COMPOSITION_LAYER_NAMES.size():
		var layer_name: String = COMPOSITION_LAYER_NAMES[index]
		var source_id: String = COMPOSITION_SOURCE_IDS[index]
		var sprite := composition.get_node_or_null(layer_name) as Sprite2D
		var layer_report: Dictionary = source_layers[index]
		if sprite == null or sprite.texture == null:
			_failures.append("registered 04→05 layer missing: %s" % layer_name)
			continue
		var source_path: String = COMPOSITION_SOURCE_PATHS[index]
		if not _composition_child_is_valid(sprite, index, layer_report):
			_failures.append("registered 04→05 source/canvas/transform/order drifted: %s" % layer_name)
		var expected_hash := String(layer_report.get("sha256", ""))
		if not FileAccess.file_exists(source_path) or FileAccess.get_sha256(source_path) != expected_hash:
			_failures.append("registered 04→05 source hash no longer matches report for %s" % source_id)
		var alpha_bounds: Array = layer_report.get("alpha_bounds_xyxy_exclusive", [])
		if alpha_bounds.size() != 4 or alpha_bounds[0] < 0 or alpha_bounds[1] < 0 \
				or alpha_bounds[2] > COMPOSITION_CANVAS.x or alpha_bounds[3] > COMPOSITION_CANVAS.y:
			_failures.append("registered 04→05 source alpha silhouette is missing/out of canvas: %s" % source_id)
		if source_id == "connector_04_05" and Vector4i(alpha_bounds[0], alpha_bounds[1],
				alpha_bounds[2], alpha_bounds[3]) != Vector4i(258, 672, 1300, 1256):
			_failures.append("connector source silhouette bounds changed from its complete reviewed plate")

	var reference_canvas: Dictionary = report.get("reference_canvas", {})
	var runtime_registration: Dictionary = report.get("runtime_registration", {})
	if reference_canvas.get("width") != COMPOSITION_CANVAS.x or reference_canvas.get("height") != COMPOSITION_CANVAS.y \
			or runtime_registration.get("shared_root_position") != [COMPOSITION_CENTER.x, COMPOSITION_CENTER.y]:
		_failures.append("04→05 exception no longer agrees with its measured registered-composition report")
	var operator := scene.get_node("World/Operator") as Node2D
	for zone_check in [
		{"point": Vector2(704, -1984), "layer": "LockerReliquary"},
		{"point": Vector2(0, -3200), "layer": "DustLung"},
	]:
		operator.global_position = zone_check["point"]
		scene.call("_update_zone_art_visibility")
		await process_frame
		var layer := composition.get_node(zone_check["layer"]) as Sprite2D
		if not layer.is_visible_in_tree() or layer.modulate.a < 0.999:
			_failures.append("registered %s layer is not admitted at its owner-room center" % layer.name)


func _load_composition_report() -> Dictionary:
	if not FileAccess.file_exists(COMPOSITION_REPORT_PATH):
		_failures.append("registered 04→05 measured source report is missing")
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COMPOSITION_REPORT_PATH))
	if not parsed is Dictionary or parsed.get("schema") != "custodian.awakening_registered_composition.v1":
		_failures.append("registered 04→05 measured source report has invalid schema")
		return {}
	return parsed


func _check_failure_sentinels(scene: Node) -> void:
	# Negative controls make the proof's sensitivity executable: a changed Layout
	# envelope, sprite transform/canvas, composition child, or source hash must fail.
	var first_zone: Dictionary = LAYOUT.ZONES[0].duplicate(true)
	var zone_path := "World/AwakeningZones/%s" % first_zone["node"]
	var underlay := scene.get_node("%s/ArtUnderlay/Underlay" % zone_path) as Sprite2D
	var foreground := scene.get_node("%s/Occlusion/Foreground" % zone_path) as Sprite2D
	var probe: Array[String] = []
	first_zone["envelope"] = (first_zone["envelope"] as Rect2).grow(1.0)
	_check_ordinary_registration(first_zone, underlay, foreground, probe)
	if probe.is_empty():
		_failures.append("negative control did not reject a changed Layout envelope")

	probe.clear()
	var saved_position := underlay.position
	underlay.position.x += 1.0
	_check_ordinary_registration(LAYOUT.ZONES[0], underlay, foreground, probe)
	underlay.position = saved_position
	if probe.is_empty():
		_failures.append("negative control did not reject a changed standalone sprite transform")

	probe.clear()
	var saved_texture := foreground.texture
	foreground.texture = scene.get_node("World/AwakeningZones/Zone06_Undergate/ArtUnderlay/Underlay").texture
	_check_ordinary_registration(LAYOUT.ZONES[0], underlay, foreground, probe)
	foreground.texture = saved_texture
	if probe.is_empty():
		_failures.append("negative control did not reject a changed foreground canvas")

	var composition := scene.get_node("World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05") as Node2D
	var connector := composition.get_node("Connector") as Sprite2D
	var report := _load_composition_report()
	var report_layers: Array = report.get("layers_bottom_to_top", [])
	var saved_connector_position := connector.position
	connector.position.x += 1.0
	var mutated_child_passed := report_layers.size() > 1 \
			and _composition_child_is_valid(connector, 1, report_layers[1])
	connector.position = saved_connector_position
	if mutated_child_passed:
		_failures.append("negative control did not reject a changed composition child transform")

	var saved_connector_texture := connector.texture
	connector.texture = underlay.texture
	var mutated_report := report.duplicate(true)
	var layers: Array = mutated_report.get("layers_bottom_to_top", [])
	if layers.size() > 1:
		layers[1]["sha256"] = "intentionally-mutated-source-state"
		mutated_report["layers_bottom_to_top"] = layers
	probe.clear()
	_check_composition_source_state(composition, mutated_report, probe)
	connector.texture = saved_connector_texture
	if probe.is_empty():
		_failures.append("negative control did not reject a changed composition source state")


func _check_composition_source_state(composition: Node2D, report: Dictionary, failures: Array[String]) -> void:
	var layers: Array = report.get("layers_bottom_to_top", [])
	if layers.size() != COMPOSITION_LAYER_NAMES.size():
		failures.append("source-state layer count changed")
		return
	var connector := composition.get_node_or_null("Connector") as Sprite2D
	if connector == null or connector.texture == null:
		failures.append("source-state connector missing")
		return
	if not _composition_child_is_valid(connector, 1, layers[1]):
		failures.append("source-state connector identity/hash changed")


func _composition_child_is_valid(sprite: Sprite2D, index: int, layer_report: Dictionary) -> bool:
	if sprite == null or sprite.texture == null or index < 0 or index >= COMPOSITION_LAYER_NAMES.size():
		return false
	var expected_path: String = COMPOSITION_SOURCE_PATHS[index]
	return String(layer_report.get("id", "")) == COMPOSITION_SOURCE_IDS[index] \
			and sprite.texture.resource_path == expected_path \
			and FileAccess.get_sha256(expected_path) == String(layer_report.get("sha256", "")) \
			and Vector2i(sprite.texture.get_size()) == COMPOSITION_CANVAS \
			and sprite.position == Vector2.ZERO and sprite.scale == Vector2.ONE \
			and is_zero_approx(sprite.rotation) and sprite.z_index == index
