class_name CompoundVerticalEntryController
extends Node

## Consumes a layered compound's paired `vertical_entry` edges.
##
## ProcGenTilemap stays the only tile/layer authority: the active layer is always derived from
## where the operator stands, never stored. Standing on the anchor of the layer you are in moves
## you to the paired anchor of the other layer (reversible), and the camera is isolated to the
## active layer through the existing authored-bounds API. Walking between underground rooms never
## triggers anything because only entry anchors trigger.

signal layer_changed(from_layer: StringName, to_layer: StringName, entry_id: StringName)

const LAYER_SURFACE := &"surface"
const LAYER_SUBSURFACE := &"subsurface"
const NO_TILE := Vector2i(-2147483648, -2147483648)

## Untyped on purpose: ProcGenTilemap preloads this script, and a typed back-reference would be a cycle.
var tilemap
var operator: Node2D
var camera: Node

var _observed_layer: StringName = LAYER_SURFACE
## The arrival tile of the last transfer; no transfer fires until the operator leaves it.
var _lockout_tile := NO_TILE
var _camera_restore: Dictionary = {}


func setup(map, actor: Node2D = null, view: Node = null) -> void:
	tilemap = map
	operator = actor
	camera = view
	_lockout_tile = NO_TILE
	_observed_layer = _layer_of_operator()


func _physics_process(_delta: float) -> void:
	update()


## Advances the controller one step. Returns true when a transfer happened.
func update() -> bool:
	if tilemap == null or not is_instance_valid(tilemap):
		return false
	var actor := _operator()
	if actor == null:
		return false
	var tile := _tile_of(actor.global_position)
	var layer := StringName(str(tilemap.get_compound_layer_at_tile(tile)))
	if layer != _observed_layer:
		_set_layer(layer, &"")
	if tile == _lockout_tile:
		return false
	_lockout_tile = NO_TILE
	var entry := _entry_anchored_at(tile, layer)
	if entry.is_empty():
		return false
	return transfer(entry)


## Moves the operator through `entry` from the layer it currently stands in.
func transfer(entry: Dictionary) -> bool:
	var actor := _operator()
	if actor == null or entry.is_empty():
		return false
	var from_layer := StringName(str(tilemap.get_compound_layer_at_tile(_tile_of(actor.global_position))))
	var from_key := "surface_anchor" if from_layer == LAYER_SURFACE else "subsurface_anchor"
	var to_key := "subsurface_anchor" if from_layer == LAYER_SURFACE else "surface_anchor"
	var from_tile: Vector2i = entry.get(from_key, NO_TILE)
	var to_tile: Vector2i = entry.get(to_key, NO_TILE)
	if from_tile == NO_TILE or to_tile == NO_TILE:
		return false
	actor.global_position = _tile_center(to_tile)
	if "velocity" in actor:
		actor.set("velocity", Vector2.ZERO)
	_lockout_tile = to_tile
	_set_layer(StringName(str(tilemap.get_compound_layer_at_tile(to_tile))), StringName(str(entry.get("id", ""))))
	return true


func active_layer() -> StringName:
	return _layer_of_operator()


func _set_layer(layer: StringName, entry_id: StringName) -> void:
	var previous := _observed_layer
	_observed_layer = layer
	_apply_camera(layer)
	if previous != layer:
		layer_changed.emit(previous, layer, entry_id)


func _apply_camera(layer: StringName) -> void:
	var view := _camera()
	if view == null or not view.has_method("set_authored_map_bounds"):
		return
	if layer == LAYER_SUBSURFACE:
		if _camera_restore.is_empty():
			_camera_restore = {
				"authored": view.get("authored_map_bounds"),
				"map": view.get("map_bounds"),
			}
		view.call("set_authored_map_bounds", tilemap.get_compound_layer_world_bounds("subsurface"))
	elif not _camera_restore.is_empty():
		var authored: Rect2 = _camera_restore.get("authored", Rect2())
		view.call("set_authored_map_bounds", authored)
		view.set("map_bounds", _camera_restore.get("map", Rect2()))
		_camera_restore = {}


func _entry_anchored_at(tile: Vector2i, layer: StringName) -> Dictionary:
	var key := "surface_anchor" if layer == LAYER_SURFACE else "subsurface_anchor"
	for entry: Dictionary in tilemap.get_compound_vertical_entries():
		if (entry.get(key, NO_TILE) as Vector2i) == tile:
			return entry
	return {}


func _layer_of_operator() -> StringName:
	var actor := _operator()
	if tilemap == null or actor == null:
		return LAYER_SURFACE
	return StringName(str(tilemap.get_compound_layer_at_tile(_tile_of(actor.global_position))))


func _operator() -> Node2D:
	if operator != null and is_instance_valid(operator):
		return operator
	var found := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	return found as Node2D


func _camera() -> Node:
	if camera != null and is_instance_valid(camera):
		return camera
	return get_tree().get_first_node_in_group("camera") if is_inside_tree() else null


func _tile_of(world_position: Vector2) -> Vector2i:
	var floor_layer: TileMapLayer = tilemap.floor_tilemap
	return floor_layer.local_to_map(floor_layer.to_local(world_position))


func _tile_center(tile: Vector2i) -> Vector2:
	var floor_layer: TileMapLayer = tilemap.floor_tilemap
	return floor_layer.to_global(floor_layer.map_to_local(tile))
