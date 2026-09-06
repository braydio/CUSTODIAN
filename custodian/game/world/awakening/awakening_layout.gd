extends RefCounted

## Single spatial authority for CUSTODIAN Awakening / The First Return, sections 01-10.
##
## Every coordinate in the opening dungeon lives here. The runtime scene, the
## progression controller, the mapper adapter, the debug tour, and the geometry
## validator all query this file. Do not duplicate these numbers into a .tscn, a
## controller, or a test — except where a test is deliberately asserting a locked
## value.
##
## Convention: +X east, -X west, +Y south, -Y north. World origin is the centre of
## the Crèche. Macro geometry is 32px aligned.

const WORLD_TILE := 32.0
const AWAKENING_ORIGIN := Vector2.ZERO
const OPERATOR_WAKE_POSITION := Vector2(0, 160)
const WORLD_BOUNDS := Rect2(-1088, -7328, 2176, 7680)

const OPERATOR_COLLISION_RADIUS := 11.0

const ROAD_PROTOTYPE := preload("res://game/world/hub/road_of_witnesses_prototype.gd")

# --- Road of Witnesses reuse -------------------------------------------------
# The Road prototype is authored around its own origin. Section 10 is that same
# scene translated so its existing southern spawn lands on the Approach exit.
const ROAD_LOCAL_SOUTH_ENTRY := Vector2(-6, 482)
const ROAD_WORLD_SOUTH_ENTRY := Vector2(0, -6144)
const ROAD_WORLD_OFFSET := Vector2(6, -6626)
const ROAD_LOCAL_BOUNDS := Rect2(-627, -627, 1254, 1254)
# Local-space gap cut in the Road's southern boundary wall so the Approach joins
# it as continuous walkable space instead of a sealed map edge.
const ROAD_SOUTH_GATE_GAP_CENTER_X := -6.0
const ROAD_SOUTH_GATE_GAP_WIDTH := 192.0

const SOUTH_REACH_COMPLETION_CENTER := Vector2(0, -6464)
const SOUTH_REACH_COMPLETION_SIZE := Vector2(256, 96)
const SOUTH_REACH_BARRIER_Y := -6530.0
const SOUTH_REACH_BARRIER_X_MIN := -541.0
const SOUTH_REACH_BARRIER_X_MAX := 553.0
const SOUTH_REACH_BARRIER_DEPTH := 48.0

# --- Zones -------------------------------------------------------------------

