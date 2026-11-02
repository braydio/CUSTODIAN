class_name PlayableBlackoutTransition
extends Node

const BRIDGE_SCRIPT := preload(
	"res://game/world/routes/transitions/"
	+ "playable_blackout_bridge_2d.gd"
)
const MIST_TEXTURE_PATHS := [
	"res://content/backgrounds/sundered_keep/approach/occlusion/"
	+ "approach_edge_mist_wrap.png",
	"res://content/backgrounds/sundered_keep/grand_vista/atmosphere/"
	+ "grand_vista_edge_spray_wrap.png",
	"res://content/backgrounds/sundered_keep/grand_vista/atmosphere/"
	+ "grand_vista_ocean_spray_overlay.png",
]

var bridge: PlayableBlackoutBridge2D
var _handoff_layer: CanvasLayer
var _handoff_root: Control


func begin_blackout(actor: Node2D, world_parent: Node) -> void:
	bridge = BRIDGE_SCRIPT.new() as PlayableBlackoutBridge2D
	bridge.name = "PlayableBlackoutBridge"
	world_parent.add_child(bridge)
	bridge.begin(actor)


func fade_origin_branches(branch_states: Array, duration: float) -> void:
	var tween := create_tween().set_parallel(true)
	for state_variant: Variant in branch_states:
		if not (state_variant is Dictionary):
			continue
		var branch := (state_variant as Dictionary).get("node") as CanvasItem
		if branch == null or not is_instance_valid(branch):
			continue
		tween.tween_property(branch, "modulate:a", 0.0, duration)
	await tween.finished


func wait_for_bridge_run() -> void:
	if bridge == null:
		return
	while (
		is_instance_valid(bridge)
		and bridge.get_run_progress() < bridge.get_required_run_distance()
	):
		await get_tree().physics_frame


func fade_target_in(target: CanvasItem, duration: float) -> void:
	if target == null:
		return
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 1.0, duration)
	await tween.finished


func finish_blackout() -> void:
	if bridge != null and is_instance_valid(bridge):
		bridge.queue_free()
	bridge = null


func begin_occluded_handoff() -> void:
	_handoff_layer = CanvasLayer.new()
	_handoff_layer.name = "RouteOccludedHandoffLayer"
	_handoff_layer.layer = 9000
	_handoff_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_handoff_layer)
	_handoff_root = Control.new()
	_handoff_root.name = "MistAndSprayCoverage"
	_handoff_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_handoff_root.modulate.a = 0.0
	_handoff_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_handoff_layer.add_child(_handoff_root)
	for index in MIST_TEXTURE_PATHS.size():
		var texture := load(MIST_TEXTURE_PATHS[index]) as Texture2D
		if texture == null:
			continue
		var layer := TextureRect.new()
		layer.name = "HandoffMist%02d" % index
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.texture = texture
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		layer.modulate = Color(0.78, 0.86, 0.92, 0.92)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_handoff_root.add_child(layer)


func fade_handoff_to(alpha: float, duration: float) -> void:
	if _handoff_root == null:
		return
	var tween := create_tween()
	tween.tween_property(
		_handoff_root,
		"modulate:a",
		clampf(alpha, 0.0, 1.0),
		duration
	)
	await tween.finished


func finish_handoff() -> void:
	if _handoff_layer != null and is_instance_valid(_handoff_layer):
		_handoff_layer.queue_free()
	_handoff_layer = null
	_handoff_root = null
