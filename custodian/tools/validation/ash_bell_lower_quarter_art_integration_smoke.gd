extends SceneTree

const ASSETS := {
	"floor": ["res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png", Vector2i(512, 512)],
	"wall": ["res://content/tiles/ash_bell/lower_quarter/meridian_civic_wall_atlas_512.png", Vector2i(512, 512)],
	"props": ["res://content/tiles/ash_bell/lower_quarter/meridian_civic_props_atlas_512.png", Vector2i(512, 512)],
	"overlap": ["res://content/tiles/ash_bell/lower_quarter/ash_bell_overlap_atlas_512.png", Vector2i(512, 512)],
	"landmark": ["res://content/backgrounds/ash_bell/lower_quarter/station_ix_district/station_ix_district_landmark_contact_cutout_768x768.png", Vector2i(768, 768)],
	"pedestal": ["res://content/sprites/environment/props/ash_bell/lower_quarter/meridian_answer_pedestal/runtime/body/meridian_answer_pedestal__body__interaction__idle__omni__1f__96.png", Vector2i(96, 96)],
	"receiver": ["res://content/sprites/environment/props/ash_bell/station_ix/station_ix_receiver/runtime/body/station_ix_receiver__body__interaction__active__omni__8f__96.png", Vector2i(768, 96)],
	"core": ["res://content/sprites/environment/props/ash_bell/station_ix/station_ix_sync_core/runtime/body/station_ix_sync_core__body__interaction__idle__omni__1f__384x320.png", Vector2i(384, 320)],
	"ingress": ["res://content/sprites/environment/props/ash_bell/lower_quarter/meridian_transit_descent/runtime/body/meridian_transit_descent__body__interaction__idle__omni__1f__288x224.png", Vector2i(288, 224)],
	"relay": ["res://content/sprites/environment/props/ash_bell/common/meridian_civic_relay/runtime/body/meridian_civic_relay__body__interaction__idle__omni__1f__96.png", Vector2i(96, 96)],
}

func _init() -> void: call_deferred("_run")

func _run() -> void:
	for key in ASSETS:
		var contract: Array = ASSETS[key]
		var texture := load(contract[0]) as Texture2D
		assert(texture != null and Vector2i(texture.get_size()) == contract[1], "%s asset contract failed" % key)
	for key in ["floor", "wall", "props", "overlap"]: assert((ASSETS[key][1] as Vector2i) / 16 == Vector2i(32, 32))
	assert((ASSETS["receiver"][1] as Vector2i).x / 96 == 8)
	assert(ResourceLoader.exists("res://game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd"))
	assert(not ResourceLoader.exists("res://game/world/levels/authored/ash_bell/common/meridian_civic_blockout_presenter.gd"))
	var lower := load("res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn").instantiate() as AshBellLowerQuarter
	root.add_child(lower)
	await process_frame
	assert(not lower.blockout_grid.visible)
	var civic_presenter := lower.get_node("BackgroundRoot/MeridianCivicArtPresenter") as MeridianCivicArtPresenter
	assert(civic_presenter != null)
	var native_props := lower.get_node("PropsRoot/NativePropRoot") as LowerQuarterNativePropLayer2D
	assert(native_props != null)
	assert(native_props.get_child_count() == 104)
	for child: Node in native_props.get_children():
		assert(child is SemanticNativeProp2D)
		assert((child as SemanticNativeProp2D).get_sprite().scale == Vector2.ONE)
	var landmark_root := lower.get_node("BackgroundRoot/StationIXLandmarkRoot") as Node2D
	var landmark := landmark_root.get_node("StationIXLandmark") as Sprite2D
	assert(landmark_root.position == lower.cell_center(lower.STATION_LANDMARK_CONTACT_CELL))
	assert(landmark.position.y == (384.0 - lower.STATION_LANDMARK_GROUND_Y_PX) * lower.STATION_LANDMARK_SCALE)
	var cutout_image := Image.load_from_file(ProjectSettings.globalize_path(ASSETS["landmark"][0]))
	var source_image := Image.load_from_file(ProjectSettings.globalize_path("res://content/backgrounds/ash_bell/lower_quarter/station_ix_district/station_ix_district_landmark_768x768.png"))
	assert(cutout_image.get_used_rect().end.y <= int(lower.STATION_LANDMARK_GROUND_Y_PX) + 1)
	assert(cutout_image.get_used_rect().size != cutout_image.get_size())
	for y in range(cutout_image.get_height()):
		for x in range(cutout_image.get_width()):
			var cutout_pixel := cutout_image.get_pixel(x, y)
			if cutout_pixel.a > 0.0:
				var source_pixel := source_image.get_pixel(x, y)
				assert(cutout_pixel.r == source_pixel.r and cutout_pixel.g == source_pixel.g and cutout_pixel.b == source_pixel.b)
	assert(lower.get_node_or_null("PropsRoot/DirectRouteSign") == null)
	assert(lower.get_node("DynamicGates/DirectPersonnelCollapse/CollisionShape2D").shape != null)
	assert(not lower.authored_navigation.is_world_position_walkable(lower.cell_center(Vector2i(60, 72))))
	for path in ["POIRoot/EvacAnnunciator", "POIRoot/GatePressureRelay", "POIRoot/StationIXTransitInterlock"]:
		assert((lower.get_node(path) as CivicRelay2D).presentation_texture != null)
	var ingress := load("res://game/world/approaches/ash_bell/lower_quarter/meridian_transit_ingress_site.tscn").instantiate() as MeridianTransitIngressSite
	root.add_child(ingress)
	await process_frame
	assert(ingress.requires_explicit_interaction)
	assert(ingress.CLEARANCE_RECT == Rect2(-176, -144, 352, 288))
	assert((ingress.get_node("ProductionPresentation") as Sprite2D).texture != null)
	for path in ["res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.gd", "res://game/world/levels/authored/ash_bell/west_gate_works/west_gate_works.gd", "res://game/world/levels/authored/ash_bell/station_ix/station_ix.gd"]:
		assert("asset_catalog.generated.json" not in FileAccess.get_file_as_string(path))
	lower.free()
	ingress.free()
	await process_frame
	print("ash_bell_lower_quarter_art_integration_smoke: PASS assets=10 atlas_cell=32 receiver_frames=8")
	quit(0)