const ZONES: Array[Dictionary] = [
	{
		"id": &"zone01_creche", "index": 1, "node": "Zone01_Creche",
		"location": "CRÈCHE OF ANSWERLESS NAMES", "phase": "RECOVERY",
		"envelope": Rect2(-416, -320, 832, 576),
		"entry": Vector2(0, 160), "exit": Vector2(0, -320), "optional": false,
	},
	{
		"id": &"zone02_ambulatory", "index": 2, "node": "Zone02_Ambulatory",
		"location": "RECOVERY AMBULATORY", "phase": "PROCESSING",
		"envelope": Rect2(-512, -1280, 1024, 832),
		"entry": Vector2(0, -480), "exit": Vector2(0, -1248), "optional": false,
	},
	{
		"id": &"zone03_attestation", "index": 3, "node": "Zone03_Attestation",
		"location": "ATTESTATION GALLERY", "phase": "AUTHORITY CHECK",
		"envelope": Rect2(-352, -2144, 704, 800),
		"entry": Vector2(0, -1344), "exit": Vector2(352, -1984), "optional": false,
	},
	{
		"id": &"zone04_locker_reliquary", "index": 4, "node": "Zone04_LockerReliquary",
		"location": "LOCKER RELIQUARY", "phase": "ASSIGNMENT",
		"envelope": Rect2(416, -2272, 576, 576),
		"entry": Vector2(416, -1984), "exit": Vector2(704, -2272), "optional": false,
	},
	{
		"id": &"zone05_dust_lung", "index": 5, "node": "Zone05_DustLung",
		"location": "DUST LUNG CISTERN", "phase": "ASCENT",
		"envelope": Rect2(-544, -3744, 1088, 1088),
		"entry": Vector2(0, -2656), "exit": Vector2(0, -3744), "optional": false,
	},
	{
		"id": &"zone06_undergate", "index": 6, "node": "Zone06_Undergate",
		"location": "UNDERGATE MECHANISM HALL", "phase": "PORT INFRASTRUCTURE",
		"envelope": Rect2(-384, -4864, 768, 1088),
		"entry": Vector2(0, -3776), "exit": Vector2(0, -4864), "optional": false,
	},
	{
		"id": &"zone07_gate_of_dust", "index": 7, "node": "Zone07_GateOfDust",
		"location": "GATE OF DUST", "phase": "HISTORICAL CITY",
		"envelope": Rect2(-704, -5504, 1408, 640),
		"entry": Vector2(0, -4864), "exit": Vector2(0, -5504), "optional": false,
	},
	{
		"id": &"zone08_custodian_approach", "index": 8, "node": "Zone08_CustodianApproach",
		"location": "CUSTODIAN APPROACH", "phase": "RECALL",
		"envelope": Rect2(-448, -6240, 896, 736),
		"entry": Vector2(0, -5504), "exit": Vector2(0, -6144), "optional": false,
	},
	{
		"id": &"zone09_chapel_late_service", "index": 9, "node": "Zone09_ChapelLateService",
		"location": "CHAPEL OF LATE SERVICE", "phase": "UNREGISTERED CHAPEL",
		"envelope": Rect2(-1024, -6048, 576, 640),
		"entry": Vector2(-448, -5760), "exit": Vector2(-448, -5760), "optional": true,
	},
	{
		"id": &"zone10_road_south_reach", "index": 10, "node": "Zone10_RoadSouthReach",
		"location": "ROAD OF WITNESSES // SOUTH REACH", "phase": "CIVIC AXIS",
		"envelope": Rect2(-621, -7253, 1254, 1254),
		"entry": Vector2(0, -6144), "exit": Vector2(0, -6464), "optional": false,
	},
]

# --- Locked connectors -------------------------------------------------------
# Verbatim from the design lock. Minimum critical-route width is 128px.

const CONNECTORS := {
	"01_02": Rect2(-64, -480, 128, 160),
	"02_03": Rect2(-64, -1344, 128, 96),
	"03_04": Rect2(352, -2048, 64, 128),
	"04_05_A": Rect2(640, -2432, 128, 160),
	"04_05_B": Rect2(0, -2560, 704, 128),
	"04_05_C": Rect2(-64, -2656, 128, 96),
	"05_06": Rect2(-64, -3776, 128, 32),
	"09_BRANCH": Rect2(-448, -5824, 288, 128),
}

## Doorways derived from the locked room skeleton: each one bridges a zone's
## walkable floor to a locked connector or to an adjoining zone edge. Like
## connectors, these always win over set-piece collision.
const THRESHOLDS := {
	"z01_north_door": Rect2(-64, -320, 128, 64),
	"z03_south_door": Rect2(-64, -1376, 128, 32),
	"z03_east_door": Rect2(256, -2048, 96, 128),
	"z06_south_door": Rect2(-64, -3840, 128, 64),
	"z06_north_door": Rect2(-64, -4864, 128, 64),
	"z06_register_corridor": Rect2(-416, -4368, 192, 96),
	"z09_chapel_corridor": Rect2(-544, -5824, 96, 128),
}

# --- Walkable floors ---------------------------------------------------------

const FLOOR_RECTS := {
	&"zone01_creche": [Rect2(-352, -256, 704, 512)],
	&"zone03_attestation": [Rect2(-256, -2080, 512, 704)],
	&"zone06_undergate": [
		Rect2(-224, -4800, 448, 960),
		Rect2(-704, -4512, 288, 320),
	],
	&"zone07_gate_of_dust": [Rect2(-704, -5504, 1408, 640)],
	&"zone08_custodian_approach": [Rect2(-160, -6208, 320, 704)],
	# Section 10 is the existing Road prototype translated by ROAD_WORLD_OFFSET;
	# its own blocker rects supply the interior collision (see road_blocking_rects).
	&"zone10_road_south_reach": [Rect2(-621, -7253, 1254, 1254)],
}

