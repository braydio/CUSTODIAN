class_name WorldSimulationState
extends RefCounted

const SectorStateScript := preload("res://game/state/world/sector_state.gd")
const StructureStateScript := preload("res://game/state/world/structure_state.gd")
const PolicyStateScript := preload("res://game/state/world/policy_state.gd")
const AssaultStateScript := preload("res://game/state/world/assault_state.gd")

## Pure campaign-world data. Systems may mutate this object; scenes must not.

const SNAPSHOT_VERSION := 1
const DEFAULT_SECTORS := [
	{"id": "COMMAND", "name": "Command"}, {"id": "POWER", "name": "Power"},
	{"id": "DEFENSE", "name": "Defense"}, {"id": "ARCHIVE", "name": "Archive"},
	{"id": "STORAGE", "name": "Storage"}, {"id": "TRANSIT", "name": "Transit"},
]

var seed := 0
var tick := 0
var ambient_threat := 0.0
var failed := false
var failure_reason := ""
var materials := 3
var inventory: Dictionary = {"SCRAP": 12, "COMPONENTS": 0, "ASSEMBLIES": 0, "MODULES": 0}
var power_load := 1.0
var logistics_throughput := 3.0
var logistics_load := 0.0
var logistics_pressure := 0.0
var logistics_multiplier := 1.0
var policies = PolicyStateScript.new()
var assault = AssaultStateScript.new()
var sectors: Dictionary = {}
var structures: Dictionary = {}
var repairs: Array[Dictionary] = []
var fabrication: Array[Dictionary] = []
var events: Array[Dictionary] = []

func _init(world_seed: int = 0) -> void:
	seed = world_seed
	for definition in DEFAULT_SECTORS:
		var sector = SectorStateScript.new(definition.id, definition.name)
		sectors[sector.sector_id] = sector
		var structure = StructureStateScript.new("%s_CORE" % sector.sector_id, "CORE", sector.sector_id, 100)
		structures[structure.structure_id] = structure

func threat_bucket() -> String:
	if ambient_threat < 1.5:
		return "LOW"
	if ambient_threat < 3.0:
		return "ELEVATED"
	if ambient_threat < 5.0:
		return "HIGH"
	return "CRITICAL"

func record_event(kind: String, data: Dictionary = {}) -> void:
	events.append({"tick": tick, "kind": kind, "data": data.duplicate(true)})
	if events.size() > 32:
		events.pop_front()

func to_dict() -> Dictionary:
	var sector_rows := {}
	for key in sectors.keys():
		sector_rows[String(key)] = sectors[key].to_dict()
	var structure_rows := {}
	for key in structures.keys():
		structure_rows[String(key)] = structures[key].to_dict()
	return {
		"snapshot_version": SNAPSHOT_VERSION, "seed": seed, "tick": tick,
		"ambient_threat": ambient_threat, "threat_bucket": threat_bucket(),
		"failed": failed, "failure_reason": failure_reason, "materials": materials,
		"inventory": inventory.duplicate(true), "power_load": power_load,
		"logistics": {"throughput": logistics_throughput, "load": logistics_load, "pressure": logistics_pressure, "multiplier": logistics_multiplier},
		"policies": policies.to_dict(), "assault": assault.to_dict(),
		"sectors": sector_rows, "structures": structure_rows,
		"repairs": repairs.duplicate(true), "fabrication": fabrication.duplicate(true),
		"events": events.duplicate(true),
	}

func fingerprint() -> String:
	return "%016x" % hash(JSON.stringify(to_dict()))
