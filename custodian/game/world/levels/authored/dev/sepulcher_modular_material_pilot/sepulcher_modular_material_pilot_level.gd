extends AuthoredLevel2D
class_name SepulcherModularMaterialPilotLevel

enum PresentationMode { BLOCKOUT = 1, NATIVE_QUAD = 2, REPEAT_NW = 3 }

const ROOM_BOUNDS := Rect2(0.0, 0.0, 1024.0, 768.0)
const BOUNDARY_SEGMENTS := [
	[Vector2(0.0, 0.0), Vector2(1024.0, 0.0)],
	[Vector2(1024.0, 0.0), Vector2(1024.0, 768.0)],
	[Vector2(1024.0, 768.0), Vector2(0.0, 768.0)],
	[Vector2(0.0, 768.0), Vector2(0.0, 0.0)],
]
const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "Spawn_Main",
		"label": "SEPULCHER PAVING PLAYTEST",
		"kind": "spawn",
		"position": Vector2(512.0, 520.0),
	},
}

@onready var _blockout_root: Node2D = %BlockoutPresentation
@onready var _quad_root: Node2D = %NativeQuadPresentation
@onready var _repeat_root: Node2D = %RepeatDiagnosticPresentation
@onready var _mode_label: Label = %ModeLabel

var _presentation_mode := PresentationMode.NATIVE_QUAD
var _vault_manager: Node
var _vault_fallback_was_enabled := false
var _restore_vault_fallback := false


func _ready() -> void:
	super._ready()
	_disable_unrelated_debug_vault_fallback()
	_build_neutral_blockout()
	set_presentation_mode(PresentationMode.NATIVE_QUAD)


func _exit_tree() -> void:
	if _restore_vault_fallback and is_instance_valid(_vault_manager):
		_vault_manager.set("create_debug_vault_if_missing", _vault_fallback_was_enabled)


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func set_presentation_mode(mode: PresentationMode) -> void:
	if mode < PresentationMode.BLOCKOUT or mode > PresentationMode.REPEAT_NW:
		push_warning("Sepulcher paving preview: invalid presentation mode %s" % mode)
		return
	_presentation_mode = mode
	_blockout_root.visible = mode == PresentationMode.BLOCKOUT
	_quad_root.visible = mode == PresentationMode.NATIVE_QUAD
	_repeat_root.visible = mode == PresentationMode.REPEAT_NW
	_mode_label.text = _mode_label_text()


func get_presentation_mode() -> PresentationMode:
	return _presentation_mode


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			set_presentation_mode(PresentationMode.BLOCKOUT)
		KEY_2:
			set_presentation_mode(PresentationMode.NATIVE_QUAD)
		KEY_3:
			set_presentation_mode(PresentationMode.REPEAT_NW)
		KEY_TAB:
			set_presentation_mode(
				PresentationMode.NATIVE_QUAD
				if _presentation_mode == PresentationMode.BLOCKOUT
				else PresentationMode.BLOCKOUT
			)


func _mode_label_text() -> String:
	match _presentation_mode:
		PresentationMode.BLOCKOUT:
			return "MODE 1 · NEUTRAL BLOCKOUT · 2 NATIVE QUAD · 3 NW REPEAT · TAB 1/2"
		PresentationMode.NATIVE_QUAD:
			return "MODE 2 · NATIVE FOUR-CROP · 1 BLOCKOUT · 3 NW REPEAT · TAB 1/2"
		PresentationMode.REPEAT_NW:
			return "MODE 3 · NW REPEAT DIAGNOSTIC · NOT FOR PRODUCTION"
	return "SEPULCHER PAVING PLAYTEST"


func _build_neutral_blockout() -> void:
	var floor := Polygon2D.new()
	floor.name = "NeutralFloor"
	floor.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(ROOM_BOUNDS.size.x, 0.0),
		ROOM_BOUNDS.size,
		Vector2(0.0, ROOM_BOUNDS.size.y),
	])
	floor.color = Color("#555653")
	floor.z_index = -20
	_blockout_root.add_child(floor)
	for x in range(0, int(ROOM_BOUNDS.size.x) + 1, 128):
		_add_blockout_line(Vector2(x, 0.0), Vector2(x, ROOM_BOUNDS.size.y))
	for y in range(0, int(ROOM_BOUNDS.size.y) + 1, 128):
		_add_blockout_line(Vector2(0.0, y), Vector2(ROOM_BOUNDS.size.x, y))


func _add_blockout_line(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.name = "NeutralGridLine"
	line.points = PackedVector2Array([from, to])
	line.width = 1.0
	line.default_color = Color(0.84, 0.82, 0.76, 0.22)
	line.z_index = -19
	_blockout_root.add_child(line)


func _disable_unrelated_debug_vault_fallback() -> void:
	_vault_manager = get_node_or_null("/root/VaultManager")
	if _vault_manager == null or not ("create_debug_vault_if_missing" in _vault_manager):
		return
	_vault_fallback_was_enabled = bool(_vault_manager.get("create_debug_vault_if_missing"))
	_restore_vault_fallback = true
	_vault_manager.set("create_debug_vault_if_missing", false)