const FLOOR_POLYGONS := {
	&"zone02_ambulatory": [[
		Vector2(-288, -1248), Vector2(288, -1248), Vector2(480, -1056), Vector2(480, -672),
		Vector2(288, -480), Vector2(-288, -480), Vector2(-480, -672), Vector2(-480, -1056),
	]],
	&"zone04_locker_reliquary": [[
		Vector2(576, -2272), Vector2(832, -2272), Vector2(992, -2112), Vector2(992, -1856),
		Vector2(832, -1696), Vector2(576, -1696), Vector2(416, -1856), Vector2(416, -2112),
	]],
	&"zone05_dust_lung": [[
		Vector2(-320, -3744), Vector2(320, -3744), Vector2(544, -3520), Vector2(544, -2880),
		Vector2(320, -2656), Vector2(-320, -2656), Vector2(-544, -2880), Vector2(-544, -3520),
	]],
	&"zone09_chapel_late_service": [[
		Vector2(-832, -5408), Vector2(-640, -5408), Vector2(-544, -5504), Vector2(-544, -5856),
		Vector2(-608, -5984), Vector2(-736, -6048), Vector2(-864, -5984), Vector2(-928, -5856),
		Vector2(-928, -5504),
	]],
}

## Inaccessible cores. The Ambulatory rings the Crèche headwall; the Cistern rings
## its dry shaft.
const VOID_POLYGONS := {
	&"zone02_ambulatory": [[
		Vector2(-160, -1120), Vector2(160, -1120), Vector2(288, -992), Vector2(288, -736),
		Vector2(160, -608), Vector2(-160, -608), Vector2(-288, -736), Vector2(-288, -992),
	]],
	&"zone05_dust_lung": [[
		Vector2(-128, -3408), Vector2(128, -3408), Vector2(208, -3328), Vector2(208, -3072),
		Vector2(128, -2992), Vector2(-128, -2992), Vector2(-208, -3072), Vector2(-208, -3328),
	]],
}

# --- Set pieces --------------------------------------------------------------
# `blocking` set pieces contribute collision. Connectors and thresholds are carved
# back out afterwards, so a set piece can never seal the locked route.

