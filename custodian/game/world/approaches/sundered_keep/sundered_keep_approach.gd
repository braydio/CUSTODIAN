extends Node2D
class_name SunderedKeepApproach

const DISTANT_KEEP := "res://content/backgrounds/sundered_keep/distant_sundered_keep.png"

const MAINLAND_APPROACH_PATH := "res://content/sprites/world/return_causeway/path/mainland_approach_path.png"
const HILL_CLIMB_PATH := "res://content/sprites/world/return_causeway/path/hill_climb_path.png"
const OVERLOOK_LEDGE_PATH := "res://content/sprites/world/return_causeway/path/overlook_ledge.png"
const LATERAL_TRAVERSE_PATH := "res://content/sprites/world/return_causeway/path/lateral_traverse_path.png"
const FORTRESS_WALL_MASS_PATH := "res://content/sprites/world/return_causeway/path/fortress_wall_mass.png"

const CLIFF_OCCLUDER_PATH := "res://content/sprites/world/return_causeway/occlusion/cliff_occluder.png"
const WALL_SHADOW_OCCLUDER_PATH := "res://content/sprites/world/return_causeway/occlusion/wall_shadow_occluder.png"
const UNDERLAY_FOG_BAND_PATH := "res://content/sprites/world/return_causeway/underlay/underlay_fog_band.png"

const RECT_MAINLAND_APPROACH := Rect2(Vector2(-300.0, 120.0), Vector2(470.0, 400.0))
const RECT_HILL_CLIMB := Rect2(Vector2(-190.0, -120.0), Vector2(400.0, 240.0))
const RECT_OVERLOOK_LEDGE := Rect2(Vector2(-320.0, -320.0), Vector2(640.0, 200.0))
const RECT_LATERAL_TRAVERSE := Rect2(Vector2(260.0, -260.0), Vector2(520.0, 180.0))
const RECT_FORTRESS_WALL_MASS := Rect2(Vector2(650.0, -420.0), Vector2(350.0, 380.0))
const RECT_CLIFF_OCCLUDER := Rect2(Vector2(520.0, -420.0), Vector2(520.0, 540.0))
const RECT_WALL_SHADOW_OCCLUDER := Rect2(Vector2(-900.0, -360.0), Vector2(2100.0, 130.0))
const RECT_UNDERLAY_FOG := Rect2(Vector2(-900.0, -620.0), Vector2(2100.0, 360.0))
const RECT_DISTANT_KEEP := Rect2(Vector2(-900.0, -720.0), Vector2(2100.0, 480.0))

# Leave this false while tuning the scene. Turn it on only after the visual route
# is stable enough for precise edge collision.
@export var enable_route_blockers := false

var _ingress_config: Dictionary = {}

var entry_spawn: Marker2D = null
var progress_start: Marker2D = null
var progress_end: Marker2D = null

var vista_underlay: Node2D = null
var path_sprites: Node2D = null
var occlusion: Node2D = null
var gameplay: Node2D = null


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	_ensure_roots()
	_build_visuals()
	_build_gameplay()


func configure_ingress(config: Dictionary) -> void:
	_ingress_config = config


func get_entry_position() -> Vector2:
	if entry_spawn != null:
		return entry_spawn.global_position
	return global_position + Vector2(-65.0, 470.0)


func _ensure_roots() -> void:
	entry_spawn = get_node_or_null("EntrySpawn") as Marker2D
	if entry_spawn == null:
		entry_spawn = Marker2D.new()
		entry_spawn.name = "EntrySpawn"
		entry_spawn.position = Vector2(-65.0, 470.0)
		add_child(entry_spawn)

	progress_start = get_node_or_null("ProgressStart") as Marker2D
	if progress_start == null:
		progress_start = Marker2D.new()
		progress_start.name = "ProgressStart"
		progress_start.position = Vector2(-65.0, 470.0)
		add_child(progress_start)

	progress_end = get_node_or_null("ProgressEnd") as Marker2D
	if progress_end == null:
		progress_end = Marker2D.new()
		progress_end.name = "ProgressEnd"
		progress_end.position = Vector2(760.0, -170.0)
		add_child(progress_end)

	vista_underlay = get_node_or_null("VistaUnderlay") as Node2D
	if vista_underlay == null:
		vista_underlay = Node2D.new()
		vista_underlay.name = "VistaUnderlay"
		vista_underlay.z_as_relative = false
		vista_underlay.z_index = -400
		add_child(vista_underlay)

	path_sprites = get_node_or_null("PathSprites") as Node2D
	if path_sprites == null:
		path_sprites = Node2D.new()
		path_sprites.name = "PathSprites"
		path_sprites.z_as_relative = false
		path_sprites.z_index = -80
		add_child(path_sprites)

	occlusion = get_node_or_null("Occlusion") as Node2D
	if occlusion == null:
		occlusion = Node2D.new()
		occlusion.name = "Occlusion"
		occlusion.z_as_relative = false
		occlusion.z_index = 80
		add_child(occlusion)

	gameplay = get_node_or_null("Gameplay") as Node2D
	if gameplay == null:
		gameplay = Node2D.new()
		gameplay.name = "Gameplay"
		gameplay.z_as_relative = false
		gameplay.z_index = 0
		add_child(gameplay)


