extends StaticBody2D
class_name ResourceNode

signal harvested(node: ResourceNode, resource_id: String, remaining_work: int)
signal depleted(node: ResourceNode, resource_id: String, amount: int)

@export_enum(
	"blackwood_deadfall",
	"alloy_vein",
	"machine_wreckage",
	"power_node",
	"moss_patch",
	"fungal_resin_pod",
	"ruptured_capacitor_bank",
	"broken_signal_relay",
	"shattered_archive_terminal"
) var node_kind: String = "blackwood_deadfall"
@export_enum("CUT", "MINE", "SALVAGE", "EXTRACT") var harvest_label: String = "CUT"
@export var resource_id: String = "blackwood"
@export_range(1, 20, 1) var work_required: int = 3
@export_range(1, 999, 1) var yield_amount: int = 6
@export var secondary_yields: Dictionary = {}
@export_range(24.0, 160.0, 1.0) var interaction_distance: float = 84.0
@export var standing_color: Color = Color(0.18, 0.14, 0.1, 1.0)
@export var depleted_color: Color = Color(0.08, 0.075, 0.07, 1.0)
@export var prompt_resource_label: String = ""
@export var depleted_prompt: String = ""
@export_file("*.png") var idle_sheet_path: String = ""
@export_file("*.png") var depleted_sheet_path: String = ""
@export_file("*.png") var idle_fx_sheet_path: String = ""
@export_file("*.png") var strike_fx_sheet_path: String = ""
@export var play_idle_fx: bool = false
@export_enum("loop", "harvest_states") var sprite_playback_mode: String = "loop"
@export_range(0.02, 1.0, 0.01) var state_fx_flash_duration: float = 0.18
@export var sprite_frame_size: Vector2i = Vector2i(96, 96)
@export var sprite_fps: float = 6.0
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_position: Vector2 = Vector2(0.0, -48.0)

@onready var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
@onready var node_sprite: AnimatedSprite2D = get_node_or_null("NodeSprite") as AnimatedSprite2D
@onready var fx_sprite: AnimatedSprite2D = get_node_or_null("FxSprite") as AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var _work_remaining: int = 1
var _is_depleted: bool = false
var _fx_flash_token: int = 0
var _pending_body_state_frame: int = -1
var _pending_idle_fx_frame: int = -1
var _pending_visual_depleted: bool = false
var _defer_harvest_visual_transition: bool = false


func _ready() -> void:
	add_to_group("resource_nodes")
	add_to_group("interactable")
	_work_remaining = max(1, work_required)
	_setup_runtime_sprites()
	_apply_visual_state()


func is_depleted() -> bool:
	return _is_depleted


func get_interaction_prompt() -> String:
	if _is_depleted:
		return depleted_prompt
	var label := prompt_resource_label
	if label.is_empty():
		label = resource_id.replace("_", " ").to_upper()
	var harvested_count := work_required - _work_remaining
	return "%s %s (%d/%d)" % [harvest_label, label, harvested_count, work_required]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func interact(_actor: Node) -> void:
	apply_harvest(1)


func apply_harvest(work_amount: int = 1) -> bool:
	if _is_depleted:
		return false

	var previous_harvested_count: int = work_required - _work_remaining
	_work_remaining -= max(1, work_amount)
	var harvested_count: int = work_required - maxi(0, _work_remaining)
	_play_strike_fx(harvested_count, previous_harvested_count)
	harvested.emit(self, resource_id, max(0, _work_remaining))
	if not _defer_harvest_visual_transition:
		_apply_visual_state()

	if _work_remaining <= 0:
		_deplete()

	return true


func _deplete() -> void:
	if _is_depleted:
		return

	_is_depleted = true
	_deposit_yields()
	if not _defer_harvest_visual_transition:
		_apply_visual_state()
	remove_from_group("interactable")
	depleted.emit(self, resource_id, yield_amount)


func _deposit_yields() -> void:
	var ledger := get_node_or_null("/root/ResourceLedger")
	if ledger == null:
		push_warning("[ResourceNode] ResourceLedger unavailable; harvest yield was not stored")
		return

	ledger.call("add", resource_id, yield_amount)
	for secondary_id_variant in secondary_yields.keys():
		var secondary_id := str(secondary_id_variant)
		var amount := int(secondary_yields[secondary_id_variant])
		if amount > 0:
			ledger.call("add", secondary_id, amount)


func _apply_visual_state() -> void:
	if node_sprite != null and node_sprite.sprite_frames != null:
		if _is_depleted and node_sprite.sprite_frames.has_animation("depleted"):
			node_sprite.play("depleted")
			node_sprite.stop()
			node_sprite.set_frame_and_progress(0, 0.0)
		elif node_sprite.sprite_frames.has_animation("idle"):
			if sprite_playback_mode == "harvest_states":
				var harvested_count: int = work_required - _work_remaining
				_set_sprite_static_frame(node_sprite, "idle", harvested_count)
			else:
				node_sprite.play("idle")
	if visual != null:
		visual.visible = node_sprite == null or node_sprite.sprite_frames == null
		visual.color = depleted_color if _is_depleted else standing_color
		var scale_y := 0.45 if _is_depleted else 1.0
		visual.scale = Vector2(1.0, scale_y)
	if collision_shape != null:
		collision_shape.disabled = _is_depleted


