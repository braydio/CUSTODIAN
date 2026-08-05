class_name SectorSimulationState
extends RefCounted

var sector_id := ""
var name := ""
var damage := 0.0
var alertness := 0.0
var power := 1.0
var occupied := false
var effects: Dictionary = {}

func _init(id: String = "", sector_name: String = "") -> void:
	sector_id = id
	name = sector_name

func status_label() -> String:
	if damage >= 2.0:
		return "COMPROMISED"
	if damage >= 1.0 or alertness >= 2.0:
		return "DAMAGED"
	if alertness >= 0.8 or occupied:
		return "ALERT"
	return "STABLE"

func to_dict() -> Dictionary:
	return {"id": sector_id, "name": name, "damage": damage, "alertness": alertness, "power": power, "occupied": occupied, "effects": effects.duplicate(true), "status": status_label()}
