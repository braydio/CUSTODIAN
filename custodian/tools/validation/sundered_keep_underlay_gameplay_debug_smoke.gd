extends SceneTree

const SCENE_PATHS := [
	"res://scenes/debug/sundered_keep_production_underlay_debug.tscn",
	"res://scenes/debug/sundered_keep_gameplay_debug.tscn",
]
const UNDERLAY_TEXTURE := "res://content/masters/sundered_keep/sundered_keep_main_overlay.png"
const GAMEPLAY_CAMERA_ZOOM := Vector2(0.84, 0.84)
const SPAWN_TILE := Vector2i(56, 76)

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for scene_path in SCENE_PATHS:
		await _validate_scene(scene_path)
	_finish()


func _validate_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	_assert(packed != null, "Sundered Keep underlay gameplay debug scene did not load: %s" % scene_path)
	if packed == null:
		return

	var scene := packed.instantiate()
	_assert(scene != null, "Sundered Keep underlay gameplay debug scene did not instantiate: %s" % scene_path)
	if scene == null:
		return

	root.add_child(scene)
	await process_frame
	await process_frame

	_assert(scene.name == "GameRoot", "underlay debug root must be GameRoot for runtime absolute paths")
	_assert(scene.get_node_or_null("World/SunderedKeepMap") == null, "underlay debug must not instantiate the tiled SunderedKeepMap: %s" % scene_path)
	_assert(_count_forbidden_visual_nodes(scene) == 0, "underlay debug contains Sundered Keep wall/prop/tile visual nodes: %s" % scene_path)
	_assert(scene.get_node_or_null("World/PlayerController") != null, "underlay debug missing PlayerController")
	_assert(scene.get_node_or_null("World/Projectiles") != null, "underlay debug missing Projectiles root")

	var underlay := scene.get_node_or_null("World/SunderedKeepMainUnderlay") as Sprite2D
	var operator := scene.get_node_or_null("World/Operator") as Node2D
	var camera := scene.get_node_or_null("World/Camera2D") as Camera2D
	var bounds_root := scene.get_node_or_null("World/UnderlayWalkBounds")
	_assert(underlay != null, "main underlay Sprite2D missing")
	_assert(operator != null, "underlay debug missing Operator")
	_assert(camera != null, "underlay debug missing gameplay Camera2D")
	_assert(bounds_root != null and bounds_root.get_child_count() == 4, "underlay debug missing four perimeter walk bounds")

	if underlay != null:
		_assert(underlay.texture != null and underlay.texture.resource_path == UNDERLAY_TEXTURE, "underlay debug is not using the active main underlay texture")
		_assert(underlay.z_index < 0, "underlay should render beneath the Operator")

	if scene.has_method("get_entry_position") and operator != null:
		var entry_position := scene.call("get_entry_position") as Vector2
		_assert(operator.global_position.distance_to(entry_position) <= 0.5, "Operator did not spawn at underlay debug entry position")
		_assert(scene.call("global_to_minimap_tile", operator.global_position) == SPAWN_TILE, "Operator did not spawn on authored Sundered Keep spawn tile")

	if scene.has_method("get_camera_bounds") and camera != null:
		var bounds := scene.call("get_camera_bounds") as Rect2
		_assert(bounds.size == Vector2(3584, 2560), "underlay debug camera bounds are not the 112x80 gameplay rect")
		var base_zoom := camera.get("base_zoom") as Vector2
		_assert(base_zoom.is_equal_approx(GAMEPLAY_CAMERA_ZOOM), "underlay debug camera base zoom is not gameplay zoom")
		_assert(camera.zoom.x >= 0.8 and camera.zoom.x <= 1.0 and camera.zoom.y >= 0.8 and camera.zoom.y <= 1.0, "underlay debug camera resolved to review zoom instead of gameplay zoom")
		_assert(camera.has_method("set_runtime_map"), "underlay debug camera is not using CameraController")

	root.remove_child(scene)
	scene.queue_free()
	await process_frame


func _count_forbidden_visual_nodes(root_node: Node) -> int:
	var forbidden_names := {
		"SunderedKeepMap": true,
		"TerrainBase": true,
		"TerrainEdges": true,
		"WallsLow": true,
		"WallsHigh": true,
		"PropsStatic": true,
		"PropsDynamic": true,
		"FloorDetail": true,
		"Overlays": true,
		"Collision": true,
	}
	var count := 0
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if forbidden_names.has(String(node.name)):
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SunderedKeepUnderlayGameplayDebugSmoke] PASS")
		quit(0)
		return
	print("[SunderedKeepUnderlayGameplayDebugSmoke] FAIL failures=%d" % _failures.size())
	quit(1)
