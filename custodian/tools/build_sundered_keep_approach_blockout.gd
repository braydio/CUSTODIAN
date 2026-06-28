extends SceneTree

const OUT_SCENE := "res://scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn"
const CAMERA_DIRECTOR_SCRIPT := "res://scripts/levels/sundered_keep/overlook_camera_director.gd"
const OPERATOR_SCENE := "res://game/actors/operator/operator.tscn"

const BG := "res://content/backgrounds/sundered_keep/"

func _init() -> void:
	var root := Node2D.new()
	root.name = "SunderedKeepApproach"

	var underlay_root := Node2D.new()
	underlay_root.name = "UnderlayRoot"
	_set_absolute_z(underlay_root, -300)
	root.add_child(underlay_root)
	underlay_root.owner = root

	var playable_root := Node2D.new()
	playable_root.name = "PlayableRoot"
	_set_absolute_z(playable_root, 0)
	root.add_child(playable_root)
	playable_root.owner = root

	var vista_root := Node2D.new()
	vista_root.name = "VistaRoot"
	_set_absolute_z(vista_root, -200)
	root.add_child(vista_root)
	vista_root.owner = root

	var occlusion_root := Node2D.new()
	occlusion_root.name = "OcclusionRoot"
	_set_absolute_z(occlusion_root, 100)
	root.add_child(occlusion_root)
	occlusion_root.owner = root

	var markers := Node2D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.owner = root

	_build_underlay(underlay_root, root)
	_build_playable(playable_root, root)
	_build_vista(vista_root, root)
	_build_occlusion(occlusion_root, root)
	_build_markers(markers, root)

	var operator_packed := load(OPERATOR_SCENE) as PackedScene
	if operator_packed:
		var op := operator_packed.instantiate() as Node2D
		op.name = "Operator"
		op.position = markers.get_node("MainlandStart").position
		_set_absolute_z(op, 50)
		root.add_child(op)
		op.owner = root

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, 120)
	camera.zoom = Vector2(1.0, 1.0)
	camera.enabled = true
	root.add_child(camera)
	camera.owner = root

	var director := Node.new()
	director.name = "OverlookCameraDirector"
	var script := load(CAMERA_DIRECTOR_SCRIPT)
	if script:
		director.set_script(script)
	root.add_child(director)
	director.owner = root

	_wire_director(director, root)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Failed to pack scene: %s" % err)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/levels/sundered_keep"))
	err = ResourceSaver.save(packed, OUT_SCENE)

	if err != OK:
		push_error("Failed to save scene: %s" % err)
		quit(1)
		return

	print("Generated: %s" % OUT_SCENE)
	quit()


# ---------------------------------------------------------------------------
# UnderlayRoot — always-visible ocean, cliff depth, atmospheric fog
# ---------------------------------------------------------------------------
func _build_underlay(parent: Node2D, owner: Node) -> void:
	_sprite_rect(parent, owner, "OceanUnderlay",
		BG + "ocean_underlay.png",
		Rect2(-900, -700, 2100, 1400), 0)

	_sprite_rect(parent, owner, "CliffDepthUnderlay",
		BG + "cliff_depth_underlay.png",
		Rect2(-500, -440, 520, 540), 1)

	_sprite_rect(parent, owner, "FogUnderlay",
		BG + "approach/playable/underlay_fog_band.png",
		Rect2(-900, -620, 2172, 724), 2)


# ---------------------------------------------------------------------------
# PlayableRoot — walkable path Sprite2D + collision StaticBody2D polygons
# ---------------------------------------------------------------------------
func _build_playable(parent: Node2D, owner: Node) -> void:
	# Visual path sprites — replace old Polygon2D placeholders with authored art
	_sprite_rect(parent, owner, "MainlandApproachPath",
		BG + "approach/playable/mainland_approach_path.png",
		Rect2(-300, 120, 470, 400), 0)

	_sprite_rect(parent, owner, "HillClimbPath",
		BG + "approach/playable/hill_climb_path.png",
		Rect2(-190, -120, 400, 240), 1)

	_sprite_rect(parent, owner, "OverlookLedge",
		BG + "approach/playable/overlook_ledge.png",
		Rect2(-320, -320, 640, 240), 2)

	_sprite_rect(parent, owner, "LateralTraversePath",
		BG + "approach/playable/lateral_traverse_path.png",
		Rect2(260, -260, 520, 180), 3)

	# FortressWallMass — authored art exists (360×380)
	_sprite_rect(parent, owner, "FortressWallMass",
		BG + "approach/playable/fortress_wall_mass.png",
		Rect2(650, -420, 360, 380), 10)

	# Collision polygons — unchanged from original, kept as StaticBody2D only
	_add_collision_polygon(parent, owner, "PlayableCollision_Mainland",
		PackedVector2Array([
			Vector2(-280, 520), Vector2(80, 520), Vector2(170, 280),
			Vector2(80, 120), Vector2(-140, 120), Vector2(-300, 300),
		]), Vector2.ZERO)

	_add_collision_polygon(parent, owner, "PlayableCollision_Hill",
		PackedVector2Array([
			Vector2(-140, 120), Vector2(130, 120), Vector2(210, -120), Vector2(-190, -120),
		]), Vector2.ZERO)

	_add_collision_polygon(parent, owner, "PlayableCollision_Overlook",
		PackedVector2Array([
			Vector2(-260, -120), Vector2(280, -120), Vector2(320, -320), Vector2(-320, -320),
		]), Vector2.ZERO)

	_add_collision_polygon(parent, owner, "PlayableCollision_Lateral",
		PackedVector2Array([
			Vector2(260, -260), Vector2(780, -260), Vector2(780, -80), Vector2(300, -80),
		]), Vector2.ZERO)