const SET_PIECES := {
	&"zone01_creche": [
		{"id": "active_alcove", "label": "ACTIVE RECOVERY ALCOVE", "position": Vector2(0, 208), "size": Vector2(96, 144), "blocking": false},
		{"id": "creche_console", "label": "CRÈCHE CONSOLE", "position": Vector2(112, 144), "size": Vector2(56, 40), "blocking": true},
		{"id": "authority_floor_seal", "label": "AUTHORITY FLOOR SEAL", "position": Vector2(0, -160), "size": Vector2(160, 160), "blocking": false},
		{"id": "headwall_inscription", "label": "HEADWALL INSCRIPTION", "position": Vector2(0, -240), "size": Vector2(320, 32), "blocking": false},
		{"id": "alcove_w1", "label": "INACTIVE ALCOVE", "position": Vector2(-320, -192), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_w2", "label": "INACTIVE ALCOVE", "position": Vector2(-320, -64), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_w3", "label": "INACTIVE ALCOVE", "position": Vector2(-320, 64), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_w4", "label": "INACTIVE ALCOVE", "position": Vector2(-320, 192), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_e1", "label": "INACTIVE ALCOVE", "position": Vector2(320, -192), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_e2", "label": "INACTIVE ALCOVE", "position": Vector2(320, -64), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_e3", "label": "INACTIVE ALCOVE", "position": Vector2(320, 64), "size": Vector2(72, 112), "blocking": true},
		{"id": "alcove_e4", "label": "INACTIVE ALCOVE", "position": Vector2(320, 192), "size": Vector2(72, 112), "blocking": true},
		{"id": "hammered_seals", "label": "WALL OF HAMMERED SEALS", "position": Vector2(-272, 224), "size": Vector2(128, 32), "blocking": true},
		{"id": "relic_table", "label": "SIDE RELIC TABLE", "position": Vector2(272, 224), "size": Vector2(96, 40), "blocking": true},
	],
	&"zone02_ambulatory": [
		{"id": "west_service_basin", "label": "WEST SERVICE BASIN", "position": Vector2(-352, -704), "size": Vector2(96, 96), "blocking": true},
		{"id": "nw_inspection_niche", "label": "NORTHWEST INSPECTION NICHE", "position": Vector2(-352, -1024), "size": Vector2(96, 96), "blocking": true},
		{"id": "hidden_reliquary", "label": "HIDDEN RELIQUARY COMPARTMENT", "position": Vector2(-368, -1088), "size": Vector2(48, 48), "blocking": false},
		{"id": "east_service_basin", "label": "EAST SERVICE BASIN", "position": Vector2(352, -864), "size": Vector2(96, 96), "blocking": true},
		{"id": "broken_panel", "label": "BROKEN REFLECTIVE PANEL", "position": Vector2(352, -688), "size": Vector2(48, 96), "blocking": false},
		{"id": "lore_plaque", "label": "LORE PLAQUE", "position": Vector2(352, -1040), "size": Vector2(48, 64), "blocking": false},
	],
	&"zone03_attestation": [
		{"id": "stele_w1", "label": "ATTESTATION STELE", "position": Vector2(-304, -1440), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_w2", "label": "ATTESTATION STELE", "position": Vector2(-304, -1536), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_w3", "label": "ATTESTATION STELE", "position": Vector2(-304, -1632), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_w4", "label": "ATTESTATION STELE", "position": Vector2(-304, -1728), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_w5", "label": "ATTESTATION STELE", "position": Vector2(-304, -1824), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_w6", "label": "ATTESTATION STELE", "position": Vector2(-304, -1920), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_e1", "label": "ATTESTATION STELE", "position": Vector2(304, -1440), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_e2", "label": "ATTESTATION STELE", "position": Vector2(304, -1536), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_e3", "label": "ATTESTATION STELE", "position": Vector2(304, -1632), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_e4", "label": "ATTESTATION STELE", "position": Vector2(304, -1728), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_e5", "label": "ATTESTATION STELE", "position": Vector2(304, -1824), "size": Vector2(48, 96), "blocking": true},
		{"id": "stele_e6", "label": "ATTESTATION STELE", "position": Vector2(304, -1920), "size": Vector2(48, 96), "blocking": true},
		{"id": "attestation_dais", "label": "ATTESTATION DAIS", "position": Vector2(0, -2048), "size": Vector2(192, 64), "blocking": false},
		{"id": "sigil_fragment", "label": "SIGIL FRAGMENT", "position": Vector2(0, -2016), "size": Vector2(32, 32), "blocking": false},
	],
	# Reliquary lockers are recessed into the chamber wall face, so they read as
	# relief rather than free-standing obstacles; the central basin is the only
	# floor obstruction and circulation runs around it.
	&"zone04_locker_reliquary": [
		{"id": "dry_basin", "label": "CENTRAL DRY BASIN", "position": Vector2(704, -1984), "size": Vector2(128, 128), "blocking": true},
		{"id": "p9_locker", "label": "P-9 DESIGNATION LOCKER", "position": Vector2(836, -1944), "size": Vector2(88, 96), "blocking": true, "prop": true},
		{"id": "inactive_locker_a", "label": "INACTIVE LOCKER", "position": Vector2(832, -2112), "size": Vector2(88, 96), "blocking": false},
		{"id": "inactive_locker_b", "label": "INACTIVE LOCKER", "position": Vector2(576, -2112), "size": Vector2(88, 96), "blocking": false},
		{"id": "inactive_locker_c", "label": "INACTIVE LOCKER", "position": Vector2(576, -1824), "size": Vector2(88, 96), "blocking": false},
		{"id": "recalled_not_verified", "label": "RECALLED / NOT VERIFIED", "position": Vector2(896, -1824), "size": Vector2(88, 96), "blocking": false},
		{"id": "welded_locker", "label": "WELDED LOCKER", "position": Vector2(512, -1952), "size": Vector2(88, 96), "blocking": false},
	],
	&"zone05_dust_lung": [
		{"id": "broken_west_bridge", "label": "BROKEN WEST BRIDGE", "position": Vector2(-352, -3264), "size": Vector2(224, 64), "blocking": false},
		{"id": "lift_mechanism", "label": "LIFT MECHANISM", "position": Vector2(448, -2944), "size": Vector2(64, 64), "blocking": true},
		{"id": "daylight_split", "label": "DAYLIGHT SPLIT", "position": Vector2(0, -3680), "size": Vector2(256, 32), "blocking": false},
	],
	&"zone06_undergate": [
		{"id": "drum_west", "label": "GIANT DRUM", "position": Vector2(-288, -4144), "size": Vector2(160, 224), "blocking": true},
		{"id": "drum_east", "label": "GIANT DRUM", "position": Vector2(288, -4144), "size": Vector2(160, 224), "blocking": true},
		{"id": "coil_west", "label": "ROUTE COIL", "position": Vector2(-288, -4448), "size": Vector2(96, 96), "blocking": true},
		{"id": "coil_east", "label": "ROUTE COIL", "position": Vector2(288, -4448), "size": Vector2(96, 96), "blocking": true},
		{"id": "damaged_plinth", "label": "DAMAGED MECHANISM PLINTH", "position": Vector2(128, -4016), "size": Vector2(64, 56), "blocking": true},
		{"id": "housing_wa", "label": "BLIND HOUSING", "position": Vector2(-320, -3968), "size": Vector2(64, 96), "blocking": true},
		{"id": "housing_ea", "label": "BLIND HOUSING", "position": Vector2(320, -3968), "size": Vector2(64, 96), "blocking": true},
		{"id": "housing_wb", "label": "BLIND HOUSING", "position": Vector2(-320, -4512), "size": Vector2(64, 96), "blocking": true},
		{"id": "housing_eb", "label": "BLIND HOUSING", "position": Vector2(320, -4512), "size": Vector2(64, 96), "blocking": true},
		{"id": "route_tablets", "label": "ROUTE TABLETS", "position": Vector2(-640, -4448), "size": Vector2(96, 48), "blocking": true},
		{"id": "fallen_shelving", "label": "FALLEN SHELVING", "position": Vector2(-608, -4256), "size": Vector2(128, 48), "blocking": true},
		{"id": "brass_needles", "label": "DEAD BRASS NEEDLES", "position": Vector2(-528, -4448), "size": Vector2(48, 48), "blocking": false},
		{"id": "route_map_wall", "label": "ROUTE MAP WALL", "position": Vector2(-560, -4496), "size": Vector2(224, 32), "blocking": false},
	],
	&"zone07_gate_of_dust": [
		{"id": "gate_pylon_west", "label": "GATE PYLON", "position": Vector2(-256, -4768), "size": Vector2(160, 320), "blocking": true},
		{"id": "gate_pylon_east", "label": "GATE PYLON", "position": Vector2(256, -4768), "size": Vector2(160, 320), "blocking": true},
		{"id": "rest_checkpoint", "label": "REST / CHECKPOINT", "position": Vector2(0, -5056), "size": Vector2(96, 64), "blocking": false},
	],
	&"zone08_custodian_approach": [
		{"id": "chapel_shell_w1", "label": "CHAPEL SHELL", "position": Vector2(-304, -5600), "size": Vector2(192, 160), "blocking": true},
		{"id": "chapel_shell_w2", "label": "CHAPEL SHELL", "position": Vector2(-304, -5824), "size": Vector2(192, 160), "blocking": true},
		{"id": "chapel_shell_w3", "label": "CHAPEL SHELL", "position": Vector2(-304, -6048), "size": Vector2(192, 160), "blocking": true},
		{"id": "chapel_shell_e1", "label": "CHAPEL SHELL", "position": Vector2(304, -5600), "size": Vector2(192, 160), "blocking": true},
		{"id": "chapel_shell_e2", "label": "CHAPEL SHELL", "position": Vector2(304, -5824), "size": Vector2(192, 160), "blocking": true},
		{"id": "chapel_shell_e3", "label": "CHAPEL SHELL", "position": Vector2(304, -6048), "size": Vector2(192, 160), "blocking": true},
		{"id": "burial_terrace_sw", "label": "BURIAL TERRACE", "position": Vector2(-416, -5664), "size": Vector2(96, 64), "blocking": false},
		{"id": "burial_terrace_se", "label": "BURIAL TERRACE", "position": Vector2(416, -5664), "size": Vector2(96, 64), "blocking": false},
		{"id": "burial_terrace_nw", "label": "BURIAL TERRACE", "position": Vector2(-416, -5984), "size": Vector2(96, 64), "blocking": false},
		{"id": "burial_terrace_ne", "label": "BURIAL TERRACE", "position": Vector2(416, -5984), "size": Vector2(96, 64), "blocking": false},
	],
	&"zone09_chapel_late_service": [
		{"id": "mosaic_center", "label": "MOSAIC", "position": Vector2(-736, -5696), "size": Vector2(192, 192), "blocking": false},
		{"id": "relay_lamp_altar", "label": "RELAY-LAMP ALTAR", "position": Vector2(-736, -5904), "size": Vector2(112, 64), "blocking": true},
		{"id": "thread_anchor_nw", "label": "THREAD ANCHOR", "position": Vector2(-896, -5888), "size": Vector2(32, 32), "blocking": false},
		{"id": "thread_anchor_ne", "label": "THREAD ANCHOR", "position": Vector2(-576, -5888), "size": Vector2(32, 32), "blocking": false},
		{"id": "thread_anchor_sw", "label": "THREAD ANCHOR", "position": Vector2(-896, -5568), "size": Vector2(32, 32), "blocking": false},
		{"id": "thread_anchor_se", "label": "THREAD ANCHOR", "position": Vector2(-576, -5568), "size": Vector2(32, 32), "blocking": false},
	],
}

