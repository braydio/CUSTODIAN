extends AuthoredLevel2D
class_name SepulcherMaterialOperatorV2Level

enum PresentationMode {
	NEUTRAL_BLOCKOUT = 1,
	NATIVE_COURTYARD = 2,
	REPEAT_NW_DIAGNOSTIC = 3,
	QUIET_MODULAR = 4,
}

const ROOM_BOUNDS := Rect2(0.0, 0.0, 1024.0, 768.0)
const TILE_SIZE := 128
const STONE_ATLAS_REGIONS := {
	"Limestone": Rect2(202.0, 227.0, 128.0, 128.0),
	"Basalt": Rect2(29.0, 332.0, 128.0, 128.0),
}
const LIMESTONE_TEXTURE := preload(
	"res://game/world/levels/authored/dev/sepulcher_modular_material_pilot/preview/generated/native_paving_nw.png"
)
const BASALT_TEXTURE := preload(
	"res://game/world/levels/authored/dev/sepulcher_modular_material_pilot/preview/generated/native_paving_ne.png"
)
const NW_TEXTURE := preload(
	"res://game/world/levels/authored/dev/sepulcher_modular_material_pilot/preview/generated/native_paving_nw.png"
)

const BOUNDARY_SEGMENTS := [
	[Vector2(0.0, 0.0), Vector2(1024.0, 0.0)],
	[Vector2(1024.0, 0.0), Vector2(1024.0, 768.0)],
	[Vector2(1024.0, 768.0), Vector2(0.0, 768.0)],
	[Vector2(0.0, 768.0), Vector2(0.0, 0.0)],
]

const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "Spawn_Main",
		"label": "SEPULCHER CANONICAL OPERATOR + MATERIAL V2",
		"kind": "spawn",
		"position": Vector2(512.0, 520.0),
	},
}

var BRONZE_ROUTES := [
	PackedVector2Array([Vector2(192, 192), Vector2(192, 320), Vector2(448, 320)]),
	PackedVector2Array([Vector2(704, 448), Vector2(832, 448), Vector2(832, 576)]),
]

@onready var _blockout_root: Node2D = %NeutralBlockoutPresentation
@onready var _courtyard_root: Node2D = %NativeCourtyardPresentation
@onready var _repeat_root: Node2D = %RepeatDiagnosticPresentation
@onready var _quiet_root: Node2D = %QuietModularPresentation
@onready var _mode_label: Label = %ModeLabel
@onready var _coverage_label: Label = %AnimationCoverageLabel

var _presentation_mode := PresentationMode.QUIET_MODULAR
var _inlays_enabled := true
var _vault_manager: Node
var _vault_fallback_was_enabled := false
var _restore_vault_fallback := false


func _ready() -> void:
	super._ready()
	_disable_unrelated_debug_vault_fallback()
	_build_neutral_blockout()
	_build_quiet_modular_floor()
	set_presentation_mode(PresentationMode.QUIET_MODULAR)
	call_deferred("_configure_dev_camera")


func _process(_delta: float) -> void:
	_update_labels()


func _exit_tree() -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null:
		if camera.has_method("clear_presentation_framing"):
			camera.call("clear_presentation_framing", false)
		if camera.has_method("clear_presentation_bounds_override"):
			camera.call("clear_presentation_bounds_override")
	if _restore_vault_fallback and is_instance_valid(_vault_manager):
		_vault_manager.set("create_debug_vault_if_missing", _vault_fallback_was_enabled)


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func set_presentation_mode(mode: PresentationMode) -> void:
	if mode < PresentationMode.NEUTRAL_BLOCKOUT or mode > PresentationMode.QUIET_MODULAR:
		push_warning("Sepulcher V2: invalid presentation mode %s" % mode)
		return
	_presentation_mode = mode
	_blockout_root.visible = mode == PresentationMode.NEUTRAL_BLOCKOUT
	_courtyard_root.visible = mode == PresentationMode.NATIVE_COURTYARD
	_repeat_root.visible = mode == PresentationMode.REPEAT_NW_DIAGNOSTIC
	_quiet_root.visible = mode == PresentationMode.QUIET_MODULAR
	_update_labels()


