extends Node2D
class_name AshBellThreadwayCauseway

signal resolution_finished
signal visual_resolution_finished

const RESOLVE_TEXTURE := preload(
	"res://content/sprites/world/ingress/ash_bell/ash_bell_threadway_resolve_01__7f__32.png"
)
const FLOOR_TEXTURES: Array[Texture2D] = [
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_1.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_2.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_3.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_4.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_5.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_6.png"),
]
const SOURCE_TILE_SIZE := Vector2(32.0, 32.0)
const RESOLVE_FRAME_COUNT := 7
const RESOLVE_FPS := 11.0
const WAVE_STEP_SECONDS := 0.065
const LOCAL_JITTER_MAX_MILLISECONDS := 100

var _map_instance: Node = null
var _persistent_by_tile: Dictionary = {}
var _temporary_blocker: StaticBody2D = null
var _reveal_play_count := 0
var _resolve_frames: SpriteFrames = null
var _planned_cells: Dictionary = {}
var _spawned_cells: Dictionary = {}
var _resolved_cells: Dictionary = {}
var _active_effects: Dictionary = {}
var _reveal_delay_by_cell: Dictionary = {}
var _visual_completion_emitted := false


func configure(map_instance: Node, connector: Dictionary, play_reveal: bool) -> void:
	_map_instance = map_instance
	var cells: Array = connector.get("cells", [])
	var variants: Dictionary = connector.get("tile_variants", {})
	var tile_size := _runtime_tile_size()
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var sprite := Sprite2D.new()
		sprite.name = "ThreadwayFloor_%d_%d" % [cell.x, cell.y]
		sprite.texture = FLOOR_TEXTURES[int(variants.get(cell, 0)) % FLOOR_TEXTURES.size()]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = tile_size / SOURCE_TILE_SIZE
		sprite.z_as_relative = false
		sprite.z_index = 0
		sprite.visible = not play_reveal
		add_child(sprite)
		sprite.global_position = _tile_to_global(cell)
		_persistent_by_tile[cell] = sprite
	if not play_reveal:
		return
	_build_temporary_blocker(cells, tile_size)
	_play_resolution.call_deferred(connector)


func _play_resolution(connector: Dictionary) -> void:
	_reveal_play_count += 1
	_planned_cells.clear()
	_spawned_cells.clear()
	_resolved_cells.clear()
	_active_effects.clear()
	_reveal_delay_by_cell.clear()
	_visual_completion_emitted = false
	var cells: Array = connector.get("cells", [])
	var centerline: Array = connector.get("centerline_cells", [])
	var supplied_progress := connector.get("centerline_progress_by_cell", {}) as Dictionary
	var route_seed := int(connector.get("route_seed", 0))
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if _planned_cells.has(cell):
			continue
		_planned_cells[cell] = true
		var island_progress := int(supplied_progress.get(
			cell,
			_nearest_centerline_index(cell, centerline)
		))
		var mainland_progress := maxi(0, centerline.size() - 1 - island_progress)
		var jitter_milliseconds := _deterministic_cell_hash(cell, route_seed) \
			% (LOCAL_JITTER_MAX_MILLISECONDS + 1)
		var delay := float(mainland_progress) * WAVE_STEP_SECONDS \
			+ float(jitter_milliseconds) / 1000.0
		_reveal_delay_by_cell[cell] = delay
		_resolve_cell_after_delay(cell, delay)
	if _planned_cells.is_empty():
		_emit_visual_completion_once.call_deferred()


func finish_resolution() -> void:
	_remove_temporary_blocker()
	resolution_finished.emit()


