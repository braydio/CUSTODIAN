extends Damageable
class_name LightBarricade

@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var intact_visual: Node2D = $Visuals/Intact
@onready var damaged_visual: Node2D = $Visuals/Damaged


func _ready() -> void:
	add_to_group("structure")
	add_to_group("buildable_structure")
	add_to_group("enemy_obstacle")
	super._ready()
	_update_damage_visuals()


func _on_state_changed(_new_state: String) -> void:
	_update_damage_visuals()


func _on_destroyed() -> void:
	destroyed.emit()
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	queue_free()


func _update_damage_visuals() -> void:
	if intact_visual == null or damaged_visual == null:
		return
	var show_damaged := state == "damaged" or state == "critical"
	intact_visual.visible = not show_damaged
	damaged_visual.visible = show_damaged
