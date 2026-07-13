extends SceneTree

const MAPPER_SCENE_PATH := "res://scenes/debug/sundered_keep_underlay_collision_mapper.tscn"
const UNDERLAY_DEBUG_SCENE_PATH := "res://scenes/debug/sundered_keep_production_underlay_debug.tscn"

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await _validate_underlay_debug_collision_layer()
	await _validate_mapper_scene()
	_finish()


func _validate_underlay_debug_collision_layer() -> void:
	var packed := load(UNDERLAY_DEBUG_SCENE_PATH) as PackedScene
	_assert(packed != null, "underlay debug scene did not load")
	if packed == null:
		return
	var scene := packed.instantiate()
	_assert(scene != null, "underlay debug scene did not instantiate")
	if scene == null:
		return

	root.add_child(scene)
	await process_frame
	await process_frame

	var mapped_root := scene.get_node_or_null("World/MappedUnderlayBounds")
	var mapped_body := scene.get_node_or_null("World/MappedUnderlayBounds/UnderlayBoundaryCollision") as StaticBody2D
	_assert(mapped_root != null, "underlay debug scene missing MappedUnderlayBounds")
	_assert(mapped_body != null, "underlay debug scene missing UnderlayBoundaryCollision")
	_assert(scene.has_method("get_underlay_debug_state"), "underlay debug scene missing debug state")
	if scene.has_method("get_underlay_debug_state"):
		var state := scene.call("get_underlay_debug_state") as Dictionary
		_assert(state.has("underlay_boundary_segments"), "underlay debug state missing underlay boundary segment count")

	root.remove_child(scene)
	scene.queue_free()
	await process_frame


func _validate_mapper_scene() -> void:
	var packed := load(MAPPER_SCENE_PATH) as PackedScene
	_assert(packed != null, "underlay collision mapper scene did not load")
	if packed == null:
		return
	var scene := packed.instantiate()
	_assert(scene != null, "underlay collision mapper scene did not instantiate")
	if scene == null:
		return

	root.add_child(scene)
	await process_frame
	await process_frame

	_assert(scene.get_node_or_null("World/Camera2D") is Camera2D, "underlay collision mapper missing camera")
	_assert(scene.get_node_or_null("World/CollisionOverlay") != null, "underlay collision mapper missing overlay")
	_assert(scene.get_node_or_null("CanvasLayer/Help") is Label, "underlay collision mapper missing help label")
	_assert(scene.has_method("get_collision_mapper_state"), "underlay collision mapper missing state method")
	_assert(scene.has_method("_replace_underlay_boundary_segments_block"), "underlay collision mapper missing replacement helper")

	if scene.has_method("get_collision_mapper_state"):
		var state := scene.call("get_collision_mapper_state") as Dictionary
		var underlay_scene := state.get("underlay_scene") as Node
		_assert(underlay_scene != null, "underlay collision mapper did not instantiate underlay debug scene")
		if underlay_scene != null:
			_assert(underlay_scene.get_node_or_null("World/SunderedKeepMainUnderlay") is Sprite2D, "mapper underlay review missing main underlay sprite")
			_assert(underlay_scene.get_node_or_null("World/MappedUnderlayBounds/UnderlayBoundaryCollision") is StaticBody2D, "mapper underlay review missing mapped collision body")

	if scene.has_method("_replace_underlay_boundary_segments_block"):
		var source := "const UNDERLAY_BOUNDARY_SEGMENTS := [\n]\nconst NEXT := 1\n"
		var replacement := "const UNDERLAY_BOUNDARY_SEGMENTS := [\n\t[Vector2(1.0, 2.0), Vector2(3.0, 4.0)],\n]"
		var result := scene.call("_replace_underlay_boundary_segments_block", source, replacement) as String
		_assert(result.contains("Vector2(1.0, 2.0)"), "mapper replacement helper did not insert draft segments")
		_assert(result.contains("const NEXT := 1"), "mapper replacement helper did not preserve following source")
		var idempotent_result := scene.call("_replace_underlay_boundary_segments_block", result, replacement) as String
		_assert(idempotent_result == result, "mapper replacement helper should preserve already-current segment blocks")
		if scene.has_method("_extract_underlay_boundary_segments_block"):
			var extracted := scene.call("_extract_underlay_boundary_segments_block", result) as String
			_assert(extracted == replacement, "mapper extraction helper did not isolate the current segment block")

	root.remove_child(scene)
	scene.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SunderedKeepUnderlayCollisionMapperSmoke] PASS")
		quit(0)
		return
	print("[SunderedKeepUnderlayCollisionMapperSmoke] FAIL failures=%d" % _failures.size())
	quit(1)