# --- Named markers -----------------------------------------------------------
# Gameplay anchors: spawns, interactables, triggers, disabled encounter slots and
# future-art anchors. Kinds: spawn, interactable, trigger, encounter, marker, lift.

const MARKERS := {
	&"zone01_creche": [
		{"id": "operator_wake", "label": "CUSTODIAN WAKE", "kind": "spawn", "position": Vector2(0, 160)},
		{"id": "creche_console", "label": "CRÈCHE CONSOLE", "kind": "interactable", "position": Vector2(112, 144)},
	],
	&"zone02_ambulatory": [
		{"id": "hidden_reliquary", "label": "HIDDEN RELIQUARY COMPARTMENT", "kind": "marker", "position": Vector2(-368, -1088)},
		{"id": "lore_plaque", "label": "LORE PLAQUE", "kind": "marker", "position": Vector2(352, -1040)},
	],
	&"zone03_attestation": [
		{"id": "central_aisle_trigger", "label": "CENTRAL AISLE", "kind": "trigger", "position": Vector2(0, -1696)},
		{"id": "sentinel_spawn_a", "label": "ATTESTATION SENTINEL A", "kind": "encounter", "position": Vector2(-160, -1664)},
		{"id": "sentinel_spawn_b", "label": "ATTESTATION SENTINEL B", "kind": "encounter", "position": Vector2(160, -1664)},
		{"id": "attestation_dais", "label": "ATTESTATION DAIS", "kind": "marker", "position": Vector2(0, -2048)},
		{"id": "sigil_fragment", "label": "SIGIL FRAGMENT", "kind": "marker", "position": Vector2(0, -2016)},
	],
	&"zone04_locker_reliquary": [
		{"id": "p9_locker", "label": "P-9 DESIGNATION LOCKER", "kind": "interactable", "position": Vector2(832, -1952)},
	],
	&"zone05_dust_lung": [
		{"id": "lift_lower", "label": "TRANSIT LIFT / LOWER", "kind": "lift", "position": Vector2(384, -3008)},
		{"id": "lift_upper", "label": "TRANSIT LIFT / UPPER", "kind": "lift", "position": Vector2(384, -3424)},
		{"id": "lift_mechanism", "label": "LIFT MECHANISM", "kind": "interactable", "position": Vector2(448, -2944)},
		{"id": "scavenger_nest", "label": "SCAVENGER NEST", "kind": "encounter", "position": Vector2(-384, -3504)},
		{"id": "central_shaft", "label": "CENTRAL SHAFT", "kind": "marker", "position": Vector2(0, -3200)},
	],
	&"zone06_undergate": [
		{"id": "port_status_plaque", "label": "DAMAGED PORT CONSOLE", "kind": "interactable", "position": Vector2(128, -4016)},
		{"id": "register_of_departures", "label": "REGISTER OF DEPARTURES", "kind": "marker", "position": Vector2(-560, -4352)},
	],
	&"zone07_gate_of_dust": [
		{"id": "gate_aperture", "label": "GATE OF DUST APERTURE", "kind": "marker", "position": Vector2(0, -4768)},
		{"id": "south_wasteland_vista", "label": "SOUTH WASTELAND VISTA", "kind": "marker", "position": Vector2(0, -4704)},
		{"id": "rest_checkpoint", "label": "REST / CHECKPOINT", "kind": "marker", "position": Vector2(0, -5056)},
	],
	&"zone08_custodian_approach": [
		{"id": "return_to_post_beacon", "label": "RETURN TO POST", "kind": "trigger", "position": Vector2(0, -5600)},
		{"id": "approach_sentinel", "label": "LONG-RANGE SENTINEL", "kind": "encounter", "position": Vector2(0, -5888)},
		{"id": "road_reveal_trigger", "label": "ROAD REVEAL", "kind": "trigger", "position": Vector2(0, -6080)},
		{"id": "road_anchor", "label": "ROAD SOUTH REACH ANCHOR", "kind": "marker", "position": Vector2(0, -6144)},
	],
	&"zone09_chapel_late_service": [
		{"id": "reward_cache", "label": "OPTIONAL REWARD CACHE", "kind": "marker", "position": Vector2(-880, -5488)},
		{"id": "route_leech", "label": "ROUTE-LEECH", "kind": "encounter", "position": Vector2(-704, -5888)},
	],
	&"zone10_road_south_reach": [
		{"id": "south_reach_completion", "label": "SOUTH REACH COMPLETION", "kind": "trigger", "position": Vector2(0, -6464)},
	],
}

