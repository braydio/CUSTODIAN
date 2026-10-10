class_name HubFirstSetMap
extends AuthoredLevel2D

const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const CROWN_TRANSFER_INGRESS_SCRIPT := preload(
	"res://game/world/hub/hub_crown_transfer_ingress.gd"
)
const ADJUDICATION_DAIS_SCRIPT := preload(
	"res://game/world/hub/hub_adjudication_dais.gd"
)
const CONTINUITY_PORT_SCRIPT := preload(
	"res://game/world/hub/hub_continuity_port_interaction.gd"
)
const CROWN_TRANSFER_ROUTE := &"hub_twin_solaria"
const CROWN_TRANSFER_PROFILE := &"production"

@onready var blockout_grid: AuthoredBlockoutGrid2D = $BlockoutGrid
@onready var authored_navigation: AuthoredNavigationProvider2D = $NavigationRoot/AuthoredNavigationProvider
@onready var boundary_collision: StaticBody2D = $CollisionRoot
@onready var marker_root: Node2D = $Markers


func _ready() -> void:
	camera_bounds = LAYOUT.WORLD_BOUNDS
	draw_placeholder_grid = false
	blockout_grid.position = LAYOUT.GRID_ORIGIN
	blockout_grid.configure(LAYOUT.CELL_SIZE, LAYOUT.GRID_SIZE, LAYOUT.WALKABLE_REGIONS, _visual_regions())
	blockout_grid.visible = true
	authored_navigation.configure(blockout_grid)
	_build_markers()
	_build_labels()
	super._ready()
	add_to_group("world_origin_branch")
	_build_crown_transfer_ingress()
	_build_adjudication_dais()
	_build_continuity_port()


func get_authoring_markers() -> Dictionary:
	var result: Dictionary = {}
	for marker_name: Variant in LAYOUT.MARKERS:
		var name := str(marker_name)
		result[name.to_snake_case()] = {
			"kind": "spawn" if name.begins_with("Spawn_") else "poi",
			"node_name": name,
			"position": LAYOUT.MARKERS[marker_name],
			"label": name,
		}
	return result


func get_boundary_segments() -> Array:
	return blockout_grid.get_boundary_segments()


func get_named_marker(marker_name: StringName) -> Marker2D:
	return marker_root.get_node_or_null(String(marker_name)) as Marker2D


func get_spawn_position(spawn_id: StringName) -> Vector2:
	return super.get_spawn_position(spawn_id)


func _rebuild_boundary_collision() -> void:
	for child in boundary_collision.get_children():
		child.queue_free()
	var index := 1
	for raw_segment: Variant in get_boundary_segments():
		if raw_segment is Array and (raw_segment as Array).size() >= 2:
			_add_boundary_segment(
				boundary_collision,
				"BoundarySegment_%03d" % index,
				(raw_segment as Array)[0] as Vector2,
				(raw_segment as Array)[1] as Vector2
			)
			index += 1


func _visual_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region_name: Variant in LAYOUT.ENVELOPES:
		if str(region_name).ends_with("connector"):
			continue
		result.append({
			"name": str(region_name),
			"rect": LAYOUT.ENVELOPES[region_name],
			"color": LAYOUT.DISTRICT_COLORS[region_name],
		})
	return result


func _build_markers() -> void:
	for marker_name: Variant in LAYOUT.MARKERS:
		var marker := Marker2D.new()
		marker.name = str(marker_name)
		marker.position = LAYOUT.MARKERS[marker_name]
		marker_root.add_child(marker)
		var pip := ColorRect.new()
		pip.name = "MapPip"
		pip.position = Vector2(-10.0, -10.0)
		pip.size = Vector2(28.0, 28.0)
		pip.color = Color("f2df9c") if str(marker_name).begins_with("Spawn_") else Color("e4e7df")
		pip.z_index = 10
		marker.add_child(pip)
		var label := Label.new()
		label.name = "MapLabel"
		label.text = str(marker_name)
		label.position = LAYOUT.MARKER_LABEL_OFFSETS.get(str(marker_name), Vector2(24.0, -30.0))
		label.size = Vector2(520.0, 52.0)
		label.add_theme_font_size_override("font_size", 42)
		label.add_theme_color_override("font_color", Color("f1f1e8"))
		label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.z_index = 10
		marker.add_child(label)


func _build_labels() -> void:
	for region_name: Variant in LAYOUT.ENVELOPES:
		if str(region_name).ends_with("connector"):
			continue
		var rect: Rect2i = LAYOUT.ENVELOPES[region_name]
		var label := Label.new()
		label.name = "Label_%s" % str(region_name).to_pascal_case()
		label.text = str(region_name).replace("_", " ").to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = LAYOUT.GRID_ORIGIN + Vector2(rect.position) * LAYOUT.CELL_SIZE
		label.size = Vector2(rect.size) * LAYOUT.CELL_SIZE
		label.add_theme_font_size_override("font_size", 64)
		label.add_theme_color_override("font_color", Color("d5d9d8"))
		label.add_theme_color_override("font_shadow_color", Color(0.05, 0.06, 0.07, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.z_index = 8
		add_child(label)


func _build_crown_transfer_ingress() -> void:
	var world := get_parent()
	var marker := get_named_marker(&"CrownTransfer")
	if world == null or marker == null \
			or world != get_node_or_null("/root/GameRoot/World") \
			or world.get_node_or_null("RouteTraversalManager") == null:
		return
	var ingress := CROWN_TRANSFER_INGRESS_SCRIPT.new() as Node2D
	ingress.name = "CrownTransferIngress"
	ingress.call(
		"configure_hub_route",
		CROWN_TRANSFER_ROUTE,
		CROWN_TRANSFER_PROFILE,
		self,
		&"Spawn_TwinReturn"
	)
	call_deferred("_attach_crown_transfer_ingress", ingress, world, marker.global_position)


func _attach_crown_transfer_ingress(
	ingress: Node2D,
	world: Node,
	world_position: Vector2
) -> void:
	if not is_instance_valid(ingress) or not is_instance_valid(world):
		return
	world.add_child(ingress)
	ingress.global_position = world_position


func _build_adjudication_dais() -> void:
	var marker := get_named_marker(&"AdjudicationDais")
	var host := get_node_or_null("/root/GameRoot")
	var authority := host.get_node_or_null("HubCampaignAuthority") if host != null else null
	if marker == null or authority == null \
			or get_parent() != get_node_or_null("/root/GameRoot/World"):
		return
	var dais := Node2D.new()
	dais.name = "AdjudicationDaisInteraction"
	dais.set_script(ADJUDICATION_DAIS_SCRIPT)
	dais.call("configure", authority, self)
	call_deferred("_attach_adjudication_dais", dais, marker.global_position)


func _attach_adjudication_dais(dais: Node2D, world_position: Vector2) -> void:
	if not is_instance_valid(dais):
		return
	add_child(dais)
	dais.global_position = world_position


func _build_continuity_port() -> void:
	var marker := get_named_marker(&"ContinuityPort")
	var host := get_node_or_null("/root/GameRoot")
	var authority := host.get_node_or_null("HubCampaignAuthority") if host != null else null
	if marker == null or authority == null or get_parent() != get_node_or_null("/root/GameRoot/World"):
		return
	var port := Node2D.new()
	port.name = "ContinuityPortInteraction"
	port.set_script(CONTINUITY_PORT_SCRIPT)
	port.call("configure", authority, self)
	call_deferred("_attach_adjudication_dais", port, marker.global_position)
