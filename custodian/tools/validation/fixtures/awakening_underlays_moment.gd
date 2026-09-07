extends Node2D

const REVIEW_POINTS := {
	"creche": Vector2(0, -32),
	"ambulatory": Vector2(0, -864),
	"attestation": Vector2(0, -1744),
	"locker_reliquary": Vector2(704, -1984),
	"dust_lung": Vector2(0, -3200),
}

@onready var awakening: Node2D = $AwakeningFirstReturn
@onready var operator: Node2D = $AwakeningFirstReturn/World/Operator
@onready var camera: Camera2D = $AwakeningFirstReturn/World/Camera2D

var checkpoint := "ready"
var production_underlays_ready := false
var remaining_blockouts_ready := false


func _ready() -> void:
	operator.set_process(false)
	operator.set_physics_process(false)
	production_underlays_ready = _check_production_underlays()
	remaining_blockouts_ready = _check_remaining_blockouts()
	_show_zone("creche")


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	if not command.begins_with("show_"):
		return false
	var zone_name := command.trim_prefix("show_")
	if not REVIEW_POINTS.has(zone_name):
		return false
	_show_zone(zone_name)
	return true


func _show_zone(zone_name: String) -> void:
	checkpoint = zone_name
	var point: Vector2 = REVIEW_POINTS[zone_name]
	operator.global_position = point
	camera.global_position = point


func _check_production_underlays() -> bool:
	for zone_name in ["Zone01_Creche", "Zone02_Ambulatory", "Zone03_Attestation", "Zone04_LockerReliquary", "Zone05_DustLung"]:
		var base := "World/AwakeningZones/%s" % zone_name
		var underlay := awakening.get_node_or_null("%s/ArtUnderlay/Underlay" % base) as Sprite2D
		var blockout := awakening.get_node_or_null("%s/BlockoutPresentation" % base) as Node2D
		if underlay == null or underlay.texture == null or underlay.scale != Vector2.ONE:
			return false
		if blockout == null or blockout.visible:
			return false
	return true


func _check_remaining_blockouts() -> bool:
	for zone_name in ["Zone06_Undergate", "Zone07_GateOfDust", "Zone08_CustodianApproach", "Zone09_ChapelLateService"]:
		var blockout := awakening.get_node_or_null("World/AwakeningZones/%s/BlockoutPresentation" % zone_name) as Node2D
		if blockout == null or not blockout.visible:
			return false
	return true
