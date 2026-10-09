extends SceneTree

## Checks the production room-plate registration and the reviewed 04→05 stack.

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const PLATES := [
	{"node": "Zone01_Creche", "center": Vector2(0, -32), "size": Vector2i(960, 704)},
	{"node": "Zone02_Ambulatory", "center": Vector2(0, -864), "size": Vector2i(1152, 960)},
	{"node": "Zone03_Attestation", "center": Vector2(0, -1744), "size": Vector2i(832, 928)},
	{"node": "Zone06_Undergate", "center": Vector2(0, -4320), "size": Vector2i(1536, 1216)},
	{"node": "Zone07_GateOfDust", "center": Vector2(0, -5184), "size": Vector2i(1536, 768)},
	{"node": "Zone08_CustodianApproach", "center": Vector2(0, -5872), "size": Vector2i(1024, 864)},
	{"node": "Zone09_ChapelLateService", "center": Vector2(-736, -5728), "size": Vector2i(704, 768)},
]
const COMPOSITION_CENTER := Vector2(349, -2585)
const COMPOSITION_SIZE := Vector2i(1502, 2048)

var _failures: Array[String] = []

func _init() -> void:
	var scene := SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await _check_room_plates(scene)
	await _check_registered_composition(scene)
	if _failures.is_empty():
		print("awakening_art_registration_smoke: PASS plates=%d composition_layers=3" % PLATES.size())
		quit(0)
	else:
		for failure in _failures:
			push_error("awakening_art_registration_smoke: " + failure)
		quit(1)


func _check_room_plates(scene: Node) -> void:
	var operator := scene.get_node("World/Operator") as Node2D
	for plate in PLATES:
		var zone_path := "World/AwakeningZones/%s" % plate["node"]
		for role in ["Underlay", "Foreground"]:
			var sprite := scene.get_node_or_null("%s/%s/%s" % [zone_path,
				"ArtUnderlay" if role == "Underlay" else "Occlusion", role]) as Sprite2D
			if sprite == null or sprite.texture == null:
				_failures.append("%s %s texture is missing" % [plate["node"], role])
				continue
			if Vector2i(sprite.texture.get_size()) != plate["size"]:
				_failures.append("%s %s canvas %s != %s" % [plate["node"], role,
					str(sprite.texture.get_size()), str(plate["size"])])
			if sprite.position != plate["center"] or sprite.scale != Vector2.ONE or not is_zero_approx(sprite.rotation):
				_failures.append("%s %s registration drifted: pos=%s scale=%s rotation=%s" % [
					plate["node"], role, str(sprite.position), str(sprite.scale), str(sprite.rotation),
				])
			if role == "Foreground" and sprite.z_index != 10:
				_failures.append("%s foreground z-index is %d, expected 10" % [plate["node"], sprite.z_index])
		operator.global_position = plate["center"]
		scene.call("_update_zone_art_visibility")
		await process_frame
		var underlay := scene.get_node("%s/ArtUnderlay/Underlay" % zone_path) as Sprite2D
		var underlay_parent := underlay.get_parent() as CanvasItem
		if not underlay.visible or underlay.modulate.a < 0.999 or not underlay_parent.visible or underlay_parent.modulate.a < 0.999:
			_failures.append("%s underlay was not admitted visibly at its registered center" % plate["node"])


func _check_registered_composition(scene: Node) -> void:
	var composition := scene.get_node_or_null(
		"World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05"
	) as Node2D
	if composition == null:
		_failures.append("registered 04→05 composition is missing")
		return
	if composition.position != COMPOSITION_CENTER or composition.scale != Vector2.ONE or not is_zero_approx(composition.rotation):
		_failures.append("registered 04→05 root transform drifted")
	if not composition.visible or composition.modulate.a < 0.999:
		_failures.append("registered 04→05 root is not fully visible and opaque")
	var expected_order := ["DustLung", "Connector", "LockerReliquary"]
	for index in expected_order.size():
		var sprite := composition.get_node_or_null(expected_order[index]) as Sprite2D
		if sprite == null or sprite.texture == null:
			_failures.append("registered 04→05 layer missing: %s" % expected_order[index])
			continue
		if Vector2i(sprite.texture.get_size()) != COMPOSITION_SIZE or sprite.position != Vector2.ZERO:
			_failures.append("registered 04→05 layer registration drifted: %s" % sprite.name)
		if sprite.z_index != index or sprite.scale != Vector2.ONE or not is_zero_approx(sprite.rotation):
			_failures.append("registered 04→05 layer order/transform drifted: %s" % sprite.name)
	var operator := scene.get_node("World/Operator") as Node2D
	for zone_check in [
		{"point": Vector2(704, -1984), "layer": "LockerReliquary"},
		{"point": Vector2(0, -3200), "layer": "DustLung"},
	]:
		operator.global_position = zone_check["point"]
		scene.call("_update_zone_art_visibility")
		await process_frame
		var layer := composition.get_node(zone_check["layer"]) as Sprite2D
		if not layer.visible or layer.modulate.a < 0.999:
			_failures.append("registered %s layer is not admitted at its owner-room center" % layer.name)
