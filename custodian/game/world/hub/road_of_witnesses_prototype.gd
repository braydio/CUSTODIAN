extends Node2D
class_name RoadOfWitnessesPrototype

const FOLIAGE_OCCLUSION_SHADER := preload("res://game/world/procgen/foliage_occlusion_bubble.gdshader")

const MAP_TEXTURE_PATH := "res://content/levels/hub/Road_of_Witnesses_Tilemap.png"
const PLAYER_PATH := ^"/root/GameRoot/World/Operator"
const CAMERA_PATH := ^"/root/GameRoot/World/Camera2D"

const OCCLUSION_Z_INDEX := 4
const OCCLUSION_RADIUS := 72.0
const OCCLUSION_SOFTNESS := 10.0
const OCCLUSION_ALPHA := 0.45

const BLOCKER_RECTS := [
	Rect2(-627.0, -627.0, 80.0, 1254.0),
	Rect2(547.0, -627.0, 80.0, 1254.0),
	Rect2(-627.0, -627.0, 1254.0, 92.0),
	Rect2(-627.0, 535.0, 1254.0, 92.0),
	Rect2(-486.0, -408.0, 222.0, 236.0),
	Rect2(270.0, -420.0, 232.0, 248.0),
	Rect2(-512.0, -126.0, 152.0, 224.0),
	Rect2(360.0, -102.0, 166.0, 210.0),
	Rect2(-542.0, 252.0, 254.0, 252.0),
	Rect2(300.0, 246.0, 250.0, 244.0),
	Rect2(-90.0, -502.0, 180.0, 58.0),
	Rect2(-304.0, -402.0, 72.0, 202.0),
	Rect2(232.0, -402.0, 72.0, 202.0),
	Rect2(-144.0, -238.0, 58.0, 92.0),
	Rect2(88.0, -238.0, 58.0, 92.0),
	Rect2(-136.0, 4.0, 58.0, 92.0),
	Rect2(84.0, 4.0, 58.0, 92.0),
	Rect2(-126.0, 246.0, 58.0, 92.0),
	Rect2(84.0, 246.0, 58.0, 92.0),
	Rect2(-114.0, 462.0, 58.0, 92.0),
	Rect2(74.0, 462.0, 58.0, 92.0),
]

const OCCLUSION_REGIONS := [
	{
		"name": "ForumWallsFront",
		"region": Rect2(154.0, 0.0, 946.0, 496.0),
		"threshold_y": -252.0,
	},
	{
		"name": "LeftLowerFront",
		"region": Rect2(0.0, 830.0, 350.0, 424.0),
		"threshold_y": 258.0,
	},
	{
		"name": "RightLowerFront",
		"region": Rect2(906.0, 794.0, 348.0, 460.0),
		"threshold_y": 246.0,
	},
]

@onready var background: Sprite2D = $Background
@onready var collision_root: StaticBody2D = $CollisionRoot
@onready var occlusion_root: Node2D = $ForegroundOcclusion

var _map_texture: Texture2D = null
var _player: Node2D = null
var _occlusion_sprites: Array[Dictionary] = []
var _map_bounds := Rect2()


func _ready() -> void:
	_map_texture = load(MAP_TEXTURE_PATH) as Texture2D
	if _map_texture == null:
		push_error("RoadOfWitnessesPrototype: failed to load %s" % MAP_TEXTURE_PATH)
		return
	background.texture = _map_texture
	background.centered = true
	background.position = Vector2.ZERO
	_map_bounds = Rect2(-_map_texture.get_size() * 0.5, _map_texture.get_size())
	_build_collision()
	_build_occlusion()
	_player = get_node_or_null(PLAYER_PATH) as Node2D
	call_deferred("_apply_camera_bounds")


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_node_or_null(PLAYER_PATH) as Node2D
		if _player == null:
			return
	_update_occlusion()


func _build_collision() -> void:
	for child in collision_root.get_children():
		child.queue_free()
	for rect in BLOCKER_RECTS:
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		shape.position = rect.position + rect.size * 0.5
		collision_root.add_child(shape)


func _build_occlusion() -> void:
	for child in occlusion_root.get_children():
		child.queue_free()
	_occlusion_sprites.clear()
	var texture_size := _map_texture.get_size()
	var top_left := -texture_size * 0.5
	for entry in OCCLUSION_REGIONS:
		var region: Rect2 = entry.region
		var sprite := Sprite2D.new()
		sprite.name = String(entry.name)
		sprite.texture = _map_texture
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = region
		sprite.position = top_left + region.position
		sprite.z_index = OCCLUSION_Z_INDEX
		sprite.visible = false
		var material := ShaderMaterial.new()
		material.shader = FOLIAGE_OCCLUSION_SHADER
		material.set_shader_parameter("bubble_enabled", true)
		material.set_shader_parameter("bubble_radius", OCCLUSION_RADIUS)
		material.set_shader_parameter("bubble_softness", OCCLUSION_SOFTNESS)
		material.set_shader_parameter("bubble_alpha", OCCLUSION_ALPHA)
		sprite.material = material
		occlusion_root.add_child(sprite)
		_occlusion_sprites.append({
			"sprite": sprite,
			"threshold_y": float(entry.threshold_y),
		})


func _update_occlusion() -> void:
	var player_pos := _player.global_position
	for entry in _occlusion_sprites:
		var sprite := entry.get("sprite") as Sprite2D
		if sprite == null:
			continue
		var is_behind := player_pos.y <= float(entry.get("threshold_y", 0.0))
		sprite.visible = is_behind
		var material := sprite.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("bubble_enabled", is_behind)
			material.set_shader_parameter("bubble_center", player_pos)


func _apply_camera_bounds() -> void:
	var camera := get_node_or_null(CAMERA_PATH)
	if camera == null:
		return
	camera.set("map_bounds", _map_bounds)
