class_name WorldSimulationState
extends RefCounted

const SNAPSHOT_SCHEMA := "custodian.world_simulation_state"
const SNAPSHOT_VERSION := 4
const MAX_EVENTS := 32

var seed: int = 0
var text_seed: int = 0
var fixed_tick: int = 0
var world_tick: int = 0
var ambient_threat: float = 0.0
var assaults_enabled := true
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
var relay_knowledge_level := 0
var relay_dormancy_pressure := 0
var macro_fidelity := "FULL"
var signal_interference_ticks := 0
var ambient_fab_progress: Dictionary = {"DEFENSE": 0.0, "DRONES": 0.0, "REPAIRS": 0.0, "ARCHIVE": 0.0}
var repairs: Array = []
var fabrication_queue: Array = []
var events: Array = []
var systemic_event_state: Dictionary = {
	"ticks_since_assault": 0, "ticks_since_hostile": 0, "last_category": "",
	"recent_categories": [], "recent_keys": [], "history": [],
}
var rng_state: int = 1

func _init(world_seed: int = 0, world_text_seed: int = -1) -> void:
	seed = world_seed; text_seed = world_seed if world_text_seed < 0 else world_text_seed
	rng_state = (world_seed ^ 0x6D2B79F5) & 0x7fffffff
	if rng_state == 0: rng_state = 1
	for sector_id in WorldIdentityContract.MACRO_SECTOR_IDS:
		sectors[sector_id] = SectorSimulationState.new(sector_id, WorldIdentityContract.display_name(sector_id))
		policies.sector_fortification[sector_id] = 0
	for transit_id in WorldIdentityContract.TRANSIT_IDS:
		transit_states[transit_id] = {"id": transit_id, "status": "STABLE"}
	_initialize_relays()

func _initialize_relays() -> void:
	relays = {
		"R_NORTH": {"id": "R_NORTH", "sector_id": "T_NORTH", "status": "LOCATED", "stability": 80.0, "packets_pending": 0},
		"R_SOUTH": {"id": "R_SOUTH", "sector_id": "T_SOUTH", "status": "LOCATED", "stability": 80.0, "packets_pending": 0},
		"R_ARCHIVE": {"id": "R_ARCHIVE", "sector_id": "ARCHIVE", "status": "UNKNOWN", "stability": 40.0, "packets_pending": 0},
		"R_GATEWAY": {"id": "R_GATEWAY", "sector_id": "GATEWAY", "status": "UNKNOWN", "stability": 40.0, "packets_pending": 0},
	}

func next_random_unit() -> float:
	# One serialized LCG stream is shared by all authoritative macro systems.
	rng_state = int((int(rng_state) * 1103515245 + 12345) & 0x7fffffff)
	return float(rng_state) / 2147483648.0

func next_random_index(count: int) -> int:
	return 0 if count <= 1 else mini(count - 1, int(next_random_unit() * count))

func get_tick() -> int: return fixed_tick
var tick: int:
	get: return fixed_tick

func record_event(kind: StringName, data: Dictionary = {}) -> void:
	events.append({"fixed_tick": fixed_tick, "world_tick": world_tick, "kind": String(kind), "data": data.duplicate(true)})
	while events.size() > MAX_EVENTS: events.pop_front()

func to_dict() -> Dictionary:
	return {"schema": SNAPSHOT_SCHEMA, "schema_version": SNAPSHOT_VERSION, "seed": seed, "text_seed": text_seed, "rng_state": rng_state, "fixed_tick": fixed_tick, "world_tick": world_tick, "ambient_threat": ambient_threat, "assaults_enabled": assaults_enabled, "failed": failed, "failure_reason": failure_reason, "resources": {"materials": materials}, "inventory": inventory.duplicate(true), "stocks": stocks.duplicate(true), "power_load": power_load, "logistics": {"throughput": logistics_throughput, "load": logistics_load, "pressure": logistics_pressure, "multiplier": logistics_multiplier}, "policies": policies.to_dict(), "assault": assault.to_dict(), "relay_knowledge_level": relay_knowledge_level, "relay_dormancy_pressure": relay_dormancy_pressure, "macro_fidelity": macro_fidelity, "ambient_fab_progress": ambient_fab_progress.duplicate(true), "signal_interference_ticks": signal_interference_ticks, "systemic_event_state": systemic_event_state.duplicate(true), "sectors": _objects_to_dict(sectors), "transit_states": _deep_dict(transit_states), "structures": _objects_to_dict(structures), "relays": _objects_to_dict(relays), "repairs": _object_array(repairs), "fabrication_queue": _object_array(fabrication_queue), "events": events.duplicate(true)}

