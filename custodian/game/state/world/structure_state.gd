class_name StructureSimulationState
extends RefCounted

var structure_id := ""
var structure_type := ""
var sector_id := ""
var hp := 0
var max_hp := 0
var subtype := ""
var powered := true

func _init(id: String = "", type: String = "", sector: String = "", health: int = 0) -> void:
	structure_id = id
	structure_type = type
	sector_id = sector
	hp = health
	max_hp = health

func apply_damage(amount: int) -> int:
	var before := hp
	hp = maxi(0, hp - maxi(0, amount))
	return before - hp

func to_dict() -> Dictionary:
	return {"id": structure_id, "type": structure_type, "sector": sector_id, "hp": hp, "max_hp": max_hp, "subtype": subtype, "powered": powered}
