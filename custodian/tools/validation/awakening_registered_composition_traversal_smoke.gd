extends SceneTree

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const ROUTE := [
	{"action": "move_left", "axis": 0, "target": 672.0},
	{"action": "move_up", "axis": 1, "target": -2464.0},
	{"action": "move_left", "axis": 0, "target": 16.0},
	{"action": "move_up", "axis": 1, "target": -2760.0},
	{"action": "move_down", "axis": 1, "target": -2496.0},
	{"action": "move_right", "axis": 0, "target": 672.0},
	{"action": "move_down", "axis": 1, "target": -2208.0},
]
const ROOT_CENTER := Vector2(349, -2585)

var _failures: Array[String] = []
var _layer_images: Array[Image] = []
var _layer_sprites: Array[Sprite2D] = []
var _operator: CharacterBody2D
var _composition: CanvasItem
var _samples := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := SCENE.instantiate()
	root.add_child(scene)
	await physics_frame
	_operator = scene.get_node("World/Operator") as CharacterBody2D
	_composition = scene.get_node("World/AwakeningZones/Traversal/ProductionArt/RegisteredComposition04_05") as CanvasItem
	for node_name in ["DustLung", "Connector", "LockerReliquary"]:
		var sprite := _composition.get_node(node_name) as Sprite2D
		_layer_sprites.append(sprite)
		_layer_images.append(sprite.texture.get_image())
	_operator.global_position = Vector2(704, -2208)
	scene.call("_update_zone_art_visibility")
	await physics_frame
	_check_floor("start")
	for segment in ROUTE:
		await _walk_segment(String(segment["action"]), int(segment["axis"]), float(segment["target"]))
		if not _failures.is_empty():
			break
		await _coast_and_check()
	if _failures.is_empty():
		print("awakening_registered_composition_traversal_smoke: PASS samples=%d final=%s" % [_samples, str(_operator.global_position)])
		quit(0)
	else:
		for failure in _failures:
			push_error("awakening_registered_composition_traversal_smoke: " + failure)
		quit(1)


func _walk_segment(action: String, axis: int, target: float) -> void:
	var frames := 0
	while absf(_operator.global_position[axis] - target) > 20.0 and frames < 360:
		Input.action_press(action)
		await physics_frame
		frames += 1
		_check_floor(action)
		if not _failures.is_empty():
			break
	Input.action_release(action)
	if frames >= 360 and absf(_operator.global_position[axis] - target) > 48.0:
		_failures.append("Operator failed to reach %s target %.1f from %s" % [action, target, str(_operator.global_position)])


func _coast_and_check() -> void:
	for _frame in 10:
		await physics_frame
		_check_floor("coast")
		if not _failures.is_empty():
			return


func _check_floor(label: String) -> void:
	_samples += 1
	var point := _operator.global_position
	if not Layout.is_point_walkable(point):
		_failures.append("Operator left Layout walkable floor during %s at %s" % [label, str(point)])
		return
	if not _composition.visible or _composition.modulate.a < 0.99:
		_failures.append("registered composition parent changed during %s at %s" % [label, str(point)])
		return
	var connector_envelope: Rect2 = Layout.CONNECTORS["04_05_A"].merge(
		Layout.CONNECTORS["04_05_B"]
	).merge(Layout.CONNECTORS["04_05_C"])
	if connector_envelope.has_point(point):
		for sprite in _layer_sprites:
			if not sprite.visible or sprite.modulate.a < 0.99:
				_failures.append("registered layer %s faded inside the 04→05 dogleg during %s at %s" % [sprite.name, label, str(point)])
				return
	if Layout.ZONES[3]["envelope"].has_point(point) and _layer_sprites[2].modulate.a < 0.99:
		_failures.append("Locker layer faded in its owner room during %s at %s" % [label, str(point)])
		return
	if Layout.ZONES[4]["envelope"].has_point(point) and _layer_sprites[0].modulate.a < 0.99:
		_failures.append("Dust layer faded in its owner room during %s at %s" % [label, str(point)])
		return
	var composition_point := point - ROOT_CENTER + Vector2(751, 1024)
	var px := roundi(composition_point.x)
	var py := roundi(composition_point.y)
	var covered := false
	for i in _layer_images.size():
		var image := _layer_images[i]
		if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height() and image.get_pixel(px, py).a > 0.05:
			if _layer_sprites[i].visible and _layer_sprites[i].modulate.a > 0.05:
				covered = true
	if not covered:
		_failures.append("Operator had no registered floor pixels underfoot during %s at %s" % [label, str(point)])