const GATE_APERTURE_CENTER := Vector2(0, -4768)
const GATE_APERTURE_DIAMETER := 352.0

# --- Camera reveals ----------------------------------------------------------

const CAMERA_REVEALS := {
	&"zone05_dust_lung": {
		"trigger": Vector2(0, -2688), "size": Vector2(256, 96),
		"offset": Vector2(0, -48), "zoom": Vector2(0.72, 0.72),
		"transition_sec": 0.90, "hold_sec": 1.20,
	},
	&"zone07_gate_of_dust": {
		"trigger": Vector2(0, -4912), "size": Vector2(320, 96),
		"offset": Vector2(0, 100), "zoom": Vector2(0.68, 0.68),
		"transition_sec": 1.10, "hold_sec": 1.80,
	},
	&"zone08_custodian_approach": {
		"trigger": Vector2(0, -6080), "size": Vector2(256, 96),
		"offset": Vector2(0, -120), "zoom": Vector2(0.66, 0.66),
		"transition_sec": 1.20, "hold_sec": 2.00,
	},
}

# --- Blockout palette --------------------------------------------------------

const COLOR_FLOOR := Color("1B1D1E")
const COLOR_DEEP_WALL := Color("0A0C0D")
const COLOR_ELEVATED_FACADE := Color("111518")
const COLOR_OLD_BRASS := Color("806B43")
const COLOR_COLD_CIVIC_LIGHT := Color("A6B6B8")
const COLOR_ACTIVE_TECH := Color("47747B")
const COLOR_DUST := Color("58534C")
const COLOR_VOID := Color("050606")

