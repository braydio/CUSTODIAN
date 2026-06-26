extends SceneTree

const OUT_SCENE := "res://scenes/levels/sundered_keep/sundered_keep_approach_blockout.tscn"
const CAMERA_DIRECTOR_SCRIPT := "res://scripts/levels/sundered_keep/overlook_camera_director.gd"
const OPERATOR_SCENE := "res://game/actors/operator/operator.tscn"

func _init() -> void:
	var root := Node2D.new()
	root.name = "SunderedKeepApproach"

	var underlay_root := Node2D.new()
	underlay_root.name = "UnderlayRoot"
	root.add_child(underlay_root)
	underlay_root.owner = root

	var playable_root := Node2D.new()
	playable_root.name = "PlayableRoot"
	root.add_child(playable_root)
	playable_root.owner = root

	var vista_root := Node2D.new()
	vista_root.name = "VistaRoot"
	root.add_child(vista_root)
	vista_root.owner = root

	var occlusion_root := Node2D.new()
	occlusion_root.name = "OcclusionRoot"
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


func _build_underlay(parent: Node2D, owner: Node) -> void:
	var ocean := _poly(
		"OceanUnderlay",
		PackedVector2Array([
			Vector2(-900, -700),
			Vector2(1200, -700),
			Vector2(1200, 700),
			Vector2(-900, 700),
		]),
		Color(0.03, 0.07, 0.08, 1.0)
	)
	parent.add_child(ocean)
	ocean.owner = owner

	var abyss := _poly(
		"CliffDepthUnderlay",
		PackedVector2Array([
			Vector2(-500, -440),
			Vector2(780, -380),
			Vector2(680, 520),
			Vector2(-420, 560),
		]),
		Color(0.06, 0.055, 0.045, 1.0)
	)
	parent.add_child(abyss)
	abyss.owner = owner

	var fog := _poly(
		"FogUnderlay",
		PackedVector2Array([
			Vector2(-900, -620),
			Vector2(1200, -620),
			Vector2(1200, -260),
			Vector2(-900, -260),
		]),
		Color(0.25, 0.30, 0.32, 0.22)
	)
	parent.add_child(fog)
	fog.owner = owner


func _build_playable(parent: Node2D, owner: Node) -> void:
	var mainland := _poly(
		"MainlandApproachPath",
		PackedVector2Array([
			Vector2(-280, 520),
			Vector2(80, 520),
			Vector2(170, 280),
			Vector2(80, 120),
			Vector2(-140, 120),
			Vector2(-300, 300),
		]),
		Color(0.22, 0.19, 0.12, 1.0)
	)
	parent.add_child(mainland)
	mainland.owner = owner

	var hill := _poly(
		"HillClimbPath",
		PackedVector2Array([
			Vector2(-140, 120),
			Vector2(130, 120),
			Vector2(210, -120),
			Vector2(-190, -120),
		]),
		Color(0.25, 0.22, 0.15, 1.0)
	)
	parent.add_child(hill)
	hill.owner = owner

	var overlook := _poly(
		"OverlookLedge",
		PackedVector2Array([
			Vector2(-260, -120),
			Vector2(280, -120),
			Vector2(320, -320),
			Vector2(-320, -320),
		]),
		Color(0.20, 0.18, 0.13, 1.0)
	)
	parent.add_child(overlook)
	overlook.owner = owner

	var lateral := _poly(
		"LateralTraversePath",
		PackedVector2Array([
			Vector2(260, -260),
			Vector2(780, -260),
			Vector2(780, -80),
			Vector2(300, -80),
		]),
		Color(0.19, 0.17, 0.12, 1.0)
	)
	parent.add_child(lateral)
	lateral.owner = owner

	var wall := _poly(
		"FortressWallMass",
		PackedVector2Array([
			Vector2(650, -420),
			Vector2(1000, -420),
			Vector2(1000, -40),
			Vector2(760, -40),
			Vector2(760, -250),
			Vector2(650, -250),
		]),
		Color(0.13, 0.13, 0.13, 1.0)
	)
	parent.add_child(wall)
	wall.owner = owner

	_add_collision_polygon(parent, owner, "PlayableCollision_Mainland", mainland.polygon, mainland.position)
	_add_collision_polygon(parent, owner, "PlayableCollision_Hill", hill.polygon, hill.position)
	_add_collision_polygon(parent, owner, "PlayableCollision_Overlook", overlook.polygon, overlook.position)
	_add_collision_polygon(parent, owner, "PlayableCollision_Lateral", lateral.polygon, lateral.position)


