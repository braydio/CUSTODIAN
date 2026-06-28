extends SceneTree

const APPROACH_SCENE_PATH := "res://scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn"
const CAMERA_DIRECTOR_SCRIPT := "res://scripts/levels/sundered_keep/overlook_camera_director.gd"

# Expected Sprite2D nodes per root (name → expected texture path fragment)
const UNDERLAY_SPRITES := {
	OceanUnderlay = "ocean_underlay.png",
	CliffDepthUnderlay = "cliff_depth_underlay.png",
	FogUnderlay = "underlay_fog_band.png",
}

const PLAYABLE_SPRITES := {
	MainlandApproachPath = "mainland_approach_path.png",
	HillClimbPath = "hill_climb_path.png",
	OverlookLedge = "overlook_ledge.png",
	LateralTraversePath = "lateral_traverse_path.png",
	FortressWallMass = "fortress_wall_mass.png",
}

const VISTA_SPRITES := {
	HorizonSky = "horizon_sky.png",
	FarSea = "far_sea.png",
	DistantSunderedKeep = "distant_sundered_keep.png",
	VistaFogBand = "vista_fog_band.png",
}

const OCCLUSION_SPRITES := {
	CliffOccluder = "cliff_occluder.png",
	WallShadowOccluder = "wall_shadow_occluder.png",
}

const EXPECTED_SPRITE_RECTS := {
	"UnderlayRoot/OceanUnderlay": Rect2(-900, -700, 2100, 1400),
	"UnderlayRoot/CliffDepthUnderlay": Rect2(-500, -440, 520, 540),
	"UnderlayRoot/FogUnderlay": Rect2(-900, -620, 2172, 724),
	"PlayableRoot/MainlandApproachPath": Rect2(-300, 120, 470, 400),
	"PlayableRoot/HillClimbPath": Rect2(-190, -120, 400, 240),
	"PlayableRoot/OverlookLedge": Rect2(-320, -320, 640, 240),
	"PlayableRoot/LateralTraversePath": Rect2(260, -260, 520, 180),
	"PlayableRoot/FortressWallMass": Rect2(650, -420, 360, 380),
	"VistaRoot/HorizonSky": Rect2(-900, -700, 2100, 380),
	"VistaRoot/FarSea": Rect2(-900, -520, 2100, 260),
	"VistaRoot/DistantSunderedKeep": Rect2(-260, -670, 540, 250),
	"VistaRoot/VistaFogBand": Rect2(-900, -380, 2100, 160),
	"OcclusionRoot/CliffOccluder": Rect2(520, -420, 520, 540),
	"OcclusionRoot/WallShadowOccluder": Rect2(-900, -360, 2100, 130),
}

const MARKER_NAMES := ["MainlandStart", "RevealStart", "RevealFull", "TraverseStart", "TraverseEnd", "ReturnTopdown"]

const COLLISION_BODIES := ["PlayableCollision_Mainland", "PlayableCollision_Hill", "PlayableCollision_Overlook", "PlayableCollision_Lateral"]

const ROOT_Z_ORDER := {
	UnderlayRoot = -300,
	VistaRoot = -200,
	PlayableRoot = 0,
	OcclusionRoot = 100,
}


