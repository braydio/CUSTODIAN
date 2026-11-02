extends Node2D

## Dev-only tour harness for the Awakening blockout.
##
## Instances the real scene and drives the real controller — it adds no gameplay
## and registers no global hotkeys, so nothing here can leak into a build's
## input map. Everything it draws comes from AwakeningLayout.

const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const AWAKENING := preload("res://scenes/awakening_first_return.tscn")

@onready var overlay: Node2D = $Overlay
@onready var zone_selector: OptionButton = $UI/Panel/Margin/Content/ZoneRow/ZoneSelector

var awakening: Node = null


func _ready() -> void:
	awakening = AWAKENING.instantiate()
	add_child(awakening)
	move_child(awakening, 0)
	_populate_zones()
	overlay.set("awakening", awakening)
	_connect_buttons()


func _populate_zones() -> void:
	zone_selector.clear()
	for zone in Layout.ZONES:
		zone_selector.add_item("%02d  %s" % [int(zone["index"]), String(zone["location"])])
	zone_selector.selected = 0


func _connect_buttons() -> void:
	var content := $UI/Panel/Margin/Content
	content.get_node("TeleportButton").pressed.connect(_on_teleport)
	content.get_node("ShowCollision").toggled.connect(_on_toggle.bind("show_collision"))
	content.get_node("ShowZoneBounds").toggled.connect(_on_toggle.bind("show_zone_bounds"))
	content.get_node("ShowLandmarks").toggled.connect(_on_toggle.bind("show_landmarks"))
	content.get_node("ResetButton").pressed.connect(_on_reset)


func _on_teleport() -> void:
	if awakening == null: return
	awakening.call("teleport_operator_to_zone", zone_selector.selected + 1)


func _on_toggle(pressed: bool, property: String) -> void:
	overlay.set(property, pressed)
	overlay.queue_redraw()


func _on_reset() -> void:
	if awakening != null:
		awakening.call("reset_progression")


func _process(_delta: float) -> void:
	var label := $UI/Panel/Margin/Content/StateLabel as Label
	if awakening == null or label == null: return
	var state: Dictionary = awakening.call("get_awakening_state")
	label.text = "ZONE %02d   console=%s  p9=%s  complete=%s\n%s" % [
		int(state.get("current_zone_index", 0)),
		str(state.get("opening_console_acknowledged", false)),
		str(state.get("p9_recovered", false)),
		str(state.get("completed", false)),
		str(state.get("operator_position", Vector2.ZERO)),
	]
