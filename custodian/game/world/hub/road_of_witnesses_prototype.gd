extends Node2D
class_name RoadOfWitnessesPrototype

const PLAYER_PATH := ^"/root/GameRoot/World/Operator"
const CAMERA_PATH := ^"/root/GameRoot/World/Camera2D"
const OCCLUSION_Z_INDEX := 4

const SOUTH_BOUNDARY_RECT := Rect2(-627.0, 535.0, 1254.0, 92.0)

const BLOCKER_RECTS := [
	Rect2(-627.0, -627.0, 80.0, 1254.0),
	Rect2(547.0, -627.0, 80.0, 1254.0),
	Rect2(-627.0, -627.0, 1254.0, 92.0),
	SOUTH_BOUNDARY_RECT,
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

const MODULES := [
	{"id": &"south_reach_civic_axis", "position": Vector2(0, 34), "size": Vector2(768, 896)},
	{"id": &"witness_plaza", "position": Vector2(0, -862), "size": Vector2(896, 896)},
	{"id": &"collapsed_chapel_court", "position": Vector2(-832, -862), "size": Vector2(768, 896)},
	{"id": &"archive_ruin_west", "position": Vector2(-832, -1820), "size": Vector2(896, 896)},
	{"id": &"overgrown_reliquary_east", "position": Vector2(832, -862), "size": Vector2(896, 896)},
]

## The Road owns camera bounds only when it is the whole world. Instanced as a
## translated zone inside a larger scene, the host owns them instead.
@export var apply_camera_bounds := true
## Width of the gap cut in the southern boundary wall, in local space. Zero keeps
## the map sealed; a positive value opens the causeway so the Road can be joined
## to walkable space to its south.
@export var south_gate_gap_width := 0.0
@export var south_gate_gap_center_x := -6.0

@onready var collision_root: StaticBody2D = $CollisionRoot
@onready var environment_root: Node2D = $EnvironmentModules

var _player: Node2D = null
var _map_bounds := Rect2()


func _ready() -> void:
	_build_modules()
	_build_collision()
	_player = get_node_or_null(PLAYER_PATH) as Node2D
	call_deferred("_apply_camera_bounds")


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_node_or_null(PLAYER_PATH) as Node2D


func _build_modules() -> void:
	for child in environment_root.get_children():
		child.queue_free()
	_map_bounds = Rect2()
	var first := true
	for spec in MODULES:
		var module := Node2D.new()
		module.name = String(spec.id).capitalize()
		module.position = spec.position
		environment_root.add_child(module)
		var underlay := Sprite2D.new()
		underlay.name = "Underlay"
		underlay.texture = load("res://content/levels/hub/road_of_witnesses/%s/road_of_witnesses_%s_underlay_%dx%d.png" % [spec.id, spec.id, int(spec.size.x), int(spec.size.y)])
		underlay.centered = true
		underlay.z_index = 0
		module.add_child(underlay)
		var foreground := Sprite2D.new()
		foreground.name = "Foreground"
		foreground.texture = load("res://content/levels/hub/road_of_witnesses/%s/road_of_witnesses_%s_foreground_%dx%d.png" % [spec.id, spec.id, int(spec.size.x), int(spec.size.y)])
		foreground.centered = true
		foreground.z_index = OCCLUSION_Z_INDEX
		module.add_child(foreground)
		var bounds := Rect2(spec.position - spec.size * 0.5, spec.size)
		_map_bounds = bounds if first else _map_bounds.merge(bounds)
		first = false


## Blocker geometry in Road-local space, with the optional southern causeway gap
## applied. Static so a host scene can reason about the same collision without
## copying these rects.
static func build_blocker_rects(gap_center_x := 0.0, gap_width := 0.0) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in BLOCKER_RECTS:
		if gap_width <= 0.0 or rect != SOUTH_BOUNDARY_RECT:
			result.append(rect)
			continue
		var gap_min := gap_center_x - gap_width * 0.5
		var gap_max := gap_center_x + gap_width * 0.5
		if gap_min > rect.position.x:
			result.append(Rect2(rect.position, Vector2(gap_min - rect.position.x, rect.size.y)))
		if gap_max < rect.end.x:
			result.append(Rect2(Vector2(gap_max, rect.position.y), Vector2(rect.end.x - gap_max, rect.size.y)))
	return result


func _build_collision() -> void:
	for child in collision_root.get_children():
		child.queue_free()
	for rect in build_blocker_rects(south_gate_gap_center_x, south_gate_gap_width):
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		shape.position = rect.position + rect.size * 0.5
		collision_root.add_child(shape)


func _apply_camera_bounds() -> void:
	if not apply_camera_bounds:
		return
	var camera := get_node_or_null(CAMERA_PATH)
	if camera == null:
		return
	camera.set("map_bounds", _map_bounds)
