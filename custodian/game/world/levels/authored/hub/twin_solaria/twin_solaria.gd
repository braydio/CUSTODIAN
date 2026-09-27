extends AuthoredLevel2D
class_name TwinSolaria

const Layout := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria_layout.gd")
const ReadoutScript := preload("res://game/world/interactions/world_readout_interactable.gd")

@onready var _underlay_root: Node2D = $UnderlayRoot
@onready var _plate_root: Node2D = $PlayableRoot/PlateRoot
@onready var _presentation: Node = $PlayableRoot/TwinSolariaPresentation
@onready var _poi_root: Node2D = $POIRoot


func _ready() -> void:
	draw_placeholder_grid = false
	camera_bounds = Layout.WORLD_BOUNDS
	_build_environment()
	_build_readouts()
	super._ready()


func _build_environment() -> void:
	_presentation.call("build", _underlay_root, _plate_root)
	var underlay := _underlay_root.get_node_or_null("FidelityUnderlay") as Sprite2D
	if underlay != null:
		underlay.position = Vector2.ZERO
		underlay.scale = Vector2.ONE
	for registration in Layout.PLATES:
		var plate := _plate_root.get_node_or_null(String(registration["node"])) as Sprite2D
		if plate == null:
			continue
		plate.position = registration["position"] as Vector2
		plate.scale = Vector2.ONE


func _build_readouts() -> void:
	for poi_data in Layout.POIS:
		var node_name := "POI_" + String(poi_data["id"]).to_pascal_case()
		var interactable := ReadoutScript.new() as Node2D
		interactable.name = node_name
		interactable.set("title", String(poi_data["title"]))
		interactable.set("readout", String(poi_data["readout"]))
		interactable.set("single_use", true)
		interactable.set("interaction_distance", 72.0)
		interactable.position = Layout.poi_position(poi_data)
		_poi_root.add_child(interactable)


func get_boundary_segments() -> Array:
	return Layout.AUTHORED_BOUNDARY_SEGMENTS.duplicate(true)


func get_authoring_markers() -> Dictionary:
	var markers := {
		&"spawn_crown_causeway": {
			"kind": "spawn",
			"node_name": "Spawn_CrownCauseway",
			"position": Layout.SPAWN_CROWN_CAUSEWAY,
			"label": "CROWN CAUSEWAY SPAWN",
		},
		&"return_crown_transfer": {
			"kind": "return",
			"node_name": "Return_CrownTransfer",
			"position": Layout.RETURN_CROWN_TRANSFER,
			"label": "CROWN TRANSFER RETURN",
		},
	}
	for poi_data in Layout.POIS:
		var poi_id: StringName = poi_data["id"]
		markers[poi_id] = {
			"kind": "poi",
			"node_name": "POI_" + String(poi_id).to_pascal_case(),
			"position": Layout.poi_position(poi_data),
			"label": str(poi_data["title"]),
		}
	return markers


func get_camera_bounds() -> Rect2:
	return Layout.WORLD_BOUNDS


func has_passage_activation() -> bool:
	return false
