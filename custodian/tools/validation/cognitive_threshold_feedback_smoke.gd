extends SceneTree
const STATE := preload("res://game/systems/cognitive/cognitive_state_system.gd")
const OVERLAY := preload("res://game/ui/cognitive/cognitive_feedback_overlay.tscn")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var state := STATE.new(); state.name = "TestCognitive"; state.decay_per_second = 0.0; root.add_child(state)
	var changes: Array = []; state.cognitive_threshold_changed.connect(func(axis, old, new, value): changes.append([axis, old, new, value]))
	state.add_recollection(3.0); assert(state.get_axis_tier(&"recollection") == 1); state.add_recollection(3.0); assert(state.get_axis_tier(&"recollection") == 2)
	assert(changes.size() == 2 and is_equal_approx(state.get_axis_intensity(&"recollection"), 1.0))
	var overlay := OVERLAY.instantiate(); root.add_child(overlay); assert(overlay.layer == 10); assert((overlay.get_node("Overlay") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(FileAccess.get_file_as_string("res://scenes/game.tscn").contains("layer = 20"))
	print("cognitive_threshold_feedback_smoke: PASS"); quit(0)
