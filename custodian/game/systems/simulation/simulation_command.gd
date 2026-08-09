class_name SimulationCommand
extends RefCounted
const SET_POLICY := &"set_policy"
const SET_FABRICATION_ALLOCATION := &"set_fabrication_allocation"
const SET_SECTOR_FORTIFICATION := &"set_sector_fortification"
const SET_TRANSIT_FORTIFICATION := &"set_transit_fortification"
const ADD_MATERIALS := &"add_materials"
const SPEND_MATERIALS := &"spend_materials"
const DAMAGE_STRUCTURE := &"damage_structure"
const QUEUE_REPAIR := &"queue_repair"
const QUEUE_FABRICATION := &"queue_fabrication"
const FAIL_CAMPAIGN := &"fail_campaign"
var sequence: int = 0
var issued_fixed_tick: int = 0
var at_world_tick: int = -1
var kind: StringName = &""
var payload: Dictionary = {}
func _init(command_kind: StringName = &"", data: Dictionary = {}, scheduled_world_tick: int = -1) -> void: kind = command_kind; payload = data.duplicate(true); at_world_tick = scheduled_world_tick
func to_dict() -> Dictionary: return {"sequence": sequence, "issued_fixed_tick": issued_fixed_tick, "at_world_tick": at_world_tick, "kind": String(kind), "payload": payload.duplicate(true)}
