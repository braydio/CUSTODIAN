extends SceneTree

const VISTA_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const RETURN_SCENE := preload(
	"res://game/world/sundered_keep/return_causeway/ReturnCausewayApproach.tscn"
)

const REQUIRED_TEXTURE_PATHS := [
	"res://content/backgrounds/sundered_keep/approach/parallax/far_cliff_islands.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/lower_cliff_depth.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/causeway_far_arches.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/ocean_mist_strip_left.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/ocean_mist_strip_right.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/near_edge_mist_left.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/near_edge_mist_right.png",
	"res://content/backgrounds/sundered_keep/approach/parallax/foreground_ruined_arch.png",
]

const VISTA_LAYERS := {}

const RETURN_LAYERS := {
	"BaseDepth/DistantKeep_Parallax2D": Vector2(0.18, 0.12),
}

const REVIEW_BLOCKED_LAYERS := [
	"BaseDepth/FarCliffIslands_Parallax2D",
	"RevealDepth/CausewayFarArches_Parallax2D",
	"BaseDepth/LowerCliffDepth_Parallax2D",
	"BaseDepth/OceanMist_Parallax2D",
	"ForegroundDepth/NearEdgeMist_Parallax2D",
	"ForegroundDepth/ForegroundRuinedArch_Parallax2D",
]


func _init() -> void:
	var errors: Array[String] = []
	for texture_path: String in REQUIRED_TEXTURE_PATHS:
		if not ResourceLoader.exists(texture_path):
			errors.append("Missing required texture: %s" % texture_path)

	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)

	var vista := VISTA_SCENE.instantiate()
	var return_causeway := RETURN_SCENE.instantiate()
	root.add_child(vista)
	root.add_child(return_causeway)
	await process_frame
	await process_frame

	_check_rig(vista, "Vista", VISTA_LAYERS, errors)
	_check_rig(
		return_causeway,
		"Return Causeway",
		RETURN_LAYERS,
		errors
	)

	if errors.is_empty():
		print("[SunderedKeepParallaxDepthSmoke] PASS")
		quit(0)
		return

	for error in errors:
		push_error("[SunderedKeepParallaxDepthSmoke] %s" % error)
	quit(1)


func _check_rig(
	scene: Node,
	label: String,
	expected_layers: Dictionary,
	errors: Array[String]
) -> void:
	var parallax_root := scene.get_node_or_null("ParallaxRoot")
	if parallax_root == null:
		errors.append("%s ParallaxRoot missing" % label)
		return

	var review_state: Variant = parallax_root.call(
		"get_layer_review_state"
	)
	if not review_state is Dictionary:
		errors.append("%s layer review state missing" % label)
	else:
		var review := review_state as Dictionary
		for layer_name: String in review:
			if bool(review[layer_name]):
				errors.append(
					"%s review-blocked layer enabled: %s"
					% [label, layer_name]
				)

	for group_name in ["BaseDepth", "RevealDepth", "ForegroundDepth"]:
		if parallax_root.get_node_or_null(group_name) == null:
			errors.append("%s ParallaxRoot/%s missing" % [label, group_name])

	var reveal_root := parallax_root.get_node_or_null("RevealDepth") as CanvasItem
	var foreground_root := (
		parallax_root.get_node_or_null("ForegroundDepth")
		as CanvasItem
	)
	var expected_reveal_alpha := 0.0 if label == "Vista" else 1.0
	var expected_foreground_alpha := 0.55 if label == "Vista" else 1.0
	if (
		reveal_root != null
		and not is_equal_approx(
			reveal_root.modulate.a,
			expected_reveal_alpha
		)
	):
		errors.append(
			"%s reveal alpha expected %s, got %s"
			% [label, expected_reveal_alpha, reveal_root.modulate.a]
		)
	if (
		foreground_root != null
		and not is_equal_approx(
			foreground_root.modulate.a,
			expected_foreground_alpha
		)
	):
		errors.append(
			"%s foreground alpha expected %s, got %s"
			% [label, expected_foreground_alpha, foreground_root.modulate.a]
		)

	for layer_path: String in expected_layers:
		var layer := parallax_root.get_node_or_null(layer_path) as Parallax2D
		if layer == null:
			errors.append("%s missing Parallax2D %s" % [label, layer_path])
			continue
		var expected_scale := expected_layers[layer_path] as Vector2
		if not layer.scroll_scale.is_equal_approx(expected_scale):
			errors.append(
				"%s %s scroll_scale expected %s, got %s"
				% [label, layer_path, expected_scale, layer.scroll_scale]
			)
		if layer.repeat_size != Vector2.ZERO:
			errors.append("%s %s must keep repeat_size disabled" % [label, layer_path])
		_check_layer_sprites(layer, "%s %s" % [label, layer_path], errors)

	for layer_path: String in REVIEW_BLOCKED_LAYERS:
		if parallax_root.get_node_or_null(layer_path) != null:
			errors.append(
				"%s review-blocked layer was built: %s"
				% [label, layer_path]
			)

	_check_presentation_only(parallax_root, label, errors)


func _check_layer_sprites(
	layer: Parallax2D,
	label: String,
	errors: Array[String]
) -> void:
	var sprite_count := 0
	for child in layer.get_children():
		if not (child is Sprite2D):
			continue
		sprite_count += 1
		var sprite := child as Sprite2D
		if sprite.texture == null:
			errors.append("%s/%s has no texture" % [label, sprite.name])
		if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
			errors.append("%s/%s must use linear filtering" % [label, sprite.name])
	if sprite_count == 0:
		errors.append("%s has no painterly sprites" % label)


func _check_presentation_only(
	node: Node,
	label: String,
	errors: Array[String]
) -> void:
	if (
		node is CollisionObject2D
		or node is CollisionShape2D
		or node is CollisionPolygon2D
		or node is NavigationRegion2D
	):
		errors.append("%s ParallaxRoot contains gameplay node %s" % [label, node.get_path()])
	for child in node.get_children():
		_check_presentation_only(child, label, errors)