func _setup_runtime_sprites() -> void:
	if node_sprite != null:
		node_sprite.position = sprite_position
		node_sprite.scale = sprite_scale
		var frames := SpriteFrames.new()
		_add_strip_animation(frames, "idle", idle_sheet_path, sprite_playback_mode != "harvest_states", sprite_fps)
		_add_strip_animation(frames, "depleted", depleted_sheet_path, false, sprite_fps)
		if frames.has_animation("idle") or frames.has_animation("depleted"):
			node_sprite.sprite_frames = frames
			node_sprite.visible = true
		else:
			node_sprite.visible = false
	if fx_sprite != null:
		fx_sprite.position = sprite_position
		fx_sprite.scale = sprite_scale
		fx_sprite.visible = false
		var fx_frames := SpriteFrames.new()
		_add_strip_animation(fx_frames, "idle_fx", idle_fx_sheet_path, true, sprite_fps)
		_add_strip_animation(fx_frames, "strike_fx", strike_fx_sheet_path, false, sprite_fps)
		if fx_frames.has_animation("idle_fx") or fx_frames.has_animation("strike_fx"):
			fx_sprite.sprite_frames = fx_frames
			if play_idle_fx and fx_frames.has_animation("idle_fx"):
				fx_sprite.visible = true
				fx_sprite.play("idle_fx")
			var fx_finished := Callable(self, "_on_fx_animation_finished")
			if not fx_sprite.animation_finished.is_connected(fx_finished):
				fx_sprite.animation_finished.connect(fx_finished)


func _add_strip_animation(frames: SpriteFrames, animation_name: String, path: String, loop: bool, fps: float) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var resource := load(path)
	if not (resource is Texture2D):
		return
	var texture := resource as Texture2D
	var frame_width: int = max(1, sprite_frame_size.x)
	var frame_height: int = max(1, sprite_frame_size.y)
	var frame_count: int = max(1, texture.get_width() / frame_width)
	if texture.get_height() < frame_height:
		return
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, fps)
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(float(frame_index * frame_width), 0.0, float(frame_width), float(frame_height))
		frames.add_frame(animation_name, atlas)


func _play_strike_fx(harvested_count: int, previous_harvested_count: int) -> void:
	if sprite_playback_mode == "harvest_states":
		_pending_body_state_frame = harvested_count
		_pending_idle_fx_frame = previous_harvested_count
		_pending_visual_depleted = harvested_count >= work_required
		_defer_harvest_visual_transition = true
	if fx_sprite == null or fx_sprite.sprite_frames == null:
		if sprite_playback_mode == "harvest_states":
			_finish_harvest_state_transition()
		return
	if not fx_sprite.sprite_frames.has_animation("strike_fx"):
		if sprite_playback_mode == "harvest_states":
			_play_harvest_state_idle_flash()
		return
	_fx_flash_token += 1
	fx_sprite.visible = true
	fx_sprite.play("strike_fx")
	fx_sprite.set_frame_and_progress(0, 0.0)


func _set_sprite_static_frame(sprite: AnimatedSprite2D, animation_name: String, frame_index: int) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation_name):
		return
	var frame_count: int = sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return
	var safe_frame: int = clampi(frame_index, 0, frame_count - 1)
	sprite.play(animation_name)
	sprite.stop()
	sprite.set_frame_and_progress(safe_frame, 0.0)


func _hide_fx_after_flash(flash_token: int, finish_transition: bool = false) -> void:
	await get_tree().create_timer(state_fx_flash_duration).timeout
	if flash_token != _fx_flash_token:
		return
	if fx_sprite != null:
		fx_sprite.visible = false
	if finish_transition:
		_finish_harvest_state_transition()


func _play_harvest_state_idle_flash() -> void:
	if sprite_playback_mode != "harvest_states":
		return
	if fx_sprite == null or fx_sprite.sprite_frames == null:
		_finish_harvest_state_transition()
		return
	if not fx_sprite.sprite_frames.has_animation("idle_fx"):
		_finish_harvest_state_transition()
		return
	_fx_flash_token += 1
	var flash_token: int = _fx_flash_token
	fx_sprite.visible = true
	_set_sprite_static_frame(fx_sprite, "idle_fx", _pending_idle_fx_frame)
	_hide_fx_after_flash(flash_token, true)


func _finish_harvest_state_transition() -> void:
	_defer_harvest_visual_transition = false
	if _pending_body_state_frame >= 0 or _pending_visual_depleted:
		_apply_visual_state()
	_pending_body_state_frame = -1
	_pending_idle_fx_frame = -1
	_pending_visual_depleted = false


func _on_fx_animation_finished() -> void:
	if fx_sprite == null or fx_sprite.sprite_frames == null:
		return
	if sprite_playback_mode == "harvest_states":
		if str(fx_sprite.animation) == "strike_fx":
			_play_harvest_state_idle_flash()
		return
	if _is_depleted:
		fx_sprite.visible = false
		return
	if play_idle_fx and fx_sprite.sprite_frames.has_animation("idle_fx"):
		fx_sprite.visible = true
		fx_sprite.play("idle_fx")
	else:
		fx_sprite.visible = false