func _init() -> void:
	# Load and instantiate the packed scene
	var packed := load(APPROACH_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load approach scene: %s" % APPROACH_SCENE_PATH)
		return

	var scene := packed.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate approach scene")
		return

	root.add_child(scene)
	await process_frame

	var errors: Array[String] = []

	# --- Check all Sprite2D nodes in UnderlayRoot ---
	_check_sprite_root(scene, "UnderlayRoot", UNDERLAY_SPRITES, errors)
	# --- Check all Sprite2D nodes in PlayableRoot ---
	_check_sprite_root(scene, "PlayableRoot", PLAYABLE_SPRITES, errors)
	# --- Check all Sprite2D nodes in VistaRoot ---
	_check_sprite_root(scene, "VistaRoot", VISTA_SPRITES, errors)
	# --- Check all Sprite2D nodes in OcclusionRoot ---
	_check_sprite_root(scene, "OcclusionRoot", OCCLUSION_SPRITES, errors)

	# --- Check absolute root render ordering ---
	for root_name: String in ROOT_Z_ORDER:
		_check_absolute_z(scene, root_name, ROOT_Z_ORDER[root_name] as int, errors)
		_check_no_polygon2d(scene.get_node_or_null(root_name), root_name, errors)

	# --- Check VistaRoot starts with alpha 0.0 ---
	var vista_root := scene.get_node_or_null("VistaRoot") as Node2D
	if vista_root == null:
		errors.append("VistaRoot missing")
	elif vista_root.modulate.a != 0.0:
		errors.append("VistaRoot.modulate.a expected 0.0, got %s" % vista_root.modulate.a)

	# --- Check OcclusionRoot starts with alpha 0.0 ---
	var occlusion_root := scene.get_node_or_null("OcclusionRoot") as Node2D
	if occlusion_root == null:
		errors.append("OcclusionRoot missing")
	elif occlusion_root.modulate.a != 0.0:
		errors.append("OcclusionRoot.modulate.a expected 0.0, got %s" % occlusion_root.modulate.a)

	# --- Check Operator exists (position may shift due to internal scene offset) ---
	var operator := scene.get_node_or_null("Operator")
	if operator == null:
		errors.append("Operator node missing")
	elif operator is CanvasItem:
		_check_absolute_z(scene, "Operator", 50, errors)

	# --- Check Camera exists ---
	var camera := scene.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		errors.append("Camera2D missing")
	elif not camera.enabled:
		errors.append("Camera2D not enabled")

	# --- Check Markers exist ---
	for marker_name: String in MARKER_NAMES:
		var marker := scene.get_node_or_null("Markers/%s" % marker_name) as Marker2D
		if marker == null:
			errors.append("Marker %s missing or not a Marker2D" % marker_name)

	# --- Check Collision bodies exist with CollisionPolygon2D children ---
	for body_name: String in COLLISION_BODIES:
		var body := scene.get_node_or_null("PlayableRoot/%s" % body_name) as StaticBody2D
		if body == null:
			errors.append("StaticBody2D %s missing" % body_name)
			continue
		var col := body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if col == null:
			errors.append("%s missing CollisionPolygon2D child" % body_name)
		elif col.polygon.size() < 3:
			errors.append("%s collision polygon has <3 vertices" % body_name)

	# --- Check CameraDirector exists with wired exports ---
	var director := scene.get_node_or_null("OverlookCameraDirector")
	if director == null:
		errors.append("OverlookCameraDirector missing")
	else:
		var director_script: Script = director.get_script()
		if director_script == null or director_script.resource_path != CAMERA_DIRECTOR_SCRIPT:
			errors.append("OverlookCameraDirector has wrong script: %s" % (director_script.resource_path if director_script else "null"))

		# Check wired exports
		var checks := {
			player = "Operator",
			camera = "Camera2D",
			reveal_start_marker = "Markers/RevealStart",
			reveal_full_marker = "Markers/RevealFull",
			traverse_start_marker = "Markers/TraverseStart",
			traverse_end_marker = "Markers/TraverseEnd",
			return_topdown_marker = "Markers/ReturnTopdown",
			vista_root = "VistaRoot",
			occlusion_root = "OcclusionRoot",
			fog_band = "VistaRoot/VistaFogBand",
		}
		for export_name: String in checks:
			var expected_path := checks[export_name] as String
			var exported: Variant = director.get(export_name)
			if exported == null:
				errors.append("Director export '%s' is null, expected %s" % [export_name, expected_path])

		if operator is Node2D and camera != null and vista_root != null and occlusion_root != null:
			_check_director_alpha_path(director, operator as Node2D, vista_root, occlusion_root, errors)

	# --- Report ---
	if errors.is_empty():
		print("[SunderedKeepApproachRenderSmoke] PASS")
		quit(0)
	else:
		for err in errors:
			push_error("[SunderedKeepApproachRenderSmoke] %s" % err)
		_fail("%d checks failed" % errors.size())


func _check_sprite_root(parent: Node, root_name: String, expected: Dictionary, errors: Array[String]) -> void:
	var root_node := parent.get_node_or_null(root_name) as Node2D
	if root_node == null:
		errors.append("%s root missing" % root_name)
		return

	for sprite_name: String in expected:
		var texture_fragment := expected[sprite_name] as String
		var node := root_node.get_node_or_null(sprite_name) as Sprite2D
		if node == null:
			errors.append("%s/%s missing or not Sprite2D" % [root_name, sprite_name])
			continue
		if node.texture == null:
			errors.append("%s/%s has null texture" % [root_name, sprite_name])
			continue
		if not node.texture.resource_path.contains(texture_fragment):
			errors.append("%s/%s texture path does not contain '%s': %s" \
				% [root_name, sprite_name, texture_fragment, node.texture.resource_path])
		_check_sprite_render_rect("%s/%s" % [root_name, sprite_name], node, errors)


func _check_sprite_render_rect(sprite_path: String, sprite: Sprite2D, errors: Array[String]) -> void:
	if not EXPECTED_SPRITE_RECTS.has(sprite_path):
		errors.append("%s has no expected render Rect2 in smoke table" % sprite_path)
		return
	var expected := EXPECTED_SPRITE_RECTS[sprite_path] as Rect2
	if not _vec2_nearly_equal(sprite.position, expected.position):
		errors.append("%s.position expected %s, got %s" % [sprite_path, expected.position, sprite.position])
	if sprite.texture == null:
		errors.append("%s has null texture during render-rect check" % sprite_path)
		return
	var actual_size := Vector2(
		float(sprite.texture.get_width()) * sprite.scale.x,
		float(sprite.texture.get_height()) * sprite.scale.y
	)
	if not _vec2_nearly_equal(actual_size, expected.size):
		errors.append("%s rendered size expected %s, got %s from texture=%sx%s scale=%s" % [
			sprite_path,
			expected.size,
			actual_size,
			sprite.texture.get_width(),
			sprite.texture.get_height(),
			sprite.scale,
		])


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon


func _check_absolute_z(parent: Node, node_path: String, expected_z: int, errors: Array[String]) -> void:
	var node := parent.get_node_or_null(node_path) as CanvasItem
	if node == null:
		errors.append("%s missing or not CanvasItem" % node_path)
		return
	if node.z_index != expected_z:
		errors.append("%s.z_index expected %d, got %d" % [node_path, expected_z, node.z_index])
	if node.z_as_relative:
		errors.append("%s.z_as_relative expected false" % node_path)


func _check_no_polygon2d(node: Node, label: String, errors: Array[String]) -> void:
	if node == null:
		return
	for child: Node in node.get_children():
		if child is Polygon2D:
			errors.append("%s contains visual Polygon2D child: %s" % [label, child.name])
		_check_no_polygon2d(child, "%s/%s" % [label, child.name], errors)


func _check_director_alpha_path(
	director: Node,
	operator: Node2D,
	vista_root: CanvasItem,
	occlusion_root: CanvasItem,
	errors: Array[String]
) -> void:
	operator.global_position = Vector2(0, -250)
	director.call("_process", 1.0)
	if vista_root.modulate.a < 0.95:
		errors.append("Director reveal did not fade vista in; alpha=%s" % vista_root.modulate.a)

	operator.global_position = Vector2(520, -180)
	director.call("_process", 1.0)
	if occlusion_root.modulate.a <= 0.0:
		errors.append("Director traverse did not begin occlusion fade; alpha=%s" % occlusion_root.modulate.a)
	if vista_root.modulate.a > 0.6:
		errors.append("Director traverse did not reduce vista alpha; alpha=%s" % vista_root.modulate.a)

	operator.global_position = Vector2(760, -80)
	director.call("_process", 1.0)
	if vista_root.modulate.a > 0.05:
		errors.append("Director return did not fade vista back out; alpha=%s" % vista_root.modulate.a)


func _fail(message: String) -> void:
	push_error("[SunderedKeepApproachRenderSmoke] %s" % message)
	quit(1)
