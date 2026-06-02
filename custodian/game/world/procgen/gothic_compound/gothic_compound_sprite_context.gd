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
	for layer_name in ["TerrainLayer", "RoadLayer", "WallLayer", "PropLayer", "DecalLayer", "MarkerLayer"]:
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
	for layer_name in ["TerrainLayer", "RoadLayer", "WallLayer", "PropLayer", "DecalLayer", "MarkerLayer"]:
		_get_layer(layer_name)


func _get_layer(layer_name: String) -> Node2D:
	if _layers.has(layer_name) and is_instance_valid(_layers[layer_name]):
		return _layers[layer_name]
	var layer := get_node_or_null(NodePath(layer_name)) as Node2D
	if layer == null:
		layer = Node2D.new()
		layer.name = layer_name
		add_child(layer)
	_layers[layer_name] = layer
	return layer


func spawn_asset(cell: Vector2i, def: Dictionary) -> Sprite2D:
	var parent := _layer_for_kind(str(def.get("kind", "prop")))
	var sprite := Sprite2D.new()
	var footprint: Vector2i = def.get("footprint", Vector2i.ONE)
	var asset_path := str(def.get("path", ""))
	sprite.name = _unique_node_name(cell, def)
	sprite.texture = load(asset_path) as Texture2D if ResourceLoader.exists(asset_path) else null
	sprite.centered = false
	sprite.position = grid_to_world(cell)
	sprite.z_as_relative = false
	sprite.z_index = int(def.get("z", 0))
	sprite.set_meta("origin_cell", cell)
	sprite.set_meta("footprint", footprint)
	sprite.set_meta("asset_path", asset_path)
	parent.add_child(sprite)
	var blocks_cells := bool(def.get("blocks", false))
	_register_occupancy(cell, footprint, blocks_cells)
	if blocks_cells:
		_add_collision_rect(sprite, footprint)
	if bool(def.get("depth_sort", false)) or str(def.get("kind", "prop")) == "prop":
		_register_depth_sorted_asset(sprite, cell, footprint, def)
	return sprite


func update_depth_sort(actor: Node2D) -> void:
	if actor == null:
		return
	var actor_pos := actor.global_position
	for entry in _depth_sorted_assets:
		var sprite := entry.get("node") as Sprite2D
		if sprite == null or not is_instance_valid(sprite):
			continue
		var footprint: Vector2i = entry.get("footprint", Vector2i.ONE)
		var horizon_ratio := float(entry.get("horizon_ratio", 0.75))
		var horizon_y := sprite.global_position.y + float(footprint.y * tile_size) * horizon_ratio
		sprite.z_index = int(entry.get("front_z", 1)) if actor_pos.y > horizon_y else int(entry.get("behind_z", 40))


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


func _register_occupancy(origin: Vector2i, footprint: Vector2i, blocks_cells: bool) -> void:
	if not blocks_cells:
		return
	for y in range(origin.y, origin.y + footprint.y):
		for x in range(origin.x, origin.x + footprint.x):
			mark_blocked(Vector2i(x, y), true)


func _register_depth_sorted_asset(sprite: Sprite2D, origin: Vector2i, footprint: Vector2i, def: Dictionary) -> void:
	_depth_sorted_assets.append({
		"node": sprite,
		"origin": origin,
		"footprint": footprint,
		"front_z": int(def.get("front_z", 1)),
		"behind_z": int(def.get("behind_z", int(def.get("z", 40)))),
		"horizon_ratio": float(def.get("horizon_ratio", 0.75)),
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
## The parent Sprite2D uses top-left anchoring (sprite.centered = false,
## positioned at grid_to_world(origin_cell)). The collision body must be
## offset by rect.size * 0.5 so its world-space center aligns with the
## footprint center.
func _add_collision_rect(parent: Node2D, size: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.name = "Collision"
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(float(size.x * tile_size), float(size.y * tile_size))
	shape.shape = rect
	body.position = rect.size * 0.5
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
