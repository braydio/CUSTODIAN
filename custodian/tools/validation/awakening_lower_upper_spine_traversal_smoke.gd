extends SceneTree

## Walks the live Awakening from the Dust Lung, across the semantic 05→06
## passage, through Zones06–08, and into South Reach using normal Operator input.

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const PASSAGE_ID := "lower_upper_spine_05_06"
const FRAME_DISPLACEMENT_LIMIT := 32.0
const MAX_WALK_FRAMES := 2400

var _failures: Array[String] = []
var _operator: CharacterBody2D
var _scene: Node
var _dust_layer: CanvasItem
var _gate_layer: CanvasItem
var _dust_underlay: Sprite2D
var _gate_underlay: Sprite2D
var _dust_foreground_layer: CanvasItem
var _gate_foreground_layer: CanvasItem
var _dust_foreground: Sprite2D
var _gate_foreground: Sprite2D
var _visited_zones := {}
var _movement_samples := 0
var _passage_samples := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_scene = SCENE.instantiate()
	root.add_child(_scene)
	await physics_frame
	_operator = _scene.get_node("World/Operator") as CharacterBody2D
	_dust_layer = _scene.get_node("World/AwakeningZones/Zone05_DustLung/ArtUnderlay") as CanvasItem
	_gate_layer = _scene.get_node("World/AwakeningZones/Zone06_Undergate/ArtUnderlay") as CanvasItem
	_dust_underlay = _scene.get_node("World/AwakeningZones/Zone05_DustLung/ArtUnderlay/Underlay") as Sprite2D
	_gate_underlay = _scene.get_node("World/AwakeningZones/Zone06_Undergate/ArtUnderlay/Underlay") as Sprite2D
	_dust_foreground_layer = _scene.get_node("World/AwakeningZones/Zone05_DustLung/Occlusion") as CanvasItem
	_gate_foreground_layer = _scene.get_node("World/AwakeningZones/Zone06_Undergate/Occlusion") as CanvasItem
	_dust_foreground = _scene.get_node("World/AwakeningZones/Zone05_DustLung/Occlusion/Foreground") as Sprite2D
	_gate_foreground = _scene.get_node("World/AwakeningZones/Zone06_Undergate/Occlusion/Foreground") as Sprite2D
	if not _dependencies_valid():
		_report()
		return

	var split := _find_piece_position(&"zone05_dust_lung", "daylight_split")
	var start := split + Vector2(0, 96)
	var goal := Layout.south_reach_completion_rect().get_center()
	_operator.global_position = start
	_scene.call("_update_zone_art_visibility")
	await physics_frame
	_check_sample("start")

	var previous := _operator.global_position
	var stalled_frames := 0
	for _frame in MAX_WALK_FRAMES:
		Input.action_press("move_up")
		await physics_frame
		_movement_samples += 1
		var point := _operator.global_position
		var delta := point - previous
		if delta.length() > FRAME_DISPLACEMENT_LIMIT:
			_fail("Operator displacement exceeded ordinary per-frame movement bounds: %s" % str(delta))
			break
		if point.y > previous.y + 1.0:
			_fail("northbound input moved the Operator south at %s" % str(point))
			break
		if absf(delta.y) < 0.05:
			stalled_frames += 1
		else:
			stalled_frames = 0
		if stalled_frames > 90:
			_fail("Operator stalled before reaching South Reach at %s" % str(point))
			break
		previous = point
		_check_sample("walk")
		if not _failures.is_empty():
			break
		if point.y <= goal.y + 8.0:
			break
	Input.action_release("move_up")
	for _frame in 8:
		await physics_frame
		_check_sample("coast")
		if not _failures.is_empty():
			break

	if absf(_operator.global_position.y - goal.y) > 48.0:
		_fail("Operator did not reach South Reach completion area; final=%s goal=%s" % [str(_operator.global_position), str(goal)])
	if _passage_samples < 4:
		_fail("normal movement did not produce enough 05→06 passage samples: %d" % _passage_samples)
	for zone_index in [5, 6, 7, 8, 10]:
		var zone := Layout.zone_by_index(zone_index)
		if not _visited_zones.has(String(zone["id"])):
			_fail("real traversal did not enter mandatory Zone%02d" % zone_index)
	if _visited_zones.has("zone09_chapel_late_service"):
		_fail("mandatory lower→upper route unexpectedly entered optional Late Service")
	if not _scene.is_inside_tree():
		_fail("Awakening scene was unloaded during continuous traversal")

	if _failures.is_empty():
		print("awakening_lower_upper_spine_traversal_smoke: PASS movement_samples=%d passage_samples=%d final=%s zones=%s" % [
			_movement_samples, _passage_samples, str(_operator.global_position), str(_visited_zones.keys())
		])
		quit(0)
	else:
		_report()


