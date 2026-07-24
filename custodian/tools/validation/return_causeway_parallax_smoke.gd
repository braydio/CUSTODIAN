extends SceneTree

const RETURN_CAUSEWAY_SCENE := preload("res://game/world/sundered_keep/return_causeway/ReturnCausewayApproach.tscn")
const DISTANT_KEEP_TEXTURE_PATH := "res://content/backgrounds/sundered_keep/distant_sundered_keep.png"
const REQUIRED_LAYER_PATHS := [
	"BaseDepth/DistantKeep_Parallax2D",
	"BaseDepth/FarCliffIslands_Parallax2D",
	"RevealDepth/CausewayFarArches_Parallax2D",
	"BaseDepth/LowerCliffDepth_Parallax2D",
	"BaseDepth/OceanMist_Parallax2D",
	"ForegroundDepth/NearEdgeMist_Parallax2D",
	"ForegroundDepth/ForegroundRuinedArch_Parallax2D",
]


func _init() -> void:
	var scene := RETURN_CAUSEWAY_SCENE.instantiate()
	if scene == null:
		_fail("Could not instantiate ReturnCausewayApproach")
		return

	root.add_child(scene)
	await process_frame

	var parallax_root := scene.get_node_or_null("ParallaxRoot")
	if parallax_root == null:
		_fail("Missing ParallaxRoot")
		return

	for layer_path: String in REQUIRED_LAYER_PATHS:
		if parallax_root.get_node_or_null(layer_path) == null:
			_fail("Missing parallax layer: %s" % layer_path)
			return

	var distant_layer := parallax_root.get_node_or_null(
		"BaseDepth/DistantKeep_Parallax2D"
	) as Parallax2D
	if distant_layer == null:
		_fail("Missing DistantKeep_Parallax2D")
		return
	if distant_layer.scroll_scale != Vector2(0.18, 0.12):
		_fail("Unexpected distant keep scroll_scale: %s" % distant_layer.scroll_scale)
		return

	var keep_sprite := distant_layer.get_node_or_null("DistantSunderedKeepLandmark") as Sprite2D
	if keep_sprite == null:
		_fail("Missing DistantSunderedKeepLandmark Sprite2D")
		return
	if keep_sprite.texture == null:
		_fail("Distant keep sprite has no texture")
		return
	if keep_sprite.texture.resource_path != DISTANT_KEEP_TEXTURE_PATH:
		_fail("Unexpected distant keep texture: %s" % keep_sprite.texture.resource_path)
		return
	if keep_sprite.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
		_fail("Distant keep texture_filter is not linear")
		return

	if _contains_collision_or_navigation(parallax_root):
		_fail("ParallaxRoot contains collision/navigation nodes")
		return

	root.remove_child(scene)
	scene.free()
	await process_frame

	print("[ReturnCausewayParallaxSmoke] PASS")
	quit(0)


func _contains_collision_or_navigation(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is NavigationRegion2D:
		return true
	for child in node.get_children():
		if _contains_collision_or_navigation(child):
			return true
	return false


func _fail(message: String) -> void:
	push_error("[ReturnCausewayParallaxSmoke] %s" % message)
	quit(1)
