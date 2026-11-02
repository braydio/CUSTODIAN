extends "res://game/world/levels/authored/dev/sepulcher_material_operator_v2/sepulcher_material_operator_v2_level.gd"
class_name SepulcherModularAssemblyPilotV1Level

enum AssemblyMode {
	NEUTRAL_BLOCKOUT = 1,
	NATIVE_COURTYARD = 2,
	REPEAT_NW_DIAGNOSTIC = 3,
	QUIET_MODULAR = 4,
	FOUR_ASSET_ASSEMBLY = 5,
}

const ASSEMBLY_ROOT_NAME := "FourAssetAssemblyPresentation"
const DAMAGE_SEED := 11012026
const DAMAGE_ROTATIONS := [0.0, 90.0, 180.0, 270.0]
const DAMAGE_X_CENTERS := [256.0, 384.0, 512.0, 640.0, 768.0]
const DAMAGE_Y_CENTERS := [320.0, 448.0, 576.0, 704.0]
const TILE_CENTERS := [
	Vector2(256.0, 256.0),
	Vector2(768.0, 256.0),
	Vector2(256.0, 768.0),
	Vector2(768.0, 768.0),
]
const TILE_ROTATIONS := [0.0, 90.0, 180.0, 270.0]
const DAMAGE_TEXTURE := preload("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/paving_damage_overlay.png")
const BASE_TEXTURE := preload("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/paving_base.png")
const RING_TEXTURE := preload("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/witness_ring_inlay.png")
const WALL_MODULE_TEXTURE := preload("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/retaining_wall_segment.png")
const WALL_STRIP_TEXTURE := preload("res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/preview/generated/retaining_wall_full_strip_768.png")
const CANONICAL_IDLE_TEXTURE := preload("res://game/world/levels/authored/dev/sepulcher_material_operator_v2/preview/operator_2_5d_idle_relaxed_8dir_15f_128.png")
const NORTH_WALL_SEGMENT := [Vector2(128.0, 240.0), Vector2(896.0, 240.0)]

var _assembly_mode := AssemblyMode.FOUR_ASSET_ASSEMBLY
var _damage_enabled := true
var _ring_enabled := true
var _wall_art_enabled := true
var _rotated_paving_enabled := true
var _wall_join_diagnostic_enabled := false
var _damage_layout_snapshot: Array[Dictionary] = []

@onready var _assembly_root: Node2D = Node2D.new()
@onready var _damage_root: Node2D = Node2D.new()
@onready var _ring_sprite: Sprite2D = Sprite2D.new()
@onready var _wall_sprite: Sprite2D = Sprite2D.new()
@onready var _wall_diagnostic_root: Node2D = Node2D.new()


func _ready() -> void:
	super._ready()
	_build_four_asset_assembly()
	set_presentation_mode(AssemblyMode.FOUR_ASSET_ASSEMBLY)
	set_damage_enabled(true)
	set_ring_enabled(true)
	set_wall_art_enabled(true)
	_update_assembly_label()


func _process(delta: float) -> void:
	super._process(delta)
	_update_assembly_label()


func get_boundary_segments() -> Array:
	var result := super.get_boundary_segments().duplicate(true)
	result.append(NORTH_WALL_SEGMENT.duplicate())
	return result


func set_presentation_mode(mode: int) -> void:
	if mode < AssemblyMode.NEUTRAL_BLOCKOUT or mode > AssemblyMode.FOUR_ASSET_ASSEMBLY:
		push_warning("Sepulcher assembly pilot: invalid presentation mode %s" % mode)
		return
	_assembly_mode = mode
	if mode == AssemblyMode.FOUR_ASSET_ASSEMBLY:
		super.set_presentation_mode(PresentationMode.QUIET_MODULAR)
		%NeutralBlockoutPresentation.visible = false
		%NativeCourtyardPresentation.visible = false
		%RepeatDiagnosticPresentation.visible = false
		%QuietModularPresentation.visible = false
		_assembly_root.visible = true
	else:
		_assembly_root.visible = false
		match mode:
			AssemblyMode.NEUTRAL_BLOCKOUT:
				super.set_presentation_mode(PresentationMode.NEUTRAL_BLOCKOUT)
			AssemblyMode.NATIVE_COURTYARD:
				super.set_presentation_mode(PresentationMode.NATIVE_COURTYARD)
			AssemblyMode.REPEAT_NW_DIAGNOSTIC:
				super.set_presentation_mode(PresentationMode.REPEAT_NW_DIAGNOSTIC)
			AssemblyMode.QUIET_MODULAR:
				super.set_presentation_mode(PresentationMode.QUIET_MODULAR)
	_update_assembly_label()


