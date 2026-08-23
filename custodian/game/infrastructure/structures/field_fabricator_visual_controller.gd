class_name FieldFabricatorVisualController
extends Node

const RUNTIME_ROOT := "res://content/sprites/environment/props/field_fabricator_mk1/runtime"
const FRAME_SIZE := Vector2i(96, 96)

@export_node_path("AnimatedSprite2D") var body_path: NodePath = NodePath("../Body")
@export_node_path("AnimatedSprite2D") var fx_path: NodePath = NodePath("../FX")
@export_node_path("Node") var power_consumer_path: NodePath = NodePath("../PowerConsumer")

@onready var body: AnimatedSprite2D = get_node_or_null(body_path)
@onready var fx: AnimatedSprite2D = get_node_or_null(fx_path)
@onready var power_consumer: Node = get_node_or_null(power_consumer_path)

var _body_frames: Dictionary = {}
var _fx_frames: Dictionary = {}
var _active_state: StringName = &"idle"

func _ready() -> void:
	_build_available_frames()
	if power_consumer != null and power_consumer.has_signal("allocation_changed"):
		power_consumer.allocation_changed.connect(_on_allocation_changed)
	play_state(&"idle")

func play_state(state: StringName) -> void:
	var resolved := _resolve_state(state, _body_frames)
	if body != null and resolved != &"":
		body.sprite_frames = _body_frames[resolved]
		body.animation = resolved
		body.play()
		_active_state = state
	var fx_resolved := _resolve_state(state, _fx_frames)
	if fx != null and fx_resolved != &"":
		fx.sprite_frames = _fx_frames[fx_resolved]
		fx.animation = fx_resolved
		fx.visible = true
		fx.play()
	elif fx != null:
		fx.stop()
		fx.visible = false

func play_fabricate() -> void:
	play_state(&"fabricate")

func play_fabricate_complete() -> void:
	play_state(&"fabricate_complete")
	if body != null and body.sprite_frames != null:
		body.animation_finished.connect(_on_one_shot_finished.bind(&"idle"), CONNECT_ONE_SHOT)

func _on_one_shot_finished(state: StringName) -> void:
	play_state(state)

func _on_allocation_changed(_allocated: float, power_tier: StringName, _effective_output: float) -> void:
	if power_tier == &"offline":
		play_state(&"offline")
	else:
		play_state(&"startup")

func _resolve_state(requested: StringName, available: Dictionary) -> StringName:
	if available.has(requested): return requested
	if requested == &"startup" or requested == &"offline" or requested == &"fabricate_complete":
		return &"idle" if available.has(&"idle") else &""
	return &"idle" if available.has(&"idle") else ""

func _build_available_frames() -> void:
	var states := [&"idle", &"startup", &"fabricate", &"fabricate_complete", &"offline"]
	for state in states:
		var body_path_value := "%s/body/interaction/field_fabricator_mk1__body__interaction__%s__omni__8f__96.png" % [RUNTIME_ROOT, state]
		var body_resource := _load_frames(body_path_value, state)
		if body_resource != null: _body_frames[state] = body_resource
		var fx_path_value := "%s/fx/interaction/field_fabricator_mk1__fx__interaction__%s__omni__8f__96.png" % [RUNTIME_ROOT, state]
		var fx_resource := _load_frames(fx_path_value, state)
		if fx_resource != null: _fx_frames[state] = fx_resource

func _load_frames(path: String, state: StringName) -> SpriteFrames:
	if not ResourceLoader.exists(path): return null
	var texture := load(path) as Texture2D
	if texture == null or texture.get_width() != 768 or texture.get_height() != 96: return null
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(state)
	frames.set_animation_speed(state, 8.0 if state == &"fabricate" else 6.0)
	frames.set_animation_loop(state, state == &"idle" or state == &"fabricate" or state == &"offline")
	for index in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(state, atlas)
	return frames