static func from_dict(data: Dictionary) -> WorldSimulationState:
	var value := WorldSimulationState.new(int(data.get("seed", 0)), int(data.get("text_seed", data.get("seed", 0))))
	value.fixed_tick = int(data.get("fixed_tick", data.get("tick", 0))); value.world_tick = int(data.get("world_tick", value.fixed_tick / 60)); value.ambient_threat = float(data.get("ambient_threat", 0.0)); value.assaults_enabled = bool(data.get("assaults_enabled", true)); value.failed = bool(data.get("failed", false)); value.failure_reason = String(data.get("failure_reason", "")); value.rng_state = int(data.get("rng_state", value.rng_state)); value.relay_knowledge_level = int(data.get("relay_knowledge_level", 0)); value.relay_dormancy_pressure = int(data.get("relay_dormancy_pressure", 0)); value.macro_fidelity = String(data.get("macro_fidelity", "FULL")); value.ambient_fab_progress = (data.get("ambient_fab_progress", value.ambient_fab_progress) as Dictionary).duplicate(true); value.signal_interference_ticks = maxi(0, int(data.get("signal_interference_ticks", 0))); value.systemic_event_state = _normalize_integer_values((data.get("systemic_event_state", value.systemic_event_state) as Dictionary).duplicate(true))
	var resources: Dictionary = data.get("resources", {}); value.materials = int(resources.get("materials", data.get("materials", 3))); value.inventory = _integer_dict(data.get("inventory", value.inventory)); value.stocks = _integer_dict(data.get("stocks", value.stocks)); value.power_load = float(data.get("power_load", 1.0))
	var logistics: Dictionary = data.get("logistics", {}); value.logistics_throughput = float(logistics.get("throughput", 3.0)); value.logistics_load = float(logistics.get("load", 0.0)); value.logistics_pressure = float(logistics.get("pressure", 0.0)); value.logistics_multiplier = float(logistics.get("multiplier", 1.0)); value.policies = PolicySimulationState.from_dict(data.get("policies", {})); value.assault = AssaultSimulationState.from_dict(data.get("assault", {}))
	for key in (data.get("sectors", {}) as Dictionary): value.sectors[String(key)] = SectorSimulationState.from_dict(data["sectors"][key])
	value.transit_states = (data.get("transit_states", {}) as Dictionary).duplicate(true)
	for key in (data.get("structures", {}) as Dictionary): value.structures[String(key)] = StructureSimulationState.from_dict(data["structures"][key])
	if data.has("relays"):
		value.relays = (data.get("relays", {}) as Dictionary).duplicate(true)
		for relay_id in value.relays:
			var relay: Dictionary = value.relays[relay_id]
			relay.stability = float(relay.get("stability", 0.0)); relay.packets_pending = int(relay.get("packets_pending", 0))
	value.repairs = (data.get("repairs", []) as Array).duplicate(true); value.fabrication_queue = (data.get("fabrication_queue", data.get("fabrication", [])) as Array).duplicate(true); value.events = _normalize_integer_values((data.get("events", []) as Array).duplicate(true))
	return value

func clone() -> WorldSimulationState: return from_dict(to_dict())

func parity_projection() -> Dictionary:
	var relay_projection := {}
	for relay_id in relays:
		var relay: Dictionary = relays[relay_id]
		relay_projection[relay_id] = {"sector_id": relay.sector_id, "status": relay.status, "stability": relay.stability, "packets_pending": relay.packets_pending}
	return {"schema_version": 3, "seed": seed, "world_tick": world_tick, "resources": {"materials": materials}, "inventory": inventory.duplicate(true), "stocks": stocks.duplicate(true), "policies": policies.to_dict(), "power_load": power_load, "logistics": {"throughput": logistics_throughput, "load": logistics_load, "pressure": logistics_pressure, "multiplier": logistics_multiplier}, "macro_state": {"relays": relay_projection, "relay_knowledge": relay_knowledge_level, "relay_dormancy_pressure": relay_dormancy_pressure, "ticks_since_assault": int(systemic_event_state.get("ticks_since_assault", 0)), "ticks_since_hostile": int(systemic_event_state.get("ticks_since_hostile", 0)), "assault": {"phase": assault.phase, "ingress": assault.ingress_id, "target": assault.objective, "eta_ticks": assault.eta_ticks}}}

func canonical_fingerprint() -> String: return SimulationCanonicalJson.sha256(to_dict())
func fingerprint() -> String: return canonical_fingerprint()

static func _objects_to_dict(source: Dictionary) -> Dictionary:
	var result := {}; for key in source: result[String(key)] = source[key].to_dict() if source[key] is Object and source[key].has_method("to_dict") else source[key]
	return result
static func _deep_dict(source: Dictionary) -> Dictionary: return source.duplicate(true)
static func _integer_dict(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if source is Dictionary:
		for key in source: result[String(key)] = int(source[key])
	return result
static func _normalize_integer_values(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = _normalize_integer_values(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(_normalize_integer_values(item))
		return result
	if value is float and is_equal_approx(value, round(value)): return int(round(value))
	return value
static func _object_array(source: Array) -> Array:
	var result: Array = []
	for item in source:
		result.append(item.to_dict() if item is Object and item.has_method("to_dict") else item)
	return result