func get_presentation_mode() -> int:
	return _assembly_mode


func get_damage_layout() -> Array[Dictionary]:
	return _damage_layout_snapshot.duplicate(true)


func get_damage_seed() -> int:
	return DAMAGE_SEED


func set_damage_enabled(enabled: bool) -> void:
	_damage_enabled = enabled
	_damage_root.visible = enabled
	_update_assembly_label()


func is_damage_enabled() -> bool:
	return _damage_enabled


func set_ring_enabled(enabled: bool) -> void:
	_ring_enabled = enabled
	_ring_sprite.visible = enabled
	_update_assembly_label()


func is_ring_enabled() -> bool:
	return _ring_enabled


func set_wall_art_enabled(enabled: bool) -> void:
	_wall_art_enabled = enabled
	_wall_sprite.visible = enabled and not _wall_join_diagnostic_enabled
	_wall_diagnostic_root.visible = enabled and _wall_join_diagnostic_enabled
	_update_assembly_label()


func is_wall_art_enabled() -> bool:
	return _wall_art_enabled


func set_rotated_paving_enabled(enabled: bool) -> void:
	_rotated_paving_enabled = enabled
	var paving := _assembly_root.get_node_or_null("PavingTiles")
	if paving == null:
		return
	for index in TILE_CENTERS.size():
		(paving.get_child(index) as Sprite2D).rotation_degrees = TILE_ROTATIONS[index] if enabled else 0.0
	_update_assembly_label()


func is_rotated_paving_enabled() -> bool:
	return _rotated_paving_enabled


func set_wall_join_diagnostic_enabled(enabled: bool) -> void:
	_wall_join_diagnostic_enabled = enabled
	_wall_sprite.visible = _wall_art_enabled and not enabled
	_wall_diagnostic_root.visible = _wall_art_enabled and enabled


func is_wall_join_diagnostic_enabled() -> bool:
	return _wall_join_diagnostic_enabled


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			set_presentation_mode(AssemblyMode.NEUTRAL_BLOCKOUT)
		KEY_2:
			set_presentation_mode(AssemblyMode.NATIVE_COURTYARD)
		KEY_3:
			set_presentation_mode(AssemblyMode.REPEAT_NW_DIAGNOSTIC)
		KEY_4:
			set_presentation_mode(AssemblyMode.QUIET_MODULAR)
		KEY_5:
			set_presentation_mode(AssemblyMode.FOUR_ASSET_ASSEMBLY)
		KEY_M:
			set_presentation_mode(AssemblyMode.FOUR_ASSET_ASSEMBLY if _assembly_mode == AssemblyMode.QUIET_MODULAR else AssemblyMode.QUIET_MODULAR)
		KEY_TAB:
			set_presentation_mode(AssemblyMode.NATIVE_COURTYARD if _assembly_mode == AssemblyMode.QUIET_MODULAR else AssemblyMode.QUIET_MODULAR)
		KEY_D:
			set_damage_enabled(not _damage_enabled)
		KEY_R:
			set_ring_enabled(not _ring_enabled)
		KEY_W:
			set_wall_art_enabled(not _wall_art_enabled)
		KEY_U:
			set_rotated_paving_enabled(not _rotated_paving_enabled)
		KEY_J:
			set_wall_join_diagnostic_enabled(not _wall_join_diagnostic_enabled)
		KEY_B:
			set_inlays_enabled(not are_inlays_enabled())
		KEY_V:
			var operator := get_node_or_null("/root/GameRoot/World/Operator")
			var preview := operator.get_node_or_null("CanonicalOperatorPresentation") if operator != null else null
			if preview != null:
				preview.call("set_canonical_enabled", not bool(preview.call("is_canonical_enabled")))
		_:
			return
	get_viewport().set_input_as_handled()


func _mode_name() -> String:
	match _assembly_mode:
		AssemblyMode.NEUTRAL_BLOCKOUT:
			return "MODE 1 · NEUTRAL BLOCKOUT"
		AssemblyMode.NATIVE_COURTYARD:
			return "MODE 2 · ORIGINAL NATIVE COURTYARD"
		AssemblyMode.REPEAT_NW_DIAGNOSTIC:
			return "MODE 3 · NW REPEAT · NONPRODUCTION"
		AssemblyMode.QUIET_MODULAR:
			return "MODE 4 · QUIET MODULAR 128 STUDY"
		AssemblyMode.FOUR_ASSET_ASSEMBLY:
			return "MODE 5 · FOUR-ASSET MATERIAL ASSEMBLY"
	return "SEPULCHER MATERIAL PILOT"