const Z_FLOOR := 0
const Z_WORLD_PROPS := 1
const Z_OPERATOR := 2
const Z_FOREGROUND := 4

const WALL_CAP_DEPTH := 24.0
const WALL_FACADE_DEPTH := 48.0

# --- Queries -----------------------------------------------------------------

static func zone_by_id(zone_id: StringName) -> Dictionary:
	for zone in ZONES:
		if StringName(zone["id"]) == zone_id: return zone
	return {}

static func zone_by_index(index: int) -> Dictionary:
	for zone in ZONES:
		if int(zone["index"]) == index: return zone
	return {}

static func zone_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for zone in ZONES: result.append(StringName(zone["id"]))
	return result

static func zone_entry(index: int) -> Vector2:
	var zone := zone_by_index(index)
	return zone.get("entry", OPERATOR_WAKE_POSITION) if not zone.is_empty() else OPERATOR_WAKE_POSITION

static func floors_for(zone_id: StringName) -> Array:
	var result: Array = []
	for rect in FLOOR_RECTS.get(zone_id, []): result.append(rect)
	for polygon in FLOOR_POLYGONS.get(zone_id, []): result.append(polygon)
	return result

static func set_pieces_for(zone_id: StringName) -> Array:
	return SET_PIECES.get(zone_id, [])

