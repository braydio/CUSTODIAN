class_name FieldFabricatorVisualController
extends Node

const FRAME_SIZE := Vector2i(156, 156)
const FRAME_COUNT := 8
const BODY_PATHS := {
	&"idle": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/body/interaction/field_fabricator_mk1__body__interaction__idle__omni__8f__156.png",
	&"startup": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/body/interaction/field_fabricator_mk1__body__interaction__startup__omni__8f__156.png",
	&"fabricate": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/body/interaction/field_fabricator_mk1__body__interaction__fabricate__omni__8f__156.png",
	&"fabricate_complete": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/body/interaction/field_fabricator_mk1__body__interaction__fabricate_complete__omni__8f__156.png",
	&"offline": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/body/interaction/field_fabricator_mk1__body__interaction__offline__omni__8f__156.png",
}
const FX_PATHS := {
	&"idle": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/fx/interaction/field_fabricator_mk1__fx__interaction__idle__omni__8f__156.png",
	&"startup": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/fx/interaction/field_fabricator_mk1__fx__interaction__startup__omni__8f__156.png",
	&"fabricate": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/fx/interaction/field_fabricator_mk1__fx__interaction__fabricate__omni__8f__156.png",
	&"fabricate_complete": "res://content/sprites/environment/props/field_fabricator_mk1/runtime/fx/interaction/field_fabricator_mk1__fx__interaction__fabricate_complete__omni__8f__156.png",
}
const STATE_FPS := {&"idle": 6.0, &"startup": 9.0, &"fabricate": 8.0, &"fabricate_complete": 9.0, &"offline": 6.0}

@export_node_path("AnimatedSprite2D") var body_path := NodePath("../Body")
@export_node_path("AnimatedSprite2D") var fx_path := NodePath("../FX")
@export_node_path("Node") var power_consumer_path := NodePath("../PowerConsumer")

@onready var body: AnimatedSprite2D = get_node_or_null(body_path)
@onready var fx: AnimatedSprite2D = get_node_or_null(fx_path)
@onready var power_consumer: Node = get_node_or_null(power_consumer_path)

var _body_frames: Dictionary = {}
var _fx_frames: Dictionary = {}
var _active_state := &"offline"
var _service_output := 0.0
var _destroyed := false


func _ready() -> void:
	_build_available_frames()
	if body != null:
		body.animation_finished.connect(_on_body_animation_finished)
	if power_consumer != null and power_consumer.has_signal("allocation_changed"):
		power_consumer.allocation_changed.connect(_on_allocation_changed)
		_service_output = float(power_consumer.get("effective_output"))
	var structure := get_parent()
	if structure != null:
		if structure.has_signal("structure_destroyed"):
			structure.structure_destroyed.connect(_on_structure_destroyed)
		if structure.has_signal("integrity_changed"):
			structure.integrity_changed.connect(_on_integrity_changed)
	var pipeline := _get_fab_pipeline()
	if pipeline != null:
		pipeline.job_started.connect(_on_job_started)
		pipeline.job_completed.connect(_on_job_completed)
	play_state(&"offline" if _service_output <= 0.0 else &"startup")


func play_state(state: StringName) -> void:
	if state == _active_state and state in [&"idle", &"fabricate", &"offline"] \
	and body != null and body.is_playing():
		return
	var resolved_body := _resolve_body_state(state)
	if body != null and not resolved_body.is_empty():
		body.sprite_frames = _body_frames[resolved_body]
		body.animation = resolved_body
		body.play()
	_active_state = state
	if fx == null:
		return
	if _fx_frames.has(state):
		fx.sprite_frames = _fx_frames[state]
		fx.animation = state
		fx.visible = true
		fx.play()
	else:
		fx.stop()
		fx.visible = false


func play_fabricate() -> void:
	play_state(&"fabricate")


func play_fabricate_complete() -> void:
	play_state(&"fabricate_complete")


func get_active_state() -> StringName:
	return _active_state


func _on_body_animation_finished() -> void:
	if _active_state in [&"startup", &"fabricate_complete"]:
		_sync_activity_state()


func _on_allocation_changed(_allocated: float, power_tier: StringName, effective_output: float) -> void:
	var was_powered := _service_output > 0.0
	_service_output = maxf(0.0, effective_output)
	if power_tier == &"offline" or _service_output <= 0.0:
		play_state(&"offline")
	elif not was_powered or _active_state == &"offline":
		play_state(&"startup")


func _on_job_started(_job_id: int, _recipe_id: String) -> void:
	if _service_output > 0.0 and _active_state not in [&"startup", &"fabricate_complete"]:
		_sync_activity_state()


func _on_job_completed(_job_id: int, _recipe_id: String, _output_type: String, _output_id: String, _output_amount: int) -> void:
	if _service_output > 0.0 and not _destroyed:
		play_state(&"fabricate_complete")


func _on_integrity_changed(_current: float, _maximum: float) -> void:
	if get_parent() != null and get_parent().has_method("is_dead"):
		_destroyed = bool(get_parent().call("is_dead"))
	if _destroyed:
		play_state(&"offline")


func _on_structure_destroyed() -> void:
	_destroyed = true
	_service_output = 0.0
	play_state(&"offline")


func _sync_activity_state() -> void:
	if _destroyed or _service_output <= 0.0:
		play_state(&"offline")
		return
	var pipeline := _get_fab_pipeline()
	var jobs: Array = pipeline.call("get_jobs_snapshot") if pipeline != null else []
	play_state(&"fabricate" if not jobs.is_empty() else &"idle")


func _get_fab_pipeline() -> Node:
	return get_node_or_null("/root/FabPipeline")


func _resolve_body_state(requested: StringName) -> StringName:
	if _body_frames.has(requested):
		return requested
	return &"idle" if _body_frames.has(&"idle") else &""


func _build_available_frames() -> void:
	for state in BODY_PATHS:
		var frames := _load_frames(String(BODY_PATHS[state]), state)
		if frames != null:
			_body_frames[state] = frames
	for state in FX_PATHS:
		var frames := _load_frames(String(FX_PATHS[state]), state)
		if frames != null:
			_fx_frames[state] = frames


func _load_frames(path: String, state: StringName) -> SpriteFrames:
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if texture == null or texture.get_size() != Vector2(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y):
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(state)
	frames.set_animation_speed(state, float(STATE_FPS.get(state, 6.0)))
	frames.set_animation_loop(state, state in [&"idle", &"fabricate", &"offline"])
	for index in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(state, atlas)
	return frames