func get_presentation_mode() -> PresentationMode:
	return _presentation_mode


func set_inlays_enabled(enabled: bool) -> void:
	_inlays_enabled = enabled
	for child in _quiet_root.get_node("BronzeInlayRoutes").get_children():
		child.visible = enabled
	_update_labels()


func are_inlays_enabled() -> bool:
	return _inlays_enabled


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			set_presentation_mode(PresentationMode.NEUTRAL_BLOCKOUT)
		KEY_2:
			set_presentation_mode(PresentationMode.NATIVE_COURTYARD)
		KEY_3:
			set_presentation_mode(PresentationMode.REPEAT_NW_DIAGNOSTIC)
		KEY_4:
			set_presentation_mode(PresentationMode.QUIET_MODULAR)
		KEY_TAB:
			set_presentation_mode(
				PresentationMode.NATIVE_COURTYARD
				if _presentation_mode == PresentationMode.QUIET_MODULAR
				else PresentationMode.QUIET_MODULAR
			)
		KEY_B:
			set_inlays_enabled(not _inlays_enabled)


func _update_labels() -> void:
	if not is_instance_valid(_mode_label):
		return
	_mode_label.text = "%s · TAB COURTYARD/QUIET · 1–4 FLOORS · B INLAYS · V OPERATOR ART" % _mode_name()
	var operator := get_node_or_null("/root/GameRoot/World/Operator")
	var preview := operator.get_node_or_null("CanonicalOperatorPresentation") if operator != null else null
	var canonical := bool(preview.call("is_canonical_enabled")) if preview != null else true
	_coverage_label.text = (
		"CANONICAL 128 · IDLE ONLY · 8 FPS ILLUSTRATIVE · MOTION/COMBAT ART NOT AUTHORED"
		if canonical
		else "LIVE LEGACY OPERATOR · V TO VIEW ACCEPTED 128 IDLE PREVIEW"
	)


func _mode_name() -> String:
	match _presentation_mode:
		PresentationMode.NEUTRAL_BLOCKOUT:
			return "MODE 1 · NEUTRAL BLOCKOUT"
		PresentationMode.NATIVE_COURTYARD:
			return "MODE 2 · ORIGINAL NATIVE COURTYARD"
		PresentationMode.REPEAT_NW_DIAGNOSTIC:
			return "MODE 3 · NW REPEAT · NONPRODUCTION DIAGNOSTIC"
		PresentationMode.QUIET_MODULAR:
			return "MODE 4 · QUIET MODULAR 128 STUDY"
	return "SEPULCHER MATERIAL V2"


func _build_neutral_blockout() -> void:
	var floor := Polygon2D.new()
	floor.name = "NeutralFloor"
	floor.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(ROOM_BOUNDS.size.x, 0.0),
		ROOM_BOUNDS.size,
		Vector2(0.0, ROOM_BOUNDS.size.y),
	])
	floor.color = Color("#565a58")
	floor.z_index = -20
	_blockout_root.add_child(floor)
	for x in range(0, int(ROOM_BOUNDS.size.x) + 1, TILE_SIZE):
		_add_grid_line(_blockout_root, Vector2(x, 0), Vector2(x, ROOM_BOUNDS.size.y), Color(0.88, 0.87, 0.82, 0.28), 1.0)
	for y in range(0, int(ROOM_BOUNDS.size.y) + 1, TILE_SIZE):
		_add_grid_line(_blockout_root, Vector2(0, y), Vector2(ROOM_BOUNDS.size.x, y), Color(0.88, 0.87, 0.82, 0.28), 1.0)


