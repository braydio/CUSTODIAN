extends AuthoredLevel2D
class_name ProcgenShowcaseGallery

const WING_DATA: Array[Dictionary] = [
	{"id": &"terrain", "label": "TERRAIN", "anchor": Vector2(0, -1320), "floor": Rect2(-420, -1780, 840, 860), "color": Color("#39464a")},
	{"id": &"topology", "label": "TOPOLOGY", "anchor": Vector2(1220, -520), "floor": Rect2(760, -900, 920, 760), "color": Color("#45434d")},
	{"id": &"sites", "label": "SITES", "anchor": Vector2(1220, 520), "floor": Rect2(760, 140, 920, 760), "color": Color("#4a463d")},
	{"id": &"population", "label": "POPULATION", "anchor": Vector2(0, 1320), "floor": Rect2(-420, 920, 840, 860), "color": Color("#493f3d")},
	{"id": &"presentation", "label": "PRESENTATION", "anchor": Vector2(-1220, 0), "floor": Rect2(-1680, -380, 920, 760), "color": Color("#3f4840")},
]

# These authored rectangles form one continuous ring of public gallery floor.
# The omitted central rectangle is intentionally outside this floor union.
const FLOOR_REGIONS: Array[Rect2] = [
	Rect2(-520, -520, 1040, 1040),
	Rect2(-260, -1320, 520, 800),
	Rect2(-520, -920, 1040, 400),
	Rect2(520, -380, 700, 760),
	Rect2(920, -520, 300, 1040),
	Rect2(-260, 520, 520, 800),
	Rect2(-520, 520, 1040, 400),
	Rect2(-1220, -260, 700, 520),
	Rect2(-1220, -520, 700, 1040),
]

# The segment across the north side of the center is the sealed arena threshold.
const BOUNDARY_SEGMENTS := [
	[Vector2(-1680, -1780), Vector2(1680, -1780)],
	[Vector2(1680, -1780), Vector2(1680, 900)],
	[Vector2(1680, 900), Vector2(420, 1780)],
	[Vector2(420, 1780), Vector2(-420, 1780)],
	[Vector2(-420, 1780), Vector2(-1680, 900)],
	[Vector2(-420, 1780), Vector2(420, 1780)],
	[Vector2(-1680, 900), Vector2(-1680, -1780)],
	[Vector2(-520, -520), Vector2(-210, -520)],
	[Vector2(210, -520), Vector2(520, -520)],
	[Vector2(-210, -520), Vector2(210, -520)],
]

const AUTHORING_MARKERS := {
	"spawn": {"node_name": "Spawn_Main", "label": "MAIN ENTRY", "kind": "spawn", "position": Vector2(-1220, 0)},
	"return_main": {"node_name": "Return_Main", "label": "RETURN TO MAIN WORLD", "kind": "level_exit", "position": Vector2(-1220, 260)},
	"terrain": {"node_name": "Wing_Terrain", "label": "TERRAIN EXHIBIT", "kind": "poi", "position": Vector2(0, -1320)},
	"topology": {"node_name": "Wing_Topology", "label": "TOPOLOGY EXHIBIT", "kind": "poi", "position": Vector2(1220, -520)},
	"sites": {"node_name": "Wing_Sites", "label": "SITES EXHIBIT", "kind": "poi", "position": Vector2(1220, 520)},
	"population": {"node_name": "Wing_Population", "label": "POPULATION EXHIBIT", "kind": "poi", "position": Vector2(0, 1320)},
	"presentation": {"node_name": "Wing_Presentation", "label": "PRESENTATION EXHIBIT", "kind": "poi", "position": Vector2(-1220, 0)},
	"arena_threshold": {"node_name": "ArenaThreshold", "label": "ARENA SEALED · GENERATED MAP NOT LOADED", "kind": "sealed_threshold", "position": Vector2(0, -520)},
}


func _ready() -> void:
	super._ready()
	_build_gallery()
	var presenter_script := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_presenter.gd")
	var presenter := presenter_script.new()
	presenter.name = "ExhibitPresenter"
	add_child(presenter)


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func get_gallery_wing_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for wing in WING_DATA:
		result.append(wing["id"])
	return result


func get_gallery_floor_regions() -> Array[Rect2]:
	var result := FLOOR_REGIONS.duplicate()
	for wing in WING_DATA:
		result.append(wing["floor"])
	return result


func get_arena_threshold_segment() -> Array:
	return BOUNDARY_SEGMENTS.back()


func _build_gallery() -> void:
	var background := get_node("BackgroundRoot")
	var props := get_node("PropsRoot")
	_add_floor(background, Rect2(-520, -520, 1040, 1040), Color("#42464a"), "CENTRAL CONCOURSE")
	for region_index in range(1, FLOOR_REGIONS.size()):
		_add_floor(background, FLOOR_REGIONS[region_index], Color("#353a3f"), "CONNECTOR_%02d" % region_index)
	for wing in WING_DATA:
		_add_floor(background, wing["floor"], wing["color"], str(wing["label"]))
		_add_label(background, str(wing["label"]) + " · EXHIBIT WING", wing["anchor"] + Vector2(-250, -300), 22)
		_add_exhibit_marker(props, wing)
	_add_floor(background, Rect2(-210, -500, 420, 18), Color("#b58c49"), "SEALED ARENA THRESHOLD")
	_add_label(background, "ARENA SEALED · GENERATED MAP NOT LOADED", Vector2(-330, -590), 18)
	_add_label(background, "PROCGEN SHOWCASE · PGA-2 EXHIBIT CATALOG", Vector2(-470, -80), 22)


func _add_floor(parent: Node, rect: Rect2, color: Color, node_name: String) -> void:
	var floor := Polygon2D.new()
	floor.name = node_name.replace(" ", "_")
	floor.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	floor.color = color
	floor.z_index = -10
	parent.add_child(floor)


func _add_exhibit_marker(parent: Node, wing: Dictionary) -> void:
	var marker := Marker2D.new()
	marker.name = "%sExhibitMarker" % String(wing["id"]).to_pascal_case()
	marker.position = wing["anchor"]
	marker.set_meta("wing_id", wing["id"])
	marker.set_meta("placeholder_exhibit", true)
	marker.add_to_group("procgen_showcase_exhibit_marker")
	parent.add_child(marker)
	var plinth := Polygon2D.new()
	plinth.name = "%s_NeutralPlinth" % String(wing["id"]).to_pascal_case()
	plinth.polygon = PackedVector2Array([Vector2(-48, -32), Vector2(48, -32), Vector2(48, 32), Vector2(-48, 32)])
	plinth.position = wing["anchor"]
	plinth.color = Color(0.69, 0.65, 0.54, 0.7)
	plinth.z_index = -2
	plinth.set_meta("non_blocking_visual_only", true)
	parent.add_child(plinth)


func _add_label(parent: Node, text: String, position: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = Color("#ddd4bc")
	parent.add_child(label)
