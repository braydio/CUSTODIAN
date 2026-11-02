extends Node2D

const NativeProp := preload("res://game/world/levels/presentation/semantic_native_prop_2d.gd")

const DISPLAY := [
	[&"meridian_civic_lighting", &"lantern_standard_a", Vector2(-500, -90)],
	[&"meridian_civic_lighting", &"lantern_standard_amber", Vector2(-380, -90)],
	[&"meridian_civic_bench", &"bench_wood_short", Vector2(-220, -90)],
	[&"meridian_civic_utility", &"cabinet_tall_closed", Vector2(-40, -90)],
	[&"meridian_civic_basin", &"octagonal_jet_fountain", Vector2(140, -90)],
	[&"meridian_civic_planter", &"planter_rect_small_a", Vector2(320, -90)],
	[&"meridian_civic_traffic_control", &"concrete_barrier_striped", Vector2(500, -90)],
	[&"meridian_civic_crate", &"cargo_crate_long", Vector2(-250, 170)],
]

@onready var operator: Node2D = $Operator
@onready var props_root: Node2D = $Props

var ready_count := 0
var native_scale_preserved := true
var real_operator := false


func _ready() -> void:
	operator.add_to_group("player")
	operator.position = Vector2(0, 175)
	operator.visible = false
	operator.set_process(false)
	operator.set_physics_process(false)
	real_operator = operator.scene_file_path.ends_with("operator.tscn")
	for contract: Array in DISPLAY:
		var prop := NativeProp.new() as SemanticNativeProp2D
		prop.position = contract[2]
		if prop.configure(contract[0], contract[1]):
			props_root.add_child(prop)
			ready_count += 1
			native_scale_preserved = native_scale_preserved and prop.get_sprite().scale == Vector2.ONE
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-640, -360, 1280, 720), Color("11161a"), true)
	draw_rect(Rect2(-590, -120, 1180, 72), Color("30373a"), true)
	draw_line(Vector2(-590, -48), Vector2(590, -48), Color("9d7b3e"), 3.0)
	draw_rect(Rect2(-590, 145, 1180, 72), Color("30373a"), true)
	draw_line(Vector2(-590, 217), Vector2(590, 217), Color("9d7b3e"), 3.0)


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	return command == "hold_scale_fixture"
