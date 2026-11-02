extends Node

const ReplayPlayer := preload("res://game/systems/replay/instant_replay_player.gd")
const ReplayOverlay := preload("res://game/ui/replay/instant_replay_overlay.gd")
const ACTION := &"instant_replay"
const SAMPLE_HZ := 30.0
const HISTORY_SEC := 15.0
const MAX_FRAMES := int(SAMPLE_HZ * HISTORY_SEC)
const REWIND_DURATION_SEC := 0.7

var _frames: Array[Dictionary] = []
var _sample_accumulator := 0.0
var _elapsed_sec := 0.0
var _active := false
var _rewinding := false
var _playing := true
var _rate := 1.0
var _cursor_sec := 0.0
var _rewind_elapsed := 0.0
var _proxy_root: Node2D
var _overlay: InstantReplayOverlay
var _hidden_nodes: Dictionary = {}
var _camera: Camera2D
var _camera_state: Dictionary = {}
var _pause_before := false
var _proxies_by_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _active:
		_update_replay(delta)
		return
	if get_tree().paused:
		return
	_sample_accumulator += delta
	var interval := 1.0 / SAMPLE_HZ
	while _sample_accumulator >= interval:
		_sample_accumulator -= interval
		_elapsed_sec += interval
		_record_frame()


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed(ACTION):
		if _active:
			finish_replay()
		else:
			start_replay()
		get_viewport().set_input_as_handled()
		return
	if not _active:
		return
	if event.is_action_pressed(&"ui_cancel"):
		finish_replay()
	elif event.is_action_pressed(&"ui_accept"):
		_playing = not _playing
	elif event.is_action_pressed(&"move_left"):
		_scrub(-1.0)
	elif event.is_action_pressed(&"move_right"):
		_scrub(1.0)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scrub(-1.0)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scrub(1.0)
	elif event is InputEventKey:
		match (event as InputEventKey).keycode:
			KEY_1: _rate = 0.5
			KEY_2: _rate = 1.0
			KEY_3: _rate = 2.0
	get_viewport().set_input_as_handled()


func start_replay() -> bool:
	if _active or _frames.size() < 2:
		return false
	_active = true
	_rewinding = true
	_playing = true
	_rate = 1.0
	_rewind_elapsed = 0.0
	_cursor_sec = float(_frames[_frames.size() - 1].get("timestamp_sec", 0.0))
	_pause_before = get_tree().paused
	_camera = _resolve_camera()
	if _camera != null:
		_camera_state = {
			"position": _camera.global_position,
			"zoom": _camera.zoom,
		}
	_create_proxy_surface()
	_hide_live_entities()
	get_tree().paused = true
	_apply_sample(ReplayPlayer.sample_frames(_frames, _cursor_sec))
	return true


func finish_replay() -> void:
	if not _active:
		return
	if _proxy_root != null:
		_proxy_root.free()
	_proxies_by_id.clear()
	if _overlay != null:
		_overlay.free()
	for node in _hidden_nodes.keys():
		if node != null and is_instance_valid(node):
			(node as CanvasItem).visible = bool(_hidden_nodes[node])
	_hidden_nodes.clear()
	if _camera != null and is_instance_valid(_camera):
		_camera.global_position = _camera_state.get("position", _camera.global_position)
		_camera.zoom = _camera_state.get("zoom", _camera.zoom)
	get_tree().paused = _pause_before
	_active = false
	_rewinding = false


func clear_history() -> void:
	if _active:
		finish_replay()
	_frames.clear()
	_sample_accumulator = 0.0
	_elapsed_sec = 0.0


func get_replay_status() -> Dictionary:
	return {
		"active": _active,
		"frame_count": _frames.size(),
		"duration_sec": _history_duration(),
		"cursor_sec": _cursor_sec,
		"rewinding": _rewinding,
		"playing": _playing,
		"rate": _rate,
	}


func debug_record_now() -> void:
	_elapsed_sec += 1.0 / SAMPLE_HZ
	_record_frame()


