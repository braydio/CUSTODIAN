class_name WorldSimulationState
extends RefCounted

const SNAPSHOT_SCHEMA := "custodian.world_simulation_state"
const SNAPSHOT_VERSION := 2
const MAX_EVENTS := 32

var seed: int = 0
var text_seed: int = 0
var fixed_tick: int = 0
var world_tick: int = 0
var ambient_threat: float = 0.0
var failed: bool = false
var failure_reason: String = ""
var materials: int = 3
var inventory: Dictionary = {"SCRAP": 12, "COMPONENTS": 0, "ASSEMBLIES": 0, "MODULES": 0}
var stocks: Dictionary = {"repair_drones": 0, "turret_ammo": 6}
var power_load: float = 1.0
var logistics_throughput: float = 3.0
var logistics_load: float = 0.0
var logistics_pressure: float = 0.0
var logistics_multiplier: float = 1.0
var policies: PolicySimulationState = PolicySimulationState.new()
var assault: AssaultSimulationState = AssaultSimulationState.new()
var sectors: Dictionary = {}
var transit_states: Dictionary = {}
var structures: Dictionary = {}
var relays: Dictionary = {}
var repairs: Array = []
var fabrication_queue: Array = []
var events: Array = []

func _init(world_seed: int = 0, world_text_seed: int = -1) -> void:
	seed = world_seed; text_seed = world_seed if world_text_seed < 0 else world_text_seed
	for sector_id in WorldIdentityContract.MACRO_SECTOR_IDS:
		sectors[sector_id] = SectorSimulationState.new(sector_id, WorldIdentityContract.display_name(sector_id))
		policies.sector_fortification[sector_id] = 0
	for transit_id in WorldIdentityContract.TRANSIT_IDS:
		transit_states[transit_id] = {"id": transit_id, "status": "STABLE"}

func get_tick() -> int: return fixed_tick
var tick: int:
	get: return fixed_tick

func record_event(kind: StringName, data: Dictionary = {}) -> void:
	events.append({"fixed_tick": fixed_tick, "world_tick": world_tick, "kind": String(kind), "data": data.duplicate(true)})
	while events.size() > MAX_EVENTS: events.pop_front()

func to_dict() -> Dictionary:
	return {"schema": SNAPSHOT_SCHEMA, "schema_version": SNAPSHOT_VERSION, "seed": seed, "text_seed": text_seed, "fixed_tick": fixed_tick, "world_tick": world_tick, "ambient_threat": ambient_threat, "failed": failed, "failure_reason": failure_reason, "resources": {"materials": materials}, "inventory": inventory.duplicate(true), "stocks": stocks.duplicate(true), "power_load": power_load, "logistics": {"throughput": logistics_throughput, "load": logistics_load, "pressure": logistics_pressure, "multiplier": logistics_multiplier}, "policies": policies.to_dict(), "assault": assault.to_dict(), "sectors": _objects_to_dict(sectors), "transit_states": _deep_dict(transit_states), "structures": _objects_to_dict(structures), "relays": _objects_to_dict(relays), "repairs": _object_array(repairs), "fabrication_queue": _object_array(fabrication_queue), "events": events.duplicate(true)}

static func from_dict(data: Dictionary) -> WorldSimulationState:
	var value := WorldSimulationState.new(int(data.get("seed", 0)), int(data.get("text_seed", data.get("seed", 0))))
	value.fixed_tick = int(data.get("fixed_tick", data.get("tick", 0))); value.world_tick = int(data.get("world_tick", value.fixed_tick / 60)); value.ambient_threat = float(data.get("ambient_threat", 0.0)); value.failed = bool(data.get("failed", false)); value.failure_reason = String(data.get("failure_reason", ""))
	var resources: Dictionary = data.get("resources", {}); value.materials = int(resources.get("materials", data.get("materials", 3))); value.inventory = (data.get("inventory", value.inventory) as Dictionary).duplicate(true); value.stocks = (data.get("stocks", value.stocks) as Dictionary).duplicate(true); value.power_load = float(data.get("power_load", 1.0))
	var logistics: Dictionary = data.get("logistics", {}); value.logistics_throughput = float(logistics.get("throughput", 3.0)); value.logistics_load = float(logistics.get("load", 0.0)); value.logistics_pressure = float(logistics.get("pressure", 0.0)); value.logistics_multiplier = float(logistics.get("multiplier", 1.0)); value.policies = PolicySimulationState.from_dict(data.get("policies", {})); value.assault = AssaultSimulationState.from_dict(data.get("assault", {}))
	for key in (data.get("sectors", {}) as Dictionary): value.sectors[String(key)] = SectorSimulationState.from_dict(data["sectors"][key])
	value.transit_states = (data.get("transit_states", {}) as Dictionary).duplicate(true)
	for key in (data.get("structures", {}) as Dictionary): value.structures[String(key)] = StructureSimulationState.from_dict(data["structures"][key])
	value.relays = (data.get("relays", {}) as Dictionary).duplicate(true); value.repairs = (data.get("repairs", []) as Array).duplicate(true); value.fabrication_queue = (data.get("fabrication_queue", data.get("fabrication", [])) as Array).duplicate(true); value.events = (data.get("events", []) as Array).duplicate(true)
	return value

func clone() -> WorldSimulationState: return from_dict(to_dict())

func parity_projection() -> Dictionary:
	return {"schema_version": 2, "seed": seed, "world_tick": world_tick, "resources": {"materials": materials}, "inventory": inventory.duplicate(true), "stocks": stocks.duplicate(true), "policies": policies.to_dict(), "power_load": power_load, "logistics": {"throughput": logistics_throughput, "load": logistics_load, "pressure": logistics_pressure, "multiplier": logistics_multiplier}}

func canonical_fingerprint() -> String: return SimulationCanonicalJson.sha256(to_dict())
func fingerprint() -> String: return canonical_fingerprint()

static func _objects_to_dict(source: Dictionary) -> Dictionary:
	var result := {}; for key in source: result[String(key)] = source[key].to_dict() if source[key] != null and source[key].has_method("to_dict") else source[key]
	return result
static func _deep_dict(source: Dictionary) -> Dictionary: return source.duplicate(true)
static func _object_array(source: Array) -> Array:
	var result: Array = []
	for item in source:
		result.append(item.to_dict() if item is Object and item.has_method("to_dict") else item)
	return result
