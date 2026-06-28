extends Node2D
class_name SunderedKeepApproach

const PATH_MAINLAND := "res://content/sprites/world/return_causeway/path/mainland_approach_path.png"
const PATH_HILL := "res://content/sprites/world/return_causeway/path/hill_climb_path.png"
const PATH_OVERLOOK := "res://content/sprites/world/return_causeway/path/overlook_ledge.png"
const PATH_TRAVERSE := "res://content/sprites/world/return_causeway/path/lateral_traverse_path.png"
const PATH_WALL_MASS := "res://content/sprites/world/return_causeway/path/fortress_wall_mass.png"

const OCCLUDER_CLIFF := "res://content/sprites/world/return_causeway/occlusion/cliff_occluder.png"
const OCCLUDER_SHADOW := "res://content/sprites/world/return_causeway/occlusion/wall_shadow_occluder.png"
const FOG_BAND := "res://content/sprites/world/return_causeway/underlay/underlay_fog_band.png"
const DISTANT_KEEP := "res://content/backgrounds/sundered_keep/distant_sundered_keep.png"

var _ingress_config: Dictionary = {}
var _entry_spawn: Marker2D = null
var _path_sprites: Node2D = null
var _vista_underlay: Node2D = null
var _occlusion: Node2D = null


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")
	_ensure_scene_roots()
	_build_approach_visuals()
	_refresh_vista_controller()


func configure_ingress(config: Dictionary) -> void:
	_ingress_config = config.duplicate(true)

	var trigger := get_node_or_null("ExitTransitionTrigger")
	if trigger != null:
		if config.has("target_scene_path"):
			trigger.set("target_scene_path", String(config["target_scene_path"]))
		if config.has("target_spawn_id"):
			trigger.set("target_spawn_id", config["target_spawn_id"])
		if config.has("return_world_position"):
			trigger.set("return_world_position", config["return_world_position"])


func get_entry_position() -> Vector2:
	if _entry_spawn != null:
		return _entry_spawn.global_position
	return global_position + Vector2(-240.0, 420.0)


func get_ingress_config() -> Dictionary:
	return _ingress_config.duplicate(true)


func _ensure_scene_roots() -> void:
	_entry_spawn = get_node_or_null("EntrySpawn") as Marker2D
	if _entry_spawn == null:
		_entry_spawn = Marker2D.new()
		_entry_spawn.name = "EntrySpawn"
		add_child(_entry_spawn)
	_entry_spawn.position = Vector2(-240.0, 420.0)

	_path_sprites = get_node_or_null("PathSprites") as Node2D
	if _path_sprites == null:
		_path_sprites = Node2D.new()
		_path_sprites.name = "PathSprites"
		add_child(_path_sprites)
	_path_sprites.z_as_relative = false
	_path_sprites.z_index = 0

	_vista_underlay = get_node_or_null("VistaUnderlay") as Node2D
	if _vista_underlay == null:
		_vista_underlay = Node2D.new()
		_vista_underlay.name = "VistaUnderlay"
		add_child(_vista_underlay)
	_vista_underlay.z_as_relative = false
	_vista_underlay.z_index = -300

	_occlusion = get_node_or_null("Occlusion") as Node2D
	if _occlusion == null:
		_occlusion = Node2D.new()
		_occlusion.name = "Occlusion"
		add_child(_occlusion)
	_occlusion.z_as_relative = false
	_occlusion.z_index = 120


func _build_approach_visuals() -> void:
	_add_void_backdrop()

	_add_fitted_sprite(
		_vista_underlay,
		"DistantKeepProxy",
		DISTANT_KEEP,
		Rect2(Vector2(-900.0, -680.0), Vector2(2100.0, 420.0)),
		-340,
		Color(0.72, 0.78, 0.86, 0.45)
	)
	_add_fitted_sprite(
		_vista_underlay,
		"UnderlayFogBand",
		FOG_BAND,
		Rect2(Vector2(-900.0, -620.0), Vector2(2100.0, 360.0)),
		-280,
		Color(1.0, 1.0, 1.0, 0.28)
	)

	_add_fitted_sprite(
		_path_sprites,
		"MainlandApproachPath",
		PATH_MAINLAND,
		Rect2(Vector2(-300.0, 120.0), Vector2(470.0, 400.0)),
		0,
		Color.WHITE
	)
	_add_fitted_sprite(
		_path_sprites,
		"HillClimbPath",
		PATH_HILL,
		Rect2(Vector2(-190.0, -120.0), Vector2(400.0, 240.0)),
		1,
		Color.WHITE
	)
	_add_fitted_sprite(
		_path_sprites,
		"OverlookLedge",
		PATH_OVERLOOK,
		Rect2(Vector2(-320.0, -320.0), Vector2(640.0, 200.0)),
		2,
		Color.WHITE
	)
	_add_fitted_sprite(
		_path_sprites,
		"LateralTraversePath",
		PATH_TRAVERSE,
		Rect2(Vector2(260.0, -260.0), Vector2(520.0, 180.0)),
		3,
		Color.WHITE
	)
	_add_fitted_sprite(
		_path_sprites,
		"FortressWallMass",
		PATH_WALL_MASS,
		Rect2(Vector2(650.0, -420.0), Vector2(350.0, 380.0)),
		30,
		Color.WHITE
	)

	_add_fitted_sprite(
		_occlusion,
		"CliffOccluder",
		OCCLUDER_CLIFF,
		Rect2(Vector2(520.0, -420.0), Vector2(520.0, 540.0)),
		120,
		Color(1.0, 1.0, 1.0, 0.0)
	)
	_add_fitted_sprite(
		_occlusion,
		"WallShadowOccluder",
		OCCLUDER_SHADOW,
		Rect2(Vector2(-900.0, -360.0), Vector2(2100.0, 130.0)),
		130,
		Color(1.0, 1.0, 1.0, 0.0)
	)


func _add_void_backdrop() -> void:
	var backdrop := get_node_or_null("ApproachVoidBackdrop") as ColorRect
	if backdrop == null:
		backdrop = ColorRect.new()
		backdrop.name = "ApproachVoidBackdrop"
		add_child(backdrop)
		move_child(backdrop, 0)
	backdrop.color = Color(0.008, 0.011, 0.014, 1.0)
	backdrop.position = Vector2(-1200.0, -760.0)
	backdrop.size = Vector2(2600.0, 1500.0)
	backdrop.z_as_relative = false
	backdrop.z_index = -500


func _add_fitted_sprite(
	parent: Node,
	node_name: String,
	texture_path: String,
	rect: Rect2,
	z: int,
	tint: Color
) -> Sprite2D:
	if parent == null:
		return null
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("[SunderedKeepApproach] Missing texture: %s" % texture_path)
		return null

	var sprite := parent.get_node_or_null(node_name) as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = node_name
		parent.add_child(sprite)

	sprite.texture = texture
	sprite.centered = false
	sprite.position = rect.position
	sprite.z_as_relative = false
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint

	var tex_size := texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(
			rect.size.x / tex_size.x,
			rect.size.y / tex_size.y
		)
	return sprite


func _refresh_vista_controller() -> void:
	var controller := get_node_or_null("VistaController")
	if controller == null:
		return
	if controller.has_method("refresh_bindings"):
		controller.call("refresh_bindings")
	if controller.has_method("apply_progress"):
		controller.call("apply_progress", 0.0)