static func markers_for(zone_id: StringName) -> Array:
	return MARKERS.get(zone_id, [])

## Every rect that is unconditionally walkable, regardless of set-piece collision.
static func traversal_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for key in CONNECTORS: result.append(CONNECTORS[key])
	for key in THRESHOLDS: result.append(THRESHOLDS[key])
	return result

static func set_piece_rect(piece: Dictionary) -> Rect2:
	var size: Vector2 = piece.get("size", Vector2(32, 32))
	var position: Vector2 = piece.get("position", Vector2.ZERO)
	return Rect2(position - size * 0.5, size)

## Blocking collision contributed by set pieces across all zones.
static func blocking_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for zone_id in SET_PIECES:
		for piece in SET_PIECES[zone_id]:
			if bool(piece.get("blocking", false)):
				result.append(set_piece_rect(piece))
	return result

static func south_reach_barrier_rect() -> Rect2:
	return Rect2(
		SOUTH_REACH_BARRIER_X_MIN,
		SOUTH_REACH_BARRIER_Y - SOUTH_REACH_BARRIER_DEPTH * 0.5,
		SOUTH_REACH_BARRIER_X_MAX - SOUTH_REACH_BARRIER_X_MIN,
		SOUTH_REACH_BARRIER_DEPTH
	)

static func south_reach_completion_rect() -> Rect2:
	return Rect2(
		SOUTH_REACH_COMPLETION_CENTER - SOUTH_REACH_COMPLETION_SIZE * 0.5,
		SOUTH_REACH_COMPLETION_SIZE
	)

static func road_world_bounds() -> Rect2:
	return Rect2(ROAD_LOCAL_BOUNDS.position + ROAD_WORLD_OFFSET, ROAD_LOCAL_BOUNDS.size)

## The Road prototype owns its own blocker geometry; this translates it into
## Awakening world space with the southern causeway gap applied, so the validator
## and the runtime scene agree without either copying the numbers.
static func road_blocking_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in ROAD_PROTOTYPE.build_blocker_rects(ROAD_SOUTH_GATE_GAP_CENTER_X, ROAD_SOUTH_GATE_GAP_WIDTH):
		result.append(Rect2(rect.position + ROAD_WORLD_OFFSET, rect.size))
	result.append(south_reach_barrier_rect())
	return result

## Const dictionaries cannot hold PackedVector2Array literals, so polygons are
## authored as plain Vector2 arrays and packed here.
static func to_polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points: result.append(point as Vector2)
	return result


static func rect_to_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
	])

static func is_point_walkable(point: Vector2) -> bool:
	for rect in traversal_rects():
		if rect.has_point(point): return true
	if road_world_bounds().has_point(point):
		for blocker in road_blocking_rects():
			if blocker.has_point(point): return false
	for zone in ZONES:
		var zone_id := StringName(zone["id"])
		for area in floors_for(zone_id):
			var inside := false
			if area is Rect2: inside = (area as Rect2).has_point(point)
			else: inside = Geometry2D.is_point_in_polygon(point, to_polygon(area as Array))
			if not inside: continue
			for hole in VOID_POLYGONS.get(zone_id, []):
				if Geometry2D.is_point_in_polygon(point, to_polygon(hole as Array)): return false
			return true
	return false