func _record_frame() -> void:
	var entities: Array[Dictionary] = []
	var seen: Dictionary = {}
	for group_name in ["player", "enemies", "projectiles", "instant_replay_vfx"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not node is Node2D or seen.has(node):
				continue
			seen[node] = true
			entities.append(_capture_entity(node as Node2D, group_name))
	var camera := _resolve_camera()
	var frame := {
		"timestamp_sec": _elapsed_sec,
		"entities": entities,
		"camera": {
			"position": camera.global_position,
			"zoom": camera.zoom,
		} if camera != null else {},
	}
	_frames.append(frame)
	while _frames.size() > MAX_FRAMES:
		_frames.pop_front()


func _capture_entity(node: Node2D, kind: String) -> Dictionary:
	var layers: Array[Dictionary] = []
	_capture_sprite_layers(node, node, layers)
	return {
		"id": node.get_instance_id(),
		"kind": kind,
		"position": node.global_position,
		"rotation": node.global_rotation,
		"layers": layers,
	}


func _capture_sprite_layers(root: Node2D, cursor: Node, layers: Array[Dictionary]) -> void:
	if cursor is AnimatedSprite2D:
		var sprite := cursor as AnimatedSprite2D
		if sprite.visible and sprite.sprite_frames != null:
			layers.append({
				"type": "animated",
				"frames": sprite.sprite_frames,
				"animation": sprite.animation,
				"frame": sprite.frame,
				"transform": root.global_transform.affine_inverse() * sprite.global_transform,
				"modulate": sprite.modulate,
				"z_index": sprite.z_index,
				"flip_h": sprite.flip_h,
				"flip_v": sprite.flip_v,
			})
	elif cursor is Sprite2D:
		var sprite := cursor as Sprite2D
		if sprite.visible and sprite.texture != null:
			layers.append({
				"type": "sprite",
				"texture": sprite.texture,
				"region_enabled": sprite.region_enabled,
				"region_rect": sprite.region_rect,
				"hframes": sprite.hframes,
				"vframes": sprite.vframes,
				"frame": sprite.frame,
				"transform": root.global_transform.affine_inverse() * sprite.global_transform,
				"modulate": sprite.modulate,
				"z_index": sprite.z_index,
				"flip_h": sprite.flip_h,
				"flip_v": sprite.flip_v,
			})
	for child in cursor.get_children():
		_capture_sprite_layers(root, child, layers)


func _create_proxy_surface() -> void:
	_proxy_root = Node2D.new()
	_proxy_root.name = "InstantReplayProxies"
	_proxy_root.process_mode = Node.PROCESS_MODE_ALWAYS
	var host := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	host.add_child(_proxy_root)
	_overlay = ReplayOverlay.new()
	_overlay.name = "InstantReplayOverlay"
	host.add_child(_overlay)


func _hide_live_entities() -> void:
	for group_name in ["player", "enemies", "projectiles", "instant_replay_vfx"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is CanvasItem and not _hidden_nodes.has(node):
				_hidden_nodes[node] = (node as CanvasItem).visible
				(node as CanvasItem).visible = false


func _update_replay(delta: float) -> void:
	var oldest := float(_frames[0].get("timestamp_sec", 0.0))
	var newest := float(_frames[_frames.size() - 1].get("timestamp_sec", oldest))
	if _rewinding:
		_rewind_elapsed += delta
		_cursor_sec = lerpf(newest, oldest, minf(1.0, _rewind_elapsed / REWIND_DURATION_SEC))
		if _rewind_elapsed >= REWIND_DURATION_SEC:
			_rewinding = false
			_cursor_sec = oldest
	elif _playing:
		_cursor_sec += delta * _rate
		if _cursor_sec >= newest:
			finish_replay()
			return
	_apply_sample(ReplayPlayer.sample_frames(_frames, _cursor_sec))
	if _overlay != null:
		_overlay.set_status(_cursor_sec - oldest, newest - oldest, _rate, _playing, _rewinding)


func _apply_sample(sample: Dictionary) -> void:
	if _proxy_root == null:
		return
	var visible_ids: Dictionary = {}
	for entity in sample.get("entities", []):
		var replay_id := int(entity.get("id", 0))
		visible_ids[replay_id] = true
		var proxy := _proxies_by_id.get(replay_id) as Node2D
		if proxy == null:
			proxy = Node2D.new()
			proxy.name = "ReplayEntity_%s" % replay_id
			_proxy_root.add_child(proxy)
			_proxies_by_id[replay_id] = proxy
		proxy.position = entity.get("position", Vector2.ZERO)
		proxy.rotation = float(entity.get("rotation", 0.0))
		for child in proxy.get_children():
			child.free()
		for layer in entity.get("layers", []):
			var sprite: CanvasItem
			if String(layer.get("type", "")) == "animated":
				var animated := AnimatedSprite2D.new()
				animated.sprite_frames = layer.get("frames") as SpriteFrames
				animated.animation = layer.get("animation", &"")
				animated.frame = int(layer.get("frame", 0))
				animated.flip_h = bool(layer.get("flip_h", false))
				animated.flip_v = bool(layer.get("flip_v", false))
				sprite = animated
			else:
				var static_sprite := Sprite2D.new()
				static_sprite.texture = layer.get("texture") as Texture2D
				static_sprite.region_enabled = bool(layer.get("region_enabled", false))
				static_sprite.region_rect = layer.get("region_rect", Rect2())
				static_sprite.hframes = int(layer.get("hframes", 1))
				static_sprite.vframes = int(layer.get("vframes", 1))
				static_sprite.frame = int(layer.get("frame", 0))
				static_sprite.flip_h = bool(layer.get("flip_h", false))
				static_sprite.flip_v = bool(layer.get("flip_v", false))
				sprite = static_sprite
			(sprite as Node2D).transform = layer.get("transform", Transform2D.IDENTITY)
			sprite.modulate = layer.get("modulate", Color.WHITE)
			sprite.z_index = int(layer.get("z_index", 0))
			proxy.add_child(sprite)
	for replay_id in _proxies_by_id.keys():
		if visible_ids.has(replay_id):
			continue
		var stale := _proxies_by_id[replay_id] as Node2D
		if stale != null:
			stale.free()
		_proxies_by_id.erase(replay_id)
	var camera_state := sample.get("camera", {}) as Dictionary
	if _camera != null and not camera_state.is_empty():
		_camera.global_position = camera_state.get("position", _camera.global_position)
		_camera.zoom = camera_state.get("zoom", _camera.zoom)


func _scrub(amount_sec: float) -> void:
	_rewinding = false
	_playing = false
	var oldest := float(_frames[0].get("timestamp_sec", 0.0))
	var newest := float(_frames[_frames.size() - 1].get("timestamp_sec", oldest))
	_cursor_sec = clampf(_cursor_sec + amount_sec, oldest, newest)


func _history_duration() -> float:
	if _frames.size() < 2:
		return 0.0
	return float(_frames[_frames.size() - 1].get("timestamp_sec", 0.0)) \
		- float(_frames[0].get("timestamp_sec", 0.0))


func _resolve_camera() -> Camera2D:
	var viewport := get_viewport()
	return viewport.get_camera_2d() if viewport != null else null
