extends Node2D
class_name GothicCompoundSpriteContext

@export var tile_size: int = 32
@export var map_size: Vector2i = Vector2i(80, 60)
@export var world_seed: int = 12345

var blocked: Dictionary = {}
var reserved: Dictionary = {}
var walkable: Dictionary = {}
var _layers: Dictionary = {}
var _spawn_sequence: int = 0
var _depth_sorted_assets: Array[Dictionary] = []


func _ready() -> void:
	_ensure_layers()


func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x * tile_size), float(cell.y * tile_size))


func clear_cell(cell: Vector2i) -> void:
	blocked.erase(cell)
	walkable.erase(cell)
	for layer_name in ["TerrainLayer", "RoadLayer", "WallLayer", "DepthSortLayer", "PropLayer", "DecalLayer", "MarkerLayer"]:
		var layer := _get_layer(layer_name)
		var node_name := _cell_node_name(cell)
		var child := layer.get_node_or_null(NodePath(node_name))
		if child != null:
			child.queue_free()
		for layer_child in layer.get_children():
			if layer_child.has_meta("origin_cell") and layer_child.get_meta("origin_cell") == cell:
				layer_child.queue_free()
	_prune_depth_sorted_assets()


func reserve_cell(cell: Vector2i) -> void:
	reserved[cell] = true


func is_reserved(cell: Vector2i) -> bool:
	return reserved.has(cell)


func is_blocked(cell: Vector2i) -> bool:
	return bool(blocked.get(cell, false))


func mark_blocked(cell: Vector2i, value: bool = true) -> void:
	if value:
		blocked[cell] = true
	else:
		blocked.erase(cell)


func mark_walkable(cell: Vector2i, value: bool = true) -> void:
	if value:
		walkable[cell] = true
	else:
		walkable.erase(cell)


func is_walkable(cell: Vector2i) -> bool:
	return bool(walkable.get(cell, false))


func set_floor(cell: Vector2i, asset) -> void:
	spawn_asset(cell, _coerce_asset_def(asset, "tile", false, 0))
	mark_walkable(cell, true)


func set_road(cell: Vector2i, asset) -> void:
	spawn_asset(cell, _coerce_asset_def(asset, "road", false, 4))
	mark_walkable(cell, true)
	mark_blocked(cell, false)


func set_wall(cell: Vector2i, asset, blocks_cell: bool = true) -> void:
	var def := _coerce_asset_def(asset, "wall", blocks_cell, 20)
	def["blocks"] = blocks_cell
	spawn_asset(cell, def)
	if blocks_cell:
		mark_blocked(cell, true)


func set_decal(cell: Vector2i, asset) -> void:
	spawn_asset(cell, _coerce_asset_def(asset, "decal", false, 8))


func spawn_prop(cell: Vector2i, asset, blocks_cells: bool = false, size: Vector2i = Vector2i.ONE) -> void:
	var def := _coerce_asset_def(asset, "prop", blocks_cells, 30)
	def["blocks"] = blocks_cells
	def["footprint"] = size
	spawn_asset(cell, def)


func spawn_prop_def(cell: Vector2i, def: Dictionary) -> void:
	spawn_asset(cell, def)


func set_decal_def(cell: Vector2i, def: Dictionary) -> void:
	spawn_asset(cell, def)


func spawn_marker(cell: Vector2i, asset, marker_type: String) -> void:
	var sprite := spawn_asset(cell, _coerce_asset_def(asset, "marker", false, 40))
	sprite.visible = false
	sprite.set_meta("marker_type", marker_type)


func _ensure_layers() -> void:
	for layer_name in ["TerrainLayer", "RoadLayer", "WallLayer", "DepthSortLayer", "PropLayer", "DecalLayer", "MarkerLayer"]:
		var layer := _get_layer(layer_name)
		if layer_name == "DepthSortLayer":
			layer.y_sort_enabled = true


func _get_layer(layer_name: String) -> Node2D:
	if _layers.has(layer_name) and is_instance_valid(_layers[layer_name]):
		return _layers[layer_name]
	var layer := get_node_or_null(NodePath(layer_name)) as Node2D
	if layer == null:
		layer = Node2D.new()
		layer.name = layer_name
		add_child(layer)
	if layer_name == "DepthSortLayer":
		layer.y_sort_enabled = true
	_layers[layer_name] = layer
	return layer


func spawn_asset(cell: Vector2i, def: Dictionary) -> Node2D:
	var dynamic_occluder := _is_dynamic_occluder(def)
	var parent := _get_layer("DepthSortLayer") if dynamic_occluder else _layer_for_kind(str(def.get("kind", "prop")))
	var sprite := Sprite2D.new()
	var footprint: Vector2i = def.get("footprint", Vector2i.ONE)
	var asset_path := str(def.get("path", ""))
	sprite.name = "Visual"
	sprite.texture = load(asset_path) as Texture2D if ResourceLoader.exists(asset_path) else null
	sprite.centered = false
	var root := _build_spawn_root(cell, def, footprint, dynamic_occluder)
	root.z_as_relative = false
	root.z_index = int(def.get("z", 0))
	root.set_meta("origin_cell", cell)
	root.set_meta("footprint", footprint)
	root.set_meta("asset_path", asset_path)
	parent.add_child(root)
	if dynamic_occluder:
		sprite.position = -_base_sort_offset(footprint, def)
		root.add_child(sprite)
	else:
		sprite.position = Vector2.ZERO
		root.add_child(sprite)
	var blocks_cells := bool(def.get("blocks", false))
	_register_occupancy(cell, footprint, blocks_cells)
	if blocks_cells:
		_add_collision_rect(root, footprint, dynamic_occluder, def)
	if dynamic_occluder:
		_register_depth_sorted_asset(root, cell, footprint, def)
	return root