func _resolve_cell_after_delay(cell: Vector2i, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or _resolved_cells.has(cell):
		return
	_spawn_resolve_vfx(cell)


func _spawn_resolve_vfx(cell: Vector2i) -> void:
	if _spawned_cells.has(cell):
		return
	if _resolve_frames == null:
		_resolve_frames = SpriteFrames.new()
		_resolve_frames.add_animation(&"resolve")
		_resolve_frames.set_animation_loop(&"resolve", false)
		_resolve_frames.set_animation_speed(&"resolve", RESOLVE_FPS)
		for frame_index in range(RESOLVE_FRAME_COUNT):
			var atlas := AtlasTexture.new()
			atlas.atlas = RESOLVE_TEXTURE
			atlas.region = Rect2(frame_index * 32.0, 0.0, 32.0, 32.0)
			_resolve_frames.add_frame(&"resolve", atlas)
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = _resolve_frames
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.scale = _runtime_tile_size() / SOURCE_TILE_SIZE
	effect.z_as_relative = false
	effect.z_index = 1
	effect.set_meta("threadway_cell", cell)
	add_child(effect)
	effect.global_position = _tile_to_global(cell)
	_spawned_cells[cell] = true
	_active_effects[cell] = effect
	effect.animation_finished.connect(
		_on_cell_resolve_finished.bind(cell, effect),
		CONNECT_ONE_SHOT
	)
	effect.play(&"resolve")


func _on_cell_resolve_finished(cell: Vector2i, effect: AnimatedSprite2D) -> void:
	if _resolved_cells.has(cell):
		return
	_resolved_cells[cell] = true
	_active_effects.erase(cell)
	var persistent := _persistent_by_tile.get(cell) as Sprite2D
	if persistent != null:
		persistent.visible = true
	if is_instance_valid(effect):
		effect.queue_free()
	if _resolved_cells.size() == _planned_cells.size():
		_emit_visual_completion_once()


func _emit_visual_completion_once() -> void:
	if _visual_completion_emitted:
		return
	_visual_completion_emitted = true
	visual_resolution_finished.emit()


func _nearest_centerline_index(cell: Vector2i, centerline: Array) -> int:
	var best_index := 0
	var best_distance := 1 << 30
	for index in range(centerline.size()):
		if not centerline[index] is Vector2i:
			continue
		var distance := cell.distance_squared_to(centerline[index] as Vector2i)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _deterministic_cell_hash(cell: Vector2i, route_seed: int) -> int:
	var value := cell.x * 73856093 ^ cell.y * 19349663 ^ route_seed * 83492791
	return absi(value)


func _build_temporary_blocker(cells: Array, tile_size: Vector2) -> void:
	_temporary_blocker = StaticBody2D.new()
	_temporary_blocker.name = "ThreadwayResolutionBlocker"
	add_child(_temporary_blocker)
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue
		var shape := RectangleShape2D.new()
		shape.size = tile_size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		_temporary_blocker.add_child(collision)
		collision.global_position = _tile_to_global(cell_variant as Vector2i)


func _remove_temporary_blocker() -> void:
	if _temporary_blocker == null:
		return
	_temporary_blocker.queue_free()
	_temporary_blocker = null


func _runtime_tile_size() -> Vector2:
	if _map_instance != null and _map_instance.has_method("get_runtime_tile_size"):
		return _map_instance.call("get_runtime_tile_size") as Vector2
	return SOURCE_TILE_SIZE


func _tile_to_global(cell: Vector2i) -> Vector2:
	if _map_instance != null and _map_instance.has_method("tile_to_global_position"):
		return _map_instance.call("tile_to_global_position", cell) as Vector2
	return Vector2(cell) * _runtime_tile_size() + _runtime_tile_size() * 0.5


func debug_get_persistent_tile_count() -> int:
	return _persistent_by_tile.size()


func debug_get_reveal_play_count() -> int:
	return _reveal_play_count


func debug_has_temporary_blocker() -> bool:
	return _temporary_blocker != null


func debug_get_visible_persistent_tile_count() -> int:
	var count := 0
	for sprite_variant in _persistent_by_tile.values():
		var sprite := sprite_variant as Sprite2D
		if sprite != null and sprite.visible:
			count += 1
	return count


func debug_get_active_resolve_effect_count() -> int:
	return _active_effects.size()


func debug_get_spawned_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell_variant in _spawned_cells.keys():
		result.append(cell_variant as Vector2i)
	return result


func debug_get_resolved_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell_variant in _resolved_cells.keys():
		result.append(cell_variant as Vector2i)
	return result


func debug_get_reveal_delays() -> Dictionary:
	return _reveal_delay_by_cell.duplicate(true)


func debug_finish_resolve_cell(cell: Vector2i) -> void:
	var effect := _active_effects.get(cell) as AnimatedSprite2D
	if effect != null:
		_on_cell_resolve_finished(cell, effect)