func _build_vista(parent: Node2D, owner: Node) -> void:
	parent.modulate.a = 0.0

	var sky := _poly(
		"HorizonSky",
		PackedVector2Array([
			Vector2(-900, -700),
			Vector2(1200, -700),
			Vector2(1200, -320),
			Vector2(-900, -320),
		]),
		Color(0.06, 0.075, 0.09, 1.0)
	)
	parent.add_child(sky)
	sky.owner = owner

	var sea := _poly(
		"FarSea",
		PackedVector2Array([
			Vector2(-900, -520),
			Vector2(1200, -520),
			Vector2(1200, -260),
			Vector2(-900, -260),
		]),
		Color(0.025, 0.06, 0.07, 1.0)
	)
	parent.add_child(sea)
	sea.owner = owner

	var keep := _poly(
		"DistantSunderedKeep",
		PackedVector2Array([
			Vector2(-220, -510),
			Vector2(-120, -610),
			Vector2(-20, -560),
			Vector2(40, -670),
			Vector2(130, -550),
			Vector2(260, -500),
			Vector2(280, -420),
			Vector2(-260, -420),
		]),
		Color(0.035, 0.035, 0.04, 1.0)
	)
	parent.add_child(keep)
	keep.owner = owner

	var fog := _poly(
		"VistaFogBand",
		PackedVector2Array([
			Vector2(-900, -380),
			Vector2(1200, -380),
			Vector2(1200, -220),
			Vector2(-900, -220),
		]),
		Color(0.32, 0.36, 0.38, 0.45)
	)
	parent.add_child(fog)
	fog.owner = owner


func _build_occlusion(parent: Node2D, owner: Node) -> void:
	parent.modulate.a = 0.0

	var cliff_wall := _poly(
		"CliffOccluder",
		PackedVector2Array([
			Vector2(520, -420),
			Vector2(1040, -420),
			Vector2(1040, 120),
			Vector2(700, 120),
			Vector2(660, -120),
			Vector2(520, -120),
		]),
		Color(0.045, 0.04, 0.035, 1.0)
	)
	parent.add_child(cliff_wall)
	cliff_wall.owner = owner

	var upper_shadow := _poly(
		"WallShadowOccluder",
		PackedVector2Array([
			Vector2(-900, -360),
			Vector2(1200, -360),
			Vector2(1200, -230),
			Vector2(-900, -230),
		]),
		Color(0.01, 0.01, 0.012, 0.85)
	)
	parent.add_child(upper_shadow)
	upper_shadow.owner = owner


func _build_markers(parent: Node2D, owner: Node) -> void:
	_marker(parent, owner, "MainlandStart", Vector2(-80, 430))
	_marker(parent, owner, "RevealStart", Vector2(-40, 80))
	_marker(parent, owner, "RevealFull", Vector2(0, -250))
	_marker(parent, owner, "TraverseStart", Vector2(260, -180))
	_marker(parent, owner, "TraverseEnd", Vector2(760, -170))
	_marker(parent, owner, "ReturnTopdown", Vector2(720, -80))


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


func _poly(name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.name = name
	p.polygon = points
	p.color = color
	return p


func _marker(parent: Node2D, owner: Node, name: String, pos: Vector2) -> Marker2D:
	var m := Marker2D.new()
	m.name = name
	m.position = pos
	parent.add_child(m)
	m.owner = owner
	return m


func _add_collision_polygon(parent: Node2D, owner: Node, name: String, points: PackedVector2Array, pos: Vector2) -> void:
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
