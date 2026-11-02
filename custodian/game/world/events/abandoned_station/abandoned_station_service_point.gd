extends Area2D
class_name AbandonedStationServicePoint

var site: Node
var service_index := 0
var label_text := ""
var _label: Label


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	_label = Label.new()
	_label.text = label_text
	_label.position = Vector2(-52.0, -42.0)
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(0.78, 0.91, 0.95))
	add_child(_label)


func can_interact(_actor: Node = null) -> bool:
	if not is_instance_valid(site):
		return false
	if site.has_method("can_service"):
		return bool(site.call("can_service", service_index))
	return not site.is_service_complete(service_index)


func get_interaction_prompt() -> String:
	return "SERVICE %s" % label_text if can_interact() else ""


func get_interaction_prompt_body() -> String:
	return "Restore the abandoned station subsystem."


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return 76.0


func interact(_actor: Node) -> void:
	if can_interact():
		site.service_point(service_index)