func update_depth_sort(actor: Node2D) -> void:
	if actor == null:
		return
	var actor_pos := actor.global_position
	for entry in _depth_sorted_assets:
		var node := entry.get("node") as Node2D
		if node == null or not is_instance_valid(node):
			continue
		var sort_y := node.global_position.y + float(entry.get("sort_y_offset", 0.0))
		node.z_index = int(entry.get("behind_operator_z", 1)) if actor_pos.y > sort_y else int(entry.get("in_front_of_operator_z", 40))


func _layer_for_kind(kind: String) -> Node2D:
	match kind:
		"tile":
			return _get_layer("TerrainLayer")
		"road":
			return _get_layer("RoadLayer")
		"wall":
			return _get_layer("WallLayer")
		"decal":
			return _get_layer("DecalLayer")
		"marker":
			return _get_layer("MarkerLayer")
		_:
			return _get_layer("PropLayer")


func _build_spawn_root(cell: Vector2i, def: Dictionary, footprint: Vector2i, dynamic_occluder: bool) -> Node2D:
	var root := Node2D.new()
	root.name = _unique_node_name(cell, def)
	root.position = grid_to_world(cell)
	if dynamic_occluder:
		root.position += _base_sort_offset(footprint, def)
	return root


func _base_sort_offset(footprint: Vector2i, def: Dictionary) -> Vector2:
	var offset := Vector2(0.0, float(footprint.y * tile_size))
	if def.has("base_sort_offset"):
		var custom_offset: Variant = def.get("base_sort_offset")
		if custom_offset is Vector2:
			offset = custom_offset
	return offset


func _is_dynamic_occluder(def: Dictionary) -> bool:
	var kind := str(def.get("kind", "prop"))
	if kind == "tile" or kind == "road" or kind == "decal" or kind == "marker":
		return false
	if bool(def.get("depth_sort", false)):
		return true
	if kind == "wall":
		return true
	return kind == "prop" and int(def.get("z", 0)) >= 0


func _register_occupancy(origin: Vector2i, footprint: Vector2i, blocks_cells: bool) -> void:
	if not blocks_cells:
		return
	for y in range(origin.y, origin.y + footprint.y):
		for x in range(origin.x, origin.x + footprint.x):
			mark_blocked(Vector2i(x, y), true)


func _register_depth_sorted_asset(node: Node2D, origin: Vector2i, footprint: Vector2i, def: Dictionary) -> void:
	_depth_sorted_assets.append({
		"node": node,
		"origin": origin,
		"footprint": footprint,
		"behind_operator_z": int(def.get("front_z", 1)),
		"in_front_of_operator_z": int(def.get("behind_z", int(def.get("z", 40)))),
		"sort_y_offset": float(def.get("sort_y_offset", 0.0)),
		"x_padding": float(def.get("x_padding", float(tile_size))),
	})


func _prune_depth_sorted_assets() -> void:
	var live_assets: Array[Dictionary] = []
	for entry in _depth_sorted_assets:
		var node := entry.get("node") as Node
		if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
			live_assets.append(entry)
	_depth_sorted_assets = live_assets


## Adds a StaticBody2D collision rectangle centered on the asset footprint.
## Flat assets use top-left roots. Dynamic occluders use roots at their
## base/sort line, so their lower physical footprint is offset upward.
func _add_collision_rect(parent: Node2D, size: Vector2i, base_rooted: bool = false, def: Dictionary = {}) -> void:
	var body := StaticBody2D.new()
	body.name = "Collision"
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(float(size.x * tile_size), float(size.y * tile_size))
	shape.shape = rect
	body.position = rect.size * 0.5
	if base_rooted:
		body.position -= _base_sort_offset(size, def)
	body.add_child(shape)
	parent.add_child(body)


func _coerce_asset_def(asset, kind: String, blocks_cells: bool, z: int) -> Dictionary:
	if asset is Dictionary:
		return (asset as Dictionary).duplicate(true)
	return {
		"path": str(asset),
		"kind": kind,
		"footprint": Vector2i.ONE,
		"blocks": blocks_cells,
		"z": z,
	}


func _unique_node_name(cell: Vector2i, def: Dictionary) -> String:
	var path := str(def.get("path", "asset"))
	var base := path.get_file().get_basename()
	_spawn_sequence += 1
	return "%s_%d_%d_%d" % [base, cell.x, cell.y, _spawn_sequence]


func _cell_node_name(cell: Vector2i) -> String:
	return "Cell_%d_%d" % [cell.x, cell.y]