func _build_visuals() -> void:
	_clear_children(vista_underlay)
	_clear_children(path_sprites)
	_clear_children(occlusion)

	_add_void_backdrop()

	_add_fitted_sprite(
		vista_underlay,
		"DistantKeepProxy",
		DISTANT_KEEP,
		RECT_DISTANT_KEEP,
		-420,
		Color(0.72, 0.78, 0.86, 0.45)
	)

	_add_fitted_sprite(
		vista_underlay,
		"UnderlayFogBand",
		UNDERLAY_FOG_BAND_PATH,
		RECT_UNDERLAY_FOG,
		-390,
		Color(1.0, 1.0, 1.0, 0.28)
	)

	# Ground/path art must stay below the Operator.
	_add_fitted_sprite(
		path_sprites,
		"MainlandApproachPath",
		MAINLAND_APPROACH_PATH,
		RECT_MAINLAND_APPROACH,
		-80,
		Color.WHITE
	)

	_add_fitted_sprite(
		path_sprites,
		"HillClimbPath",
		HILL_CLIMB_PATH,
		RECT_HILL_CLIMB,
		-79,
		Color.WHITE
	)

	_add_fitted_sprite(
		path_sprites,
		"OverlookLedge",
		OVERLOOK_LEDGE_PATH,
		RECT_OVERLOOK_LEDGE,
		-78,
		Color.WHITE
	)

	_add_fitted_sprite(
		path_sprites,
		"LateralTraversePath",
		LATERAL_TRAVERSE_PATH,
		RECT_LATERAL_TRAVERSE,
		-77,
		Color.WHITE
	)

	# Architecture, not walkable ground.
	_add_fitted_sprite(
		path_sprites,
		"FortressWallMass",
		FORTRESS_WALL_MASS_PATH,
		RECT_FORTRESS_WALL_MASS,
		-60,
		Color.WHITE
	)

	# Occluders are visual only and start invisible.
	_add_fitted_sprite(
		occlusion,
		"CliffOccluder",
		CLIFF_OCCLUDER_PATH,
		RECT_CLIFF_OCCLUDER,
		80,
		Color(1.0, 1.0, 1.0, 0.0)
	)

	_add_fitted_sprite(
		occlusion,
		"WallShadowOccluder",
		WALL_SHADOW_OCCLUDER_PATH,
		RECT_WALL_SHADOW_OCCLUDER,
		90,
		Color(1.0, 1.0, 1.0, 0.0)
	)


func _build_gameplay() -> void:
	_clear_children(gameplay)

	var walkable_areas := Node2D.new()
	walkable_areas.name = "WalkableAreas"
	gameplay.add_child(walkable_areas)

	var blockers := Node2D.new()
	blockers.name = "Blockers"
	gameplay.add_child(blockers)

	# These are metadata/debug areas only. They are NOT solid.
	_add_walkable_area_rect(walkable_areas, "MainlandApproachWalkArea", RECT_MAINLAND_APPROACH)
	_add_walkable_area_rect(walkable_areas, "HillClimbWalkArea", RECT_HILL_CLIMB)
	_add_walkable_area_rect(walkable_areas, "OverlookLedgeWalkArea", RECT_OVERLOOK_LEDGE)
	_add_walkable_area_rect(walkable_areas, "LateralTraverseWalkArea", RECT_LATERAL_TRAVERSE)

	if not enable_route_blockers:
		return

	# Only enable these after the art is aligned.
	_add_blocker_rect(blockers, "VoidNorthBlocker", Rect2(Vector2(-1200.0, -820.0), Vector2(2600.0, 180.0)))
	_add_blocker_rect(blockers, "VoidSouthBlocker", Rect2(Vector2(-1200.0, 540.0), Vector2(2600.0, 220.0)))
	_add_blocker_rect(blockers, "VoidWestBlocker", Rect2(Vector2(-1200.0, -820.0), Vector2(780.0, 1580.0)))
	_add_blocker_rect(blockers, "VoidEastBlocker", Rect2(Vector2(1050.0, -820.0), Vector2(350.0, 1580.0)))

	# Do not block the whole fortress mass yet; it overlaps the traverse destination.
	_add_blocker_rect(blockers, "FortressUpperBlocker", Rect2(Vector2(650.0, -420.0), Vector2(350.0, 120.0)))
	_add_blocker_rect(blockers, "FortressRightBlocker", Rect2(Vector2(800.0, -300.0), Vector2(200.0, 260.0)))
	_add_blocker_rect(blockers, "FortressLowerBlocker", Rect2(Vector2(650.0, -60.0), Vector2(350.0, 40.0)))


func _add_void_backdrop() -> void:
	var old := get_node_or_null("ApproachVoidBackdrop")
	if old != null:
		old.queue_free()

	var backdrop := ColorRect.new()
	backdrop.name = "ApproachVoidBackdrop"
	backdrop.color = Color(0.008, 0.011, 0.014, 1.0)
	backdrop.position = Vector2(-1200.0, -820.0)
	backdrop.size = Vector2(2600.0, 1580.0)
	backdrop.z_as_relative = false
	backdrop.z_index = -500
	add_child(backdrop)
	move_child(backdrop, 0)


func _add_fitted_sprite(
	parent: Node,
	node_name: String,
	texture_path: String,
	rect: Rect2,
	z: int,
	tint: Color
) -> Sprite2D:
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("[SunderedKeepApproach] Missing texture: %s" % texture_path)
		return null

	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_as_relative = false
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint

	var tex_size := texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(rect.size.x / tex_size.x, rect.size.y / tex_size.y)

	parent.add_child(sprite)
	return sprite


func _add_walkable_area_rect(parent: Node, node_name: String, rect: Rect2) -> Area2D:
	var area := Area2D.new()
	area.name = node_name

	# Metadata/debug only. This must not collide with the Operator.
	area.collision_layer = 0
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	area.position = rect.position
	area.set_meta("walkable_area", true)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.size * 0.5

	area.add_child(shape)
	parent.add_child(area)
	return area


func _add_blocker_rect(parent: Node, node_name: String, rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = rect.position

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.size * 0.5

	body.add_child(shape)
	parent.add_child(body)
	return body


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.queue_free()
