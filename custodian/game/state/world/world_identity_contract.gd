class_name WorldIdentityContract
extends RefCounted

const MACRO_SECTOR_IDS := ["COMMAND", "POWER", "COMMS", "DEFENSE_GRID", "FABRICATION", "ARCHIVE", "STORAGE", "HANGAR", "GATEWAY"]
const TRANSIT_IDS := ["T_NORTH", "T_SOUTH"]
const SCENE_SECTOR_TO_MACRO := {"POWER": "POWER", "DEFENSE": "DEFENSE_GRID", "ARCHIVE": "ARCHIVE", "STORAGE": "STORAGE", "NORTH_TRANSIT": "T_NORTH", "SOUTH_TRANSIT": "T_SOUTH"}

static func is_macro_sector(value: String) -> bool: return value in MACRO_SECTOR_IDS
static func is_transit(value: String) -> bool: return value in TRANSIT_IDS
static func map_scene_identity(value: String) -> String: return String(SCENE_SECTOR_TO_MACRO.get(value, ""))
static func display_name(value: String) -> String: return "DEFENSE GRID" if value == "DEFENSE_GRID" else value
