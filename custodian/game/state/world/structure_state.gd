class_name StructureSimulationState
extends RefCounted

var structure_id := ""
var structure_type := ""
var sector_id := ""
var grid_position := Vector2i.ZERO
var hp := 0
var max_hp := 0
var status := "OPERATIONAL"
var subtype := ""
var powered := true
var critical_role := ""

func _init(id: String = "", type: String = "", sector: String = "", health: int = 0) -> void:
	structure_id = id; structure_type = type; sector_id = sector; max_hp = maxi(0, health); hp = max_hp

func apply_damage(amount: int) -> int:
	var before := hp; hp = clampi(hp - maxi(0, amount), 0, max_hp); status = "DESTROYED" if hp == 0 else ("DAMAGED" if hp < max_hp else "OPERATIONAL"); return before - hp

func repair(amount: int) -> int:
	var before := hp; hp = clampi(hp + maxi(0, amount), 0, max_hp); status = "DESTROYED" if hp == 0 else ("DAMAGED" if hp < max_hp else "OPERATIONAL"); return hp - before

func to_dict() -> Dictionary:
	return {"id": structure_id, "type": structure_type, "sector": sector_id, "grid_position": [grid_position.x, grid_position.y], "hp": hp, "max_hp": max_hp, "status": status, "subtype": subtype, "powered": powered, "critical_role": critical_role}

static func from_dict(data: Dictionary) -> StructureSimulationState:
	var value := StructureSimulationState.new(String(data.get("id", "")), String(data.get("type", "")), String(data.get("sector", "")), int(data.get("max_hp", 0)))
	value.hp = clampi(int(data.get("hp", value.max_hp)), 0, value.max_hp); value.status = String(data.get("status", "OPERATIONAL")); value.subtype = String(data.get("subtype", "")); value.powered = bool(data.get("powered", true)); value.critical_role = String(data.get("critical_role", ""))
	var position: Array = data.get("grid_position", [0, 0]); if position.size() >= 2: value.grid_position = Vector2i(int(position[0]), int(position[1]))
	return value
