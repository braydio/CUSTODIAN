class_name MeridianTransitIngressSite
extends WorldIngressSite

const CLEARANCE_RECT := Rect2(-176.0, -144.0, 352.0, 288.0)
const TRANSIT_DESCENT := preload("res://content/sprites/environment/props/ash_bell/lower_quarter/meridian_transit_descent/runtime/body/meridian_transit_descent__body__interaction__idle__omni__1f__288x224.png")


func _init() -> void:
	requires_explicit_interaction = true


func _ready() -> void:
	super._ready()
	_ensure_visual()


func _ensure_visual() -> void:
	var sprite := get_node_or_null("ProductionPresentation") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "ProductionPresentation"
		add_child(sprite)
	sprite.texture = TRANSIT_DESCENT


func _draw() -> void:
	pass


func get_procgen_dressing_clearance_world_rect() -> Rect2:
	return Rect2(to_global(CLEARANCE_RECT.position), CLEARANCE_RECT.size)
