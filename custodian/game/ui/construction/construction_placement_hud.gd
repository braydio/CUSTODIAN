class_name ConstructionPlacementHUD
extends PanelContainer

@onready var title_label: Label = %Title
@onready var category_label: Label = %Category
@onready var ready_label: Label = %Ready
@onready var footprint_label: Label = %Footprint
@onready var rotation_label: Label = %Rotation
@onready var status_label: Label = %Status


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_snapshot(snapshot: Dictionary) -> void:
	visible = true
	update_snapshot(snapshot)


func update_snapshot(snapshot: Dictionary) -> void:
	if title_label == null:
		return
	title_label.text = str(snapshot.get("display_name", "CONSTRUCTION")).to_upper()
	category_label.text = "%s INFRASTRUCTURE" % str(snapshot.get("category", "utility")).to_upper()
	ready_label.text = "READY ×%d" % int(snapshot.get("ready_count", 0))
	var footprint := snapshot.get("footprint_tiles", Vector2i.ZERO) as Vector2i
	footprint_label.text = "FOOTPRINT %d×%d" % [footprint.x, footprint.y]
	rotation_label.text = "ROTATION %d°" % int(snapshot.get("rotation_degrees", 0))
	status_label.text = ("✓ " if bool(snapshot.get("valid", false)) else "✕ ") + str(snapshot.get("message", "SELECT SITE"))
	status_label.modulate = Color(0.55, 1.0, 0.88) if bool(snapshot.get("valid", false)) else Color(1.0, 0.55, 0.38)


func hide_hud() -> void:
	visible = false
