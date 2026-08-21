extends SceneTree

const OPERATOR_SCRIPT := preload("res://game/actors/operator/operator.gd")


func _init() -> void:
	var operator := OPERATOR_SCRIPT.new()
	var errors: Array[String] = []
	var single_contact := {
		"contacts": [{"id": "primary", "frames": [3]}],
	}
	for sample in [
		[1, 2, 6],
		[0, 3, 6],
		[0, 4, 6],
		[0, 5, 6],
	]:
		var contacts := operator.debug_collect_crossed_contact_frames(
			sample[0], sample[1], sample[2], single_contact
		)
		if contacts != [2]:
			errors.append("crossed contact was not retained for sample %s: %s" % [sample, contacts])
	var two_contacts := {
		"contacts": [
			{"id": "opening", "frames": [2]},
			{"id": "return", "frames": [5]},
		],
	}
	var multi := operator.debug_collect_crossed_contact_frames(0, 5, 7, two_contacts)
	if multi != [1, 4]:
		errors.append("one update crossing two contacts did not preserve both: %s" % [multi])
	var wrapped := operator.debug_collect_crossed_contact_frames(5, 2, 6, single_contact)
	if wrapped != [2]:
		errors.append("wrapped animation cursor lost contact: %s" % [wrapped])
	operator.free()
	if errors.is_empty():
		print("operator_melee_low_fps_contact_smoke: PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("operator_melee_low_fps_contact_smoke: %s" % error)
	quit(1)
