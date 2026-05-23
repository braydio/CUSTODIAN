extends RefCounted
class_name GothicCompoundResult

var ok: bool = false
var used_fallback: bool = false
var rect: Rect2i = Rect2i()
var gate_width_tiles: int = 5
var gate_cell: Vector2i = Vector2i.ZERO
var command_keep_cell: Vector2i = Vector2i.ZERO
var terminal_cell: Vector2i = Vector2i.ZERO
var approach_path: Array[Vector2i] = []
var internal_path: Array[Vector2i] = []
var required_walkable: Dictionary = {}
var zones: Dictionary = {}
var flags := {
	"has_perimeter": false,
	"has_gate": false,
	"has_command_keep": false,
	"has_terminal": false,
	"has_approach_road": false,
	"has_internal_road": false,
}
var placement_errors: Array[String] = []
var placed_walls: Array[Vector2i] = []
var placed_structures: Array[Vector2i] = []
var placed_props: Array[Vector2i] = []
var placed_resources: Array[Vector2i] = []
var placed_markers: Array[Vector2i] = []
var placed_decals: int = 0
var errors: Array[String] = []


func mark_required_path(path: Array[Vector2i]) -> void:
	for cell in path:
		required_walkable[cell] = true
