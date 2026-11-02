extends AuthoredLevel2D
class_name KenneyIsometricBlockoutPlaytestLevel

const PRESENTATION := preload("res://scenes/debug/kenney_isometric_blockout_presentation.gd")

enum PresentationMode { NATIVE, KENNEY }

const EVALUATION_BOUNDS := PRESENTATION.EVALUATION_BOUNDS

const BOUNDARY_SEGMENTS := [
	[Vector2(-2600, -4300), Vector2(2600, -4300)],
	[Vector2(2600, -4300), Vector2(2600, 350)],
	[Vector2(2600, 350), Vector2(-2600, 350)],
	[Vector2(-2600, 350), Vector2(-2600, -4300)],
]

const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "Spawn_Main",
		"label": "FORUM SOUTH PLAYTEST",
		"kind": "spawn",
		"position": Vector2(0, -2464),
	},
	"south_reach": {
		"node_name": "Spawn_SouthReach",
		"label": "SOUTH REACH",
		"kind": "poi",
		"position": Vector2(-6, 162),
	},
	"adjudication_dais": {
		"node_name": "AdjudicationDais",
		"label": "ADJUDICATION DAIS",
		"kind": "poi",
		"position": Vector2(0, -3136),
	},
}

@onready var _shared_sample: Node2D = %SharedSpatialSample
@onready var _anchor_markers: Node2D = %AnchorMarkers
@onready var _native_root: Node2D = %NativePresentation
@onready var _kenney_root: Node2D = %KenneyPresentation
@onready var _mode_label: Label = %ModeLabel

var _kenney_textures: Dictionary = {}
var _presentation_mode := PresentationMode.NATIVE


func get_boundary_segments() -> Array:
	return BOUNDARY_SEGMENTS


func get_authoring_markers() -> Dictionary:
	return AUTHORING_MARKERS


func _ready() -> void:
	super._ready()
	_kenney_textures = PRESENTATION.load_kenney_textures()
	PRESENTATION.build(_shared_sample, _anchor_markers, _native_root, _kenney_root, _kenney_textures)
	set_presentation_mode(PresentationMode.KENNEY)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			set_presentation_mode(PresentationMode.NATIVE)
		KEY_2:
			set_presentation_mode(PresentationMode.KENNEY)
		KEY_TAB:
			var next_mode := PresentationMode.NATIVE if _presentation_mode == PresentationMode.KENNEY else PresentationMode.KENNEY
			set_presentation_mode(next_mode)


func set_presentation_mode(mode: PresentationMode) -> void:
	_presentation_mode = mode
	_native_root.visible = mode == PresentationMode.NATIVE
	_kenney_root.visible = mode == PresentationMode.KENNEY
	_mode_label.text = "K3D-1P · %s · 1 NATIVE · 2 KENNEY · TAB TOGGLE · COLLISION: ENVELOPE ONLY" % _mode_name()


func _mode_name() -> String:
	return "NATIVE" if _presentation_mode == PresentationMode.NATIVE else "KENNEY"