func _build_quiet_modular_floor() -> void:
	var limestone_atlas := _make_atlas(LIMESTONE_TEXTURE, STONE_ATLAS_REGIONS["Limestone"])
	var basalt_atlas := _make_atlas(BASALT_TEXTURE, STONE_ATLAS_REGIONS["Basalt"])
	var cells := Node2D.new()
	cells.name = "MaterialCells"
	cells.z_index = -20
	_quiet_root.add_child(cells)
	for y in range(6):
		for x in range(8):
			var basalt := (x * 7 + y * 11) % 11 < 2
			var tile := Sprite2D.new()
			tile.name = ("Basalt" if basalt else "Limestone") + "_%d_%d" % [x, y]
			tile.texture = basalt_atlas if basalt else limestone_atlas
			tile.centered = true
			tile.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			cells.add_child(tile)
	var grout := Node2D.new()
	grout.name = "CharcoalGrout"
	grout.z_index = -18
	_quiet_root.add_child(grout)
	for x in range(0, int(ROOM_BOUNDS.size.x) + 1, TILE_SIZE):
		_add_grid_line(grout, Vector2(x, 0), Vector2(x, ROOM_BOUNDS.size.y), Color("#292c2a"), 2.0)
	for y in range(0, int(ROOM_BOUNDS.size.y) + 1, TILE_SIZE):
		_add_grid_line(grout, Vector2(0, y), Vector2(ROOM_BOUNDS.size.x, y), Color("#292c2a"), 2.0)
	var routes := Node2D.new()
	routes.name = "BronzeInlayRoutes"
	routes.z_index = -16
	_quiet_root.add_child(routes)
	for index in BRONZE_ROUTES.size():
		var dark_route := Line2D.new()
		dark_route.name = "OxidizedGreenRoute_%d" % index
		dark_route.points = BRONZE_ROUTES[index]
		dark_route.width = 4.0
		dark_route.default_color = Color("#38463c")
		dark_route.begin_cap_mode = Line2D.LINE_CAP_ROUND
		dark_route.end_cap_mode = Line2D.LINE_CAP_ROUND
		var highlight := Line2D.new()
		highlight.name = "BronzeHighlight_%d" % index
		highlight.points = BRONZE_ROUTES[index]
		highlight.width = 1.0
		highlight.default_color = Color("#8e7047")
		highlight.begin_cap_mode = Line2D.LINE_CAP_ROUND
		highlight.end_cap_mode = Line2D.LINE_CAP_ROUND
		routes.add_child(dark_route)
		routes.add_child(highlight)
	set_inlays_enabled(true)


func _make_atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


func _add_grid_line(parent: Node2D, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = width
	line.default_color = color
	line.antialiased = false
	parent.add_child(line)


func _configure_dev_camera() -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	var operator := get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	if camera == null or operator == null:
		push_warning("Sepulcher V2: gameplay camera/operator unavailable for scoped framing")
		return
	if camera.has_method("set_presentation_bounds_override"):
		camera.call("set_presentation_bounds_override", ROOM_BOUNDS)
	if camera.has_method("set_presentation_subject_constraint"):
		camera.call("set_presentation_subject_constraint", operator)
	if camera.has_method("set_presentation_framing"):
		camera.call("set_presentation_framing", true, Vector2(0.0, -40.0), Vector2(1.25, 1.25))
	# This sandbox has a fixed comparison frame. Apply its scoped zoom immediately
	# instead of easing in from the unrelated global gameplay default.
	camera.zoom = Vector2(1.25, 1.25)
	camera.target_zoom = Vector2(1.25, 1.25)


func _disable_unrelated_debug_vault_fallback() -> void:
	_vault_manager = get_node_or_null("/root/VaultManager")
	if _vault_manager == null or not ("create_debug_vault_if_missing" in _vault_manager):
		return
	_vault_fallback_was_enabled = bool(_vault_manager.get("create_debug_vault_if_missing"))
	_restore_vault_fallback = true
	_vault_manager.set("create_debug_vault_if_missing", false)