# ---------------------------------------------------------------------------
# VistaRoot — horizon layers, alpha-faded by director.modulate
# ---------------------------------------------------------------------------
func _build_vista(parent: Node2D, owner: Node) -> void:
	parent.modulate.a = 0.0

	_sprite_rect(parent, owner, "HorizonSky",
		BG + "horizon_sky.png",
		Rect2(-900, -700, 2100, 380), 0)

	_sprite_rect(parent, owner, "FarSea",
		BG + "far_sea.png",
		Rect2(-900, -520, 2100, 260), 1)

	_sprite_rect(parent, owner, "DistantSunderedKeep",
		BG + "distant_sundered_keep.png",
		Rect2(-260, -670, 540, 250), 2)

	_sprite_rect(parent, owner, "VistaFogBand",
		BG + "vista_fog_band.png",
		Rect2(-900, -380, 2100, 160), 3)


# ---------------------------------------------------------------------------
# OcclusionRoot — cliff/wall blockers, alpha-faded by director.modulate
# ---------------------------------------------------------------------------
func _build_occlusion(parent: Node2D, owner: Node) -> void:
	parent.modulate.a = 0.0

	_sprite_rect(parent, owner, "CliffOccluder",
		BG + "approach/playable/cliff_occluder.png",
		Rect2(520, -420, 520, 540), 0)

	_sprite_rect(parent, owner, "WallShadowOccluder",
		BG + "approach/playable/wall_shadow_occluder.png",
		Rect2(-900, -360, 2100, 130), 1)


# ---------------------------------------------------------------------------
# Markers — Marker2D waypoints for the camera director
# ---------------------------------------------------------------------------
func _build_markers(parent: Node2D, owner: Node) -> void:
	_marker(parent, owner, "MainlandStart", Vector2(-80, 430))
	_marker(parent, owner, "RevealStart", Vector2(-40, 80))
	_marker(parent, owner, "RevealFull", Vector2(0, -250))
	_marker(parent, owner, "TraverseStart", Vector2(260, -180))
	_marker(parent, owner, "TraverseEnd", Vector2(760, -170))
	_marker(parent, owner, "ReturnTopdown", Vector2(720, -80))


# ---------------------------------------------------------------------------
# Director wiring — connects exports to scene nodes
# ---------------------------------------------------------------------------
func _wire_director(director: Node, root: Node2D) -> void:
	var markers := root.get_node("Markers")

	director.set("camera", root.get_node("Camera2D"))
	director.set("reveal_start_marker", markers.get_node("RevealStart"))
	director.set("reveal_full_marker", markers.get_node("RevealFull"))
	director.set("traverse_start_marker", markers.get_node("TraverseStart"))
	director.set("traverse_end_marker", markers.get_node("TraverseEnd"))
	director.set("return_topdown_marker", markers.get_node("ReturnTopdown"))

	director.set("vista_root", root.get_node("VistaRoot"))
	director.set("occlusion_root", root.get_node("OcclusionRoot"))
	director.set("fog_band", root.get_node("VistaRoot/VistaFogBand"))

	director.set("player", root.get_node("Operator"))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _sprite_rect(
	parent: Node2D, owner: Node,
	name: String, texture_path: String,
	rect: Rect2, z_index := 0
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_index = z_index

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_warning("[SunderedKeepApproach] Missing texture for %s: %s" % [name, texture_path])
	else:
		sprite.texture = texture
		var actual := Vector2i(texture.get_width(), texture.get_height())
		var expected := Vector2i(int(rect.size.x), int(rect.size.y))
		if actual != expected:
			push_warning("[SunderedKeepApproach] Size mismatch for %s: expected %s, actual %s" \
				% [name, str(expected), str(actual)])

	parent.add_child(sprite)
	sprite.owner = owner
	return sprite


func _set_absolute_z(node: CanvasItem, z_index: int) -> void:
	node.z_index = z_index
	node.z_as_relative = false


func _marker(parent: Node2D, owner: Node, name: String, pos: Vector2) -> Marker2D:
	var m := Marker2D.new()
	m.name = name
	m.position = pos
	parent.add_child(m)
	m.owner = owner
	return m


func _add_collision_polygon(
	parent: Node2D, owner: Node,
	name: String, points: PackedVector2Array, pos: Vector2
) -> void:
	var body := StaticBody2D.new()
	body.name = name
	body.position = pos

	var collision := CollisionPolygon2D.new()
	collision.name = "CollisionPolygon2D"
	collision.polygon = points
	collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS

	body.add_child(collision)
	parent.add_child(body)

	body.owner = owner
	collision.owner = owner
