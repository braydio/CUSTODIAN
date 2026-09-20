extends Node2D

const REVIEW_POINTS := {
	"creche": Vector2(0, -32),
	"ambulatory": Vector2(0, -864),
	"attestation": Vector2(0, -1744),
	"locker_reliquary": Vector2(704, -1984),
	"dust_lung": Vector2(0, -3200),
	"undergate": Vector2(0, -4320),
	"gate_plaza": Vector2(0, -5184),
	"custodian_approach": Vector2(0, -5872),
	"late_service": Vector2(-736, -5728),
}

@onready var awakening: Node2D = $AwakeningFirstReturn
@onready var operator: Node2D = $AwakeningFirstReturn/World/Operator
@onready var camera: Camera2D = $AwakeningFirstReturn/World/Camera2D

var checkpoint := "ready"
var production_underlays_ready := false
var production_foregrounds_ready := false

func _ready() -> void:
	operator.set_process(false)
	operator.set_physics_process(false)
	production_underlays_ready = _check_production("ArtUnderlay/Underlay")
	production_foregrounds_ready = _check_production("Occlusion/Foreground")
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

func _check_production(relative_path: String) -> bool:
	for zone_name in [
		"Zone01_Creche", "Zone02_Ambulatory", "Zone03_Attestation",
		"Zone04_LockerReliquary", "Zone05_DustLung", "Zone06_Undergate",
		"Zone07_GateOfDust", "Zone08_CustodianApproach", "Zone09_ChapelLateService",
	]:
		var node := awakening.get_node_or_null("World/AwakeningZones/%s/%s" % [zone_name, relative_path]) as Sprite2D
		if node == null or node.texture == null or node.scale != Vector2.ONE or not node.centered:
			return false
		if relative_path == "Occlusion/Foreground" and node.z_index != 10:
			return false
	return true