func _build_four_asset_assembly() -> void:
	_assembly_root.name = ASSEMBLY_ROOT_NAME
	_assembly_root.z_index = -1
	add_child(_assembly_root)
	var paving_root := Node2D.new()
	paving_root.name = "PavingTiles"
	paving_root.z_index = -20
	_assembly_root.add_child(paving_root)
	for index in TILE_CENTERS.size():
		var tile := Sprite2D.new()
		tile.name = ["PavingNW", "PavingNE", "PavingSW", "PavingSE"][index]
		tile.texture = BASE_TEXTURE
		tile.position = TILE_CENTERS[index]
		tile.rotation_degrees = TILE_ROTATIONS[index]
		tile.centered = true
		tile.scale = Vector2.ONE
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		paving_root.add_child(tile)
	_damage_root.name = "DamageOverlays"
	_damage_root.z_index = -18
	_assembly_root.add_child(_damage_root)
	_damage_layout_snapshot = _make_damage_layout()
	for index in _damage_layout_snapshot.size():
		var placement: Dictionary = _damage_layout_snapshot[index]
		var wear := Sprite2D.new()
		wear.name = "Damage_%02d" % (index + 1)
		wear.texture = DAMAGE_TEXTURE
		wear.centered = true
		wear.position = placement.position
		wear.rotation_degrees = float(placement.rotation_degrees)
		wear.flip_h = bool(placement.flip_h)
		wear.flip_v = bool(placement.flip_v)
		wear.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_damage_root.add_child(wear)
	_ring_sprite.name = "WitnessRing"
	_ring_sprite.texture = RING_TEXTURE
	_ring_sprite.centered = true
	_ring_sprite.position = Vector2(512.0, 384.0)
	_ring_sprite.z_index = -16
	_ring_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_assembly_root.add_child(_ring_sprite)
	_wall_sprite.name = "RetainingWallFullStrip"
	_wall_sprite.texture = WALL_STRIP_TEXTURE
	_wall_sprite.centered = false
	_wall_sprite.position = Vector2(128.0, 1.0)
	_wall_sprite.z_index = 2
	_wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_assembly_root.add_child(_wall_sprite)
	_build_wall_join_diagnostic()
	set_rotated_paving_enabled(true)


func _build_wall_join_diagnostic() -> void:
	_wall_diagnostic_root.name = "WallModuleJoinDiagnostic"
	_wall_diagnostic_root.visible = false
	_wall_diagnostic_root.z_index = 2
	_assembly_root.add_child(_wall_diagnostic_root)
	for index in 3:
		var module := Sprite2D.new()
		module.name = "WallModule_%d_NotCertified" % index
		module.texture = WALL_MODULE_TEXTURE
		module.centered = true
		module.position = Vector2(256.0 + index * 256.0, 704.0)
		module.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_wall_diagnostic_root.add_child(module)
	var label := Label.new()
	label.name = "DiagnosticLabel"
	label.position = Vector2(356.0, 622.0)
	label.text = "WALL MODULE JOIN · DIAGNOSTIC ONLY · NOT CERTIFIED"
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.06, 0.06, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	_wall_diagnostic_root.add_child(label)


func _make_damage_layout() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = DAMAGE_SEED
	var result: Array[Dictionary] = []
	for _index in 3:
		result.append({
			"position": Vector2(
				DAMAGE_X_CENTERS[rng.randi_range(0, DAMAGE_X_CENTERS.size() - 1)],
				DAMAGE_Y_CENTERS[rng.randi_range(0, DAMAGE_Y_CENTERS.size() - 1)]
			),
			"rotation_degrees": DAMAGE_ROTATIONS[rng.randi_range(0, DAMAGE_ROTATIONS.size() - 1)],
			"flip_h": rng.randi_range(0, 1) == 1,
			"flip_v": rng.randi_range(0, 1) == 1,
		})
	return result


func _update_assembly_label() -> void:
	if not is_instance_valid(_mode_label):
		return
	var rotation_text := "ROTATED" if _rotated_paving_enabled else "UNROTATED SEAM CHECK"
	_mode_label.text = "%s · 1–5 MODES · TAB 1/2 · M 4/5 · U %s · D DAMAGE:%s · R RING:%s · W WALL:%s · J JOIN DIAG · B INLAYS · V OPERATOR" % [
		_mode_name(), rotation_text, _visibility_token(_damage_enabled), _visibility_token(_ring_enabled), _visibility_token(_wall_art_enabled)
	]


func _visibility_token(enabled: bool) -> String:
	return "ON" if enabled else "OFF"