func _dependencies_valid() -> bool:
	var valid := true
	for check in [
		{"value": _operator, "label": "Operator"},
		{"value": _dust_layer, "label": "Dust Lung underlay layer"},
		{"value": _gate_layer, "label": "Undergate underlay layer"},
		{"value": _dust_underlay, "label": "Dust Lung underlay"},
		{"value": _gate_underlay, "label": "Undergate underlay"},
		{"value": _dust_foreground, "label": "Dust Lung foreground"},
		{"value": _gate_foreground, "label": "Undergate foreground"},
	]:
		if check["value"] == null:
			_fail("missing %s" % check["label"])
			valid = false
	if not Layout.PASSAGES.has(PASSAGE_ID):
		_fail("Layout has no semantic lower→upper passage")
		valid = false
	if _operator != null and not _operator is CharacterBody2D:
		_fail("Operator is not a physics-driven CharacterBody2D")
		valid = false
	return valid


func _check_sample(label: String) -> void:
	if _operator == null:
		return
	var point := _operator.global_position
	if not Layout.is_point_walkable(point):
		_fail("Operator left Layout walkable floor during %s at %s" % [label, str(point)])
		return
	for zone in Layout.ZONES:
		if (zone["envelope"] as Rect2).has_point(point):
			_visited_zones[String(zone["id"])] = true
	var passage: Rect2 = Layout.PASSAGES[PASSAGE_ID]
	if not passage.has_point(point):
		return
	_passage_samples += 1
	if _dust_layer.modulate.a < 0.999 or _gate_layer.modulate.a < 0.999:
		_fail("room art faded below full readability in passage during %s (dust=%0.3f undergate=%0.3f)" % [
			label, _dust_layer.modulate.a, _gate_layer.modulate.a
		])
	if not _dust_layer.visible or not _gate_layer.visible:
		_fail("room underlay became hidden inside passage during %s" % label)
	var pixel_coverage := maxf(
		_sprite_alpha_at(_dust_underlay, point) * _dust_layer.modulate.a,
		_sprite_alpha_at(_gate_underlay, point) * _gate_layer.modulate.a
	)
	if pixel_coverage < 0.99:
		_fail("no room underlay covers the live Operator center at %s (alpha=%0.3f)" % [str(point), pixel_coverage])
	var foreground_coverage := maxf(
		_sprite_alpha_at(_dust_foreground, point) * _dust_foreground_layer.modulate.a,
		_sprite_alpha_at(_gate_foreground, point) * _gate_foreground_layer.modulate.a
	)
	if foreground_coverage >= 0.99:
		_fail("room foreground opaque-masked the live Operator center at %s" % str(point))


func _find_piece_position(zone_id: StringName, piece_id: String) -> Vector2:
	for piece in Layout.set_pieces_for(zone_id):
		if String(piece.get("id", "")) == piece_id:
			return piece.get("position", Vector2.ZERO)
	_fail("Layout is missing the daylight split marker used to place the real-Operator start")
	return Vector2.ZERO


func _sprite_alpha_at(sprite: Sprite2D, world_point: Vector2) -> float:
	if sprite == null or sprite.texture == null:
		return 0.0
	var image := sprite.texture.get_image()
	var local := sprite.to_local(world_point)
	var pixel := Vector2i(
		floori(local.x + image.get_width() * 0.5),
		floori(local.y + image.get_height() * 0.5)
	)
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= image.get_width() or pixel.y >= image.get_height():
		return 0.0
	return image.get_pixelv(pixel).a


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	for failure in _failures:
		push_error("awakening_lower_upper_spine_traversal_smoke: " + failure)
	quit(1)
